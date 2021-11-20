`default_nettype none

module validator(
  input  wire         clk,
  input  wire         rst,

  input  wire         i_valid,
  input  wire [127:0] i_transcation,

  output reg          o_valid,
  output reg  [127:0] o_hash
);

endmodule

`default_nettype wire