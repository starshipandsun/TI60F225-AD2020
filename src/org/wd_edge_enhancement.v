//边缘增强
module edge_enhancement (
    input clk,                  // 像素时钟 (720p60约需74.25MHz)
    input rst_n,                // 异步复位，低有效
    
    // 输入视频信号
    input [23:0] rgb_in,           // 输入红色分量
    input vsync_in,             // 输入场同步信号
    input hsync_in,             // 输入行同步信号
    input de_in,                // 输入数据有效信号
    
    input [7:0] edge_value,
    // 输出视频信号
    output [23:0] rgb_out,          // 输出红色分量
    output reg vsync_out,            // 输出场同步信号
    output reg hsync_out,            // 输出行同步信号
    output reg de_out                // 输出数据有效信号
);
wire [7:0]  r_in,g_in,b_in;
assign r_in[7:0] = rgb_in[23:16];
assign g_in[7:0] = rgb_in[15: 8];
assign b_in[7:0] = rgb_in[ 7: 0];
reg [7:0] r_out,g_out,b_out;
assign rgb_out ={r_out[7:0],g_out[7:0],b_out[7:0]};

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        vsync_out <= 0;
        hsync_out <= 0;
        de_out <= 0;
    end else begin
        vsync_out <= vs_01;
        hsync_out <= hs_01;
        de_out <= de_01;
    end
end


// 图像尺寸参数 (720p)
localparam H_ACTIVE = 1280;         // 水平有效像素
localparam V_ACTIVE = 720;          // 垂直有效像素
// 中间寄存器定义
reg [16:0] gray;                    // 灰度值

// 行计数和列计数
reg [10:0] h_cnt;                  // 水平计数 (0~1279)
reg [10:0] v_cnt;                  // 垂直计数 (0~719)

// 同步信号延迟寄存器 (匹配图像处理延迟)
reg [2:0] vsync_dly;
reg [2:0] hsync_dly;
reg [2:0] de_dly;

// RGB转灰度 (采用ITU-R BT.601标准)

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        gray <= 17'd0;
    end else if (de_in) begin
        // 灰度 = 0.299*R + 0.587*G + 0.114*B
        gray <= (r_in * 77 + g_in * 150 + b_in * 29 + 128) >> 8;
    end
end

/*
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        gray<=8'h0;
    end else if(h_cnt>11'd100 && h_cnt< 11'd400 && v_cnt> 11'd100 && v_cnt< 11'd400)
        gray<=8'hff;
    else
        gray<=8'h20;
end
*/
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        r_out<= 0;
        g_out<= 0;
        b_out<= 0;
    end else if(edge_value[7]==1)begin
        r_out<= (enhanced_r[8]==1)? 8'd255: enhanced_r[7:0];
        g_out<= (enhanced_g[8]==1)? 8'd255: enhanced_g[7:0];
        b_out<= (enhanced_b[8]==1)? 8'd255: enhanced_b[7:0];
    end else begin
        r_out<= r00;
        g_out<= g00;
        b_out<= b00;
    end
end


// Sobel边缘检测与增强
reg [10:0] gx, gy;         // 水平和垂直梯度
reg [10:0] g;              // 梯度绝对值
reg [8:0] enhanced_r, enhanced_g, enhanced_b;
reg [7:0] r00,r01,r02,r03;         // RGB延迟线，匹配灰度处理延迟
reg [7:0] g00,g01,g02,g03;
reg [7:0] b00,b01,b02,b03;
// RGB信号延迟，与灰度处理保持同步
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        r00 <= 8'd0; r01 <= 8'd0; r02 <= 8'd0; r02 <= 8'd0;
        g00 <= 8'd0; g01 <= 8'd0; g02 <= 8'd0; g02 <= 8'd0;
        b00 <= 8'd0; b01 <= 8'd0; b02 <= 8'd0; b02 <= 8'd0;
    end else if (de_in) begin
        r00 <= r_in; r01 <= r00; r02 <= r01; r03 <= r02;
        g00 <= g_in; g01 <= g00; g02 <= g01; g03 <= g02;
        b00 <= b_in; b01 <= b00; b02 <= b01; b03 <= b02;
    end else begin
        r00 <= r00; r01 <= r01; r02 <= r02; r03 <= r03;
        g00 <= g00; g01 <= g01; g02 <= g02; g03 <= g03;
        b00 <= b00; b01 <= b01; b02 <= b02; b03 <= b03;
    end
end

reg [7:0] w00,  w01,  w02;
reg [7:0] w10,  w11,  w12;
reg [7:0] w20,  w21,  w22;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        w00 <= 8'd0; w01 <= 8'd0; w02 <= 8'd0;
        w10 <= 8'd0; w11 <= 8'd0; w12 <= 8'd0;
        w20 <= 8'd0; w21 <= 8'd0; w22 <= 8'd0;
    end else begin
        w20 <= w10; w10 <= w00; w00 <= line_o_01;
        w21 <= w11; w11 <= w01; w01 <= line_o_00;
        w22 <= w12; w12 <= w02; w02 <= line_i_00;
    end
end


// 计算Sobel梯度 (3x3卷积)
// Gx = (P3 + 2*P6 + P9) - (P1 + 2*P4 + P7)
// Gy = (P7 + 2*P8 + P9) - (P1 + 2*P2 + P3)
reg [10:0] gx,gx0,gx1,gy,gy0,gy1;
always @(*) begin
     gx1 <= w20 + w21 + w21 + w22;
     gx0 <= w00 + w01 + w01 + w02;
     gy1 <= w02 + w12 + w12 + w22;
     gy0 <= w00 + w10 + w10 + w02;
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        gx <=0; gy <=0;
    end else begin
        gx[9:0] <= (gx1 >= gx0) ? gx1[9:0]-gx0[9:0]: gx0[9:0]-gx1[9:0];
        gx[10]  <= (gx1 >= gx0) ? 0:1;
        gy[9:0] <= (gy1 >= gy0) ? gy1[9:0]-gy0[9:0]: gy0[9:0]-gy1[9:0];
        gy[10]  <= (gy1 >= gy0) ? 0:1;
    end
end
reg [10:0] g_tmp;
wire [1:0] dir_gxy;
assign dir_gxy[0] = gx[10];
assign dir_gxy[1] = gy[10];

always @(*) begin
    case(dir_gxy[1:0])
    2'd0:begin g[10:0] <=  gy[10:0] + gx[10:0]; end 
    2'd1:begin g[10:0] <= (gy[9:0] >= gx[9:0])? {0,(gy[9:0] - gx[10:0])}:{1,(gx[9:0] - gy[9:0])}; end //(gy[9:0] >= gx[9:0])? g[10] = 0：g[10] = 1; end 
    2'd2:begin g[10:0] <= (gx[9:0] >= gy[9:0])? {0,(gx[9:0] - gy[10:0])}:{1,(gy[9:0] - gx[9:0])}; end //(gy[9:0] >= gx[9:0])? g[10] = 0：g[10] = 1; end 
    2'd3:begin g[9:0] <= gy[9:0] + gx[9:0];  g[10] <= 1; end 
    endcase
    g_tmp <= (g[9:0] * gain_edge[3:0])>> 3;
    
end


always @(posedge clk or negedge rst_n) begin
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        enhanced_r <= 8'd0;
        enhanced_g <= 8'd0;
        enhanced_b <= 8'd0;
    end else if (de_02) begin
        // 边缘增强公式：输出 = 原图 + 增益 * 边缘强度
        enhanced_r <= (g[10]==0)? r_ld03 + g_tmp: (r_ld03 >= g_tmp)? r_ld03 - g_tmp:0 ;
        enhanced_g <= (g[10]==0)? g_ld03 + g_tmp: (g_ld03 >= g_tmp)? g_ld03 - g_tmp:0 ;
        enhanced_b <= (g[10]==0)? g_ld03 + g_tmp: (b_ld03 >= g_tmp)? b_ld03 - g_tmp:0 ;
    end else begin
        enhanced_r <= r_ld03;
        enhanced_g <= g_ld03;
        enhanced_b <= b_ld03;
    end
end

/*
// 计算梯度绝对值并限制范围
assign g = (gx[10] ? -gx : gx) + (gy[10] ? -gy : gy);

// 边缘增强：原图 + 边缘信息 (带增益控制)
localparam EDGE_GAIN = 4'd1;        // 边缘增益，可调整
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        enhanced_r <= 8'd0;
        enhanced_g <= 8'd0;
        enhanced_b <= 8'd0;
    end else if (de_dly[2]) begin
        // 边缘增强公式：输出 = 原图 + 增益 * 边缘强度
        enhanced_r <= (r02 + (g * EDGE_GAIN) >> 3) > 255 ? 255 : 
                     (r02 + (g * EDGE_GAIN) >> 3) < 0 ? 0 : 
                     r02 + (g * EDGE_GAIN) >> 3;
                     
        enhanced_g <= (g02 + (g * EDGE_GAIN) >> 3) > 255 ? 255 : 
                     (g02 + (g * EDGE_GAIN) >> 3) < 0 ? 0 : 
                     g02 + (g * EDGE_GAIN) >> 3;
                     
        enhanced_b <= (delayed_b[2] + (g * EDGE_GAIN) >> 3) > 255 ? 255 : 
                     (delayed_b[2] + (g * EDGE_GAIN) >> 3) < 0 ? 0 : 
                     delayed_b[2] + (g * EDGE_GAIN) >> 3;
    end else begin
        enhanced_r <= delayed_r[2];
        enhanced_g <= delayed_g[2];
        enhanced_b <= delayed_b[2];
    end
end

// 输出信号赋值
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        r_out <= 8'd0;
        g_out <= 8'd0;
        b_out <= 8'd0;
        vsync_out <= 1'b0;
        hsync_out <= 1'b0;
        de_out <= 1'b0;
    end else begin
        r_out <= enhanced_r;
        g_out <= enhanced_g;
        b_out <= enhanced_b;
        vsync_out <= vsync_dly[2];
        hsync_out <= hsync_dly[2];
        de_out <= de_dly[2];
    end
end
*/
reg [10:0] h_cnt;              // 行计数器
reg [10:0] v_cnt;              // 场计数器
reg vs_00,vs_01,vs_02,edge_HL_vs;
reg hs_00,hs_01,hs_02,edge_HL_hs;
reg de_00,de_01,de_02,edge_LH_de,edge_HL_de;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        vs_00 <=0; vs_01 <=0; vs_02 <= 0;
        hs_00 <=0; hs_01 <=0; hs_02 <= 0;
        de_00 <=0; de_01 <=0; de_02 <= 0;
        edge_LH_de <=0;
        edge_HL_de <=0;
        edge_HL_hs <=0;
        edge_HL_vs <=0;
    end else begin
        vs_00 <= vsync_in; 
        vs_02 <= vs_01;vs_01 <= vs_00;
        de_00 <= de_in;    
        de_02 <= de_01;de_01 <= de_00;
        hs_00 <= hsync_in; 
        hs_02 <= hs_01;hs_01 <= hs_00;
        edge_HL_vs = vs_02 & !vs_01;
        edge_LH_de = de_01 & !de_02;
        edge_HL_de = !de_01 & de_02;
        edge_HL_hs = hs_02 & !hs_01;
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        v_cnt <= 0;
    end else if (edge_HL_vs) begin
        v_cnt <= 0;
    end else if (edge_HL_de) begin
        v_cnt <= v_cnt +1;
    end else begin
        v_cnt <= v_cnt;
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        h_cnt <= 0;
    end else if (edge_HL_de) begin
        h_cnt <= 0;
    end else if(de_in)begin
        h_cnt <= h_cnt + 1;
    end else begin
        h_cnt <= 0;    
    end
end

reg [7:0] edge_value_00;
//localparam EDGE_GAIN = 4'd1;        // 边缘增益，可调整
wire [3:0] gain_edge;
assign gain_edge[3:0] = edge_value_00[3:0];
always @(posedge clk or negedge rst_n) begin 
    if (!rst_n) 
        edge_value_00 <= 0;
    else if (edge_HL_vs)
        edge_value_00 <= edge_value;
    else
        edge_value_00 <= edge_value_00;
end
wire [7:0] line_i_00;
wire [7:0] line_o_00,line_o_01;
assign line_i_00 = gray[7:0];
line_delay_8bit ld8_001(
    .clk(clk               ), // 像素时钟（约74.25 MHz for 720p60）
    .rst_n(rst_n           ), // 异步复位（低电平有效）
    .rgb_in(line_i_00 ), // 输入RGB数据（R[23:16], G[15:8], B[7:0]）
    .vsync_in(vs_01   ), // 垂直同步信号（帧开始）
    .hsync_in(hs_01   ), // 水平同步信号（行开始）
    .de_in   (de_01   ),
    .rgb_out(line_o_00    ) // 输出RGB数据（R[23:16], G[15:8], B[7:0]）
);
line_delay_8bit ld8_002(
    .clk(clk               ), // 像素时钟（约74.25 MHz for 720p60）
    .rst_n(rst_n           ), // 异步复位（低电平有效）
    .rgb_in(line_o_00  ), // 输入RGB数据（R[23:16], G[15:8], B[7:0]）
    .vsync_in(vs_01   ), // 垂直同步信号（帧开始）
    .hsync_in(hs_01   ), // 水平同步信号（行开始）
    .de_in   (de_01   ),
    .rgb_out(line_o_01 ) // 输出RGB数据（R[23:16], G[15:8], B[7:0]）
);
reg [23:0]  rgb_in_00;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rgb_in_00[23:0] <=0;
        rgb_ld_01[23:0] <=0;
        rgb_ld_02[23:0] <=0;
        rgb_ld_03[23:0] <=0;
    end else begin
        rgb_in_00[23:0] <= rgb_in[23:0];
        rgb_ld_01[23:0] <= rgb_ld_00[23:0];
        rgb_ld_02[23:0] <= rgb_ld_01[23:0];
        rgb_ld_03[23:0] <= rgb_ld_02[23:0];
    end
end
wire [7:0]  r_ld03,g_ld03,b_ld03;
assign r_ld03[7:0] = rgb_ld_03[23:16];
assign g_ld03[7:0] = rgb_ld_03[15: 8];
assign b_ld03[7:0] = rgb_ld_03[ 7: 0];
wire  [23:0] rgb_ld_00;
reg  [23:0] rgb_ld_01,rgb_ld_02,rgb_ld_03;
line_delay ld_001(
    .clk(clk               ), // 像素时钟（约74.25 MHz for 720p60）
    .rst_n(rst_n           ), // 异步复位（低电平有效）
    .rgb_in(rgb_in_00 ), // 输入RGB数据（R[23:16], G[15:8], B[7:0]）
    .vsync_in(vs_01     ), // 垂直同步信号（帧开始）
    .hsync_in(hs_01     ), // 水平同步信号（行开始）
    .de_in   (de_01     ),
    .rgb_out(rgb_ld_00    ) // 输出RGB数据（R[23:16], G[15:8], B[7:0]）
);
endmodule