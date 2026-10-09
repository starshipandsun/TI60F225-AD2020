//contract
module contrast_adjuster (
    input           clk,            
    input           rst_n,          // 异步复位信号, 低有效
    input [23:0]    rgb_in,           // 输入红色分量
    input           vsync_in,             // 输入场同步信号
    input           hsync_in,             // 输入行同步信号
    input           de_in,                // 输入数据有效信号
    input [7:0]     contrast_level, // 对比度调节值(0-255), 128为默认
    
    output [23:0]   rgb_out,          // 输出红色分量
    output          vsync_out,            // 输出场同步信号
    output          hsync_out,            // 输出行同步信号
    output          de_out                // 输出数据有效信号
);
wire [7:0] r_in,g_in, b_in;
assign r_in[7:0] = rgb_in[23:16];
assign g_in[7:0] = rgb_in[15: 8];
assign b_in[7:0] = rgb_in[ 7: 0];
//wire [7:0] r_out,g_out,b_out;
assign rgb_out ={r_out[7:0],g_out[7:0],b_out[7:0]};
// 对比度调节公式: 
// output = 128 + (input - 128) * contrast_factor
// 其中contrast_factor = contrast_level / 128.0

// 中间变量定义
reg [15:0] contrast_factor;  // 对比度系数(扩大256倍表示浮点数)
reg [15:0] r_temp, g_temp, b_temp;
reg [7:0] r_shifted, g_shifted, b_shifted;

// 同步控制信号
reg vsync_out,hsync_out,de_out;
reg vsync_d1, vsync_d2;
reg hsync_d1, hsync_d2;
reg de_d1, de_d2;

// 计算对比度系数 (contrast_level / 128.0) * 256 = contrast_level * 2
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        contrast_factor <= 16'd256;  // 默认对比度(128*2=256)
    end else begin
        contrast_factor <= {contrast_level, 1'b0};  // 等价于contrast_level * 2
    end
end
// 同步控制信号(延迟两拍以匹配数据路径延迟)
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        vsync_d1 <= 1'b0;
        vsync_d2 <= 1'b0;
        hsync_d1 <= 1'b0;
        hsync_d2 <= 1'b0;
        de_d1 <= 1'b0;
        de_d2 <= 1'b0;
        vsync_out <= 1'b0;
        hsync_out <= 1'b0;
        de_out <= 1'b0;
    end else begin
        // 延迟链
        vsync_d1 <= vsync_in;
        vsync_d2 <= vsync_d1;
        hsync_d1 <= hsync_in;
        hsync_d2 <= hsync_d1;
        de_d1 <= de_in;
        de_d2 <= de_d1;
        
        // 输出同步信号
        vsync_out <= vsync_d2;
        hsync_out <= hsync_d2;
        de_out <= de_d2;
    end
end
reg  [15:0] r_out,g_out,b_out;
reg  [15:0] r_cont_fp,g_cont_fp,b_cont_fp;
reg  [15:0] r_cont_fm,g_cont_fm,b_cont_fm;
reg  [15:0] r_cont_fm2,g_cont_fm2,b_cont_fm2;
reg  [15:0] r_in_f,g_in_f,b_in_f;
reg  [15:0] f_128;
always @(*) begin
    f_128 <= contrast_factor <<7;
    r_in_f <= r_in * contrast_factor;
    g_in_f <= g_in * contrast_factor;
    b_in_f <= b_in * contrast_factor;
    r_cont_fp <= (r_in_f - f_128)>>8;
    g_cont_fp <= (g_in_f - f_128)>>8;
    b_cont_fp <= (b_in_f - f_128)>>8;
    r_cont_fm <= (r_in_f >>8)+8'd128;
    g_cont_fm <= (g_in_f >>8)+8'd128;
    b_cont_fm <= (b_in_f >>8)+8'd128;
    r_cont_fm2 <= contrast_factor/2;
    g_cont_fm2 <= contrast_factor/2;
    b_cont_fm2 <= contrast_factor/2;
end
always @(*) begin
    if(r_in >= 8'd128)
        r_out <= (r_cont_fp>=127)? 255 : r_cont_fp + 128;
    else
        r_out <= (r_cont_fm >= r_cont_fm2)? r_cont_fm - r_cont_fm2: 0;
    if(g_in >= 8'd128)
        g_out <= (g_cont_fp>=127)? 255 : g_cont_fp + 128;
    else
        g_out <= (g_cont_fm >= g_cont_fm2)?  g_cont_fm - g_cont_fm2: 0;
    if(b_in >= 8'd128)
        b_out <= (b_cont_fp>=127)? 255 : b_cont_fp + 128;
    else
        b_out <= (b_cont_fm >= b_cont_fm2)?  b_cont_fm - b_cont_fm2: 0;
end

endmodule