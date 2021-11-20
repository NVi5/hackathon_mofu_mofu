`default_nettype none

module validator(
  input  wire         clk,
  input  wire         rst,

  input  wire         i_valid,
  input  wire [127:0] i_transcation,

  output wire         o_valid,
  output wire [127:0] o_hash
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

hash_gen u_hash_gen
(
    .clk     (clk),

    .data_i  (difficulty_filter_o),
    .valid_i (difficulty_filter_valid),

    .data_o  (o_hash),
    .valid_o (o_valid)
);

endmodule

`default_nettype wire