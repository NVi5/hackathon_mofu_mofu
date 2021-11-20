`default_nettype none

module trans_validator(
  input  wire         clk,

  input  wire [127:0] data_i,
  input  wire         valid_i,

  output reg  [127:0] data_o,
  output reg          valid_o
);

localparam WAIT_FOR_TRANSACTION = 0, READ = 1, READ_D = 2, VALIDATE_DATA = 3,
           VALIDATE_TRANSACTION = 4, WRITE_SENDER = 5, WRITE_RECEIVER = 6;

localparam MEM_WIDTH = 72;      // Width id(48bit) + amount(24bit)
localparam MEM_DEPTH = 16384;   // Depth more than 10k

localparam UNDEFINED_POINTER =  {$clog2(MEM_DEPTH){1'b1}};

localparam BIT_BLOCK_START = 9;

reg                          mem_wr_en;
reg  [$clog2(MEM_DEPTH)-1:0] mem_wr_addr;
reg          [MEM_WIDTH-1:0] mem_wr_data;
wire [$clog2(MEM_DEPTH)-1:0] mem_rd_addr;
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

reg [47:0] sender_id;
reg [47:0] receiver_id;

reg [23:0] sender_cash;
reg [23:0] receiver_cash;

wire [21:0] amount;

reg [$clog2(MEM_DEPTH)-1:0] sender_pointer;
reg [$clog2(MEM_DEPTH)-1:0] receiver_pointer;
reg [$clog2(MEM_DEPTH)-1:0] counter;
reg [$clog2(MEM_DEPTH)-1:0] mem_iter;

reg [31:0] state;

assign amount = data_o[31:10];

assign mem_rd_addr = mem_iter;

always_ff @(posedge clk) begin
  valid_o <= 0;
  mem_wr_en <= 0;

  case (state)
    WAIT_FOR_TRANSACTION: begin
      if (valid_i) state <= READ;
      if (data_i[BIT_BLOCK_START]) counter <= 0;
      sender_id <= data_i[127:80];
      receiver_id <= data_i[79:32];
      sender_pointer <= UNDEFINED_POINTER;
      receiver_pointer <= UNDEFINED_POINTER;
      mem_iter <= 0;
      data_o <= data_i;
    end

    READ: begin
      state <= READ_D;
      mem_iter <= mem_iter + 1;
    end

    READ_D: begin
      mem_iter++;
      if (mem_rd_data[71:24] == sender_id && mem_iter <= counter) begin
        sender_pointer <= mem_iter;
        sender_cash <= mem_rd_data[23:0];
      end

      if (mem_rd_data[71:24] == receiver_id && mem_iter <= counter) begin
        receiver_pointer <= mem_iter;
        receiver_cash <= mem_rd_data[23:0];
      end

      if (mem_iter > counter || (sender_pointer != UNDEFINED_POINTER && receiver_pointer != UNDEFINED_POINTER)) begin
        state <= VALIDATE_DATA;
      end
      else begin
        state <= READ_D;
      end
    end

    VALIDATE_DATA: begin
      if (sender_pointer == UNDEFINED_POINTER && receiver_pointer == UNDEFINED_POINTER) begin
        counter <= counter + 2;
        sender_cash <= 100;
        receiver_cash <= 100;
        sender_pointer <= counter;
        receiver_pointer <= counter + 1;
      end
      else if (sender_pointer != UNDEFINED_POINTER && receiver_pointer == UNDEFINED_POINTER) begin
        counter <= counter + 1;
        receiver_cash <= 100;
        receiver_pointer <= counter;
      end
      else if (sender_pointer == UNDEFINED_POINTER && receiver_pointer != UNDEFINED_POINTER) begin
        counter <= counter + 1;
        sender_cash <= 100;
        sender_pointer <= counter;
      end

      state <= VALIDATE_TRANSACTION;
    end

    VALIDATE_TRANSACTION: begin
      if (sender_cash >= amount) begin  // git
        receiver_cash <= receiver_cash + amount;
        sender_cash <= sender_cash - amount;
        valid_o <= 1;
        state <= WRITE_SENDER;
      end
      else begin
        state <= WAIT_FOR_TRANSACTION;
      end
    end

    WRITE_SENDER: begin
      mem_wr_addr <= sender_pointer;
      mem_wr_data <= {sender_id, sender_cash};
      mem_wr_en <= 1;
      state <= WRITE_RECEIVER;
    end

    WRITE_RECEIVER: begin
      mem_wr_addr <= receiver_pointer;
      mem_wr_data <= {receiver_id, receiver_cash};
      mem_wr_en <= 1;
      state <= WAIT_FOR_TRANSACTION;
    end

  endcase
end

endmodule

`default_nettype wire