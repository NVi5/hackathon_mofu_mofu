`default_nettype none

module trans_validator(
  input  wire         clk,
  input  wire         rst,

  input  wire [127:0] data_i,
  input  wire         valid_i,

  output reg  [127:0] data_o,
  output reg          valid_o
);

localparam MEM_WIDTH = 72;      // Width id(48bit) + amount(24bit)
localparam MEM_DEPTH = 16384;   // Depth more than 10k

reg                          mem_wr_en;
reg  [$clog2(MEM_DEPTH)-1:0] mem_wr_addr;
reg          [MEM_WIDTH-1:0] mem_wr_data;
reg  [$clog2(MEM_DEPTH)-1:0] mem_rd_addr;
wire         [MEM_WIDTH-1:0] mem_rd_data;

ram_rtl #(.width(MEM_WIDTH), .depth(MEM_DEPTH)) u_ram_rtl
(
    .clk(clk),

    .wr_en(mem_wr_en),
    .wr_addr(mem_wr_addr),
    .wr_data(mem_wr_data),

    .rd_addr(mem_rd_addr),
    .rd_data(mem_rd_data)
);

always_ff @(posedge clk) begin
  data_o <= data_i;
  valid_o <= valid_i;
end


reg sender_addr;
reg receiver_addr;

reg sender_hajs;
reg receiver_hajs;

reg sender_pointer;
reg receiver_pointer;

reg counter;
reg it;


always @()

case (state)
// kiedy zaczyna sie blok
counter = 0
////

  wait_for_transaction: begin
    if (valid_i) state <= READ
    sender_addr <= aaaa;
    receiver_addr <= bbbb;
    sender_pointer = fffff
    receiver_pointer = fffff
    it = 0;
  end

  READ:
    ram_addr <= it;
    state <= READ_D

  READ_D:
    it++;
    if (ram1_data[address] == sender_addr)
      sender_pointer = current_counter_reg
      sender_hajs = ram1_data[hajs];

    if (ram1_data[address] == receiver_addr)
      receiver_pointer = current_counter_reg
      receiver_hajs = ram1_data[hajs];

    if (it > counter || (sender_pointer != fff && receiver_pointer != fff)) begin
      state <= VALIDATE_data
    end
    else state <= READ;


  //after 10k cycles

  VALIDATE_data: begin
    if (sender_pointer == fff && receiver_pointer == ffff) begin
      counter = counter + 2;
      sender_hajs = 100;
      receiver_hajs = 100;
      sender_pointer = counter;
      receiver_pointer = counter + 1;
    end
    else if (sender_pointer != fff && receiver_pointer == ffff) begin
      counter = counter + 1;
      receiver_hajs = 100;
      receiver_pointer = counter;
    end
    else if (sender_pointer == fff && receiver_pointer != ffff) begin
      counter = counter + 1;
      sender_hajs = 100;
      sender_pointer = counter;
    end
  end

  VALIDATE_TRANSACTION: begin
    if (sender_hajs >= amount) begin  // git
      receiver_hajs += amount;
      sender_hajs -= amount;
      valid_transaction <= 1;
      state <= WRITE_SENDER
    end
    else begin
      state <= wait_for_transaction
    end
  end

  WRITE_SENDER:
    state <= WRITE_RECEIVER
    ram[sender_pointer] = {sender_addr, sender_hajs};
    ram_we = 1;

  WRITE_RECEIVER:
    state <= wait_for_transaction
    ram[receiver_pointer] = {receiver_addr, receiver_hajs};
    ram_we = 1;




endcase

endmodule

`default_nettype wire