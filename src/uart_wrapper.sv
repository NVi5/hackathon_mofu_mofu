
`default_nettype none

module uart_wrapper #(
  parameter F = 8000000,
  parameter BAUD = 115200
)(
  input   wire       clk,
  input   wire       reset,

  input   wire [7:0] tx_data,
  input   wire       tx_valid,
  output  wire       tx_ready,

  output  wire [7:0] rx_data,
  output  wire       rx_valid,
  input   wire       rx_ready,

  output  wire       tx,
  input   wire       rx
);

uart_tx #( 
  .F    (F),
  .BAUD (BAUD)
) uart_tx (
  .clk      (clk),
  .reset    (reset),
  .tx_data  (tx_data),
  .tx_valid (tx_valid),
  .tx_ready (tx_ready),
  .tx       (tx)
);

logic [7:0] rx_data_int;
logic       rx_valid_int;
logic       rx_ready_int;

uart_rx #( 
  .F    (F),
  .BAUD (BAUD)
) uart_rx (
  .clk      (clk),
  .reset    (reset),
  .rx       (rx),
  .rx_data  (rx_data_int),
  .rx_valid (rx_valid_int),
  .rx_ready (rx_ready_int)
);

logic rx_fifo_empty;
logic rx_fifo_full;
assign rx_valid = ~rx_fifo_empty;
assign rx_ready_int = ~rx_fifo_full;

scfifo rx_fifo (
  .aclr         (),
  .clock        (clk),
  .data         (rx_data_int),
  .rdreq        (rx_ready),
  .wrreq        (rx_valid_int),
  .empty        (rx_fifo_empty),
  .q            (rx_data),
  .usedw        (),
  .almost_empty (),
  .almost_full  (),
  .eccstatus    (),
  .full         (rx_fifo_full),
  .sclr         (reset));
defparam
  rx_fifo.add_ram_output_register  = "ON",
  rx_fifo.enable_ecc  = "FALSE",
  rx_fifo.intended_device_family  = "Cyclone V",
  rx_fifo.lpm_numwords  = 256,
  rx_fifo.lpm_showahead  = "ON",
  rx_fifo.lpm_type  = "scfifo",
  rx_fifo.lpm_width  = 8,
  rx_fifo.lpm_widthu  = 8,
  rx_fifo.overflow_checking  = "ON",
  rx_fifo.underflow_checking  = "ON",
  rx_fifo.use_eab  = "ON";

endmodule

`default_nettype wire
