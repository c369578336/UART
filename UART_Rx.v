`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer: 尘世
//
// Create Date: 2021/10/19/08点39分
// Design Name: UART
// Module Name: UART_Rx
// Project Name: UART
// Target Devices:
// Tool Versions:
// Description:
// UART的接收模块
// 共有三个状态：
// 1.等待；
// 2.接收数据；
// 3.接收校验码。
// 停止位并不影响数据的接收逻辑，只与发送有关
// Dependencies:
// Revision:
// Revision 0.01 - File Created
// Revision 1.00 - 基本功能实现，可以接收数据
// Revision 2.00 - 完成在一个周期内多次采样确保数据的可靠性。
// Revision 2.01 - 当数据接收完成后并通过检验码进行校验后，将产生一个高电平fin，持续到下一次开始接收
// Additional Comments:

// output data  接收到的实际数据
// input clk    系统时钟100M
// input rst    同步复位
// output Tx    数据校验正确：Tx=1，数据校验错误：Tx=0。工作状态下Tx=0，其他时候为1。本系统为开环，数据校验不影响数据的收发。就目前的功能而言，并不适合做数据重发，建议用上层程序控制。
// input Rx     数据接收

// 接受时用RX代替ACK，因此本工程仅仅是半双工，如果要形成全双工，则需要再增加两根线用于收发ack
// 由于此处用了除法，无法除尽，导致check中的时钟会随着时间而漂移，进而导致数据出错，需要每个时钟进行复位
//////////////////////////////////////////////////////////////////////////////////

module UART_Rx#
    (    parameter DataBits = 8,
         parameter Baud = 9600,
         parameter StopBits = 2
    )
    (
        output reg [DataBits-1:0] data,
        input clk,//clk=100M
        input rst,
        output reg Tx,
        input Rx
    );

    localparam Wait = 0;
    localparam RecieveData = 1;
    localparam RecieveEnd = 2;

    reg [2:0] state=Wait;
    reg [2:0] next_state;
    reg [DataBits-1:0] data_tmp;
    reg [2:0] count;//计数收到的数据位数
    reg parity;
    wire R;
    wire clk_out;

    ClkDiv #(
               .Baud(Baud)
           )
           u_ClkDiv
           (
               .clk(clk),
               .clk_out(clk_out)
           );

    check #(
              .Baud(Baud)
          )
          u_check(
              .clk(clk),
              .Rx(Rx),
              .R(R),
              .rst(rst|clk_out)
          );
    // assign R=Rx;
    always @(*) begin
        case (state)
            Wait:
                next_state=(R)?Wait:RecieveData;
            RecieveData:
                next_state=(count==DataBits-1)?RecieveEnd:RecieveData;
            RecieveEnd:
                next_state=Wait;
            default:
                next_state=Wait;
        endcase
    end

    always @(posedge clk_out ) begin
        case (state)
            Wait:
                Tx<=1;
            RecieveData:
                Tx<=0;
            RecieveEnd:
                if (^data_tmp==R) begin
                    Tx<=1;
                    data<=data_tmp;
                end
                else begin
                    Tx <= 0;
                end
            default:
                Tx<=1;
        endcase
    end

    always @(posedge clk_out ) begin
        if (rst) begin
            state<=Wait;
            data_tmp<=0;
            count<=0;
        end
        else
        case (state)
            Wait: begin
                state<=next_state;
                count<=0;
                data_tmp[7:0]=0;
            end
            RecieveData: begin
                data_tmp[7:0]<={R,data_tmp[7:1]};
                state<=next_state;
                count<=count+1;
            end
            RecieveEnd: begin
                state<=next_state;
                count<=0;
            end
            default: begin
                state<=Wait;
            end
        endcase
    end

endmodule

module check(
        input Rx,
        input clk,
        input rst,
        output reg R
    );
    parameter Baud = 9600;
    wire clk_out;
    reg [2:0] count=0;//用于多次统计
    reg [2:0] s=0;
    ClkDiv #(
               .Baud(Baud*8)
           )
           u_ClkDiv
           (
               .clk(clk),
               .rst(rst),
               .clk_out(clk_out)
           );

    always @(posedge clk_out) begin
        if (rst) begin
            count<=0;
            s<=0;
        end
        else begin
            if (count==6) begin
                if (s>3)
                    R<=1;
                else begin
                    R <= 0;
                end
                s<=0;
                count<=0;
            end
            else begin
                count <= count+1;
                s=s+Rx;
            end
        end
    end
endmodule

