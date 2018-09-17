/*
 *  PicoSoC - A simple example SoC using PicoRV32
 *
 *  Copyright (C) 2017  Clifford Wolf <clifford@clifford.at>
 *
 *  Permission to use, copy, modify, and/or distribute this software for any
 *  purpose with or without fee is hereby granted, provided that the above
 *  copyright notice and this permission notice appear in all copies.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 *  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 *  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 *  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 *  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 *  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 *  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 */

module hardware (
    input clk_16mhz,

    // onboard USB interface
    output pin_pu,

    // hardware UART
    output pin_1,
    input pin_2,

    // onboard SPI flash interface
    output flash_csb,
    output flash_clk,
    inout  flash_io0,
    inout  flash_io1,
    inout  flash_io2,
    inout  flash_io3,

    // GPIO buttons
    inout  [7:0] buttons,
`ifdef audio
    // Audio out pin
    output audio,
`endif
`ifdef i2c
    // I2C pins
    inout sda,
    inout scl,
`endif    
    // onboard LED
    output user_led

);
    assign pin_pu = 1'b0;

    wire clk = clk_16mhz;
  
    ///////////////////////////////////
    // Power-on Reset
    ///////////////////////////////////
    reg [5:0] reset_cnt = 0;
    wire resetn = &reset_cnt;

    always @(posedge clk) begin
        reset_cnt <= reset_cnt + !resetn;
    end
  
    ///////////////////////////////////
    // SPI Flash Interface
    ///////////////////////////////////
    wire flash_io0_oe, flash_io0_do, flash_io0_di;
    wire flash_io1_oe, flash_io1_do, flash_io1_di;
    wire flash_io2_oe, flash_io2_do, flash_io2_di;
    wire flash_io3_oe, flash_io3_do, flash_io3_di;

    SB_IO #(
        .PIN_TYPE(6'b 1010_01),
        .PULLUP(1'b 0)
    ) flash_io_buf [3:0] (
        .PACKAGE_PIN({flash_io3, flash_io2, flash_io1, flash_io0}),
        .OUTPUT_ENABLE({flash_io3_oe, flash_io2_oe, flash_io1_oe, flash_io0_oe}),
        .D_OUT_0({flash_io3_do, flash_io2_do, flash_io1_do, flash_io0_do}),
        .D_IN_0({flash_io3_di, flash_io2_di, flash_io1_di, flash_io0_di})
    );
  
    ///////////////////////////////////
    // Peripheral Bus
    ///////////////////////////////////
    wire        iomem_valid;
    reg         iomem_ready;
    wire [3:0]  iomem_wstrb;
    wire [31:0] iomem_addr;
    wire [31:0] iomem_wdata;
    reg  [31:0] iomem_rdata;

    reg [31:0] gpio;
    wire [7:0]  gpio_buttons;
    assign user_led = gpio[0];

    SB_IO #(
        .PIN_TYPE(6'b 0000_01),
        .PULLUP(1'b 1)
    ) buttons_input [7:0] (
        .PACKAGE_PIN(buttons),
        .D_IN_0(gpio_buttons)
    );
`ifdef audio
    reg [11:0] audio_out;
    pdm_dac dac(.clk(clk), .din(audio_out), .dout(audio));
`endif
`ifdef i2c
    reg i2c_enable = 0, i2c_read = 0;
    reg [31:0] i2c_write_reg = 0;
    reg [31:0] i2c_read_reg;

    I2C_master #(.freq(16)) i2c (
        .SDA(sda),
        .SCL(scl),
        .sys_clock(clk),
        .reset(~resetn),
        .ctrl_data(i2c_write_reg),
        .wr_ctrl(i2c_enable),
        .read(i2c_read),
        .status(i2c_read_reg));
`endif
    always @(posedge clk) begin
        if (!resetn) begin
            gpio <= 0;
        end else begin
            iomem_ready <= 0;
`ifdef i2c
            i2c_enable <= 0;
`endif
            ///////////////////////////
            // GPIO Peripheral
            ///////////////////////////
            if (iomem_valid && !iomem_ready && iomem_addr[31:24] == 8'h03) begin
                iomem_ready <= 1;
		if (iomem_addr[7:0] == 8'h00) begin
	            iomem_rdata <= gpio;
		    if (iomem_wstrb[0]) gpio[ 7: 0] <= iomem_wdata[ 7: 0];
		    if (iomem_wstrb[1]) gpio[15: 8] <= iomem_wdata[15: 8];
		    if (iomem_wstrb[2]) gpio[23:16] <= iomem_wdata[23:16];
		    if (iomem_wstrb[3]) gpio[31:24] <= iomem_wdata[31:24];
		end else if (iomem_addr[7:0] == 8'h04) begin
		    iomem_rdata <= ~gpio_buttons;
		end
            end

            ///////////////////////////
            // Audio Peripheral
            ///////////////////////////
`ifdef audio
            if (iomem_valid && !iomem_ready && iomem_addr[31:24] == 8'h04) begin
                iomem_ready <= 1;
                iomem_rdata <= 32'h0;
                if (iomem_wstrb[0]) audio_out[7:0] <= iomem_wdata[7:0];
                if (iomem_wstrb[1]) audio_out[11:8] <= iomem_wdata[11:8];
            end
`endif
            ///////////////////////////
            // Controller Peripheral
            ///////////////////////////
`ifdef i2c
            if (iomem_valid && !iomem_ready && iomem_addr[31:24] == 8'h07) begin
                iomem_ready <= 1;
                if (iomem_wstrb[0]) i2c_write_reg[7:0] <= iomem_wdata[ 7: 0];
                if (iomem_wstrb[1]) i2c_write_reg[15: 8] <= iomem_wdata[15: 8];
                if (iomem_wstrb[2]) i2c_write_reg[23:16] <= iomem_wdata[23:16];
                if (iomem_wstrb[3]) i2c_write_reg[31:24] <= iomem_wdata[31:24];
                iomem_rdata <= i2c_read_reg;
                if (|iomem_wstrb) i2c_enable <= 1;
                if (iomem_addr[7:0] == 8'h00) begin
                    i2c_read <= 0;
                end else if (iomem_addr[7:0] == 8'h04) begin
                    i2c_read <= 1;
                end
            end
`endif
        end
    end

    picosoc #(
        .PROGADDR_RESET(32'h0005_0000), // beginning of user space in SPI flash
        .PROGADDR_IRQ(32'h0005_0010),
        .MEM_WORDS(2048)                // use 2KBytes of block RAM by default
    ) soc (
        .clk          (clk         ),
        .resetn       (resetn      ),

        .ser_tx       (pin_1       ),
        .ser_rx       (pin_2       ),

        .flash_csb    (flash_csb   ),
        .flash_clk    (flash_clk   ),

        .flash_io0_oe (flash_io0_oe),
        .flash_io1_oe (flash_io1_oe),
        .flash_io2_oe (flash_io2_oe),
        .flash_io3_oe (flash_io3_oe),

        .flash_io0_do (flash_io0_do),
        .flash_io1_do (flash_io1_do),
        .flash_io2_do (flash_io2_do),
        .flash_io3_do (flash_io3_do),

        .flash_io0_di (flash_io0_di),
        .flash_io1_di (flash_io1_di),
        .flash_io2_di (flash_io2_di),
        .flash_io3_di (flash_io3_di),

        .irq_5        (1'b0        ),
        .irq_6        (1'b0        ),
        .irq_7        (1'b0        ),

        .iomem_valid  (iomem_valid ),
        .iomem_ready  (iomem_ready ),
        .iomem_wstrb  (iomem_wstrb ),
        .iomem_addr   (iomem_addr  ),
        .iomem_wdata  (iomem_wdata ),
        .iomem_rdata  (iomem_rdata )
    );
endmodule
