`timescale 1ns/100ps
module NFC(clk, rst, done, F_IO_A, F_CLE_A, F_ALE_A, F_REN_A, F_WEN_A, F_RB_A, F_IO_B, F_CLE_B, F_ALE_B, F_REN_B, F_WEN_B, F_RB_B);

input clk;
input rst;
output done;
inout [7:0] F_IO_A;
output F_CLE_A;
output F_ALE_A;
output F_REN_A;
output F_WEN_A;
input  F_RB_A;
inout [7:0] F_IO_B;
output F_CLE_B;
output F_ALE_B;
output F_REN_B;
output F_WEN_B;
input  F_RB_B;

`define p1 p1
// `define p2 p2
// `define FSDB fsdb
`define VCD vcd
//-----------------------------------------------------------------------------------
reg done;

reg io_A;
reg [7:0] io_A_data;
wire [7:0] F_IO_A;
reg F_CLE_A;
reg F_ALE_A;
reg F_REN_A;
reg F_WEN_A;

reg io_B;
reg [7:0] io_B_data;
wire [7:0] F_IO_B;
reg F_CLE_B;
reg F_ALE_B;
reg F_REN_B;
reg F_WEN_B;

reg [3:0] state, next_state;
reg [7:0] mem [511:0][511:0];
reg [9:0] j, k;
//-----------------------------------------------------------------------------------
parameter writeA_C = 4'b0000, writeA_A1 = 4'b0001, writeA_A2 = 4'b0010, writeA_A3 = 4'b0011;
parameter writeB_C = 4'b0100, writeB_A1 = 4'b0101, writeB_A2 = 4'b0110, writeB_A3 = 4'b0111;
parameter Aw_pending = 4'b1000, Ar_pending = 4'b1001, Bw_pending = 4'b1010, writeB_data = 4'b1011;
parameter cal = 4'b1100, readA = 4'b1101, col_done = 4'b1110, finish = 4'b1111;

assign F_IO_A = (io_A) ? io_A_data : 8'bz;
assign F_IO_B = (io_B) ? io_B_data : 8'bz;
//-----------------------------------------------------------------------------------
//-----------------------------------------------------------------------------------
always@(posedge clk or posedge rst) begin
    if(rst) begin
        F_CLE_A = 0; F_ALE_A = 0; F_REN_A = 1; F_WEN_A = 1;
        F_CLE_B = 0; F_ALE_B = 0; F_REN_B = 1; F_WEN_B = 1;
        state = writeA_C; j = 0; k = 0;
    end else begin
        case(state)
            cal: begin
                F_CLE_A = 0;
                F_ALE_A = 0;
                F_WEN_A = 1;
                F_REN_A = 0;
                io_A = 0;

                if(F_RB_A) state = readA;
            end
            Aw_pending: begin
                F_WEN_A = 1;
                state = next_state;
            end
            Ar_pending: begin
                F_REN_A = 0;
                state = next_state;
            end
            Bw_pending: begin
                F_WEN_B = 1;
                state = next_state;
            end
            writeA_C: begin
                F_CLE_A = 1;
                F_ALE_A = 0;
                F_WEN_A = 0;
                io_A = 1;
                io_A_data = 8'h00;

                F_CLE_B = 0;
                F_ALE_B = 0;
                F_WEN_B = 1;
                io_B = 0;

                state = Aw_pending;
                next_state = writeA_A1;
            end
            writeA_A1: begin
                F_CLE_A = 0;
                F_ALE_A = 1;
                F_WEN_A = 0;
                io_A = 1;
                io_A_data = 8'h00;

                state = Aw_pending;
                next_state = writeA_A2;
            end
            writeA_A2: begin
                F_CLE_A = 0;
                F_ALE_A = 1;
                F_WEN_A = 0;
                io_A = 1;
                io_A_data = j[7:0];

                state = Aw_pending;
                next_state = writeA_A3;
            end
            writeA_A3: begin
                F_CLE_A = 0;
                F_ALE_A = 1;
                F_WEN_A = 0;
                io_A = 1;
                io_A_data = {7'b0000000, j[8]};

                state = Aw_pending;
                next_state = cal;
            end
            readA: begin
                F_CLE_A = 0;
                F_ALE_A = 0;
                F_WEN_A = 1;
                F_REN_A = 1;

                mem[j][k] = F_IO_A;
                k = k + 1;

                if(k == 512) begin
                    k = 0;

                    state = Aw_pending;
                    next_state = writeB_C;
                end else begin
                    state = Ar_pending;
                    next_state = readA;
                end

            end
            writeB_C: begin
                F_CLE_B = 1;
                F_ALE_B = 0;
                F_WEN_B = 0;
                io_B = 1;
                io_B_data = 8'h80;

                F_CLE_A = 0;
                F_ALE_A = 0;
                F_WEN_A = 1;
                F_REN_A = 1;
                io_A = 0;

                state = Bw_pending;
                next_state = writeB_A1;
            end
            writeB_A1:begin
                F_CLE_B = 0;
                F_ALE_B = 1;
                F_WEN_B = 0;
                io_B = 1;
                io_B_data = 8'h00;

                state = Bw_pending;
                next_state = writeB_A2;
            end
            writeB_A2:begin
                F_CLE_B = 0;
                F_ALE_B = 1;
                F_WEN_B = 0;
                io_B = 1;
                io_B_data = j[7:0];

                state = Bw_pending;
                next_state = writeB_A3;
            end
            writeB_A3:begin
                F_CLE_B = 0;
                F_ALE_B = 1;
                F_WEN_B = 0;
                io_B = 1;
                io_B_data = {7'b0000000, j[8]};

                state = Bw_pending;
                next_state = writeB_data;
            end
            writeB_data: begin
                F_CLE_B = 0;
                F_ALE_B = 0;
                F_WEN_B = 0;
                io_B = 1;

                io_B_data = mem[j][k];
                k = k + 1;

                if(k == 512) begin
                    j = j + 1;
                    k = 0;

                    state = Bw_pending;
                    next_state = col_done;
                end else begin
                    state = Bw_pending;
                    next_state = writeB_data;
                end
            end
            col_done: begin
                F_CLE_B = 1;
                F_ALE_B = 0;
                F_WEN_B = 0;
                io_B = 1;
                io_B_data = 8'h10;

                if(j == 512) begin
                    state = Bw_pending;
                    next_state = finish;
                end else begin
                    state = Bw_pending;
                    next_state = writeA_C;
                end
            end
            finish: begin
                F_CLE_A = 0;
                F_ALE_A = 0;
                F_WEN_A = 1;
                F_REN_A = 1;
                io_A = 0;

                F_CLE_B = 0;
                F_ALE_B = 0;
                F_WEN_B = 1;
                F_REN_B = 1;
                io_B = 0;

                if(F_RB_B) done = 1;
                else state = finish;
            end
        endcase
    end
end
//-----------------------------------------------------------------------------------
endmodule
