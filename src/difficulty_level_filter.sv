module difficulty_level_filter
#(
    parameter [7:0] difficulty = 8'b0
)
(
    input wire clk,

    input wire [127:0] data_i,
    input wire         data_i_valid,

    output reg [127:0] data_o,
    output reg         data_o_valid
);

always_ff @(posedge clk) begin
    data_o <= data_i;
    data_o_valid <= 1'b0;
    if (data_i[7:0] <= difficulty) begin
        data_o_valid <= 1'b1;
    end
end



end

endmodule