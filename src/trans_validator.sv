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