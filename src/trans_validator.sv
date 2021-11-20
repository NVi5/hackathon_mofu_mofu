`default_nettype none

module trans_validator(
  input  wire         clk,
  input  wire         rst,

  input  wire [127:0] data_i,
  input  wire         valid_i,

  output wire [127:0] data_o,
  output wire         valid_o
);

assign data_o = data_i;
assign valid_o = valid_i;

endmodule

`default_nettype wire