`ifndef __TILE_MEMORY__
`define __TILE_MEMORY__

// 6 BRAMS
module tile_memory (
    input rclk, wclk, wen, ren,
    input [11:0] waddr, raddr,
    input [5:0] wdata,
    output reg [5:0] rdata
);
    reg [5:0] mem [0:4095];   // enough memory for 80x50 map of tiles // uses ~6 BRAMS of Ice40
    always @(posedge rclk) begin
      if (ren)
        rdata <= mem[raddr];
    end
    always @(posedge wclk) begin
      if (wen)
        mem[waddr] <= wdata;
    end
endmodule


`endif
