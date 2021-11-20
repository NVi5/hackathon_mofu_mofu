/*-
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * Copyright (c) 2020 Rafal Kozik
 * All rights reserved.
 */

`default_nettype none

module mac_tx #(
    parameter logic [0:5][3:0][1:0]SRC_MAC = {8'h2, 8'h0, 8'h0, 8'h0, 8'h0, 8'h0},
    parameter logic [15:0]NCOIN_ETH_TYPE = 16'hc0de
) (
    input wire clk,
    input wire rst,
    input wire valid,
    input wire [127:0] data,
    input wire [0:5][3:0][1:0]dst_mac,
    output logic ready,
    output logic [1:0]tx_d,
    output logic tx_en
);
    localparam R_ADDR = $clog2(240);
    localparam PKT_SIZE = 60;

    typedef struct packed {
        logic [223:0] padding;
        logic [127:0] hash;
        logic [  7:0] ncoin_type;
        logic [  7:0] ncoin_version;
        logic [ 15:0] eth_type;
        logic [5:0][3:0][1:0] src_mac;
        logic [5:0][3:0][1:0] dst_mac;
    } pkt_t;

    pkt_t pkt;
    logic [239:0][1:0]dbits;

    enum logic {
        IDLE,
        SEND
    } state;

    logic [R_ADDR-1:0] raddr;
    logic [1:0] d_mem;
    logic [1:0] d_crc;
    logic [1:0] d_preamb;
    logic eop_crc, valid_d, start, eop_crc_d;
    logic select_data, select_data_d, sop, eop, mem_start;
    logic mem_start_t, mem_start_t_d;
    logic [5:0] preamb_cnt;

    assign dbits = pkt;

    always_ff @(posedge clk)
        if (!rst)
            valid_d <= '0;
        else
            valid_d <= valid;

    assign start = (valid & !valid_d);

    always_ff @(posedge clk) begin
        if (!rst) begin
            for (int i=0; i<6; i++)
               pkt.src_mac[i] <= SRC_MAC[i];
            pkt.dst_mac <= '0;
            pkt.eth_type <= {NCOIN_ETH_TYPE[7:0], NCOIN_ETH_TYPE[15:8]};
            pkt.ncoin_version <= 8'd1;
            pkt.ncoin_type	<= 8'd1;
            pkt.hash <= '0;
            pkt.padding <= '0;
        end else if (state == IDLE && valid) begin
            for (int i=0; i<6; i++)
                pkt.dst_mac[i] <= dst_mac[i];
            pkt.hash <= data;
        end
    end

    always_ff @(posedge clk)
        if (!rst)
            state <= IDLE;
        else case (state)
            IDLE: state <= start ? SEND : IDLE;
            SEND: state <= eop_crc ? IDLE : SEND;
            default: state <= IDLE;
        endcase

    always_ff @(posedge clk)
        if (state == IDLE)
            preamb_cnt <= '0;
        else if (preamb_cnt[5] == 1'b0)
            preamb_cnt <= preamb_cnt + 1'b1;

    always_ff @(posedge clk)
        d_preamb <= preamb_cnt[5] ? 2'd3 : 2'd1;

    always_ff @(posedge clk)
        if (state == IDLE)
            raddr <= '0;
        else if (mem_start)
            raddr <= raddr + 1'b1;

    always_ff @(posedge clk) begin
        mem_start_t <= preamb_cnt == 6'd29;
        mem_start_t_d <= mem_start_t;
    end

    always_ff @(posedge clk)
        if (state == IDLE)
            mem_start <= 1'b0;
        else if (mem_start_t)
            mem_start <= 1'b1;

    always_ff @(posedge clk)
        sop <= mem_start_t_d;

    assign eop = (raddr == {PKT_SIZE, 2'b0});

    always_ff @(posedge clk)
        d_mem <= dbits[raddr];

    crc add_crc (
        .clk(clk),
        .rst(rst),
        .d(d_mem),
        .sop(sop),
        .eop(eop),
        .d_out(d_crc),
        .sop_out(),
        .eop_out(eop_crc));

    always_ff @(posedge clk) begin
        select_data <= preamb_cnt[5];
        select_data_d <= select_data;
        tx_d <= select_data_d ? d_crc : d_preamb;
    end

    always_ff @(posedge clk)
        eop_crc_d <= eop_crc;

    always_ff @(posedge clk or negedge rst) begin
        if (!rst)
            tx_en <= '0;
        else if (preamb_cnt == 5'd2)
            tx_en <= '1;
        else if (eop_crc_d)
            tx_en <= '0;
    end

    always_ff @(posedge clk)
        ready <= state == IDLE;

endmodule

`default_nettype wire
