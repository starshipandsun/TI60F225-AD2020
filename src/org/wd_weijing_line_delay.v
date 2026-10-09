//line delay
module line_delay (
    input clk,                  // 像素时钟 (720p60约需74.25MHz)
    input rst_n,                // 异步复位，低有效
    
    // 输入视频信号
    input [23:0] rgb_in,           // 输入红色分量
    input vsync_in,             // 输入场同步信号
    input hsync_in,             // 输入行同步信号
    input de_in,                // 输入数据有效信号
    
    //output [5:0]  debug_ld,
    // 输出视频信号
    output reg [23:0] rgb_out 
    //output reg vsync_out,            // 输出场同步信号
    //output reg hsync_out,            // 输出行同步信号
    //output reg de_out                // 输出数据有效信号
);


// 720p@60Hz 时序参数定义
parameter H_TOTAL = 1650;  // 总行像素数（含消隐）
parameter H_ACTIVE = 1280; // 有效行像素数

// 行计数器：计数每行的像素个数
reg [11:0]  cnt_de_line,cnt_de_hori;
reg vs_01,vs_02,edge_HL_vs;
reg hs_01,hs_02,edge_HL_hs;
reg de_01,de_02,edge_LH_de;
reg de_line_delay;
reg en_cnt_de_line;

//assign debug_ld[5] = edge_HL_vs;
//assign debug_ld[4] = edge_HL_hs;
//assign debug_ld[3] = edge_LH_de;
//assign debug_ld[2] = de_line_delay;
//assign debug_ld[1] = rd_en_i;
//assign debug_ld[0] = wr_en_i;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        vs_01 <=0; vs_02 <= 0;
        hs_01 <=0; hs_02 <= 0;
        de_01 <=0; de_02 <= 0;
        edge_LH_de <=0;
        edge_HL_hs <=0;
        edge_HL_vs <=0;
    end else begin
        vs_01 <= vsync_in; vs_02 <= vs_01;
        de_01 <= de_in;    de_02 <= de_01;
        hs_01 <= hsync_in; hs_02 <= hs_01;
        edge_HL_vs = vs_02 & !vs_01;
        edge_LH_de = de_01 & !de_02;
        edge_HL_hs = hs_02 & !hs_01;
    end
end
always @(posedge clk or negedge rst_n)begin
    if (!rst_n) 
        cnt_de_hori <= 0;
    else if(edge_HL_hs)
        cnt_de_hori <= 0;
    else 
        cnt_de_hori <= cnt_de_hori +1;
end
always @(posedge clk or negedge rst_n)begin
    if (!rst_n) 
        cnt_de_line <= 0;
    else if(edge_HL_vs)
        cnt_de_line <= 0;
    else if(edge_HL_hs)
        cnt_de_line <= cnt_de_line +1;
    else
        cnt_de_line <= cnt_de_line;
end
reg en_cnt_de_line_tmp;
always @(posedge clk or negedge rst_n)begin
    if (!rst_n) 
        en_cnt_de_line_tmp <= 0;
    else if(edge_HL_vs)
        en_cnt_de_line_tmp <= 0;
    else if(cnt_de_hori==1000)
            en_cnt_de_line_tmp <= de_01;
    else
        en_cnt_de_line_tmp <= en_cnt_de_line_tmp;
end
always @(posedge clk or negedge rst_n)begin
    if (!rst_n) 
        en_cnt_de_line <= 0;
    else if(edge_HL_vs)
        en_cnt_de_line <= 0;
    else if(edge_HL_hs)
            en_cnt_de_line <= en_cnt_de_line_tmp;
    else
        en_cnt_de_line <= en_cnt_de_line;
end

always @(posedge clk or negedge rst_n)begin
    if (!rst_n)
        de_line_delay <= 0;
    else if(edge_HL_vs)
        de_line_delay <= 0;
    else if(cnt_de_hori>253 && cnt_de_hori<1534 && en_cnt_de_line)
        de_line_delay <= 1;
    else
        de_line_delay <= 0;
end
reg  wr_en_i,rd_en_i;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rgb_out<= 0;
        //vsync_out <= 1'b0;
        //hsync_out <= 1'b0;
        //de_out <= 1'b0;
        wr_en_i<= 0;
        rd_en_i<= 0;
    end else begin
        rgb_out <= rdata;
        //vsync_out <= vsync_in;
        //hsync_out <= hsync_in;
        //de_out <= de_in;
        wr_en_i<= de_in;
        rd_en_i<= de_line_delay;
    end
end
wire [23:0] rdata;
wire full_o_00,empty_o_00;
wire  a_rst_i;
assign a_rst_i = !rst_n;
fifo_4_2028 fifo_4_2048_00
(
    .full_o ( full_o_00 ),
    .empty_o ( empty_o_00 ),
    .clk_i ( clk ),
    .wr_en_i ( wr_en_i ),
    .rd_en_i ( rd_en_i ),
    .wdata ( rgb_in[3:0] ),
    .rst_busy ( rst_busy_00 ),
    .rdata ( rdata[3:0] ),
    .a_rst_i ( a_rst_i ),
    .datacount_o ( datacount_o_00 )
);
fifo_4_2028 fifo_4_2048_01
(
    .full_o ( full_o_01 ),
    .empty_o ( empty_o_01 ),
    .clk_i ( clk ),
    .wr_en_i ( wr_en_i ),
    .rd_en_i ( rd_en_i ),
    .wdata ( rgb_in[7:4] ),
    .rst_busy ( rst_busy_01 ),
    .rdata ( rdata[7:4] ),
    .a_rst_i ( a_rst_i ),
    .datacount_o ( datacount_o_01 )
);
fifo_4_2028 fifo_4_2048_02
(
    .full_o ( full_o_02 ),
    .empty_o ( empty_o_02 ),
    .clk_i ( clk ),
    .wr_en_i ( wr_en_i ),
    .rd_en_i ( rd_en_i ),
    .wdata ( rgb_in[11:8] ),
    .rst_busy ( rst_busy_02 ),
    .rdata ( rdata[11:8] ),
    .a_rst_i ( a_rst_i ),
    .datacount_o ( datacount_o_02 )
);
fifo_4_2028 fifo_4_2048_03
(
    .full_o ( full_o_03 ),
    .empty_o ( empty_o_03 ),
    .clk_i ( clk ),
    .wr_en_i ( wr_en_i ),
    .rd_en_i ( rd_en_i ),
    .wdata ( rgb_in[15:12] ),
    .rst_busy ( rst_busy_03 ),
    .rdata ( rdata[15:12] ),
    .a_rst_i ( a_rst_i ),
    .datacount_o ( datacount_o_03 )
);
fifo_4_2028 fifo_4_2048_04
(
    .full_o ( full_o_04 ),
    .empty_o ( empty_o_04 ),
    .clk_i ( clk ),
    .wr_en_i ( wr_en_i ),
    .rd_en_i ( rd_en_i ),
    .wdata ( rgb_in[19:16] ),
    .rst_busy ( rst_busy_04 ),
    .rdata ( rdata[19:16] ),
    .a_rst_i ( a_rst_i ),
    .datacount_o ( datacount_o_04 )
);
fifo_4_2028 fifo_4_2048_05
(
    .full_o ( full_o_05 ),
    .empty_o ( empty_o_05 ),
    .clk_i ( clk ),
    .wr_en_i ( wr_en_i ),
    .rd_en_i ( rd_en_i ),
    .wdata ( rgb_in[23:20] ),
    .rst_busy ( rst_busy_05 ),
    .rdata ( rdata[23:20] ),
    .a_rst_i ( a_rst_i ),
    .datacount_o ( datacount_o_05 )
);
endmodule
module line_delay_8bit (
    input clk,                  // 像素时钟 (720p60约需74.25MHz)
    input rst_n,                // 异步复位，低有效
    
    // 输入视频信号
    input [7:0] rgb_in,           // 输入红色分量
    input vsync_in,             // 输入场同步信号
    input hsync_in,             // 输入行同步信号
    input de_in,                // 输入数据有效信号
    
    //output [5:0]  debug_ld,
    // 输出视频信号
    output reg [7:0] rgb_out 
    //output reg vsync_out,            // 输出场同步信号
    //output reg hsync_out,            // 输出行同步信号
    //output reg de_out                // 输出数据有效信号
);


// 720p@60Hz 时序参数定义
parameter H_TOTAL = 1650;  // 总行像素数（含消隐）
parameter H_ACTIVE = 1280; // 有效行像素数

// 行计数器：计数每行的像素个数
reg [11:0]  cnt_de_line,cnt_de_hori;
reg vs_01,vs_02,edge_HL_vs;
reg hs_01,hs_02,edge_HL_hs;
reg de_01,de_02,edge_LH_de;
reg de_line_delay;
reg en_cnt_de_line;

//assign debug_ld[5] = edge_HL_vs;
//assign debug_ld[4] = edge_HL_hs;
//assign debug_ld[3] = edge_LH_de;
//assign debug_ld[2] = de_line_delay;
//assign debug_ld[1] = rd_en_i;
//assign debug_ld[0] = wr_en_i;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        vs_01 <=0; vs_02 <= 0;
        hs_01 <=0; hs_02 <= 0;
        de_01 <=0; de_02 <= 0;
        edge_LH_de <=0;
        edge_HL_hs <=0;
        edge_HL_vs <=0;
    end else begin
        vs_01 <= vsync_in; vs_02 <= vs_01;
        de_01 <= de_in;    de_02 <= de_01;
        hs_01 <= hsync_in; hs_02 <= hs_01;
        edge_HL_vs = vs_02 & !vs_01;
        edge_LH_de = de_01 & !de_02;
        edge_HL_hs = hs_02 & !hs_01;
    end
end
always @(posedge clk or negedge rst_n)begin
    if (!rst_n) 
        cnt_de_hori <= 0;
    else if(edge_HL_hs)
        cnt_de_hori <= 0;
    else 
        cnt_de_hori <= cnt_de_hori +1;
end
always @(posedge clk or negedge rst_n)begin
    if (!rst_n) 
        cnt_de_line <= 0;
    else if(edge_HL_vs)
        cnt_de_line <= 0;
    else if(edge_HL_hs)
        cnt_de_line <= cnt_de_line +1;
    else
        cnt_de_line <= cnt_de_line;
end
reg en_cnt_de_line_tmp;
always @(posedge clk or negedge rst_n)begin
    if (!rst_n) 
        en_cnt_de_line_tmp <= 0;
    else if(edge_HL_vs)
        en_cnt_de_line_tmp <= 0;
    else if(cnt_de_hori==1000)
            en_cnt_de_line_tmp <= de_01;
    else
        en_cnt_de_line_tmp <= en_cnt_de_line_tmp;
end
always @(posedge clk or negedge rst_n)begin
    if (!rst_n) 
        en_cnt_de_line <= 0;
    else if(edge_HL_vs)
        en_cnt_de_line <= 0;
    else if(edge_HL_hs)
            en_cnt_de_line <= en_cnt_de_line_tmp;
    else
        en_cnt_de_line <= en_cnt_de_line;
end

always @(posedge clk or negedge rst_n)begin
    if (!rst_n)
        de_line_delay <= 0;
    else if(edge_HL_vs)
        de_line_delay <= 0;
    else if(cnt_de_hori>253 && cnt_de_hori<1534 && en_cnt_de_line)
        de_line_delay <= 1;
    else
        de_line_delay <= 0;
end
reg  wr_en_i,rd_en_i;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rgb_out<= 0;
        //vsync_out <= 1'b0;
        //hsync_out <= 1'b0;
        //de_out <= 1'b0;
        wr_en_i<= 0;
        rd_en_i<= 0;
    end else begin
        rgb_out <= rdata;
        //vsync_out <= vsync_in;
        //hsync_out <= hsync_in;
        //de_out <= de_in;
        wr_en_i<= de_in;
        rd_en_i<= de_line_delay;
    end
end
wire [7:0] rdata;
wire full_o_00,empty_o_00;
wire  a_rst_i;
assign a_rst_i = !rst_n;
fifo_4_2028 fifo_4_2048_00
(
    .full_o ( full_o_00 ),
    .empty_o ( empty_o_00 ),
    .clk_i ( clk ),
    .wr_en_i ( wr_en_i ),
    .rd_en_i ( rd_en_i ),
    .wdata ( rgb_in[3:0] ),
    .rst_busy ( rst_busy_00 ),
    .rdata ( rdata[3:0] ),
    .a_rst_i ( a_rst_i ),
    .datacount_o ( datacount_o_00 )
);
fifo_4_2028 fifo_4_2048_01
(
    .full_o ( full_o_01 ),
    .empty_o ( empty_o_01 ),
    .clk_i ( clk ),
    .wr_en_i ( wr_en_i ),
    .rd_en_i ( rd_en_i ),
    .wdata ( rgb_in[7:4] ),
    .rst_busy ( rst_busy_01 ),
    .rdata ( rdata[7:4] ),
    .a_rst_i ( a_rst_i ),
    .datacount_o ( datacount_o_01 )
);
endmodule