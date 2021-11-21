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
difficulty_level_filter #(.difficulty(8'd2)) u_difficulty_level_filter
(
    .clk      (clk),

    .data_i   (i_transcation),
    .valid_i  (i_valid),

    .data_o   (difficulty_filter_o),
    .valid_o  (difficulty_filter_valid)
);

wire clk_2;
pll u_pll
(
    .refclk   (clk),
    .rst      (rst),
    .outclk_0 (clk_2)
);

wire [127:0] fifo_o;
wire         fifo_empty;
fifo_dual u_fifo
(
    .wrclk    (clk),
    .rdclk    (clk_2),

    .data     (difficulty_filter_o),
    .wrreq    (difficulty_filter_valid),

    .q        (fifo_o),
    .rdempty  (fifo_empty),

    .rdreq    (trans_validator_ack)
);

wire [127:0] trans_validator_o;
wire         trans_validator_valid;
wire         trans_validator_ack;
trans_validator u_trans_validator
(
    .clk      (clk_2),

    .data_i   (fifo_o),
    .valid_i  (!fifo_empty),

    .data_o   (trans_validator_o),
    .valid_o  (trans_validator_valid),
    .ack_o    (trans_validator_ack)
);


wire [127:0] fifo_2_o;
wire         fifo_2_empty;
fifo_dual u_fifo_2
(
    .wrclk    (clk_2),
    .rdclk    (clk),

    .data     (trans_validator_o),
    .wrreq    (trans_validator_valid),

    .q        (fifo_2_o),
    .rdempty  (fifo_2_empty),

    .rdreq    (!fifo_2_empty)
);

hash_gen u_hash_gen
(
    .clk      (clk),

    .data_i   (fifo_2_o),
    .valid_i  (!fifo_2_empty),

    .data_o   (o_hash),
    .valid_o  (o_valid),
);

endmodule

`default_nettype wire