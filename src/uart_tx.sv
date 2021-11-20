/*-
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * Copyright (c) 2019 Rafal Kozik
 * All rights reserved.
 */

`default_nettype none

module uart_tx #( 
  parameter F = 8000000,
  parameter BAUD = 115200
) (
  input   wire       clk,
  input   wire       reset,

  input   wire [7:0] tx_data,
  input   wire       tx_valid,
  output logic       tx_ready,

  output logic       tx
);

  enum logic [1:0] {
    WAIT,
    START,
    DATA,
    STOP
  } state;

  logic [7:0]txb;
  logic [2:0]i;
  logic handshake;
  logic tx_clk;
  logic ctx_rst, data_count_rst;
  logic data_count_ov, data_count_ov_d;

  assign handshake = tx_valid & tx_ready;
  logic tx_clk_2;

  always_ff @(posedge clk)
    if (reset)
      state <= WAIT;
    else
      case (state)
        WAIT: state <= handshake ? START : WAIT;
        START: state <= tx_clk ? DATA : START;
        DATA: state <= data_count_ov_d ? STOP : DATA;
        STOP: state <= tx_clk ? WAIT : STOP;
        default: state <= WAIT;
      endcase

  always_ff @(posedge clk)
    if (handshake)
      txb <= tx_data;

  always_ff @(posedge clk)
    tx_ready <= (state == WAIT) & !handshake;

  always_ff @(posedge clk)
    case (state)
      START: tx <= 1'b0;
      DATA: tx <= data_count_ov_d ? 1'b1 : txb[i];
      default: tx <= 1'b1;
    endcase

  assign ctx_rst = (state == WAIT);
  uart_counter #(.N((F+BAUD/2)/BAUD)) ctx (
    .clk(clk),
    .rst(ctx_rst),
    .ce(1'b1),
    .q(),
    .ov(tx_clk)
  );

  assign data_count_rst = (state != DATA);
  uart_counter #(.N(8)) data_count (
    .clk(clk),
    .rst(data_count_rst),
    .ce(tx_clk),
    .q(i),
    .ov(data_count_ov)
  );

  always_ff @(posedge clk)
    if (tx_clk)
      data_count_ov_d <= data_count_ov;

endmodule

`default_nettype wire
