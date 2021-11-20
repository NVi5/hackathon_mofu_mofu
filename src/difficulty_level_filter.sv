module difficulty_level_filter
#(
  parameter [7:0] difficulty = 8'b0
)
(
  input wire clk,

  input wire [127:0] data_i,
  input wire         valid_i,

  output reg [127:0] data_o,
  output reg         valid_o
);

always_ff @(posedge clk) begin
  valid_o <= 1'b0;
  if (valid_i && data_i[7:0] <= difficulty) begin
    valid_o <= 1'b1;
	 data_o <= data_i;
  end
end

endmodule