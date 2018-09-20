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

module top (
    input CLK,

    // hardware UART
    output SER_TX,
    input SER_RX,

    // onboard SPI flash interface
    output SPI_SS,
    output SPI_SCK,
    inout  SPI_IO0,
    inout  SPI_IO1,
    inout  SPI_IO2,
    inout  SPI_IO3,

`ifdef pdm_audio
    // Audio out pin
    output AUDIO_LEFT,
`endif

`ifdef i2c
    // I2C pins
    inout I2C_SDA,
    inout I2C_SCL,
`endif
    
`ifdef oled
    inout OLED_SPI_SCL,
    inout OLED_SPI_SDA,
    inout OLED_SPI_RES,
    inout OLED_SPI_DC,
    inout OLED_SPI_CS,
`endif

`ifdef vga
    output VGA_VSYNC,
    output VGA_HSYNC,
    output VGA_R,
    output VGA_G,
    output VGA_B,
`endif

`ifdef gpio
    // GPIO buttons
    inout  [7:0] BUTTONS,

    // onboard LED
    output LED,
`endif
    
    // onboard USB interface
    output USBPU
);
    // Disable USB
    assign USBPU = 1'b0;

    ///////////////////////////////////
    // Power-on Reset
    ///////////////////////////////////
    reg [5:0] reset_cnt = 0;
    wire resetn = &reset_cnt;

    always @(posedge CLK) begin
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
        .PACKAGE_PIN({SPI_IO3, SPI_IO2, SPI_IO1, SPI_IO0}),
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

`ifdef gpio
    reg [31:0] gpio;
    wire [7:0]  gpio_buttons;
    assign LED = gpio[0];

    SB_IO #(
        .PIN_TYPE(6'b 0000_01),
        .PULLUP(1'b 1)
    ) buttons_input [7:0] (
        .PACKAGE_PIN(BUTTONS),
        .D_IN_0(gpio_buttons)
    );
`endif

`ifdef pdm_audio
    reg [11:0] audio_out;
    pdm_dac dac(.clk(CLK), .din(audio_out), .dout(AUDIO_LEFT));
`endif

`ifdef i2c
    reg i2c_enable = 0, i2c_read = 0;
    reg [31:0] i2c_write_reg = 0;
    reg [31:0] i2c_read_reg;

    I2C_master #(.freq(16)) i2c (
        .SDA(I2C_SDA),
        .SCL(I2C_SCL),
        .sys_clock(CLK),
        .reset(~resetn),
        .ctrl_data(i2c_write_reg),
        .wr_ctrl(i2c_enable),
        .read(i2c_read),
        .status(i2c_read_reg));
`endif

`ifdef oled
        reg spi_wr, spi_rd;
	reg [31:0] spi_rdata;
	reg spi_ready;
        spi_oled #(.CLOCK_FREQ_HZ(16000000)) oled (
            .clk(CLK),
            .resetn(resetn),
            .ctrl_wr(spi_wr),
            .ctrl_rd(spi_rd),
            .ctrl_addr(iomem_addr[7:0]),
            .ctrl_wdat(iomem_wdata),
            .ctrl_rdat(spi_rdata),
            .ctrl_done(spi_ready),
            .mosi(OLED_SPI_SDA),
            .sclk(OLED_SPI_SCL),
            .cs(OLED_SPI_CS),
            .dc(OLED_SPI_DC),
            .rst(OLED_SPI_RES));
`endif

`ifdef vga
        reg [9:0] xpos, ypos;
        wire video_active;
        wire pixel_clock;
        VGASyncGen vga_generator(
            .clk(CLK),
            .hsync(VGA_HSYNC), 
            .vsync(VGA_VSYNC), 
            .x_px(xpos), 
            .y_px(ypos), 
            .activevideo(video_active), 
            .px_clk(pixel_clock));
    
        wire [5:0] texture_idx;
        map_rom map(
            .clk(pixel_clock), 
            .x_idx(xpos[8:3]), 
            .y_idx(ypos[8:3]), 
            .val(texture_idx));

        reg [2:0] rom_rgb;
        texture_rom texture(
             .clk(pixel_clock), 
             .texture_idx(texture_idx), 
             .y_idx(ypos[2:0]), 
             .x_idx(xpos[2:0]), 
             .val(rom_rgb));

        reg[2:0] sprite_rgb;
        reg [9:0] sprite_x = 20, sprite_y = 30;
        sprite_rom sprite(
            .clk(pixel_clock), 
            .y_idx(ypos[4:0] - sprite_y[4:0]), 
            .x_idx(xpos[4:0] - sprite_x[4:0]), 
            .rgb(sprite_rgb));

        wire on_sprite = (xpos >= sprite_x && xpos < sprite_x + 32 &&
                          ypos >= sprite_y && ypos < sprite_y + 32);
 
        assign VGA_R = video_active & (on_sprite ? sprite_rgb[2] : rom_rgb[0]);
        assign VGA_G = video_active & (on_sprite ? sprite_rgb[1] :rom_rgb[1]);
        assign VGA_B = video_active & (on_sprite ? sprite_rgb[0] : rom_rgb[2]);
`endif

    always @(posedge CLK) begin
        if (resetn) begin
            iomem_ready <= 0;
`ifdef gpio
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
`endif

`ifdef pdm_audio
            ///////////////////////////
            // Audio Peripheral
            ///////////////////////////

            if (iomem_valid && !iomem_ready && iomem_addr[31:24] == 8'h04) begin
                iomem_ready <= 1;
                iomem_rdata <= 32'h0;
                if (iomem_wstrb[0]) audio_out[7:0] <= iomem_wdata[7:0];
                if (iomem_wstrb[1]) audio_out[11:8] <= iomem_wdata[11:8];
            end
`endif

            ///////////////////////////
            // Video Peripheral
            ///////////////////////////

`ifdef oled
            spi_wr <= 0;
            spi_rd <= 0;
            if (iomem_valid && !iomem_ready && iomem_addr[31:24] == 8'h05) begin
                 iomem_ready <= spi_ready;
                 iomem_rdata <= spi_rdata;
                 spi_wr <= |iomem_wstrb;
                 spi_rd <= ~(|iomem_wstrb);
            end
`endif

`ifdef vga
            if (iomem_valid && !iomem_ready && iomem_addr[31:24] == 8'h05) begin
                 iomem_ready <= 1;
                 iomem_rdata <= 0;
                 if (&iomem_wstrb)  begin
                    sprite_x <= iomem_wdata[9:0];
                    sprite_y <= iomem_wdata[25:16];
                 end
            end
`endif
            ///////////////////////////
            // Controller Peripheral
            ///////////////////////////

`ifdef i2c
            i2c_enable <= 0;
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
        .clk          (CLK         ),
        .resetn       (resetn      ),

        .ser_tx       (SER_TX      ),
        .ser_rx       (SER_RX      ),

        .flash_csb    (SPI_SS      ),
        .flash_clk    (SPI_SCK     ),

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
