`default_nettype none

module trans_validator(
  input  wire         clk,
  input  wire         rst,

  input  wire [127:0] data_i,
  input  wire         valid_i,

  output reg  [127:0] data_o,
  output reg          valid_o
);

always_ff @(posedge clk) begin
  data_o <= data_i;
  valid_o <= valid_i;
end

endmodule

`default_nettype wire