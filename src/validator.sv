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
difficulty_level_filter #(.difficulty(8'b0)) u_difficulty_level_filter
(
    .clk      (clk),

    .data_i   (i_transcation),
    .valid_i  (i_valid),

    .data_o   (difficulty_filter_o),
    .valid_o  (difficulty_filter_valid)
);

wire [127:0] fifo_o;
wire         fifo_empty;
fifo u_fifo
(
    .clock    (clk),

    .data     (difficulty_filter_o),
    .wrreq    (difficulty_filter_valid),

    .q        (fifo_o),
    .empty    (fifo_empty),

    .rdreq    (trans_validator_ack)
);

wire [127:0] trans_validator_o;
wire         trans_validator_valid;
wire         trans_validator_ack;
trans_validator u_trans_validator
(
    .clk      (clk),

    .data_i   (fifo_o),
    .valid_i  (!fifo_empty),

    .data_o   (trans_validator_o),
    .valid_o  (trans_validator_valid),
    .ack_o    (trans_validator_ack)
);

hash_gen u_hash_gen
(
    .clk      (clk),

    .data_i   (trans_validator_o),
    .valid_i  (trans_validator_valid),

    .data_o   (o_hash),
    .valid_o  (o_valid),
);

endmodule

`default_nettype wire