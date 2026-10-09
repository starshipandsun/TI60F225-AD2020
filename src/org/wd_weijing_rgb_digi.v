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
module digit_overlay (
    input clk,               // 像素时钟 
    input rst,               // 复位信号 
    input [23:0] rgb_in,     // 输入像素数据 (24位)
    input vsync_in,          // 输入场同步 
    input hsync_in,          // 输入行同步 
    input de_in,             // 输入数据有效 
    input en_digi_on,
    input [47:0] digits_0,     // 6个数字（每个数字4位，digits[3:0]为最左数字）
    input [47:0] digits_1,     // 6个数字（每个数字4位，digits[3:0]为最左数字）
    input [47:0] digits_2,     // 6个数字（每个数字4位，digits[3:0]为最左数字）
    input [47:0] digits_3,     // 6个数字（每个数字4位，digits[3:0]为最左数字）
    output reg [23:0] rgb_out, // 输出像素数据 
    output reg vsync_out,    // 输出场同步 
    output reg hsync_out,    // 输出行同步 
    output reg de_out        // 输出数据有效 
);
 
// 屏幕参数 
localparam H_RES = 1280;     // 水平分辨率 
localparam V_RES = 750;      // 垂直分辨率  
// 字符参数 
localparam CHAR_WIDTH  = 8; // 字符宽度 
localparam CHAR_HEIGHT = 16; // 字符高度 
localparam CHAR_SPACING_0 = 2; // 字符间距 
localparam CHAR_SPACING_1 = 195; // 字符间距 
localparam NUM_DIGITS   = 8; // 数字数量  
// 计算显示区域位置 
//localparam TOTAL_WIDTH = NUM_DIGITS * CHAR_WIDTH + (NUM_DIGITS - 1) * CHAR_SPACING;
localparam x_START_0 = 100; // 水平起始位置
localparam y_START_0 = 150;  // 垂直起始位置
localparam y_START_1 = 320;  // 垂直起始位置
localparam y_START_2 = 510;  // 垂直起始位置
localparam y_START_3 = 690;  // 垂直起始位置
localparam sart_x_digit_00  = x_START_0 ;                         localparam  end_x_digit_00  = sart_x_digit_00 + CHAR_WIDTH;
localparam sart_x_digit_01  = end_x_digit_00 + CHAR_SPACING_0;    localparam  end_x_digit_01  = sart_x_digit_01 + CHAR_WIDTH;
localparam sart_x_digit_02  = end_x_digit_01 + CHAR_SPACING_1;    localparam  end_x_digit_02  = sart_x_digit_02 + CHAR_WIDTH;
localparam sart_x_digit_03  = end_x_digit_02 + CHAR_SPACING_0;    localparam  end_x_digit_03  = sart_x_digit_03 + CHAR_WIDTH;
localparam sart_x_digit_04  = end_x_digit_03 + CHAR_SPACING_1;    localparam  end_x_digit_04  = sart_x_digit_04 + CHAR_WIDTH;
localparam sart_x_digit_05  = end_x_digit_04 + CHAR_SPACING_0;    localparam  end_x_digit_05  = sart_x_digit_05 + CHAR_WIDTH;
localparam sart_x_digit_06  = end_x_digit_05 + CHAR_SPACING_1;    localparam  end_x_digit_06  = sart_x_digit_06 + CHAR_WIDTH;
localparam sart_x_digit_07  = end_x_digit_06 + CHAR_SPACING_0;    localparam  end_x_digit_07  = sart_x_digit_07 + CHAR_WIDTH;
localparam sart_x_digit_08  = end_x_digit_07 + CHAR_SPACING_1;    localparam  end_x_digit_08  = sart_x_digit_08 + CHAR_WIDTH;
localparam sart_x_digit_09  = end_x_digit_08 + CHAR_SPACING_0;    localparam  end_x_digit_09  = sart_x_digit_09 + CHAR_WIDTH;
localparam sart_x_digit_10  = end_x_digit_09 + CHAR_SPACING_1;    localparam  end_x_digit_10  = sart_x_digit_10 + CHAR_WIDTH;
localparam sart_x_digit_11  = end_x_digit_10 + CHAR_SPACING_0;    localparam  end_x_digit_11  = sart_x_digit_11 + CHAR_WIDTH;
localparam sart_y_digit_0   = y_START_0 ;                   localparam  end_y_digit_0   = sart_y_digit_0 + CHAR_HEIGHT;
localparam sart_y_digit_1   = y_START_1 ;                   localparam  end_y_digit_1   = sart_y_digit_1 + CHAR_HEIGHT;
localparam sart_y_digit_2   = y_START_2 ;                   localparam  end_y_digit_2   = sart_y_digit_2 + CHAR_HEIGHT;
localparam sart_y_digit_3   = y_START_3 ;                   localparam  end_y_digit_3   = sart_y_digit_3 + CHAR_HEIGHT;
// 位置计数器 
reg [10:0] x_cnt = 0;        // 水平计数器 (0-1279)
reg [10:0] y_cnt = 0;        // 垂直计数器 (0-759)
  
reg [5:0]   cnt_row_digit;
reg [5:0]   cnt_col_digit;
reg [3:0]   value_cur_digit;
reg [11:0]   x_digi_view;   
reg [7:0]   y_digi_view;
always @(*) begin 
    if((y_cnt >=sart_y_digit_0)&&(y_cnt <end_y_digit_0))   y_digi_view[0] = 1; else y_digi_view[0] = 0;  
    if((y_cnt >=sart_y_digit_1)&&(y_cnt <end_y_digit_1))   y_digi_view[1] = 1; else y_digi_view[1] = 0;  
    if((y_cnt >=sart_y_digit_2)&&(y_cnt <end_y_digit_2))   y_digi_view[2] = 1; else y_digi_view[2] = 0;  
    if((y_cnt >=sart_y_digit_3)&&(y_cnt <end_y_digit_3))   y_digi_view[3] = 1; else y_digi_view[3] = 0;
    if((x_cnt >=sart_x_digit_00)&&(x_cnt <end_x_digit_00)) x_digi_view[0] = 1; else x_digi_view[0] = 0;  
    if((x_cnt >=sart_x_digit_01)&&(x_cnt <end_x_digit_01)) x_digi_view[1] = 1; else x_digi_view[1] = 0;  
    if((x_cnt >=sart_x_digit_02)&&(x_cnt <end_x_digit_02)) x_digi_view[2] = 1; else x_digi_view[2] = 0;  
    if((x_cnt >=sart_x_digit_03)&&(x_cnt <end_x_digit_03)) x_digi_view[3] = 1; else x_digi_view[3] = 0;  
    if((x_cnt >=sart_x_digit_04)&&(x_cnt <end_x_digit_04)) x_digi_view[4] = 1; else x_digi_view[4] = 0;  
    if((x_cnt >=sart_x_digit_05)&&(x_cnt <end_x_digit_05)) x_digi_view[5] = 1; else x_digi_view[5] = 0;  
    if((x_cnt >=sart_x_digit_06)&&(x_cnt <end_x_digit_06)) x_digi_view[6] = 1; else x_digi_view[6] = 0;  
    if((x_cnt >=sart_x_digit_07)&&(x_cnt <end_x_digit_07)) x_digi_view[7] = 1; else x_digi_view[7] = 0;  
    if((x_cnt >=sart_x_digit_08)&&(x_cnt <end_x_digit_08)) x_digi_view[8] = 1; else x_digi_view[8] = 0;  
    if((x_cnt >=sart_x_digit_09)&&(x_cnt <end_x_digit_09)) x_digi_view[9] = 1; else x_digi_view[9] = 0;  
    if((x_cnt >=sart_x_digit_10)&&(x_cnt <end_x_digit_10)) x_digi_view[10]= 1; else x_digi_view[10]= 0;  
    if((x_cnt >=sart_x_digit_11)&&(x_cnt <end_x_digit_11)) x_digi_view[11]= 1; else x_digi_view[11]= 0;  
end
always @(posedge clk ) begin 
    if(y_digi_view[0]==1) begin
        cnt_row_digit <= y_cnt - sart_y_digit_0; 
        if(x_digi_view[0]==1) begin cnt_col_digit <= x_cnt - sart_x_digit_00; value_cur_digit[3:0]<= digits_0[47:44];
        end else if(x_digi_view[1]==1) begin cnt_col_digit <= x_cnt - sart_x_digit_01; value_cur_digit[3:0]<= digits_0[43:40];
        end else if(x_digi_view[2]==1) begin cnt_col_digit <= x_cnt - sart_x_digit_02; value_cur_digit[3:0]<= digits_0[39:36];
        end else if(x_digi_view[3]==1) begin cnt_col_digit <= x_cnt - sart_x_digit_03; value_cur_digit[3:0]<= digits_0[35:32];
        end else if(x_digi_view[4]==1) begin cnt_col_digit <= x_cnt - sart_x_digit_04; value_cur_digit[3:0]<= digits_0[31:28];
        end else if(x_digi_view[5]==1) begin cnt_col_digit <= x_cnt - sart_x_digit_05; value_cur_digit[3:0]<= digits_0[27:24];
        end else if(x_digi_view[6]==1) begin cnt_col_digit <= x_cnt - sart_x_digit_06; value_cur_digit[3:0]<= digits_0[23:20];
        end else if(x_digi_view[7]==1) begin cnt_col_digit <= x_cnt - sart_x_digit_07; value_cur_digit[3:0]<= digits_0[19:16];
        end else if(x_digi_view[8]==1) begin cnt_col_digit <= x_cnt - sart_x_digit_08; value_cur_digit[3:0]<= digits_0[15:12];
        end else if(x_digi_view[9]==1) begin cnt_col_digit <= x_cnt - sart_x_digit_09; value_cur_digit[3:0]<= digits_0[11:8];
        end else if(x_digi_view[10]==1)begin cnt_col_digit <= x_cnt - sart_x_digit_10; value_cur_digit[3:0]<= digits_0[7:4];
        end else if(x_digi_view[11]==1)begin cnt_col_digit <= x_cnt - sart_x_digit_11; value_cur_digit[3:0]<= digits_0[3:0];
        end else begin cnt_col_digit <= 0; value_cur_digit[3:0]<= 0;
        end
    end else if(y_digi_view[1]==1) begin
        cnt_row_digit <= y_cnt - sart_y_digit_1; 
        if(x_digi_view[0]==1) begin cnt_col_digit <= x_cnt - sart_x_digit_00; value_cur_digit[3:0]<= digits_1[47:44];
        end else if(x_digi_view[1]==1) begin cnt_col_digit <= x_cnt - sart_x_digit_01; value_cur_digit[3:0]<= digits_1[43:40];
        end else if(x_digi_view[2]==1) begin cnt_col_digit <= x_cnt - sart_x_digit_02; value_cur_digit[3:0]<= digits_1[39:36];
        end else if(x_digi_view[3]==1) begin cnt_col_digit <= x_cnt - sart_x_digit_03; value_cur_digit[3:0]<= digits_1[35:32];
        end else if(x_digi_view[4]==1) begin cnt_col_digit <= x_cnt - sart_x_digit_04; value_cur_digit[3:0]<= digits_1[31:28];
        end else if(x_digi_view[5]==1) begin cnt_col_digit <= x_cnt - sart_x_digit_05; value_cur_digit[3:0]<= digits_1[27:24];
        end else if(x_digi_view[6]==1) begin cnt_col_digit <= x_cnt - sart_x_digit_06; value_cur_digit[3:0]<= digits_1[23:20];
        end else if(x_digi_view[7]==1) begin cnt_col_digit <= x_cnt - sart_x_digit_07; value_cur_digit[3:0]<= digits_1[19:16];
        end else if(x_digi_view[8]==1) begin cnt_col_digit <= x_cnt - sart_x_digit_08; value_cur_digit[3:0]<= digits_1[15:12];
        end else if(x_digi_view[9]==1) begin cnt_col_digit <= x_cnt - sart_x_digit_09; value_cur_digit[3:0]<= digits_1[11:8];
        end else if(x_digi_view[10]==1)begin cnt_col_digit <= x_cnt - sart_x_digit_10; value_cur_digit[3:0]<= digits_1[7:4];
        end else if(x_digi_view[11]==1)begin cnt_col_digit <= x_cnt - sart_x_digit_11; value_cur_digit[3:0]<= digits_1[3:0];
        end else begin cnt_col_digit <= 0; value_cur_digit[3:0]<= 0;
        end
    end else if(y_digi_view[2]==1) begin
        cnt_row_digit <= y_cnt - sart_y_digit_2; 
        if(x_digi_view[0]==1) begin cnt_col_digit <= x_cnt - sart_x_digit_00; value_cur_digit[3:0]<= digits_2[47:44];
        end else if(x_digi_view[1]==1) begin cnt_col_digit <= x_cnt - sart_x_digit_01; value_cur_digit[3:0]<= digits_2[43:40];
        end else if(x_digi_view[2]==1) begin cnt_col_digit <= x_cnt - sart_x_digit_02; value_cur_digit[3:0]<= digits_2[39:36];
        end else if(x_digi_view[3]==1) begin cnt_col_digit <= x_cnt - sart_x_digit_03; value_cur_digit[3:0]<= digits_2[35:32];
        end else if(x_digi_view[4]==1) begin cnt_col_digit <= x_cnt - sart_x_digit_04; value_cur_digit[3:0]<= digits_2[31:28];
        end else if(x_digi_view[5]==1) begin cnt_col_digit <= x_cnt - sart_x_digit_05; value_cur_digit[3:0]<= digits_2[27:24];
        end else if(x_digi_view[6]==1) begin cnt_col_digit <= x_cnt - sart_x_digit_06; value_cur_digit[3:0]<= digits_2[23:20];
        end else if(x_digi_view[7]==1) begin cnt_col_digit <= x_cnt - sart_x_digit_07; value_cur_digit[3:0]<= digits_2[19:16];
        end else if(x_digi_view[8]==1) begin cnt_col_digit <= x_cnt - sart_x_digit_08; value_cur_digit[3:0]<= digits_2[15:12];
        end else if(x_digi_view[9]==1) begin cnt_col_digit <= x_cnt - sart_x_digit_09; value_cur_digit[3:0]<= digits_2[11:8];
        end else if(x_digi_view[10]==1)begin cnt_col_digit <= x_cnt - sart_x_digit_10; value_cur_digit[3:0]<= digits_2[7:4];
        end else if(x_digi_view[11]==1)begin cnt_col_digit <= x_cnt - sart_x_digit_11; value_cur_digit[3:0]<= digits_2[3:0];
        end else begin cnt_col_digit <= 0; value_cur_digit[3:0]<= 0;
        end
    end else if(y_digi_view[3]==1) begin
        cnt_row_digit <= y_cnt - sart_y_digit_3; 
        if(x_digi_view[0]==1) begin cnt_col_digit <= x_cnt - sart_x_digit_00; value_cur_digit[3:0]<= digits_3[47:44];
        end else if(x_digi_view[1]==1) begin cnt_col_digit <= x_cnt - sart_x_digit_01; value_cur_digit[3:0]<= digits_3[43:40];
        end else if(x_digi_view[2]==1) begin cnt_col_digit <= x_cnt - sart_x_digit_02; value_cur_digit[3:0]<= digits_3[39:36];
        end else if(x_digi_view[3]==1) begin cnt_col_digit <= x_cnt - sart_x_digit_03; value_cur_digit[3:0]<= digits_3[35:32];
        end else if(x_digi_view[4]==1) begin cnt_col_digit <= x_cnt - sart_x_digit_04; value_cur_digit[3:0]<= digits_3[31:28];
        end else if(x_digi_view[5]==1) begin cnt_col_digit <= x_cnt - sart_x_digit_05; value_cur_digit[3:0]<= digits_3[27:24];
        end else if(x_digi_view[6]==1) begin cnt_col_digit <= x_cnt - sart_x_digit_06; value_cur_digit[3:0]<= digits_3[23:20];
        end else if(x_digi_view[7]==1) begin cnt_col_digit <= x_cnt - sart_x_digit_07; value_cur_digit[3:0]<= digits_3[19:16];
        end else if(x_digi_view[8]==1) begin cnt_col_digit <= x_cnt - sart_x_digit_08; value_cur_digit[3:0]<= digits_3[15:12];
        end else if(x_digi_view[9]==1) begin cnt_col_digit <= x_cnt - sart_x_digit_09; value_cur_digit[3:0]<= digits_3[11:8];
        end else if(x_digi_view[10]==1)begin cnt_col_digit <= x_cnt - sart_x_digit_10; value_cur_digit[3:0]<= digits_3[7:4];
        end else if(x_digi_view[11]==1)begin cnt_col_digit <= x_cnt - sart_x_digit_11; value_cur_digit[3:0]<= digits_3[3:0];
        end else begin cnt_col_digit <= 0; value_cur_digit[3:0]<= 0;
        end
    end else begin 
        cnt_row_digit <= 0; cnt_col_digit <= 0; value_cur_digit[3:0]<= 0;
    end
end

// ROM接口 
wire [7:0] col_data;
hex_digit_rom hdr_001 (
    .digit  (value_cur_digit),    // 当前数字（0~9）
    //.digit  (4'b0110),    // 当前数字（0~9）
    .row_addr(cnt_row_digit), // 当前行地址（0~15）
    .col_data(col_data) // 当前行的列数据（8列）
);
reg [23:0]  pixel_cur_digit;
reg reg_digi_view_0;
always @(posedge clk ) begin
    reg_digi_view_0<=(y_digi_view[0] | y_digi_view[1] | y_digi_view[2] | y_digi_view[3]) & (x_digi_view[0] | x_digi_view[1] | x_digi_view[2] | x_digi_view[3] | x_digi_view[4] | x_digi_view[5] | x_digi_view[6] | x_digi_view[7] | x_digi_view[8] | x_digi_view[9] | x_digi_view[10] | x_digi_view[11]);
    if(reg_digi_view_0) begin
        if((col_data[7-cnt_col_digit])==1)begin
            pixel_cur_digit <= {8'd255,8'd255,8'd255};
        end else begin
            pixel_cur_digit <= {8'd32,8'd32,8'd32};
        end
    end else begin
        pixel_cur_digit <= {8'd32,8'd32,8'd32};    
    end
end
// 字符区域标志 
//wire in_digit_area;
//assign in_digit_area = (x_cnt >= X_START) && (x_cnt < X_START + TOTAL_WIDTH) &&
//                      (y_cnt >= Y_START) && (y_cnt < Y_START + CHAR_HEIGHT);
  
// 像素位置计数器 
always @(posedge clk ) begin 
    if ((rst) |(!reg_vsync_in_01 & reg_vsync_in))begin
        x_cnt <= 0;
        y_cnt <= 0;
    end else if (de_in) begin 
        if (x_cnt == H_RES - 1) begin
            x_cnt <= 0;
            y_cnt <= y_cnt +1;
        end else begin
            x_cnt <= x_cnt + 1;
            y_cnt <= y_cnt;
        end
    end else begin
        x_cnt <= x_cnt;
        y_cnt <= y_cnt;
    end
end 
reg reg_vsync_in,reg_vsync_in_01;
always @(posedge clk ) begin 
    if (rst ) begin 
        reg_vsync_in<=0;
        reg_vsync_in_01 <= 0;
    end else begin
        reg_vsync_in <= vsync_in;
        reg_vsync_in_01 <= reg_vsync_in;
    end
end 
// reg in_digit_area_00,in_digit_area_10;
always @(posedge clk) begin 
    hsync_out <= hsync_in;
    vsync_out <= vsync_in;
    de_out    <= de_in;
    
    if (!de_in)begin
        rgb_out <= 0;  // 非有效区域保持原始数据 
    end else begin 
        //if(in_digit_area_10)
        if(pixel_cur_digit[7]==1 && en_digi_on==1)
            rgb_out <= pixel_cur_digit;
        else
            rgb_out <= rgb_in;  // 非有效区域保持原始数据 
    end 
end 
endmodule 
 
// -------------------------- 字形ROM模块（0~F的8x16点阵数据） -------------------------- 
module hex_digit_rom ( 
    input wire [3:0] digit,    // 数字0~F（4位表示16个十六进制数）
    input wire [3:0] row_addr, // 行地址0~15 
    output reg [7:0] col_data  // 列数据8bit 
); 
 
always @(*) begin 
    case (digit) 
        // 数字0
        4'd0: begin  
            case (row_addr) 
                4'd0: col_data =  8'b00111100; 
                4'd1: col_data =  8'b01111110; 
                4'd2: col_data =  8'b11100111; 
                4'd3: col_data =  8'b11000011; 
                4'd4: col_data =  8'b11000011; 
                4'd5: col_data =  8'b11000011; 
                4'd6: col_data =  8'b11000011; 
                4'd7: col_data =  8'b11000011; 
                4'd8: col_data =  8'b11000011; 
                4'd9: col_data =  8'b11000011; 
                4'd10: col_data = 8'b11000011; 
                4'd11: col_data = 8'b11100111; 
                4'd12: col_data = 8'b01111110; 
                4'd13: col_data = 8'b00111100; 
                4'd14: col_data = 8'b00000000; 
                4'd15: col_data = 8'b00000000; 
                default: col_data = 8'b00000000; 
            endcase 
        end 
        
        // 数字1
        4'd1: begin  
            case (row_addr) 
                4'd0: col_data =  8'b00011000; 
                4'd1: col_data =  8'b00111000; 
                4'd2: col_data =  8'b01111000; 
                4'd3: col_data =  8'b11011000; 
                4'd4: col_data =  8'b00011000; 
                4'd5: col_data =  8'b00011000; 
                4'd6: col_data =  8'b00011000; 
                4'd7: col_data =  8'b00011000; 
                4'd8: col_data =  8'b00011000; 
                4'd9: col_data =  8'b00011000; 
                4'd10: col_data = 8'b00011000; 
                4'd11: col_data = 8'b00011000; 
                4'd12: col_data = 8'b01111110; 
                4'd13: col_data = 8'b01111110; 
                4'd14: col_data = 8'b00000000; 
                4'd15: col_data = 8'b00000000; 
                default: col_data = 8'b00000000; 
            endcase 
        end 
        
        // 数字2
        4'd2: begin  
            case (row_addr) 
                4'd0: col_data =  8'b00111100; 
                4'd1: col_data =  8'b01111110; 
                4'd2: col_data =  8'b11100111; 
                4'd3: col_data =  8'b11000011; 
                4'd4: col_data =  8'b00000111;
                4'd5: col_data =  8'b00001110; 
                4'd6: col_data =  8'b00011100; 
                4'd7: col_data =  8'b00111000; 
                4'd8: col_data =  8'b01110000; 
                4'd9: col_data =  8'b11100000; 
                4'd10: col_data = 8'b11000000; 
                4'd11: col_data = 8'b11111111; 
                4'd12: col_data = 8'b11111111; 
                4'd13: col_data = 8'b00000000; 
                4'd14: col_data = 8'b00000000; 
                4'd15: col_data = 8'b00000000; 
                default: col_data = 8'b00000000; 
            endcase 
        end 
        
        // 数字3
        4'd3: begin  
            case (row_addr) 
                4'd0: col_data =  8'b00111100; 
                4'd1: col_data =  8'b01111110; 
                4'd2: col_data =  8'b11100111; 
                4'd3: col_data =  8'b11000011; 
                4'd4: col_data =  8'b00000011;
                4'd5: col_data =  8'b00001110; 
                4'd6: col_data =  8'b00001110; 
                4'd7: col_data =  8'b00000011; 
                4'd8: col_data =  8'b00000011; 
                4'd9: col_data =  8'b11000011; 
                4'd10: col_data = 8'b11000011; 
                4'd11: col_data = 8'b11100111; 
                4'd12: col_data = 8'b01111110; 
                4'd13: col_data = 8'b00111100; 
                4'd14: col_data = 8'b00000000; 
                4'd15: col_data = 8'b00000000; 
                default: col_data = 8'b00000000; 
            endcase 
        end 
        
        // 数字4
        4'd4: begin  
            case (row_addr) 
				4'd0: col_data =  8'b00000110; 
				4'd1: col_data =  8'b00001110; 
				4'd2: col_data =  8'b00011110; 
				4'd3: col_data =  8'b00110110; 
				4'd4: col_data =  8'b01100110; 
				4'd5: col_data =  8'b11000110; 
				4'd6: col_data =  8'b11000110; 
				4'd7: col_data =  8'b11111111; 
				4'd8: col_data =  8'b11111111; 
				4'd9: col_data =  8'b00000110; 
				4'd10: col_data = 8'b00000110; 
				4'd11: col_data = 8'b00000110; 
				4'd12: col_data = 8'b00000110; 
				4'd13: col_data = 8'b00000000; 
				4'd14: col_data = 8'b00000000; 
				4'd15: col_data = 8'b00000000; 
                default: col_data = 8'b00000000; 
            endcase 
        end  
        
        // 数字5
        4'd5: begin  
            case (row_addr) 
                4'd0: col_data =  8'b11111111; 
				4'd1: col_data =  8'b11111111; 
				4'd2: col_data =  8'b11000000; 
				4'd3: col_data =  8'b11000000; 
				4'd4: col_data =  8'b11000000; 
				4'd5: col_data =  8'b11111100; 
				4'd6: col_data =  8'b11111110; 
				4'd7: col_data =  8'b00000111; 
				4'd8: col_data =  8'b00000011; 
				4'd9: col_data =  8'b00000011; 
				4'd10: col_data = 8'b11000011; 
				4'd11: col_data = 8'b11100111; 
				4'd12: col_data = 8'b01111110; 
				4'd13: col_data = 8'b00111100; 
				4'd14: col_data = 8'b00000000; 
				4'd15: col_data = 8'b00000000;
                default: col_data = 8'b00000000; 
            endcase 
        end  
        
        // 数字6
        4'd6: begin  
            case (row_addr) 
                4'd0:  col_data = 8'b00111100; 
                4'd1:  col_data = 8'b01111110; 
				4'd2:  col_data = 8'b11100111; 
				4'd3:  col_data = 8'b11000011; 
				4'd4:  col_data = 8'b11000000; 
				4'd5:  col_data = 8'b11011100; 
				4'd6:  col_data = 8'b11011110; 
				4'd7:  col_data = 8'b11100111; 
				4'd8:  col_data = 8'b11000011; 
				4'd9:  col_data = 8'b11000011; 
				4'd10: col_data = 8'b11000011; 
				4'd11: col_data = 8'b11100111; 
				4'd12: col_data = 8'b01111110; 
				4'd13: col_data = 8'b00111100; 
				4'd14: col_data = 8'b00000000; 
				4'd15: col_data = 8'b00000000;  
                default: col_data = 8'b00000000; 
            endcase 
        end 
        
        // 数字7
        4'd7: begin  
            case (row_addr) 
				4'd0:  col_data = 8'b11111111; 
				4'd1:  col_data = 8'b11111111; 
				4'd2:  col_data = 8'b00000011; 
				4'd3:  col_data = 8'b00000110; 
				4'd4:  col_data = 8'b00001100; 
				4'd5:  col_data = 8'b00011000; 
				4'd6:  col_data = 8'b00011000; 
				4'd7:  col_data = 8'b00110000; 
				4'd8:  col_data = 8'b00110000; 
				4'd9:  col_data = 8'b01100000; 
				4'd10: col_data = 8'b01100000; 
				4'd11: col_data = 8'b01100000; 
				4'd12: col_data = 8'b01100000; 
				4'd13: col_data = 8'b00000000; 
				4'd14: col_data = 8'b00000000; 
				4'd15: col_data = 8'b00000000; 
                default: col_data = 8'b00000000; 
            endcase 
        end 
        
        // 数字8
        4'd8: begin  
            case (row_addr) 
                4'd0:  col_data = 8'b00111100; 
				4'd1:  col_data = 8'b01111110; 
				4'd2:  col_data = 8'b11100111; 
				4'd3:  col_data = 8'b11000011; 
				4'd4:  col_data = 8'b11000011; 
				4'd5:  col_data = 8'b11100111; 
				4'd6:  col_data = 8'b01111110; 
				4'd7:  col_data = 8'b01111110; 
				4'd8:  col_data = 8'b11100111; 
				4'd9:  col_data = 8'b11000011; 
				4'd10: col_data = 8'b11000011; 
				4'd11: col_data = 8'b11100111; 
				4'd12: col_data = 8'b01111110; 
				4'd13: col_data = 8'b00111100; 
				4'd14: col_data = 8'b00000000; 
				4'd15: col_data = 8'b00000000; 
                default: col_data = 8'b00000000; 
            endcase 
        end 
        
        // 数字9
        4'd9: begin  
            case (row_addr) 
				4'd0:  col_data = 8'b00111100; 
				4'd1:  col_data = 8'b01111110; 
				4'd2:  col_data = 8'b11100111; 
				4'd3:  col_data = 8'b11000011; 
				4'd4:  col_data = 8'b11000011; 
				4'd5:  col_data = 8'b11000011; 
				4'd6:  col_data = 8'b11100111; 
				4'd7:  col_data = 8'b01111111; 
				4'd8:  col_data = 8'b00111011; 
				4'd9:  col_data = 8'b00000011; 
				4'd10: col_data = 8'b11000011; 
				4'd11: col_data = 8'b11100111; 
				4'd12: col_data = 8'b01111110; 
				4'd13: col_data = 8'b00111100; 
				4'd14: col_data = 8'b00000000; 
				4'd15: col_data = 8'b00000000; 
                default: col_data = 8'b00000000; 
            endcase 
        end 
        
        // 字母A (10)
        4'd10: begin  
            case (row_addr) 
                4'd0:  col_data = 8'b00000000; 
				4'd1:  col_data = 8'b00111100; 
				4'd2:  col_data = 8'b01111110; 
				4'd3:  col_data = 8'b11000011; 
				4'd4:  col_data = 8'b11000011; 
				4'd5:  col_data = 8'b11000011; 
				4'd6:  col_data = 8'b11111111; 
				4'd7:  col_data = 8'b11111111; 
				4'd8:  col_data = 8'b11000011; 
				4'd9:  col_data = 8'b11000011; 
				4'd10: col_data = 8'b11000011; 
				4'd11: col_data = 8'b11000011; 
				4'd12: col_data = 8'b11000011; 
				4'd13: col_data = 8'b00000000; 
				4'd14: col_data = 8'b00000000; 
				4'd15: col_data = 8'b00000000; 
                default: col_data = 8'b00000000; 
            endcase 
        end 
        
        // 字母B (11)
        4'd11: begin  
            case (row_addr) 
                4'd0:  col_data = 8'b11111100; 
				4'd1:  col_data = 8'b11111110; 
				4'd2:  col_data = 8'b11000011; 
				4'd3:  col_data = 8'b11000011; 
				4'd4:  col_data = 8'b11000011; 
				4'd5:  col_data = 8'b11111100; 
				4'd6:  col_data = 8'b11111100; 
				4'd7:  col_data = 8'b11000011; 
				4'd8:  col_data = 8'b11000011; 
				4'd9:  col_data = 8'b11000011; 
				4'd10: col_data = 8'b11000011; 
				4'd11: col_data = 8'b11000011; 
				4'd12: col_data = 8'b11111110; 
				4'd13: col_data = 8'b11111100; 
				4'd14: col_data = 8'b00000000; 
				4'd15: col_data = 8'b00000000; 
                default: col_data = 8'b00000000; 
            endcase 
        end 
        
        // 字母C (12)
        4'd12: begin  
            case (row_addr) 
                4'd0:  col_data = 8'b00111100; 
				4'd1:  col_data = 8'b01111110; 
				4'd2:  col_data = 8'b11000011; 
				4'd3:  col_data = 8'b11000000; 
				4'd4:  col_data = 8'b11000000; 
				4'd5:  col_data = 8'b11000000; 
				4'd6:  col_data = 8'b11000000; 
				4'd7:  col_data = 8'b11000000; 
				4'd8:  col_data = 8'b11000000; 
				4'd9:  col_data = 8'b11000000; 
				4'd10: col_data = 8'b11000000; 
				4'd11: col_data = 8'b11000011; 
				4'd12: col_data = 8'b01111110; 
				4'd13: col_data = 8'b00111100; 
				4'd14: col_data = 8'b00000000; 
				4'd15: col_data = 8'b00000000; 
                default: col_data = 8'b00000000; 
            endcase 
        end 
        
        // 字母D (13)
        4'd13: begin  
            case (row_addr) 
                4'd0:  col_data = 8'b11111100; 
				4'd1:  col_data = 8'b11111110; 
				4'd2:  col_data = 8'b11000011; 
				4'd3:  col_data = 8'b11000011; 
				4'd4:  col_data = 8'b11000011; 
				4'd5:  col_data = 8'b11000011; 
				4'd6:  col_data = 8'b11000011; 
				4'd7:  col_data = 8'b11000011; 
				4'd8:  col_data = 8'b11000011; 
				4'd9:  col_data = 8'b11000011; 
				4'd10: col_data = 8'b11000011; 
				4'd11: col_data = 8'b11000011; 
				4'd12: col_data = 8'b11111110; 
				4'd13: col_data = 8'b11111100; 
				4'd14: col_data = 8'b00000000; 
				4'd15: col_data = 8'b00000000; 
                default: col_data = 8'b00000000; 
            endcase 
        end 
        
        // 字母E (14)
        4'd14: begin  
            case (row_addr) 
                4'd0:  col_data = 8'b11111111; 
				4'd1:  col_data = 8'b11111111; 
				4'd2:  col_data = 8'b11000000; 
				4'd3:  col_data = 8'b11000000; 
				4'd4:  col_data = 8'b11000000; 
				4'd5:  col_data = 8'b11111100; 
				4'd6:  col_data = 8'b11111100; 
				4'd7:  col_data = 8'b11000000; 
				4'd8:  col_data = 8'b11000000; 
				4'd9:  col_data = 8'b11000000; 
				4'd10: col_data = 8'b11000000; 
				4'd11: col_data = 8'b11000000; 
				4'd12: col_data = 8'b11111111; 
				4'd13: col_data = 8'b11111111; 
				4'd14: col_data = 8'b00000000; 
				4'd15: col_data = 8'b00000000; 
                default: col_data = 8'b00000000; 
            endcase 
        end 
        
        // 字母F (15)
        4'd15: begin  
            case (row_addr) 
                4'd0:  col_data = 8'b11111111; 
				4'd1:  col_data = 8'b11111111; 
				4'd2:  col_data = 8'b11000000; 
				4'd3:  col_data = 8'b11000000; 
				4'd4:  col_data = 8'b11000000; 
				4'd5:  col_data = 8'b11111100; 
				4'd6:  col_data = 8'b11111100; 
				4'd7:  col_data = 8'b11000000; 
				4'd8:  col_data = 8'b11000000; 
				4'd9:  col_data = 8'b11000000; 
				4'd10: col_data = 8'b11000000; 
				4'd11: col_data = 8'b11000000; 
				4'd12: col_data = 8'b11000000; 
				4'd13: col_data = 8'b11000000; 
				4'd14: col_data = 8'b00000000; 
				4'd15: col_data = 8'b00000000; 
                default: col_data = 8'b00000000; 
            endcase 
        end 
        
        default: col_data = 8'b00000000;  // 默认为灭 
    endcase 
end 
endmodule

