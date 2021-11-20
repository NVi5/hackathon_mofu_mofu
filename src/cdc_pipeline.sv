
`default_nettype none

module cdc_pipeline#(
parameter W = 1
)(
input  wire         clk_i,
input  wire         clk_o,

input  wire [W-1:0] data_i,
output wire [W-1:0] data_o
);

logic [1:0][W-1:0] pipe_i;
logic [1:0][W-1:0] pipe_o;

always_ff@(posedge clk_i)
  pipe_i <= {pipe_i[0],data_i};

always_ff@(posedge clk_o)
  pipe_o <= {pipe_o[0],pipe_i[1]};

assign data_o = pipe_o[1];

endmodule

`default_nettype wire
