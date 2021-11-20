
`default_nettype none

module mac_wrapper(
  input  wire          clk,
  input  wire          clk_phy,

  input  wire          reset,
  input  wire          reset_phy,

  input  wire  [  1:0] l1_rx_d,
  input  wire          l1_rx_en,
  output logic [  1:0] l1_tx_d,
  output logic         l1_tx_en,

  output logic [127:0] rx_data_o,
  output logic         rx_valid_o,

  input  wire  [127:0] tx_data_i,
  input  wire          tx_valid_i
);

parameter LOC_MAC = {8'hAE, 8'h61, 8'h76, 8'h54, 8'h5A, 8'hD6};
parameter EXT_MAC = {8'hC2, 8'h6F, 8'h92, 8'h32, 8'h3B, 8'h4D};
parameter ETHERTYPE = {8'hC0,8'hDE};

logic [127:0] mac_rx_data;
logic         mac_rx_valid;
logic         rx_fifo_rdempty;

  mac_rx #(
    .MAC (LOC_MAC),
    .ETHERTYPE(ETHERTYPE)
  ) mac_rx (
    .clk     (clk_phy),
    .rst     (!reset_phy),
    .rx_d    (l1_rx_d),
    .rx_en   (l1_rx_en),
    .data    (mac_rx_data),
    .src_mac (),
    .valid   (mac_rx_valid)
  );

  dcfifo128 rx_fifo (
    .aclr    (reset),
    .data    (mac_rx_data),
    .rdclk   (clk),
    .rdreq   (~rx_fifo_rdempty),
    .wrclk   (clk_phy),
    .wrreq   (mac_rx_valid),
    .q       (rx_data_o),
    .rdempty (rx_fifo_rdempty),
    .wrfull  ()
  );

  always_ff @(posedge clk)
    rx_valid_o <= ~rx_fifo_rdempty;

  logic [127:0] mac_tx_data;
  logic         mac_tx_ready;
  logic         tx_fifo_rdempty;

  dcfifo128 tx_fifo (
    .aclr    (reset),
    .data    (tx_data_i),
    .rdclk   (clk_phy),
    .rdreq   (mac_tx_ready),
    .wrclk   (clk),
    .wrreq   (tx_valid_i),
    .q       (mac_tx_data),
    .rdempty (tx_fifo_rdempty),
    .wrfull  ()
  );

  mac_tx #(
    .SRC_MAC        (LOC_MAC),
    .NCOIN_ETH_TYPE (ETHERTYPE)
  ) mac_tx (
    .clk     (clk_phy),
    .rst     (!reset_phy),
    .valid   (~tx_fifo_rdempty),
    .data    (mac_tx_data),
    .dst_mac (EXT_MAC),
    .ready   (mac_tx_ready),
    .tx_d    (l1_tx_d),
    .tx_en   (l1_tx_en)
  );

endmodule

`default_nettype wire
