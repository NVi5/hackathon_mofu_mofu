module ram_rtl # (
    parameter width = 72,
    parameter depth = 16384
)
(
    input  wire                     clk,

    input  wire                     wr_en,
    input  wire [$clog2(depth)-1:0] wr_addr,
    input  wire [        width-1:0] wr_data,

    input  wire [$clog2(depth)-1:0] rd_addr,
    output reg  [        width-1:0] rd_data
);

reg [width-1:0] mem [depth-1:0];

always @(posedge clk) begin
    if (wr_en) mem[wr_addr] <= wr_data;
    rd_data <= mem[rd_addr];
end

endmodule