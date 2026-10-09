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
//白平衡_RGB
module wb_adjust (
    input clk,          // 像素时钟（约74.25 MHz for 720p60）
    input rst_n,      // 异步复位（低电平有效）
    input wire [23:0] rgb_in, // 输入RGB数据（R[23:16], G[15:8], B[7:0]）
    input vsync_in,        // 垂直同步信号（帧开始）
    input hsync_in,        // 水平同步信号（行开始）
    input de_in,  
    
    input en_wb_on,
    output [7:0] r_gain,
    output [7:0] g_gain,
    output [7:0] b_gain,
    
    output [23:0] rgb_out, // 输出RGB数据
    output  vsync_out,    // 输出垂直同步
    output  hsync_out,    // 输出水平同步
    output  de_out
);
 
wire [7:0] r_in,g_in, b_in;
assign r_in[7:0] = rgb_in[23:16];
assign g_in[7:0] = rgb_in[15: 8];
assign b_in[7:0] = rgb_in[ 7: 0];
reg [7:0] r_out,g_out,b_out;
assign rgb_out ={r_out[7:0],g_out[7:0],b_out[7:0]};
 
localparam FRAME_WIDTH   = 10'd1280;    // 720p宽度
localparam FRAME_HEIGHT  = 10'd720;     // 720p高度
// 状态机定义
//typedef enum {
localparam    IDLE              = 0;          // 空闲状态，等待帧开始
localparam    ACCUMULATE        = 1;    // 累加RGB值
localparam    CALC_AVG          = 2;      // 计算平均值 
localparam    APPLY             = 3;          // 应用增益到下一帧 
//} state_t;
reg [1:0] state;
 
// 内部寄存器 
reg [31:0] r_sum, g_sum, b_sum; // RGB累加器（32位防溢出）
reg [7:0]  r_avg, g_avg, b_avg;  // RGB平均值
reg [15:0] r_gain, g_gain, b_gain; // 增益值（Q8.8定点格式）
reg [19:0] r_temp, g_temp, b_temp;
 
// 目标平均值（固定为128，基于灰度世界算法）
localparam TARGET_AVG = 8'd128;

reg vsync_d1, vsync_d2,vsync_out;                 // 同步信号边沿检测
reg hsync_d1,hsync_d2,hsync_out;
reg de_d1,de_d2,de_out;

// 边沿检测：检测vsync上升沿
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        vsync_d2 <= 1'b0; vsync_d1 <= 1'b0;        
        hsync_d2 <= 1'b0; hsync_d1 <= 1'b0;
        de_d2    <= 1'b0; de_d1    <= 1'b0;
    end else begin
        vsync_d2 <= vsync_d1; vsync_d1 <= vsync_in;
        hsync_d2 <= hsync_d1; hsync_d1 <= hsync_in;
        de_d2    <= de_d1;    de_d1    <= de_in;
    end
end

wire vsync_posedge = vsync_d1 & ~vsync_d2;  // vsync上升沿
//wire vsync_negedge = ~vsync_d1 & vsync_d2;  // vsync下降沿
//wire href_posedge = hsync_in & ~hsync_d1;        // href上升沿
reg [20:0] pixel_count;                 // 像素计数
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        pixel_count <= 0;
    end else if(vsync_posedge) begin
        pixel_count <= 0;
    end else if(de_in) begin
        pixel_count <= pixel_count + 1;
    end else begin
        pixel_count <= pixel_count;
    end
end
// 状态机逻辑
always @(posedge clk or negedge rst_n) begin 
    if (!rst_n)
        state <= IDLE;
    else begin
        case (state)
            IDLE:
                if (vsync_posedge) // 帧开始时进入累加状态
                    state <= ACCUMULATE;
                else state <= state;
            ACCUMULATE:
                if (pixel_count >= (FRAME_WIDTH * FRAME_HEIGHT)-1)
                    state = CALC_AVG;
                else
                    state = ACCUMULATE;
            CALC_AVG:
                state <= APPLY;
            APPLY:
                if (vsync_in)
                    state <= IDLE;
                else state <= state ; // 下一帧开始时应用增益
        endcase
    end
end

always @(posedge clk or negedge rst_n) begin 
    if (!rst_n) begin 
        vsync_out <= 0;
        hsync_out <= 0;
        de_out <= 0;
    end else begin
        vsync_out <= vsync_d2;
        hsync_out <= hsync_d2;
        de_out <= de_d2;
    end
end
reg en_wb_on_00;
always @(posedge clk or negedge rst_n) begin 
    if (!rst_n) 
        en_wb_on_00 <= 0;
    else if (!vsync_in)
        en_wb_on_00<=en_wb_on;
    else
        en_wb_on_00<=en_wb_on_00;
end
always @(posedge clk or negedge rst_n) begin 
    if (!rst_n) begin
        r_sum <= 0; g_sum <= 0; b_sum <= 0;
    end else if (!vsync_in)begin
        r_sum <= 0; g_sum <= 0; b_sum <= 0;
    end else if (de_in==1 && state ==ACCUMULATE)begin
        r_sum <= r_sum + r_in[7:0];
        g_sum <= g_sum + g_in[7:0];
        b_sum <= b_sum + b_in[7:0];
    end else begin   // 传递同步信号 
        r_sum <= r_sum;
        g_sum <= g_sum;
        b_sum <= b_sum;
    end
end
always @(posedge clk or negedge rst_n) begin 
    if (!rst_n) begin
        r_avg <= 0; g_avg <= 0; b_avg <= 0;
        r_gain <= 16'h100; g_gain <= 16'h0100; b_gain <= 16'h0100;
    end else begin   // 传递同步信号 
        if(state==CALC_AVG)begin    // 计算平均值（整帧）
            r_avg <= r_sum[31:0] / pixel_count; // 近似除法（优化资源）
            g_avg <= g_sum[31:0] / pixel_count;
            b_avg <= b_sum[31:0] / pixel_count;
        end else begin
            r_avg <= r_avg; g_avg <= g_avg; b_avg <= b_avg;
        end
        if(state==APPLY)begin  // 下一帧开始时应用增益
            // 计算增益（Q8.8格式：增益 = TARGET_AVG / avg，防除零）
            //r_gain <= (r_avg == 0) ? 16'h0100 : (TARGET_AVG * 256) / r_avg;
            //g_gain <= (g_avg == 0) ? 16'h0100 : (TARGET_AVG * 256) / g_avg;
            //b_gain <= (b_avg == 0) ? 16'h0100 : (TARGET_AVG * 256) / b_avg;
            r_gain <= (r_avg == 0) ? 16'h0100 : (TARGET_AVG * 256) / r_avg;
            g_gain <= (g_avg == 0) ? 16'h0100 : (TARGET_AVG * 256) / g_avg;
            b_gain <= (b_avg == 0) ? 16'h0100 : (TARGET_AVG * 256) / b_avg;
        end else begin
            r_gain <= r_gain; g_gain <= g_gain; b_gain <= b_gain;
        end
    end
end

always @(posedge clk or negedge rst_n) begin 
    if (!rst_n) begin 
        r_temp <= 0; g_temp <= 0; b_temp <= 0;
        r_out <= 0;  g_out <= 0;  b_out <= 0;
    end else begin
        r_temp <= (r_in * r_gain);
        g_temp <= (g_in * g_gain);
        b_temp <= (b_in * b_gain);
        if(en_wb_on_00==1)begin
            r_out[7:0] <= (r_temp[19:8] > 255) ? 8'hFF : r_temp[15:8];
            g_out[7:0] <= (g_temp[19:8] > 255) ? 8'hFF : g_temp[15:8];
            b_out[7:0] <= (b_temp[19:8] > 255) ? 8'hFF : b_temp[15:8];
        end else begin
            r_out <= r_in;
            g_out <= g_in;
            b_out <= b_in;
        end
    end
end
endmodule 