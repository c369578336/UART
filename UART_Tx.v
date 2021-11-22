`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer: 尘世
//
// Create Date: 2021年10月16日15:07:59
// Design Name: UART
// Module Name: UART_Tx
// Project Name: UART
// Target Devices:
// Tool Versions:
// Description:
// UART发送模块
// 共有5个状态：
// 1. 等待发送
// 2. 起始位
// 3. 数据位
// 4. 校验位
// 5. 停止位
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Revision 1.00 - 基本功能实现
// Revision 2.00 - 增加了停止位的设计

// Additional Comments:
// input data  待发送的数据
// input clk,  系统时钟，100M
// input rst,  同步复位
// input en,   发送使能，可以开始发送数据，为1时开始发送数据，为0时不发送数据
// output Tx   数据发送位

// 尽可能的避免分支外有非必须重复的步骤，因为Verilog是并行性语言

//////////////////////////////////////////////////////////////////////////////////

module UART_Tx#
    (    parameter DataBits = 8,
         parameter Baud = 9600,
         parameter StopBits = 2
    )
    (
        input [DataBits-1:0] data,
        input clk,//clk=100M
        input rst,
        input en,
        output reg Tx
    );

    localparam Wait = 0;
    localparam SendStart = 1;
    localparam SendData = 2;
    localparam SendEnd = 3;
    localparam SendStop=4;

    reg [2:0] state=Wait;
    reg [2:0] next_state;
    reg [DataBits-1:0] data_tmp;
    reg [2:0] count;
    reg parity;
    wire clk_Baud;
    ClkDiv #(
               .Baud(Baud)
           )
           u_ClkDiv
           (
               .clk(clk),
               .clk_out(clk_out)
           );

    always @(*) begin
        case (state)
            Wait:
                next_state=(~en)?Wait:SendStart;
            SendStart:
                next_state=SendData;
            SendData:
                next_state=(count==DataBits-1)?SendEnd:SendData;
            SendEnd:
                next_state=SendStop;
            SendStop:
                next_state=(count==StopBits)?(~en?Wait:SendStart):SendStop;
            default:
                next_state=Wait;
        endcase
    end

    always @(negedge clk_out ) begin
        case (state)
            Wait:
                Tx=1;
            SendStart:
                Tx=0;
            SendData:
                Tx=data_tmp[0];
            SendEnd:
                Tx=parity;
            SendStop:
                Tx=1;
            default:
                Tx=1;
        endcase
    end

    always @(posedge clk_out ) begin
        if (rst) begin
            state<=Wait;
            data_tmp<=0;
            parity<=0;
            count<=0;
        end
        else
        case (state)
            Wait: begin
                state=next_state;
            end
            SendStart: begin
                state=next_state;
                data_tmp=data;
                parity=^data;
                count=0;
            end
            SendData: begin
                data_tmp[6:0]=data_tmp[7:1];
                count=count+1;
                state=next_state;
            end
            SendEnd: begin
                state=next_state;
                count=0;
            end
            SendStop: begin
                state=next_state;
                count=count+1;
            end
            default: begin
                state=Wait;
            end
        endcase
    end
endmodule

