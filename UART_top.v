`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer: 尘世
//
// Create Date: 2021�?10�?16�?10:52:38
// Design Name: UART
// Module Name: UART_top
// Project Name: UART
// Target Devices:
// Tool Versions:
// Description:
// 建立可用于UART通信的基本IP�?
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:

// input Rx,数据接收
// input clk,//clk=100M
// input data_send,代发送的数据
// input rst,   同步复位
// input en,    片选信号，en=1则发送数据，en=0，则接收数据。

// output data_recieve,接收到的数据，当校验位正确时发生改变
// output ack_out,     Rx的数据发送，详情可以参考UART_Rx
// output Tx           Tx的数据发送
// 接受时用RX代替ACK，因此本工程仅仅是半双工，如果要形成全双工，则需要再增加两根线用于收发ack
// en=1时，开始发送数据，en可以由FPGA内部或者从机提供
// 当Rx=0时，开始接收，当数据接收完成后并通过检验码进行校验后，将产生一个高电平fin，持续到下一次开始接收
//////////////////////////////////////////////////////////////////////////////////

module UART_top(
        input Rx,
        input clk,//clk=100M
        input [7:0] data_send,
        input rst,
        input en,

        output [7:0] data_recieve,
        output Tx
    );
    parameter Baud = 9600;//设置波特�?
    parameter DataBits = 8;//数据的位数，通常常用的为5�?7�?8
    parameter StopBits = 2;//停止位的长度，长度为(StopBits),常用的有1�?1.5�?2位，此处默认两位
    //停止位不仅仅是表示传输的结束，并且提供计算机校正时钟同步的机会�?��?�用于停止位的位数越多，不同时钟同步的容忍程度越大，但是数据传输率同时也越慢�?
    wire Rx_out;
    wire Tx_out;

    UART_Tx#
        (
            .DataBits(DataBits),
            .Baud(Baud),
            .StopBits(StopBits)
        )
        u_UART_Tx (
            .data                    ( data_send  ),
            .clk                     ( clk    ),
            .rst                     ( rst    ),
            .en                      ( en     ),

            .Tx                      ( Tx_out     )
        );

    UART_Rx#
        (
            .DataBits(DataBits),
            .Baud(Baud),
            .StopBits(StopBits)
        )
        u_UART_Rx
        (
            .clk                     ( clk            ),
            .rst                     ( rst|en         ),
            .Rx                      ( Rx             ),

            .data                    ( data_recieve   ),
            .Tx                      ( Rx_out         )
        );

    assign Tx=(Tx_out&en)|(Rx_out&~en);
endmodule
