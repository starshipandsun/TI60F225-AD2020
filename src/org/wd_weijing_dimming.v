//dimming
module video_dimming ( 
    input          clk,      // 像素时钟(720p60约74.25MHz) 
    input          rst_n,          // 异步复位(低有效) 
    input  [7:0]   dim_factor,     // 消光因子(0-255, 255=无消光) 
    input  [23:0]  rgb_in,           // 输入红色分量
    input          vsync_in,    // 垂直同步信号 
    input          hsync_in,    // 水平同步信号 
    input          de_in,       // 数据使能信号 
    
    input  en_dm_on,

    output [23:0]  rgb_out,          // 输出红色分量
    output reg     vsync_out,      // 输出垂直同步信号 
    output reg     hsync_out,      // 输出水平同步信号 
    output reg     de_out         // 输出数据使能信号 
); 
wire [7:0] r_in,g_in, b_in;
assign r_in[7:0] = rgb_in[23:16];
assign g_in[7:0] = rgb_in[15: 8];
assign b_in[7:0] = rgb_in[ 7: 0];
reg [7:0] r_out,g_out,b_out;
assign rgb_out ={r_out[7:0],g_out[7:0],b_out[7:0]};
 
// 同步信号延迟线(匹配数据处理延迟) 
reg [1:0] hsync_delay; 
reg [1:0] vsync_delay; 
reg [1:0] de_delay; 
 
// 消光处理流水线 
reg [15:0] r_mult, g_mult, b_mult; 
reg [7:0] r_dimming, g_dimming, b_dimming; 
 
// 计算亮度缩放 (像素值 * 消光因子 / 256) 
always @(posedge clk or negedge rst_n) begin 
    if (!rst_n) begin 
        r_mult <= 16'd0; 
        g_mult <= 16'd0; 
        b_mult <= 16'd0; 
        r_dimming <= 8'd0; 
        g_dimming <= 8'd0; 
        b_dimming <= 8'd0; 
    end else begin 
        // 第一级流水线: 乘法运算 
        r_mult <= r_in * dim_factor; 
        g_mult <= g_in * dim_factor; 
        b_mult <= b_in * dim_factor; 
        
        // 第二级流水线: 右移8位(除以256) 
        r_dimming <= r_mult[15:8]; 
        g_dimming <= g_mult[15:8]; 
        b_dimming <= b_mult[15:8]; 
    end 
end 
 
// 同步信号延迟匹配 
always @(posedge clk or negedge rst_n) begin 
    if (!rst_n) begin 
        hsync_delay <= 2'b00; 
        vsync_delay <= 2'b00; 
        de_delay <= 2'b00; 
    end else begin 
        // 延迟2个时钟周期匹配处理流水线 
        hsync_delay <= {hsync_delay[0], hsync_in}; 
        vsync_delay <= {vsync_delay[0], vsync_in}; 
        de_delay <= {de_delay[0], de_in}; 
    end 
end 
 
// 输出信号赋值 
always @(posedge clk or negedge rst_n) begin 
    if (!rst_n) begin 
        hsync_out <= 1'b0; 
        vsync_out <= 1'b0; 
        de_out <= 1'b0; 
        r_out <= 8'd0; 
        g_out <= 8'd0; 
        b_out <= 8'd0; 
    end else begin 
        hsync_out <= hsync_delay[1]; 
        vsync_out <= vsync_delay[1]; 
        de_out <= de_delay[1]; 
        
        // 仅在数据有效期间输出处理后的数据 
        if (de_delay[1]) begin 
            r_out <= r_in;//r_dimming; 
            g_out <= g_in;//g_dimming; 
            b_out <= b_in;//b_dimming; 
        end else begin 
            r_out <= 8'd0; 
            g_out <= 8'd0; 
            b_out <= 8'd0; 
        end 
    end 
end 
 
endmodule 