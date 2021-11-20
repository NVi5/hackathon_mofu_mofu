
`default_nettype none

module hash_gen(
  input  wire         clk,

  input  wire [127:0] data_i,
  input  wire         valid_i,

  output wire [127:0] data_o,
  output wire         valid_o

);

logic [127:0] hash;
logic [127:0] hash_lsl;
logic         hash_valid;

assign hash_lsl = {hash[126:0],hash[127]};

always_ff@(posedge clk) begin
  hash_valid <= '0;
  if(valid_i && data_i[7:0]==8'h00) begin
    if(data_i[8])
      hash_valid <= '1;
    if(data_i[9])
      hash <= data_i;
    else
      hash <= data_i ^ hash_lsl;
  end
end

assign data_o = hash;
assign valid_o = hash_valid;

endmodule

`default_nettype wire
