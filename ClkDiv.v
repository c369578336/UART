`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer: 尘世
//
// Create Date: 2021年10月16日11:21:31
// Design Name: UART
// Module Name: ClkDiv
// Project Name: UART
// Target Devices:
// Tool Versions:
// Description:
// 以100MHz为基准时钟，为UART提供不同波特率的时钟
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 尽可能的避免分支外有非必须重复的步骤，因为Verilog是并行性语言
//////////////////////////////////////////////////////////////////////////////////

module ClkDiv (
        input clk,
        input rst,
        output reg clk_out
    );
    parameter Baud = 9600;

    localparam  div_num= 100000000/Baud;
    reg [15:0] i = 0;

    always @(posedge clk ) begin
        if (rst) begin
            i<=0;
            clk_out<=0;
        end
        else if (i==div_num) begin
            i<=0;
            clk_out<=1;
        end
        else begin
            i <= i+1;
            clk_out<=0;
        end
    end
endmodule
