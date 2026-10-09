//AE_RGB
module video_denoising (
    input clk,                  // 像素时钟 (720p60约需74.25MHz)
    input rst_n,                // 异步复位，低有效
    
    // 输入视频信号
    input [23:0] rgb_in,           // 输入红色分量
    input vsync_in,             // 输入场同步信号
    input hsync_in,             // 输入行同步信号
    input de_in,                // 输入数据有效信号
    
    input en_ds_on,
    // 输出视频信号
    output [23:0] rgb_out,          // 输出红色分量
    output reg vsync_out,            // 输出场同步信号
    output reg hsync_out,            // 输出行同步信号
    output reg de_out,                // 输出数据有效信号
    output reg [3:0]   analog_gain,      // 模拟增益控制 (0-15档)
    output reg [9:0]   exposure_time     // 曝光时间控制 (0-1023行)
);

wire [7:0] r_in,g_in, b_in;
assign r_in[7:0] = rgb_in[23:16];
assign g_in[7:0] = rgb_in[15: 8];
assign b_in[7:0] = rgb_in[ 7: 0];
reg [7:0] r_out,g_out,b_out;
assign rgb_out ={r_out[7:0],g_out[7:0],b_out[7:0]};

// 720p参数定义
localparam WIDTH  = 1280;  // 宽度
localparam HEIGHT = 720;   // 高度

// 帧缓存地址计算参数
localparam ADDR_WIDTH = 20; // 1280*720=921600 < 2^20
localparam PIXEL_DELAY = 3; // 滤波延迟

// 内部信号定义
//reg [7:0] r_delay[0:PIXEL_DELAY-1];
//reg [7:0] g_delay[0:PIXEL_DELAY-1];
//reg [7:0] b_delay[0:PIXEL_DELAY-1];
reg [2:0] vsync_d, hsync_d, de_d;

// 空域滤波窗口 (3x3窗口)
reg [7:0] r_window[0:2][0:2];
reg [7:0] g_window[0:2][0:2];
reg [7:0] b_window[0:2][0:2];

// 帧缓存接口
//wire [ADDR_WIDTH-1:0] wr_addr, rd_addr;
wire [23:0] wr_data, rd_data;
//reg  we;  // 写使能


// 行计数器和列计数器
reg [10:0] row_cnt;
reg [10:0] col_cnt;

// 同步信号延迟对齐
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        vsync_d <= 2'b00;
        hsync_d <= 2'b00;
        de_d    <= 2'b00;
    end else begin
        vsync_d[2] <= vsync_d[1];vsync_d[1] <= vsync_d[0]; vsync_d[0] <= vsync_in;
        hsync_d[2] <= hsync_d[1];hsync_d[1] <= hsync_d[0]; hsync_d[0] <= hsync_in;
        de_d[2] <= de_d[1];de_d[1] <= de_d[0]; de_d[0] <= de_in;
    end
end
reg en_ds_on_00;
always @(posedge clk or negedge rst_n) begin 
    if (!rst_n) 
        en_ds_on_00 <= 0;
    else if (!vsync_in)
        en_ds_on_00<=en_ds_on;
    else
        en_ds_on_00<=en_ds_on_00;
end

// 行列计数
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        row_cnt <= 11'd0;
        col_cnt <= 11'd0;
    end else begin
        if (!vsync_in) begin
            row_cnt <= 11'd0;
            col_cnt <= 11'd0;
        end else if (de_in) begin
            if (col_cnt == WIDTH - 1) begin
                col_cnt <= 11'd0;
                row_cnt <= row_cnt + 11'd1;
            end else begin
                col_cnt <= col_cnt + 11'd1;
            end
        end
    end
end

// 生成3x3空域窗口 (使用移位寄存器实现)
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        r_window[0][0] <= 8'd0;r_window[0][1] <= 8'd0;r_window[0][2] <= 8'd0;
        r_window[1][0] <= 8'd0;r_window[1][1] <= 8'd0;r_window[1][2] <= 8'd0;
        r_window[2][0] <= 8'd0;r_window[2][1] <= 8'd0;r_window[2][2] <= 8'd0;

        g_window[0][0] <= 8'd0;g_window[0][1] <= 8'd0;g_window[0][2] <= 8'd0;
        g_window[1][0] <= 8'd0;g_window[1][1] <= 8'd0;g_window[1][2] <= 8'd0;
        g_window[2][0] <= 8'd0;g_window[2][1] <= 8'd0;g_window[2][2] <= 8'd0;

        b_window[0][0] <= 8'd0;b_window[0][1] <= 8'd0;b_window[0][2] <= 8'd0;
        b_window[1][0] <= 8'd0;b_window[1][1] <= 8'd0;b_window[1][2] <= 8'd0;
        b_window[2][0] <= 8'd0;b_window[2][1] <= 8'd0;b_window[2][2] <= 8'd0;
        
    end else if (hsync_in) begin
        // 窗口移位更新
        r_window[0][0] <= r_window[0][1];
        r_window[0][1] <= r_window[0][2];
        r_window[0][2] <= r_window[1][2];
        r_window[1][0] <= r_window[1][1];
        r_window[1][1] <= r_window[1][2];
        r_window[1][2] <= r_window[2][2];
        r_window[2][0] <= r_window[2][1];
        r_window[2][1] <= r_window[2][2];
        r_window[2][2] <= r_in;
        
        // 绿色通道同样处理
        g_window[0][0] <= g_window[0][1];
        g_window[0][1] <= g_window[0][2];
        g_window[0][2] <= g_window[1][2];
        g_window[1][0] <= g_window[1][1];
        g_window[1][1] <= g_window[1][2];
        g_window[1][2] <= g_window[2][2];
        g_window[2][0] <= g_window[2][1];
        g_window[2][1] <= g_window[2][2];
        g_window[2][2] <= g_in;
        
        // 蓝色通道同样处理
        b_window[0][0] <= b_window[0][1];
        b_window[0][1] <= b_window[0][2];
        b_window[0][2] <= b_window[1][2];
        b_window[1][0] <= b_window[1][1];
        b_window[1][1] <= b_window[1][2];
        b_window[1][2] <= b_window[2][2];
        b_window[2][0] <= b_window[2][1];
        b_window[2][1] <= b_window[2][2];
        b_window[2][2] <= b_in;
    end
end

// 帧缓存地址计算
//assign wr_addr = row_cnt * WIDTH + col_cnt;
//assign rd_addr = row_cnt * WIDTH + col_cnt;  // 读取对应位置的前一帧数据
assign wr_data = {r_in, g_in, b_in};

/*
// 帧缓存写控制
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        we <= 1'b0;
    end else begin
        we <= hsync_in;  // 有效像素期间写缓存
    end
end
*/
// 空域高斯滤波计算 (3x3高斯核: [1 2 1; 2 4 2; 1 2 1] 总和=16)
reg [11:0] r_gauss, g_gauss, b_gauss;
always @(posedge clk) begin
    r_gauss <= r_window[0][0] + (r_window[0][1] << 1) + r_window[0][2] +
              (r_window[1][0] << 1) + (r_window[1][1] << 2) + (r_window[1][2] << 1) +
               r_window[2][0] + (r_window[2][1] << 1) + r_window[2][2];
    
    g_gauss <= g_window[0][0] + (g_window[0][1] << 1) + g_window[0][2] +
              (g_window[1][0] << 1) + (g_window[1][1] << 2) + (g_window[1][2] << 1) +
               g_window[2][0] + (g_window[2][1] << 1) + g_window[2][2];
    
    b_gauss <= b_window[0][0] + (b_window[0][1] << 1) + b_window[0][2] +
              (b_window[1][0] << 1) + (b_window[1][1] << 2) + (b_window[1][2] << 1) +
               b_window[2][0] + (b_window[2][1] << 1) + b_window[2][2];
end
// 时空域联合降噪: 差异小时使用时域滤波，差异大时使用空域滤波
//parameter DIFF_THRESHOLD = 8'd16;  // 差异阈值，可调整
wire [7:0]  r_gauss_cur,g_gauss_cur,b_gauss_cur;
assign  r_gauss_cur[7:0] = r_gauss[11:4];
assign  g_gauss_cur[7:0] = g_gauss[11:4];
assign  b_gauss_cur[7:0] = b_gauss[11:4];
wire [9:0]  r_cur_1_2,g_cur_1_2,b_cur_1_2;
assign r_cur_1_2[9:0] = {0,0,r_gauss_cur};
assign g_cur_1_2[9:0] = {0,0,g_gauss_cur};
assign b_cur_1_2[9:0] = {0,0,b_gauss_cur};
wire [9:0]  r_old_01,g_old_01,b_old_01;
assign r_old_01[9:0] = {0,0,r_gauss_prev_01[7:0]};
assign g_old_01[9:0] = {0,0,g_gauss_prev_01[7:0]};
assign b_old_01[9:0] = {0,0,b_gauss_prev_01[7:0]};
wire [9:0]  r_old_00,g_old_00,b_old_00;
assign r_old_00[9:0] = {0,0,r_gauss_prev_00[7:0]};
assign g_old_00[9:0] = {0,0,g_gauss_prev_00[7:0]};
assign b_old_00[9:0] = {0,0,b_gauss_prev_00[7:0]};
reg [9:0]  r_out_a,g_out_a,b_out_a;
reg [9:0]  r_out_b,g_out_b,b_out_b;
reg [9:0]  r_out_c,g_out_c,b_out_c;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        r_out_a<= 0; r_out_b <= 0; r_out_c <= 0;
        g_out_a<= 0; g_out_b <= 0; g_out_c <= 0;
        b_out_a<= 0; b_out_b <= 0; b_out_c <= 0;
    end else begin
        r_out_a <= r_old_01 + r_old_00;// + r_old_00 + r_cur_1_2;
        g_out_a <= g_old_01 + g_old_00;// + r_old_00 + g_cur_1_2;
        b_out_a <= b_old_01 + b_old_00;// + r_old_00 + b_cur_1_2;
        r_out_b <= r_old_00 + r_cur_1_2;
        g_out_b <= g_old_00 + g_cur_1_2;
        b_out_b <= b_old_00 + b_cur_1_2;
        r_out_c <= r_out_a + r_out_b;
        g_out_c <= g_out_a + g_out_b;
        b_out_c <= b_out_a + b_out_b;
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        r_out <= 0; g_out <= 0; b_out <= 0; 
        vsync_out <= 1'b0; hsync_out <= 1'b0; de_out <= 1'b0;
    end else if(en_ds_on_00==1) begin
        vsync_out <= vsync_d[2];  hsync_out <= hsync_d[2]; de_out <= de_d[2]; 
        r_out <= r_out_c[9:2];
        g_out <= g_out_c[9:2];
        b_out <= b_out_c[9:2];
        /*if(row_cnt[0]==0)begin
            r_out <= r_cur_1_2[7:0];//row_cnt[7:0];//
            g_out <= g_cur_1_2[7:0];//row_cnt[7:0];//
            b_out <= b_cur_1_2[7:0];//row_cnt[7:0];//
        end else begin
            r_out <= r_old_01[7:0];
            g_out <= g_old_01[7:0];
            b_out <= b_old_01[7:0];
        end*/
    end else begin
        vsync_out <= vsync_in;  hsync_out <= hsync_in; de_out <= de_in; 
        r_out <= r_in;
        g_out <= g_in;
        b_out <= b_in;
    end
end


wire [23:0]  rgb_gauss_cur;
assign rgb_gauss_cur = {r_gauss_cur[7:0],g_gauss_cur[7:0],b_gauss_cur[7:0]};

// 从帧缓存读取前一帧数据
wire [7:0] r_gauss_prev_00,g_gauss_prev_00,b_gauss_prev_00;
assign r_gauss_prev_00 = rgb_gauss_prev_00[23:16];
assign g_gauss_prev_00 = rgb_gauss_prev_00[15:8];
assign b_gauss_prev_00 = rgb_gauss_prev_00[7:0];

// 从帧缓存读取前二帧数据
wire [7:0] r_gauss_prev_01,g_gauss_prev_01,b_gauss_prev_01;
assign r_gauss_prev_01 = rgb_gauss_prev_01[23:16];
assign g_gauss_prev_01 = rgb_gauss_prev_01[15:8];
assign b_gauss_prev_01 = rgb_gauss_prev_01[7:0];

wire  [23:0] rgb_gauss_prev_00,rgb_gauss_prev_01;
line_delay ld_001(
    .clk(clk               ), // 像素时钟（约74.25 MHz for 720p60）
    .rst_n(rst_n           ), // 异步复位（低电平有效）
    .rgb_in(rgb_gauss_cur ), // 输入RGB数据（R[23:16], G[15:8], B[7:0]）
    .vsync_in(vsync_d[2]   ), // 垂直同步信号（帧开始）
    .hsync_in(hsync_d[2]   ), // 水平同步信号（行开始）
    .de_in(de_d[2]         ),
    .rgb_out(rgb_gauss_prev_00    ) // 输出RGB数据（R[23:16], G[15:8], B[7:0]）
);
line_delay ld_002(
    .clk(clk               ), // 像素时钟（约74.25 MHz for 720p60）
    .rst_n(rst_n           ), // 异步复位（低电平有效）
    .rgb_in(rgb_gauss_prev_00  ), // 输入RGB数据（R[23:16], G[15:8], B[7:0]）
    .vsync_in(vsync_d[2]   ), // 垂直同步信号（帧开始）
    .hsync_in(hsync_d[2]   ), // 水平同步信号（行开始）
    .de_in(de_d[2]         ),
    .rgb_out(rgb_gauss_prev_01 ) // 输出RGB数据（R[23:16], G[15:8], B[7:0]）
);

endmodule
