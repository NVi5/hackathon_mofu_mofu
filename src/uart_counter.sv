/*-
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * Copyright (c) 2019 Rafal Kozik
 * All rights reserved.
 */

`default_nettype none

module uart_counter #(
  parameter N = 25,
  parameter W = $clog2(N)
) (
  input wire clk,
  input wire rst,
  input wire ce,
  output logic [W-1:0]q,
  output logic ov
);
  always_ff @(posedge clk)
    if (rst)
      q <= '0;
    else if (ce)
      if (ov)
        q <= '0;
      else
        q <= q + 1'b1;

  always_ff @(posedge clk)
    if (rst)
      ov <= '0;
    else if (ce)
      if (ov)
        ov <= 1'b0;
      else
        ov <= (q == N-2);
endmodule

`default_nettype wire
