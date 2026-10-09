module edge_enhancement (
    input wire         clk,          // 时钟信号（建议148.5MHz，满足720p60时序）
    input wire         rst_n,        // 异步复位（低有效）
    input wire [23:0]  rgb_in,       // 输入RGB数据（8bit R, 8bit G, 8bit B）
    input wire         hsync_in,     // 输入行同步信号
    input wire         vsync_in,     // 输入场同步信号
    input wire         de_in,        // 输入数据有效信号
    
    output reg [23:0]  rgb_out,      // 输出边缘加强后的RGB数据
    output reg         hsync_out,    // 输出行同步信号
    output reg         vsync_out,    // 输出场同步信号
    output reg         de_out        // 输出数据有效信号
);

// --------------------------
// 1. RGB转灰度（亮度提取）
// --------------------------
reg [7:0] gray;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        gray <= 8'd0;
    end else if (de_in) begin
        // 亮度公式：Y = 0.299R + 0.587G + 0.114B（近似整数运算）
        gray <= (rgb_in[23:16] * 77  + rgb_in[15:8] * 150 + rgb_in[7:0] * 29) >> 8;
    end else begin
        gray <= 8'd0;
    end
end

// --------------------------
// 2. 3x3窗口缓存（行缓冲）
// --------------------------
// 行缓冲深度：1280（720p宽度），数据位宽8bit（灰度值）
reg [7:0] line_buf_0 [0:1279];  // 缓存当前行的上一行
reg [7:0] line_buf_1 [0:1279];  // 缓存当前行
reg [7:0] line_buf_2 [0:1279];  // 缓存当前行的下一行（流水线延迟用）

reg [10:0] col_cnt;  // 列计数器（0~1279）
reg [9:0]  row_cnt;  // 行计数器（0~719）

// 行缓冲写入与计数器控制
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        col_cnt <= 11'd0;
        row_cnt <= 10'd0;
    end else if (de_in) begin
        // 列计数：每有效像素+1，溢出归零
        col_cnt <= (col_cnt == 11'd1279) ? 11'd0 : col_cnt + 11'd1;
        // 行计数：列溢出时+1，溢出归零
        row_cnt <= (col_cnt == 11'd1279) ? 
                  ((row_cnt == 10'd719) ? 10'd0 : row_cnt + 10'd1) : row_cnt;
        
        // 写入当前行缓冲（line_buf_1）
        line_buf_1[col_cnt] <= gray;
        // 当行结束时，更新行缓冲（上一行移至line_buf_0，当前行移至line_buf_1）
        if (col_cnt == 11'd1279) begin
            line_buf_0 <= line_buf_1;
            line_buf_2 <= line_buf_1;  // 延迟一行，用于构建3x3窗口
        end
    end
end

// --------------------------
// 3. 3x3窗口数据提取
// --------------------------
reg [7:0] window [0:8];  // 3x3窗口：[0][0]~[2][2]
reg       valid_window;  // 窗口有效标志（避免边界越界）

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        valid_window <= 1'b0;
        for (int i = 0; i < 9; i++) window[i] <= 8'd0;
    end else if (de_in && (col_cnt >= 1) && (col_cnt <= 1278) && (row_cnt >= 1) && (row_cnt <= 718)) begin
        // 提取3x3窗口数据（避免第一行、最后一行、第一列、最后一列）
        valid_window <= 1'b1;
        window[0] <= line_buf_0[col_cnt - 1];  // 上一行左
        window[1] <= line_buf_0[col_cnt];      // 上一行中
        window[2] <= line_buf_0[col_cnt + 1];  // 上一行右
        window[3] <= line_buf_1[col_cnt - 1];  // 当前行左
        window[4] <= line_buf_1[col_cnt];      // 当前行中
        window[5] <= line_buf_1[col_cnt + 1];  // 当前行右
        window[6] <= line_buf_2[col_cnt - 1];  // 下一行左
        window[7] <= line_buf_2[col_cnt];      // 下一行中
        window[8] <= line_buf_2[col_cnt + 1];  // 下一行右
    end else begin
        valid_window <= 1'b0;
        for (int i = 0; i < 9; i++) window[i] <= 8'd0;
    end
end

// --------------------------
// 4. Sobel算子计算边缘
// --------------------------
// Sobel算子：Gx（水平边缘）和Gy（垂直边缘）
// Gx = [-1 0 1; -2 0 2; -1 0 1]
// Gy = [-1 -2 -1; 0 0 0; 1 2 1]
reg [15:0] gx, gy;  // 中间结果（避免溢出）
reg [8:0]  edge_val; // 边缘强度（0~255）

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        gx <= 16'd0;
        gy <= 16'd0;
        edge_val <= 9'd0;
    end else if (valid_window) begin
        // 计算Gx
        gx <= (-$signed(window[0]) + $signed(window[2]) 
              - 2*$signed(window[3]) + 2*$signed(window[5]) 
              - $signed(window[6]) + $signed(window[8]));
        
        // 计算Gy
        gy <= (-$signed(window[0]) - 2*$signed(window[1]) - $signed(window[2]) 
              + $signed(window[6]) + 2*$signed(window[7]) + $signed(window[8]));
        
        // 边缘强度 = |Gx| + |Gy|（近似L1范数，比平方和开方简单）
        edge_val <= (gx[15] ? -gx : gx) + (gy[15] ? -gy : gy);
    end else begin
        gx <= 16'd0;
        gy <= 16'd0;
        edge_val <= 9'd0;
    end
end

// --------------------------
// 5. 边缘加强（原图+边缘）
// --------------------------
reg [7:0] gray_enhanced;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        gray_enhanced <= 8'd0;
    end else if (valid_window) begin
        // 边缘加强：原图灰度 + 边缘强度（限幅0~255）
        gray_enhanced <= (gray + edge_val[8:1]) > 8'd255 ? 8'd255 : (gray + edge_val[8:1]);
    end else begin
        // 边界像素直接输出原图灰度
        gray_enhanced <= gray;
    end
end

// --------------------------
// 6. 灰度转RGB（保持色彩格式）
// --------------------------
// 边缘加强后转为RGB（R=G=B=增强后的灰度，保持灰度图输出；或叠加原图色彩）
// 此处采用灰度图输出（如需彩色边缘可调整算法）
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rgb_out <= 24'd0;
    end else begin
        rgb_out <= {gray_enhanced, gray_enhanced, gray_enhanced};  // R=G=B
    end
end

// --------------------------
// 7. 同步信号延迟对齐
// --------------------------
// 因处理存在延迟，同步信号需延迟3个时钟周期（与数据路径匹配）
reg [2:0] hsync_dly, vsync_dly, de_dly;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        hsync_dly <= 3'b0;
        vsync_dly <= 3'b0;
        de_dly <= 3'b0;
    end else begin
        hsync_dly <= {hsync_dly[1:0], hsync_in};
        vsync_dly <= {vsync_dly[1:0], vsync_in};
        de_dly <= {de_dly[1:0], de_in};
    end
end

// 输出同步信号
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        hsync_out <= 1'b0;
        vsync_out <= 1'b0;
        de_out <= 1'b0;
    end else begin
        hsync_out <= hsync_dly[2];
        vsync_out <= vsync_dly[2];
        de_out <= de_dly[2];
    end
end

endmodule