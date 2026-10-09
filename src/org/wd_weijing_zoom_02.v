//zoom
module video_zoom (
    input wire         clk,          // 像素时钟(720p60约74.25MHz)
    input wire         rst_n,        // 异步复位(低有效)
    
    // 输入视频信号
    input wire [23:0]  in_rgb,       // 输入RGB数据(8R+8G+8B)
    input wire         in_hsync,     // 输入行同步信号
    input wire         in_vsync,     // 输入场同步信号
    input wire         in_de,        // 输入数据有效信号
    
    // 输出视频信号
    output reg [23:0]  out_rgb,      // 输出RGB数据
    output reg         out_hsync,    // 输出行同步信号
    output reg         out_vsync,    // 输出场同步信号
    output reg         out_de        // 输出数据有效信号
);

// 720p时序参数(单位:像素时钟周期)
parameter H_ACTIVE   = 1280;  // 有效行像素数
parameter V_ACTIVE   =  720;  // 有效场行数
parameter H_FRONT    =   16;  // 行同步前沿
parameter H_SYNC     =   64;  // 行同步脉宽
parameter H_BACK     =   80;  // 行同步后沿
parameter V_FRONT    =    3;  // 场同步前沿
parameter V_SYNC     =    5;  // 场同步脉宽
parameter V_BACK     =   22;  // 场同步后沿
parameter H_TOTAL    = H_ACTIVE + H_FRONT + H_SYNC + H_BACK;  // 总行周期
parameter V_TOTAL    = V_ACTIVE + V_FRONT + V_SYNC + V_BACK;  // 总场周期

// 缩放区域参数
parameter ZOOM_W     =   32;  // 原始宽度
parameter ZOOM_H     =   32;  // 原始高度
parameter ZOOM_X0    =    0;  // 起始X坐标
parameter ZOOM_Y0    =    0;  // 起始Y坐标
parameter ZOOM_RATIO =    5;  // 缩放比例分子(2.5倍 = 5/2)
parameter RATIO_DEN  =    2;  // 缩放比例分母

// 内部寄存器定义
reg [10:0] h_cnt;              // 行计数器
reg [10:0] v_cnt;              // 场计数器
reg [10:0] out_h_cnt;          // 输出行计数器
reg [10:0] out_v_cnt;          // 输出场计数器

// 原始区域像素缓存(32x32)
reg [23:0] pixel_buf [0:ZOOM_H-1][0:ZOOM_W-1];
reg [4:0]  buf_wr_x;           // 缓存写X地址
reg [4:0]  buf_wr_y;           // 缓存写Y地址
reg        buf_wr_en;          // 缓存写使能

// 坐标变换与插值计算
reg [12:0] src_x;              // 原始X坐标(10bit整数+3bit小数)
reg [12:0] src_y;              // 原始Y坐标(10bit整数+3bit小数)
reg [4:0]  x0, x1;             // 相邻X整数坐标
reg [4:0]  y0, y1;             // 相邻Y整数坐标
reg [2:0]  dx, dy;             // 小数部分(0~7, 对应0~1)
reg [23:0] p00, p01, p10, p11; // 四个相邻像素
reg [24:0] r_temp, g_temp, b_temp; // 插值中间结果

// 1. 输入时序计数与缓存写入
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        h_cnt <= 0;
        v_cnt <= 0;
        buf_wr_en <= 0;
        buf_wr_x <= 0;
        buf_wr_y <= 0;
    end else begin
        // 行计数器
        if (h_cnt == H_TOTAL - 1) begin
            h_cnt <= 0;
            // 场计数器
            if (v_cnt == V_TOTAL - 1) begin
                v_cnt <= 0;
            end else begin
                v_cnt <= v_cnt + 1;
            end
        end else begin
            h_cnt <= h_cnt + 1;
        end

        // 判断是否在缩放区域内
        buf_wr_en <= (in_de && 
                     (h_cnt >= ZOOM_X0) && (h_cnt < ZOOM_X0 + ZOOM_W) && 
                     (v_cnt >= ZOOM_Y0) && (v_cnt < ZOOM_Y0 + ZOOM_H));

        // 计算缓存写入地址
        if (buf_wr_en) begin
            buf_wr_x <= h_cnt - ZOOM_X0;
            buf_wr_y <= v_cnt - ZOOM_Y0;
            // 写入缓存
            pixel_buf[buf_wr_y][buf_wr_x] <= in_rgb;
        end
    end
end

// 2. 输出时序生成
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out_h_cnt <= 0;
        out_v_cnt <= 0;
        out_hsync <= 0;
        out_vsync <= 0;
        out_de <= 0;
    end else begin
        // 输出行计数器
        if (out_h_cnt == H_TOTAL - 1) begin
            out_h_cnt <= 0;
            // 输出场计数器
            if (out_v_cnt == V_TOTAL - 1) begin
                out_v_cnt <= 0;
            end else begin
                out_v_cnt <= out_v_cnt + 1;
            end
        end else begin
            out_h_cnt <= out_h_cnt + 1;
        end

        // 生成输出同步信号(与输入时序对齐)
        out_hsync <= (out_h_cnt >= H_FRONT) && (out_h_cnt < H_FRONT + H_SYNC);
        out_vsync <= (out_v_cnt >= V_FRONT) && (out_v_cnt < V_FRONT + V_SYNC);
        out_de <= (out_h_cnt < H_ACTIVE) && (out_v_cnt < V_ACTIVE);
    end
end

// 3. 缩放区域坐标变换
wire [10:0] zoom_out_w = ZOOM_W * ZOOM_RATIO / RATIO_DEN; // 80
wire [10:0] zoom_out_h = ZOOM_H * ZOOM_RATIO / RATIO_DEN; // 80

// 判断当前输出像素是否在缩放后区域内
wire in_zoom_area = (out_h_cnt < zoom_out_w) && (out_v_cnt < zoom_out_h);

// 计算原始坐标(带小数部分，放大2.5倍即输出坐标×2/5)
always @(posedge clk) begin
    if (in_zoom_area) begin
        // src_x = out_h_cnt * RATIO_DEN * 8 / ZOOM_RATIO (增加8倍精度)
        src_x <= (out_h_cnt * RATIO_DEN * 8) / ZOOM_RATIO;
        src_y <= (out_v_cnt * RATIO_DEN * 8) / ZOOM_RATIO;
    end
end

// 4. 双线性插值计算
always @(posedge clk) begin
    // 提取整数和小数部分(小数部分3bit，范围0~7)
    x0 <= src_x[12:3];       // 整数部分
    y0 <= src_y[12:3];
    dx <= src_x[2:0];        // 小数部分(0~7)
    dy <= src_y[2:0];
    
    // 读取相邻四个像素(边界处理)
    x1 <= (x0 == ZOOM_W - 1) ? x0 : x0 + 1;
    y1 <= (y0 == ZOOM_H - 1) ? y0 : y0 + 1;
    p00 <= pixel_buf[y0][x0];
    p01 <= pixel_buf[y1][x0];
    p10 <= pixel_buf[y0][x1];
    p11 <= pixel_buf[y1][x1];

    // 双线性插值计算(公式: (1-dy)*[(1-dx)*p00 + dx*p10] + dy*[(1-dx)*p01 + dx*p11])
    // 为避免浮点运算，放大8倍后整数计算，最后右移6位(8×8=64)
    r_temp <= ((8 - dy) * ((8 - dx) * p00[23:16] + dx * p10[23:16]) + 
               dy * ((8 - dx) * p01[23:16] + dx * p11[23:16])) << 1;
    g_temp <= ((8 - dy) * ((8 - dx) * p00[15:8] + dx * p10[15:8]) + 
               dy * ((8 - dx) * p01[15:8] + dx * p11[15:8])) << 1;
    b_temp <= ((8 - dy) * ((8 - dx) * p00[7:0] + dx * p10[7:0]) + 
               dy * ((8 - dx) * p01[7:0] + dx * p11[7:0])) << 1;
end

// 5. 输出像素选择
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out_rgb <= 0;
    end else if (out_de) begin
        if (in_zoom_area) begin
            // 缩放区域输出插值结果
            out_rgb <= {r_temp[24:17], g_temp[24:17], b_temp[24:17]};
        end else begin
            // 非缩放区域输出原始像素(延迟补偿后)
            // 注意：实际应用中需根据缓存延迟调整原始像素的对齐
            out_rgb <= in_rgb;
        end
    end else begin
        out_rgb <= 0;
    end
end

endmodule