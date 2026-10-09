`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/21
// Design Name: 
// Module Name: timer_system
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module clock_divider (
    input       clk_96MHz,   // 96MHz输入时钟
    input       rstn_sys,     // 低电平有效复位 (reset_n=0时复位)
    output reg  clk_60Hz    // 60Hz输出时钟 

);
 
// 计数器定义 (60Hz需21位，6Hz需24位)
reg [20:0] counter_60;  // 21位计数器 (0 to 2,097,151)
localparam CNT_60_MAX = 21'd0_799_999;   // 96e6/60/2 - 1 
always @(posedge clk_96MHz or negedge rstn_sys) begin
    if (!rstn_sys) begin  // 低电平复位 
        counter_60 <= 0;
        clk_60Hz   <= 0;
    end else begin
        // 60Hz时钟生成
        if (counter_60 == CNT_60_MAX) begin 
            clk_60Hz  <= ~clk_60Hz;  // 翻转时钟 
            counter_60 <= 0;
        end else begin 
            counter_60 <= counter_60 + 1;
            clk_60Hz  <= clk_60Hz;
        end 
    end 
end 
endmodule
localparam CNT_state_MAX  = 10'd299;
module counter_state_with_fram (
    input           clk_sys,   // 96MHz输入时钟
    input           rstn_sys,     // 低电平有效复位 (reset_n=0时复位)
    input           trigger_frame,
    output [9:0]    counter_state_main

);
reg [9:0]  counter_state_main;
always @(posedge clk_sys or negedge rstn_sys) begin
	if(~rstn_sys) begin
        counter_state_main <= 0;
    end else begin
        if(trigger_frame)begin
            if(counter_state_main ==CNT_state_MAX)
                counter_state_main <= 0;
            else
                counter_state_main <= counter_state_main +1;
        end else begin
            counter_state_main <= counter_state_main;
        end
    end
end
endmodule
