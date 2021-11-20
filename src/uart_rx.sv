/*-
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * Copyright (c) 2019 Rafal Kozik
 * All rights reserved.
 */

 `default_nettype none

module uart_rx #( 
  parameter F = 8000000,
  parameter BAUD = 115200
) (
  input   wire       clk,
  input   wire       reset,

  input   wire       rx,

  output logic [7:0] rx_data,
  output logic       rx_valid,
  input   wire       rx_ready
);

  localparam MOD = (F+BAUD/2)/BAUD;
  localparam MOD_LOG = $clog2(MOD);

  enum logic [1:0] {
    WAIT,
    START,
    DATA,
    STOP
  } s;

  logic [7:0]rxb;
  logic [2:0]i;
  logic [MOD_LOG-1:0]ctx_q;
  logic ctx_rst, data_count_rst;
  logic rx_clk;
  logic data_count_ov, data_count_ov_d;

  always_ff @(posedge clk)
    if (reset)
      s <= WAIT;
    else
      case (s)
        WAIT: s <= rx ? WAIT : START;
        START: s <= rx_clk ? DATA : START;
        DATA: s <= data_count_ov_d ? STOP : DATA;
        STOP: s <= rx_clk ? WAIT : STOP;
        default: s <= WAIT;
      endcase
  
  assign ctx_rst = (s == WAIT);
  uart_counter #(.N(MOD)) crx (
    .clk(clk),
    .rst(ctx_rst),
    .ce(1'b1),
    .q(ctx_q),
    .ov());
  assign rx_clk = (ctx_q == MOD/2);

  assign data_count_rst = (s != DATA);
  uart_counter #(.N(8)) data_count (
    .clk(clk),
    .rst(data_count_rst),
    .ce(rx_clk),
    .q(i),
    .ov(data_count_ov)
  );

  always_ff @(posedge clk)
      if (rx_clk)
        data_count_ov_d <= data_count_ov;

  always_ff @(posedge clk)
    if (rx_clk)
      rxb[i] <= rx;

  always_ff @(posedge clk)
    if (reset)
      rx_valid <= 1'b0;
    else if (data_count_ov_d && s == DATA)
      rx_valid <= 1'b1;
    else if (rx_ready)
      rx_valid <= 1'b0;

  always_ff @(posedge clk)
    if (data_count_ov_d && s == DATA)
      rx_data <= rxb;

endmodule

`default_nettype wire
