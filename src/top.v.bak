
`default_nettype none

module top (
  input  wire CLK_50,

  input  wire L1_OSC,
  output wire L1_TX0,
  output wire L1_TX1,
  output wire L1_TX_EN,
  input  wire L1_RX0,
  input  wire L1_RX1,
  input  wire L1_CRS_DV,

  output wire UART_TX,
  input  wire UART_RX
);

parameter UART_REF = 50000000;
parameter UART_BAUD = 115200;

wire clk;
wire clk_phy;

assign clk = CLK_50;
assign clk_phy = L1_OSC;

wire reset;
wire reset_phy;

reset_release reset_release(
  .clk   (clk),
  .reset (reset)
);

cdc_pipeline reset_phy_pipe(
  .clk_i  (clk),
  .clk_o  (clk_phy),
  .data_i (reset),
  .data_o (reset_phy)
);

uart_wrapper #(
  .F (UART_REF),
  .BAUD(UART_BAUD)
) uart_wrapper (
  .clk      (clk),
  .reset    (reset),
  .tx_data  (),
  .tx_valid (),
  .tx_ready (),
  .rx_data  (),
  .rx_valid (),
  .rx_ready (),
  .tx       (UART_TX),
  .rx       (UART_RX)
);

wire [127:0] rx_data_o;
wire         rx_valid_o;
wire [127:0] tx_data_i;
wire         tx_valid_i;

mac_wrapper mac_wrapper(
  .clk        (clk),
  .clk_phy    (clk_phy),
  .reset      (reset),
  .reset_phy  (reset_phy),
  .l1_rx_d    ({L1_RX1,L1_RX0}),
  .l1_rx_en   (L1_CRS_DV),
  .l1_tx_d    ({L1_TX1,L1_TX0}),
  .l1_tx_en   (L1_TX_EN),
  .rx_data_o  (rx_data_o),
  .rx_valid_o (rx_valid_o),
  .tx_data_i  (tx_data_i),
  .tx_valid_i (tx_valid_i)
);

defparam mac_wrapper.LOC_MAC = {8'hAE, 8'h61, 8'h76, 8'h54, 8'h5A, 8'hD6};

validator validator(
  .clk            (clk),
  .rst            (reset),
  .i_valid        (rx_valid_o),
  .i_transcation  (rx_data_o),
  .o_valid        (tx_valid_i),
  .o_hash         (tx_data_i)
);

endmodule

`default_nettype wire
