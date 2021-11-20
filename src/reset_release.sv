
`default_nettype none

module reset_release#(
  parameter N = 8
)(
input  wire  clk,
output logic reset
);

logic [N-1:0] reset_cnt = '1;
always_ff@(posedge clk)
  if(reset_cnt > 0)
    reset_cnt <= reset_cnt - 1'd1;

always_ff@(posedge clk)
  reset <= |reset_cnt;

endmodule

`default_nettype wire
