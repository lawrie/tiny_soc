/*
 * map from 8-bit -> 8-bit value for exponential falloff of decay and release
 * in the envelope generator.
 */

 module eight_bit_exponential_decay_lookup (
   input wire [7:0] din,
   output wire [7:0] dout
 );

 reg [0:7] exp_lookup [0:255];
 initial $readmemh("picosoc/audio/exp_lookup_table.rom", exp_lookup);

 assign dout = exp_lookup[din];

endmodule

