`default_nettype none

module trans_validator(
  input  wire         clk,

  input  wire [127:0] data_i,
  input  wire         valid_i,

  output reg  [127:0] data_o,
  output reg          valid_o,
  output reg          ack_o
);

localparam WAIT_FOR_TRANSACTION = 0, READ = 1, READ_D = 2, VALIDATE_DATA = 3,
           VALIDATE_TRANSACTION = 4, WRITE_SENDER = 5, WRITE_RECEIVER = 6;

localparam MEM_WIDTH = 72;      // Width id(48bit) + amount(24bit)
localparam MEM_DEPTH = 16384;   // Depth more than 10k
localparam MEM_INSTANCES = 2;

localparam UNDEFINED_POINTER =  {$clog2(MEM_DEPTH){1'b1}};

localparam BIT_BLOCK_START = 9;

localparam STEP_SIZE = 4;

reg                          mem_wr_en;
reg  [$clog2(MEM_DEPTH)-1:0] mem_wr_addr;
reg          [MEM_WIDTH-1:0] mem_wr_data;
wire [$clog2(MEM_DEPTH)-1:0] mem_rd_addr;
wire [$clog2(MEM_DEPTH)-1:0] mem_rd_addr2;
wire         [MEM_WIDTH-1:0] mem_rd_data_0;
wire         [MEM_WIDTH-1:0] mem_rd_data_1;
wire         [MEM_WIDTH-1:0] mem_rd_data_2;
wire         [MEM_WIDTH-1:0] mem_rd_data_3;

ram_rtl #(.width(MEM_WIDTH), .depth(MEM_DEPTH / MEM_INSTANCES)) u_ram_rtl
(
    .clkA(clk),
    .clkB(clk),

    .wr_en(mem_wr_en & !mem_wr_addr[0]),
    .wr_addr(mem_wr_addr >> 1),
    .wr_data(mem_wr_data),

    .wr_en2(0),
    .wr_addr2(0),
    .wr_data2(0),

    .rd_addr(mem_rd_addr >> 1),
    .rd_data(mem_rd_data_0),

    .rd_addr2(mem_rd_addr2 >> 1),
    .rd_data2(mem_rd_data_2)
);

ram_rtl #(.width(MEM_WIDTH), .depth(MEM_DEPTH / MEM_INSTANCES)) u_ram_rtl_2
(
    .clkA(clk),
    .clkB(clk),

    .wr_en(mem_wr_en & mem_wr_addr[0]),
    .wr_addr(mem_wr_addr >> 1),
    .wr_data(mem_wr_data),

    .wr_en2(0),
    .wr_addr2(0),
    .wr_data2(0),

    .rd_addr(mem_rd_addr >> 1),
    .rd_data(mem_rd_data_1),

    .rd_addr2(mem_rd_addr2 >> 1),
    .rd_data2(mem_rd_data_3)
);

reg [47:0] sender_id;
reg [47:0] receiver_id;

reg [23:0] sender_cash;
reg [23:0] receiver_cash;

wire [21:0] amount;

reg [$clog2(MEM_DEPTH)-1:0] sender_pointer;
reg [$clog2(MEM_DEPTH)-1:0] receiver_pointer;
reg [$clog2(MEM_DEPTH)-1:0] id_counter = 0;
reg [$clog2(MEM_DEPTH)-1:0] mem_iter;

reg [2:0] state = WAIT_FOR_TRANSACTION;

assign amount = data_o[31:10];

assign mem_rd_addr = mem_iter;
assign mem_rd_addr2 = mem_iter + 14'd2;

always_ff @(posedge clk) begin
  valid_o <= 0;
  mem_wr_en <= 0;
  ack_o <= 0;

  case (state)
    WAIT_FOR_TRANSACTION: begin
      if (valid_i) begin
        state <= READ;
        ack_o <= 1;
        if (data_i[BIT_BLOCK_START]) id_counter <= 0;
      end
      sender_id <= data_i[127:80];
      receiver_id <= data_i[79:32];
      sender_pointer <= UNDEFINED_POINTER;
      receiver_pointer <= UNDEFINED_POINTER;
      mem_iter <= 0;
      data_o <= data_i;
    end

    READ: begin
      mem_iter <= mem_iter + STEP_SIZE;
      state <= READ_D;
    end

    READ_D: begin
      mem_iter <= mem_iter + STEP_SIZE;
      if (mem_iter > 9999 || (sender_pointer != UNDEFINED_POINTER && receiver_pointer != UNDEFINED_POINTER)) begin
        state <= VALIDATE_DATA;
      end
      else begin
        if (mem_rd_data_0[71:24] == sender_id && (mem_iter - STEP_SIZE + 0) <= id_counter) begin
          sender_pointer <= mem_iter - STEP_SIZE + 0;
          sender_cash <= mem_rd_data_0[23:0];
        end

        if (mem_rd_data_0[71:24] == receiver_id && (mem_iter - STEP_SIZE + 0) <= id_counter) begin
          receiver_pointer <= mem_iter - STEP_SIZE + 0;
          receiver_cash <= mem_rd_data_0[23:0];
        end

        if (mem_rd_data_1[71:24] == sender_id && (mem_iter - STEP_SIZE + 1) <= id_counter) begin
          sender_pointer <= mem_iter - STEP_SIZE + 1;
          sender_cash <= mem_rd_data_1[23:0];
        end

        if (mem_rd_data_1[71:24] == receiver_id && (mem_iter - STEP_SIZE + 1) <= id_counter) begin
          receiver_pointer <= mem_iter - STEP_SIZE + 1;
          receiver_cash <= mem_rd_data_1[23:0];
        end

        if (mem_rd_data_2[71:24] == sender_id && (mem_iter - STEP_SIZE + 2) <= id_counter) begin
          sender_pointer <= mem_iter - STEP_SIZE + 2;
          sender_cash <= mem_rd_data_2[23:0];
        end

        if (mem_rd_data_2[71:24] == receiver_id && (mem_iter - STEP_SIZE + 2) <= id_counter) begin
          receiver_pointer <= mem_iter - STEP_SIZE + 2;
          receiver_cash <= mem_rd_data_2[23:0];
        end

        if (mem_rd_data_3[71:24] == sender_id && (mem_iter - STEP_SIZE + 3) <= id_counter) begin
          sender_pointer <= mem_iter - STEP_SIZE + 3;
          sender_cash <= mem_rd_data_3[23:0];
        end

        if (mem_rd_data_3[71:24] == receiver_id && (mem_iter - STEP_SIZE + 3) <= id_counter) begin
          receiver_pointer <= mem_iter - STEP_SIZE + 3;
          receiver_cash <= mem_rd_data_3[23:0];
        end

        state <= READ_D;
      end
    end

    VALIDATE_DATA: begin
      if (sender_pointer == UNDEFINED_POINTER && receiver_pointer == UNDEFINED_POINTER) begin
        id_counter <= id_counter + 2;
        sender_cash <= 100;
        receiver_cash <= 100;
        sender_pointer <= id_counter;
        receiver_pointer <= id_counter + 1;
      end
      else if (sender_pointer != UNDEFINED_POINTER && receiver_pointer == UNDEFINED_POINTER) begin
        id_counter <= id_counter + 1;
        receiver_cash <= 100;
        receiver_pointer <= id_counter;
      end
      else if (sender_pointer == UNDEFINED_POINTER && receiver_pointer != UNDEFINED_POINTER) begin
        id_counter <= id_counter + 1;
        sender_cash <= 100;
        sender_pointer <= id_counter;
      end

      state <= VALIDATE_TRANSACTION;
    end

    VALIDATE_TRANSACTION: begin
      if (sender_cash >= amount) begin
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