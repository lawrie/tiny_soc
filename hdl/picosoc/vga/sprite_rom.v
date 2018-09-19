module sprite_rom(
  input clk,
  input [4:0] y_idx,
  input [4:0] x_idx,
  output reg [2:0] rgb);

  reg[2:0] SPRITE_ROM[0:1023]; 
  initial $readmemh ("mario.mem", SPRITE_ROM);

  always @(posedge clk) begin
    rgb <= SPRITE_ROM[{ y_idx,  x_idx }];
  end

endmodule
