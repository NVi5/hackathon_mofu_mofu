`default_nettype none

module validator(
  input  wire         clk,
  input  wire         rst,

  input  wire         i_valid,
  input  wire [127:0] i_transcation,

  output reg          o_valid,
  output reg  [127:0] o_hash
);

wire [127:0] difficulty_filter_o;
wire         difficulty_filter_valid;

difficulty_level_fitler u_difficulty_level_fitler #(.difficulty(8'b0))
(
    .clk(clk),

    .data_i(i_transcation),
    .data_i_valid(i_valid),

    .data_o(difficulty_filter_o),
    .data_o_valid(difficulty_filter_valid)
);

endmodule

`default_nettype wire