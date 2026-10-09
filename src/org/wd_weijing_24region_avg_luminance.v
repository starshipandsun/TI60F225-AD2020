module video_24region_avg_8bit (
    input wire clk,                  // 像素时钟(74.25MHz)
    input wire rst_n,                // 异步复位，低有效
    input [23:0] rgb_in,           // 输入红色分量
    input wire vsync,                // 场同步信号
    input wire hsync,                // 行同步信号
    input wire de,                   // 数据有效信号
    
    // 24个区域的8bit平均亮度输出(同时有效)
    output reg [7:0] avg_00, avg_01, avg_02, avg_03, avg_04, avg_05,
    output reg [7:0] avg_10, avg_11, avg_12, avg_13, avg_14, avg_15,
    output reg [7:0] avg_20, avg_21, avg_22, avg_23, avg_24, avg_25,
    output reg [7:0] avg_30, avg_31, avg_32, avg_33, avg_34, avg_35
);

// 720p分辨率参数(4行×6列=24区域)
localparam H_ACTIVE = 1280;
localparam V_ACTIVE = 720;
localparam COL_NUM = 6;
localparam ROW_NUM = 4;
localparam REGION_WIDTH = 1280 / COL_NUM;  // ~213像素
localparam REGION_HEIGHT = 720 / ROW_NUM;  // 180像素

wire [7:0] r_in,g_in, b_in;
wire [7:0] rgb_r,rgb_g,rgb_b;
assign rgb_r[7:0] = rgb_in[23:16];
assign rgb_g[7:0] = rgb_in[15: 8];
assign rgb_b[7:0] = rgb_in[ 7: 0];
// 像素坐标计数器
reg [10:0] h_cnt;
reg [9:0] v_cnt;
reg area_00,area_01,area_02,area_03,area_04,area_05;
reg area_10,area_11,area_12,area_13,area_14,area_15;
reg area_20,area_21,area_22,area_23,area_24,area_25;
reg area_30,area_31,area_32,area_33,area_34,area_35;
// 区域索引
reg [1:0] region_row;  // 0~3
reg [2:0] region_col;  // 0~5

// 亮度计算(0~255范围)
wire [9:0] brightness = (rgb_r * 77 + rgb_g * 150 + rgb_b * 29 + 128) >> 8;
localparam MAX_BRIGHT = 10'd255;  // 单像素最大亮度
localparam cnt_area = 213 * 180;  
// 区域像素计数与亮度累加器
reg [24:0] sum_00, sum_01, sum_02, sum_03, sum_04, sum_05;
reg [24:0] sum_10, sum_11, sum_12, sum_13, sum_14, sum_15;
reg [24:0] sum_20, sum_21, sum_22, sum_23, sum_24, sum_25;
reg [24:0] sum_30, sum_31, sum_32, sum_33, sum_34, sum_35;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        h_cnt <= 0;
        v_cnt <= 0;
    end else begin
        if (edge_LH_vs) begin
            h_cnt <= 0;
            v_cnt <= 0;
        end else if (de && hsync) begin
            if (h_cnt == H_ACTIVE - 1) begin
                h_cnt <= 0;
                v_cnt <= v_cnt + 1'b1;
            end else begin
                h_cnt <= h_cnt + 1'b1;
                v_cnt <= v_cnt;
            end
        end else begin
            v_cnt <= v_cnt;
            h_cnt <= h_cnt;
        end
    end
end
reg vs_01,vs_02,edge_HL_vs,edge_LH_vs;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        vs_01 <=0; vs_02 <= 0;
        edge_HL_vs <= 0;
        edge_LH_vs <= 0;
    end else begin
        vs_01 <= vsync; vs_02 <= vs_01;
        edge_HL_vs = vs_02 & !vs_01;
        edge_LH_vs = !vs_02 & vs_01;
    end
end
// 坐标计数逻辑
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        {area_00, area_01, area_02, area_03, area_04, area_05} <= 6'b0;
        {area_10, area_11, area_12, area_13, area_14, area_15} <= 6'b0;
        {area_20, area_21, area_22, area_23, area_24, area_25} <= 6'b0;
        {area_30, area_31, area_32, area_33, area_34, area_35} <= 6'b0;
    end else if (edge_LH_vs) begin        // 场同步上升沿：所有区域置0（帧起始复位）
        {area_00, area_01, area_02, area_03, area_04, area_05} <= 6'b0;
        {area_10, area_11, area_12, area_13, area_14, area_15} <= 6'b0;
        {area_20, area_21, area_22, area_23, area_24, area_25} <= 6'b0;
        {area_30, area_31, area_32, area_33, area_34, area_35} <= 6'b0;
    end else begin        
        // 区间0：v_cnt 0~179行
        if (v_cnt >= 11'd0 && v_cnt < 11'd180 && (de==1)) begin
            area_00 <= (h_cnt >= 11'd0   && h_cnt < 11'd213)  ? 1'b1 : 1'b0;
            area_01 <= (h_cnt >= 11'd213 && h_cnt < 11'd426)  ? 1'b1 : 1'b0;
            area_02 <= (h_cnt >= 11'd426 && h_cnt < 11'd639)  ? 1'b1 : 1'b0;
            area_03 <= (h_cnt >= 11'd639 && h_cnt < 11'd852)  ? 1'b1 : 1'b0;
            area_04 <= (h_cnt >= 11'd852 && h_cnt < 11'd1065) ? 1'b1 : 1'b0;
            area_05 <= (h_cnt >= 11'd1065 && h_cnt < 11'd1278) ? 1'b1 : 1'b0;
        end else begin
            {area_00, area_01, area_02, area_03, area_04, area_05} <= 6'b0;
        end
        // 区间1：v_cnt 180~359行
        if (v_cnt >= 11'd180 && v_cnt < 11'd360 && (de==1)) begin
            area_10 <= (h_cnt >= 11'd0   && h_cnt < 11'd213)  ? 1'b1 : 1'b0;
            area_11 <= (h_cnt >= 11'd213 && h_cnt < 11'd426)  ? 1'b1 : 1'b0;
            area_12 <= (h_cnt >= 11'd426 && h_cnt < 11'd639)  ? 1'b1 : 1'b0;
            area_13 <= (h_cnt >= 11'd639 && h_cnt < 11'd852)  ? 1'b1 : 1'b0;
            area_14 <= (h_cnt >= 11'd852 && h_cnt < 11'd1065) ? 1'b1 : 1'b0;
            area_15 <= (h_cnt >= 11'd1065 && h_cnt < 11'd1278) ? 1'b1 : 1'b0;
        end else begin
            {area_10, area_11, area_12, area_13, area_14, area_15} <= 6'b0;
        end
        // 区间2：v_cnt 360~539行
        if (v_cnt >= 11'd360 && v_cnt < 11'd540 && (de==1)) begin
            area_20 <= (h_cnt >= 11'd0   && h_cnt < 11'd213)  ? 1'b1 : 1'b0;
            area_21 <= (h_cnt >= 11'd213 && h_cnt < 11'd426)  ? 1'b1 : 1'b0;
            area_22 <= (h_cnt >= 11'd426 && h_cnt < 11'd639)  ? 1'b1 : 1'b0;
            area_23 <= (h_cnt >= 11'd639 && h_cnt < 11'd852)  ? 1'b1 : 1'b0;
            area_24 <= (h_cnt >= 11'd852 && h_cnt < 11'd1065) ? 1'b1 : 1'b0;
            area_25 <= (h_cnt >= 11'd1065 && h_cnt < 11'd1278) ? 1'b1 : 1'b0;
        end else begin
            {area_20, area_21, area_22, area_23, area_24, area_25} <= 6'b0;
        end

        // 区间3：v_cnt 540~719行（720p最后一个区间）
        if (v_cnt >= 11'd540 && v_cnt < 11'd720 && (de==1)) begin
            area_30 <= (h_cnt >= 11'd0   && h_cnt < 11'd213)  ? 1'b1 : 1'b0;
            area_31 <= (h_cnt >= 11'd213 && h_cnt < 11'd426)  ? 1'b1 : 1'b0;
            area_32 <= (h_cnt >= 11'd426 && h_cnt < 11'd639)  ? 1'b1 : 1'b0;
            area_33 <= (h_cnt >= 11'd639 && h_cnt < 11'd852)  ? 1'b1 : 1'b0;
            area_34 <= (h_cnt >= 11'd852 && h_cnt < 11'd1065) ? 1'b1 : 1'b0;
            area_35 <= (h_cnt >= 11'd1065 && h_cnt < 11'd1278) ? 1'b1 : 1'b0;
        end else begin
            {area_30, area_31, area_32, area_33, area_34, area_35} <= 6'b0;
        end
    end
end

// 像素计数与亮度累加
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        {sum_00, sum_01, sum_02, sum_03, sum_04, sum_05} <= 0;
        {sum_10, sum_11, sum_12, sum_13, sum_14, sum_15} <= 0;
        {sum_20, sum_21, sum_22, sum_23, sum_24, sum_25} <= 0;
        {sum_30, sum_31, sum_32, sum_33, sum_34, sum_35} <= 0;
    end else if (edge_LH_vs) begin
        {sum_00, sum_01, sum_02, sum_03, sum_04, sum_05} <= 0;
        {sum_10, sum_11, sum_12, sum_13, sum_14, sum_15} <= 0;
        {sum_20, sum_21, sum_22, sum_23, sum_24, sum_25} <= 0;
        {sum_30, sum_31, sum_32, sum_33, sum_34, sum_35} <= 0;
    end else if (de) begin
        if(area_00) sum_00 <= sum_00 + brightness;else sum_00 <= sum_00;
        if(area_01) sum_01 <= sum_01 + brightness;else sum_01 <= sum_01;
        if(area_02) sum_02 <= sum_02 + brightness;else sum_02 <= sum_02;
        if(area_03) sum_03 <= sum_03 + brightness;else sum_03 <= sum_03;
        if(area_04) sum_04 <= sum_04 + brightness;else sum_04 <= sum_04;
        if(area_05) sum_05 <= sum_05 + brightness;else sum_05 <= sum_05;
        if(area_10) sum_10 <= sum_10 + brightness; else sum_10 <= sum_10;
        if(area_11) sum_11 <= sum_11 + brightness; else sum_11 <= sum_11;
        if(area_12) sum_12 <= sum_12 + brightness; else sum_12 <= sum_12;
        if(area_13) sum_13 <= sum_13 + brightness; else sum_13 <= sum_13;
        if(area_14) sum_14 <= sum_14 + brightness; else sum_14 <= sum_14;
        if(area_15) sum_15 <= sum_15 + brightness; else sum_15 <= sum_15;
        if(area_20) sum_20 <= sum_20 + brightness; else sum_20 <= sum_20;
        if(area_21) sum_21 <= sum_21 + brightness; else sum_21 <= sum_21;
        if(area_22) sum_22 <= sum_22 + brightness; else sum_22 <= sum_22;
        if(area_23) sum_23 <= sum_23 + brightness; else sum_23 <= sum_23;
        if(area_24) sum_24 <= sum_24 + brightness; else sum_24 <= sum_24;
        if(area_25) sum_25 <= sum_25 + brightness; else sum_25 <= sum_25;
        if(area_30) sum_30 <= sum_30 + brightness; else sum_30 <= sum_30;
        if(area_31) sum_31 <= sum_31 + brightness; else sum_31 <= sum_31;
        if(area_32) sum_32 <= sum_32 + brightness; else sum_32 <= sum_32;
        if(area_33) sum_33 <= sum_33 + brightness; else sum_33 <= sum_33;
        if(area_34) sum_34 <= sum_34 + brightness; else sum_34 <= sum_34;
        if(area_35) sum_35 <= sum_35 + brightness; else sum_35 <= sum_35;
    end
end

// 计算平均亮度并等比缩放到8bit
reg [15:0] full_avg_00, full_avg_01, full_avg_02, full_avg_03, full_avg_04, full_avg_05;
reg [15:0] full_avg_10, full_avg_11, full_avg_12, full_avg_13, full_avg_14, full_avg_15;
reg [15:0] full_avg_20, full_avg_21, full_avg_22, full_avg_23, full_avg_24, full_avg_25;
reg [15:0] full_avg_30, full_avg_31, full_avg_32, full_avg_33, full_avg_34, full_avg_35;

// 第一步：计算原始16bit平均值
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        {full_avg_00, full_avg_01, full_avg_02, full_avg_03, full_avg_04, full_avg_05} <= 0;
        {full_avg_10, full_avg_11, full_avg_12, full_avg_13, full_avg_14, full_avg_15} <= 0;
        {full_avg_20, full_avg_21, full_avg_22, full_avg_23, full_avg_24, full_avg_25} <= 0;
        {full_avg_30, full_avg_31, full_avg_32, full_avg_33, full_avg_34, full_avg_35} <= 0;

    end else begin
        if (edge_HL_vs) begin
            // 计算原始平均值(0~255范围)
            full_avg_00 <= sum_00 / cnt_area;
            full_avg_01 <= sum_01 / cnt_area;
            full_avg_02 <= sum_02 / cnt_area;
            full_avg_03 <= sum_03 / cnt_area;
            full_avg_04 <= sum_04 / cnt_area;
            full_avg_05 <= sum_05 / cnt_area;

            full_avg_10 <= sum_10 / cnt_area;
            full_avg_11 <= sum_11 / cnt_area;
            full_avg_12 <= sum_12 / cnt_area;
            full_avg_13 <= sum_13 / cnt_area;
            full_avg_14 <= sum_14 / cnt_area;
            full_avg_15 <= sum_15 / cnt_area;

            full_avg_20 <= sum_20 / cnt_area;
            full_avg_21 <= sum_21 / cnt_area;
            full_avg_22 <= sum_22 / cnt_area;
            full_avg_23 <= sum_23 / cnt_area;
            full_avg_24 <= sum_24 / cnt_area;
            full_avg_25 <= sum_25 / cnt_area;

            full_avg_30 <= sum_30 / cnt_area;
            full_avg_31 <= sum_31 / cnt_area;
            full_avg_32 <= sum_32 / cnt_area;
            full_avg_33 <= sum_33 / cnt_area;
            full_avg_34 <= sum_34 / cnt_area;
            full_avg_35 <= sum_35 / cnt_area;                
        end else begin
            //full_avg_00 <= full_avg_00;  full_avg_01 <= full_avg_01;  full_avg_02 <= full_avg_02;  full_avg_03 <= full_avg_03; full_avg_04 <= full_avg_04;
            full_avg_10 <= full_avg_10;  full_avg_11 <= full_avg_11;  full_avg_12 <= full_avg_12;  full_avg_13 <= full_avg_13;  full_avg_14 <= full_avg_14;
            full_avg_20 <= full_avg_20;  full_avg_21 <= full_avg_21;  full_avg_22 <= full_avg_22;  full_avg_23 <= full_avg_23;  full_avg_24 <= full_avg_24;
            full_avg_30 <= full_avg_30;  full_avg_31 <= full_avg_31;  full_avg_32 <= full_avg_32;  full_avg_33 <= full_avg_33;  full_avg_34 <= full_avg_34;
        end        
    end
end

// 第二步：等比缩放到8bit(0~255)
// 由于原始亮度范围就是0~255，平均后仍在此范围，直接截断高位即可保持比例
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        {avg_00, avg_01, avg_02, avg_03, avg_04, avg_05} <= 0;
        {avg_10, avg_11, avg_12, avg_13, avg_14, avg_15} <= 0;
        {avg_20, avg_21, avg_22, avg_23, avg_24, avg_25} <= 0;
        {avg_30, avg_31, avg_32, avg_33, avg_34, avg_35} <= 0;
    end else begin
        // 缩放公式：8bit值 = (原始平均值 * 255) / 255 = 原始平均值(直接取低8位)
        // 因原始亮度范围限定在0~255，平均后不会超过此范围，直接截断保持比例
        avg_00 <= full_avg_00[7:0];
        avg_01 <= full_avg_01[7:0];
        avg_02 <= full_avg_02[7:0];
        avg_03 <= full_avg_03[7:0];
        avg_04 <= full_avg_04[7:0];
        avg_05 <= full_avg_05[7:0];
        
        avg_10 <= full_avg_10[7:0];
        avg_11 <= full_avg_11[7:0];
        avg_12 <= full_avg_12[7:0];
        avg_13 <= full_avg_13[7:0];
        avg_14 <= full_avg_14[7:0];
        avg_15 <= full_avg_15[7:0];
        
        avg_20 <= full_avg_20[7:0];
        avg_21 <= full_avg_21[7:0];
        avg_22 <= full_avg_22[7:0];
        avg_23 <= full_avg_23[7:0];
        avg_24 <= full_avg_24[7:0];
        avg_25 <= full_avg_25[7:0];
        
        avg_30 <= full_avg_30[7:0];
        avg_31 <= full_avg_31[7:0];
        avg_32 <= full_avg_32[7:0];
        avg_33 <= full_avg_33[7:0];
        avg_34 <= full_avg_34[7:0];
        avg_35 <= full_avg_35[7:0];        
    end
end
endmodule