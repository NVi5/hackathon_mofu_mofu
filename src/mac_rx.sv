/*-
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * Copyright (c) 2020 Rafal Kozik
 * All rights reserved.
 */

`default_nettype none

module mac_rx #(
    parameter logic [0:5][3:0][1:0]MAC = {8'h2, 8'h0, 8'h0, 8'h0, 8'h0, 8'h0},
    parameter logic [0:1][3:0][1:0]ETHERTYPE = {8'hc0, 8'hde}
) (
    input wire clk,
    input wire rst,
    input wire [1:0]rx_d,
    input wire rx_en,
    output logic [127:0]data,
    output logic [0:5][3:0][1:0]src_mac,
    output logic valid
);
    logic [1:0]rx_d_d;
    logic [1:0]rx_en_d;
    logic [6:0]cnt;
    logic [0:5][3:0][1:0]src_mac_in;
    logic [63:0][1:0]data_in;
    logic [0:1][3:0][1:0]num;
    logic [15:0]cnt_data;
    logic data_ready;

    enum logic [3:0] {
        IDLE,
        PREAMB,
        MAC_DST,
        MAC_SRC,
        ETHER_TYPE,
        NCOIN_V,
        NCOIN_TYPE,
        NUM,
        DATA,
        TO_END
} state;

    always_ff @(posedge clk or negedge rst)
        if (!rst)
            rx_en_d <= 'b0;
        else
            rx_en_d <= {rx_en_d[0], rx_en};

    always_ff @(posedge clk)
        rx_d_d <= rx_d;

    always_ff @(posedge clk)
        if (state == PREAMB)
            cnt <= '0;
        else if(cnt == 5'd23 && (state == MAC_DST || state == MAC_SRC))
            cnt <= '0;
        else if(cnt == 5'd7 && state == ETHER_TYPE)
            cnt <= '0;
        else if(cnt == 5'd3 && (state == NCOIN_V || state == NCOIN_TYPE))
            cnt <= '0;
        else if (cnt == 5'd7 && state == NUM)
            cnt <= '0;
        else if (cnt == 7'd63 && state == DATA)
            cnt <= '0;
        else
            cnt <= cnt + 1'd1;

    always_ff @(posedge clk)
        if (state == NUM)
            num[cnt[2]][cnt[1:0]] <= rx_d_d;

    always_ff @(posedge clk)
        if (state == MAC_SRC)
            src_mac_in[cnt[4:2]][cnt[1:0]] <= rx_d_d;

    always_ff @(posedge clk)
        if (state == ETHER_TYPE)
            src_mac <= src_mac_in;

    always_ff @(posedge clk)
        if (state == IDLE)
            cnt_data <= '0;
        else if (state == DATA && cnt == 7'd63)
            cnt_data <= cnt_data + 1'd1;

    always_ff @(posedge clk)
        if (state == DATA)
            data_in[cnt] <= rx_d_d;

    assign data_ready = (state == DATA || state == TO_END) && cnt_data != '0 && cnt == '0;

    always_ff @(posedge clk)
        if (data_ready)
            data <= data_in;

    always_ff @(posedge clk)
        valid <= data_ready;

    always_ff @(posedge clk or negedge rst)
        if (!rst)
            state <= IDLE;
        else begin
            case(state)
                IDLE: state <= (rx_d_d == 2'd1 && rx_en_d[0]) ? PREAMB : IDLE;
                PREAMB:
                    case ({rx_en_d[0], rx_d_d})
                        3'b101: state <= PREAMB;
                        3'b111: state <= MAC_DST;
                        default: state <= TO_END;
                    endcase
                MAC_DST: state <= (cnt == 5'd23) ? MAC_SRC : MAC_DST;
                MAC_SRC: state <= (cnt == 5'd23) ? ETHER_TYPE : MAC_SRC;
                ETHER_TYPE:
                    if (ETHERTYPE[cnt[2]][cnt[1:0]] == rx_d_d) 
                        state <= (cnt == 5'd7) ? NCOIN_V : ETHER_TYPE;
                    else
                        state <= TO_END;
                NCOIN_V: state <= (cnt == 5'd3) ? NCOIN_TYPE : NCOIN_V;
                NCOIN_TYPE: state <= (cnt == 5'd3) ? NUM : NCOIN_TYPE;
                NUM: state <= (cnt == 5'd7) ? DATA : NUM;
                DATA: state <= (cnt == 7'd63 && cnt_data == num-1) ? TO_END : DATA;
                TO_END: state <= (|rx_en_d) ? TO_END : IDLE;
            endcase
        end

endmodule

`default_nettype wire
