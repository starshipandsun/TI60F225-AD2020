//zoom
module video_zoom (
    input wire         clk,          // 像素时钟(720p60约74.25MHz)
    input wire         rst_n,        // 异步复位(低有效)
    
    // 输入视频信号
    input wire [23:0]  rgb_in,       // 输入RGB数据(8R+8G+8B)
    input wire         vsync_in,     // 输入场同步信号
    input wire         hsync_in,     // 输入行同步信号
    input wire         de_in,        // 输入数据有效信号

    input              en_zoom_on,
    input [7:0]        zoom_x,
    input [7:0]        zoom_y,

    
    // 输出视频信号
    output reg [23:0]  rgb_out,      // 输出RGB数据
    output reg         vsync_out,    // 输出场同步信号
    output reg         hsync_out,    // 输出行同步信号
    output reg         de_out        // 输出数据有效信号
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
parameter ZOOM_W     =   64;  // 原始宽度
parameter ZOOM_H     =   64;  // 原始高度
parameter ZOOM_X0    =   11'd128;  // 起始X坐标
parameter ZOOM_Y0    =   11'd128;  // 起始Y坐标
parameter ZOOM_RATIO =    4;  // 缩放比例分子(4倍)
parameter RATIO_DEN  =    1;  // 缩放比例分母

// 内部寄存器定义
reg [10:0] h_cnt;              // 行计数器
reg [10:0] v_cnt;              // 场计数器
reg [10:0] x_start,y_start;          // 输出行计数器

wire [7:0] r_in,g_in, b_in;
assign r_in[7:0] = rgb_in[23:16];
assign g_in[7:0] = rgb_in[15: 8];
assign b_in[7:0] = rgb_in[ 7: 0];

reg vs_01,vs_02,edge_HL_vs;
reg hs_01,hs_02,edge_HL_hs;
reg de_01,de_02,edge_LH_de,edge_HL_de;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        vs_01 <=0; vs_02 <= 0;
        hs_01 <=0; hs_02 <= 0;
        de_01 <=0; de_02 <= 0;
        edge_LH_de <=0;
        edge_HL_de <=0;
        edge_HL_hs <=0;
        edge_HL_vs <=0;
    end else begin
        vs_01 <= vsync_in; vs_02 <= vs_01;
        de_01 <= de_in;    de_02 <= de_01;
        hs_01 <= hsync_in; hs_02 <= hs_01;
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
reg [5:0]  buf_wr_x;           // 缓存写X地址
reg [5:0]  buf_wr_y;           // 缓存写Y地址
wire buf_wr_en;          // 缓存写使能
assign  buf_wr_en = (de_in && 
               (h_cnt >= x_start) && (h_cnt < (x_start + ZOOM_W)) && 
               (v_cnt >= y_start) && (v_cnt < (y_start + ZOOM_H)));
reg frame_image_org;
always @(*) begin
    x_start <= ZOOM_X0 + {zoom_x,5'd0};
    y_start <= ZOOM_Y0 + {zoom_y,5'd0};
end
always @(*) begin
    if((h_cnt == x_start ) &&  (v_cnt >= y_start && v_cnt < (y_start + ZOOM_H)))begin
       frame_image_org<=1;
    end else if((h_cnt == (x_start + ZOOM_W - 1) ) &&  (v_cnt >= y_start && v_cnt < (y_start + ZOOM_H)))begin
       frame_image_org<=1;
    end else if((v_cnt == y_start) && (h_cnt >= x_start && h_cnt < (x_start + ZOOM_W)))begin
       frame_image_org<=1;
    end else if((v_cnt == (y_start + ZOOM_H - 1) ) &&  (h_cnt >= x_start && h_cnt < (x_start + ZOOM_W)))begin
       frame_image_org<=1;
    end else begin
       frame_image_org<=0;   
    end
end
reg buf_wr_en_00;
// 1. 输入时序计数与缓存写入
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        buf_wr_x <= 0;
        buf_wr_y <= 0;
        buf_wr_en_00 <= 0;
    end else begin
        // 判断是否在缩放区域内
        // 计算缓存写入地址
        buf_wr_en_00 <= buf_wr_en;
        if (buf_wr_en) begin
            buf_wr_x <= h_cnt - x_start;
            buf_wr_y <= v_cnt - y_start;
            // 写入缓存
            //r_buf[buf_wr_y][buf_wr_x] <= r_in;
            //g_buf[buf_wr_y][buf_wr_x] <= g_in;
            //b_buf[buf_wr_y][buf_wr_x] <= b_in;
        end
    end
end
/////////////////////////////////////
// 3. 缩放区域坐标变换
wire [10:0] zoom_out_w = ZOOM_W * ZOOM_RATIO / RATIO_DEN; // 128
wire [10:0] zoom_out_h = ZOOM_H * ZOOM_RATIO / RATIO_DEN; // 128
// 判断当前输出像素是否在缩放后区域内
wire en_area_zoom_org;// = (h_cnt > zoom_out_w) && (out_h_cnt < zoom_out_w) && (out_v_cnt < zoom_out_h);
//assign area_zoom = zoom_area_07;// & en_area_zoom_org;
wire [10:0] offset_zoom;
reg frame_zoom;
assign offset_zoom = 7;
assign en_area_zoom_org = de_in &&
                     (h_cnt >= (x_start + ZOOM_W - offset_zoom )) && (h_cnt < (x_start + ZOOM_W - offset_zoom + zoom_out_w )) &&
                     (v_cnt >= (y_start + ZOOM_H )) && (v_cnt < ((y_start + ZOOM_H ) + zoom_out_h));
always @(*) begin
    if((h_cnt == x_start  + ZOOM_W ) && (v_cnt >= (y_start + ZOOM_H)) && (v_cnt < (y_start + ZOOM_H + zoom_out_h)))begin
       frame_zoom <=1;
    end else if((h_cnt == (x_start + ZOOM_W + zoom_out_w -2) ) &&  (v_cnt >= (y_start + ZOOM_H)) &&( v_cnt < (y_start + ZOOM_H + zoom_out_h)))begin
       frame_zoom <=1;
    end else if((v_cnt == (y_start + ZOOM_H )) && (h_cnt >= (x_start+ ZOOM_H)) && (h_cnt < (x_start + ZOOM_W + zoom_out_w)))begin
       frame_zoom <=1;
    end else if((v_cnt == (y_start + ZOOM_H + zoom_out_h) ) && (h_cnt >= (x_start+ ZOOM_H)) && (h_cnt < (x_start + ZOOM_W + zoom_out_w)))begin
       frame_zoom <=1;
    end else begin
       frame_zoom <=0;
    end
end
reg area_zoom;
always @(*) begin
    if( de_in && (h_cnt >= (x_start  + ZOOM_W)) && (h_cnt < (x_start + ZOOM_W + zoom_out_w -2) ) && (v_cnt >= (y_start + ZOOM_H)) && (v_cnt < (y_start + ZOOM_H + zoom_out_h)))begin
       area_zoom <=1;
    end else begin
       area_zoom <=0;
    end
end
reg zoom_area_00,zoom_area_01,zoom_area_02,zoom_area_03,zoom_area_04,zoom_area_05,zoom_area_06,zoom_area_07;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        zoom_area_00 <= 0; zoom_area_01 <= 0; zoom_area_02 <= 0; zoom_area_03 <= 0;
        zoom_area_04 <= 0; zoom_area_05 <= 0; zoom_area_06 <= 0; zoom_area_07 <= 0;
    end else begin
        zoom_area_00 <= en_area_zoom_org; zoom_area_01 <= zoom_area_00; zoom_area_02 <= zoom_area_01; zoom_area_03 <= zoom_area_02;
        zoom_area_04 <= zoom_area_03; zoom_area_05 <= zoom_area_04; zoom_area_06 <= zoom_area_05; zoom_area_07 <= zoom_area_06;
    end
end
///////////////////////////////////////
// 2. 输出时序生成
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        vsync_out <= 0;
        hsync_out <= 0;
        de_out <= 0;
    end else begin
        vsync_out <= vsync_in;
        hsync_out <= hsync_in;
        de_out <= de_in;
    end
end
///////////////////////////////////////
reg [11:0]  view_x,view_y;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        view_x <= 0;
        view_y <= 0;
    end else if (edge_HL_vs) begin
        view_x <= 0;
        view_y <= 0;
    end else if (en_area_zoom_org) begin
        if(view_x >=(zoom_out_w-1))begin
            view_x <= 0;
            view_y <= view_y +1;
        end else begin
            view_x <= view_x +1;
            view_y <= view_y;            
        end
    end else begin
        view_x <= 0;
        view_y <= view_y;
    end
end
reg [9:0]  ram_x,ram_y;
reg [9:0]  view_x_00,view_x_01,view_x_02;
always @(posedge clk) begin
    view_x_00[1:0] <= view_x[1:0];
    view_x_01[1:0] <= view_x_00[1:0];
    view_x_02[1:0] <= view_x_01[1:0];
    case(view_x[1:0])
    0:   begin ram_x[5:0] <= view_x[7:2];   ram_y[5:0] <= view_y[7:2];  end
    1:   begin ram_x[5:0] <= view_x[7:2]+1; ram_y[5:0] <= view_y[7:2];  end
    2:   begin ram_x[5:0] <= view_x[7:2];   ram_y[5:0] <= view_y[7:2]+1;end
    3:   begin ram_x[5:0] <= view_x[7:2]+1; ram_y[5:0] <= view_y[7:2]+1;end
    endcase
end
/////////////////////////////////////////////
//
/////////////////////////////////////////////
wire [23:0] rgb_ram;
reg [23:0] rgb_ram_00,rgb_ram_04,rgb_ram_40,rgb_ram_44;
reg [23:0] w00,w04,w40,w44;
assign rgb_ram = {r_ram[7:0],g_ram[7:0],b_ram[7:0]};
always @(posedge clk) begin
    case(view_x_01[1:0])
    0:   begin rgb_ram_00 <= rgb_ram   ; rgb_ram_04 <= rgb_ram_04; rgb_ram_40 <= rgb_ram_40; rgb_ram_44 <= rgb_ram_44;end
    1:   begin rgb_ram_00 <= rgb_ram_00; rgb_ram_04 <= rgb_ram   ; rgb_ram_40 <= rgb_ram_40; rgb_ram_44 <= rgb_ram_44;end
    2:   begin rgb_ram_00 <= rgb_ram_00; rgb_ram_04 <= rgb_ram_04; rgb_ram_40 <= rgb_ram   ; rgb_ram_44 <= rgb_ram_44;end
    3:   begin rgb_ram_00 <= rgb_ram_00; rgb_ram_04 <= rgb_ram_04; rgb_ram_40 <= rgb_ram_40; rgb_ram_44 <= rgb_ram   ;end
    endcase
end
//////////////////////////////////////////////
always @(posedge clk) begin
    if(view_x_01[1:0]==0)begin
        w00 <= rgb_ram_00;   w04 <= rgb_ram_04;   w40 <= rgb_ram_40;   w44 <= rgb_ram_44;
    end else begin
        w00 <= w00;  w04 <= w04;  w40 <= w40;  w44 <= w44;
    end
end
wire [2:0]  dx, dy;             // 小数部分(0~7, 对应0~1)
assign dx[2:0] = {0,view_x_02[1:0]};
assign dy[2:0] = {0,view_y[1:0]};
reg [15:0] r_temp, g_temp, b_temp; // 插值中间结果
// 4. 双线性插值计算
always @(posedge clk) begin
    r_temp <= ((4-dy)*(4-dx)* w00[23:16]+ dx*(4-dy)*w04[23:16]+  dy*(4-dx)* w40[23:16] + dx*dy*w44[23:16]);
    g_temp <= ((4-dy)*(4-dx)* w00[15:8] + dx*(4-dy)*w04[15:8] +  dy*(4-dx)* w40[15:8]  + dx*dy*w44[15:8]);
    b_temp <= ((4-dy)*(4-dx)* w00[7:0]  + dx*(4-dy)*w04[7:0]  +  dy*(4-dx)* w40[7:0]   + dx*dy*w44[7:0]);
end

//////////////////////////////////////////////
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rgb_out <= 0;
    end else if(!en_zoom_on)begin
        rgb_out <= rgb_in;
    end else if (frame_image_org) begin
        rgb_out <= {8'd30,8'd60,8'd30};
    //end else if (buf_wr_en) begin
        //rgb_out <= {8'd100,8'd40, 8'd20};
        //rgb_out[23:16]<= r_in[7:0];
        //rgb_out[15:8] <= g_in[7:0];
        //rgb_out[7 :0] <= b_in[7:0];
    end else if(frame_zoom)begin
        rgb_out <= {8'd30,8'd60,8'd30};
    end else if (area_zoom) begin
        rgb_out[23:16]<= r_temp[11:4];//w00[23:16];//
        rgb_out[15:8] <= g_temp[11:4];//w00[15: 8];//
        rgb_out[7 :0] <= b_temp[11:4];//w00[ 7: 0];//
    end else begin
        rgb_out <= rgb_in;
    end
end
//////////////////////////////////////////////////////
wire [11:0] add_we;
wire [11:0] add_rd;
wire [7:0] r_ram,g_ram,b_ram;
assign add_we[11:0] = {buf_wr_y[5:0],buf_wr_x[5:0]};
assign add_rd[11:0] = {ram_y[5:0],ram_x[5:0]};
/*
reg [23:0]  rgb_ram_tmp;
always @(posedge clk) begin
    if(view_y[2]==0)begin
        case(view_x_00[1:0])
        0: rgb_ram_tmp <= {8'd32,  8'd32,  8'd32};
        1: rgb_ram_tmp <= {8'd32,  8'd32,  8'd32};
        2: rgb_ram_tmp <= {8'd128, 8'd128, 8'd128};
        3: rgb_ram_tmp <= {8'd128, 8'd128, 8'd128};
        endcase
    end else begin 
        case(view_x_00[1:0])
        0: rgb_ram_tmp <= {8'd128, 8'd128, 8'd128};
        1: rgb_ram_tmp <= {8'd128, 8'd128, 8'd128};
        2: rgb_ram_tmp <= {8'd32,  8'd32,  8'd32};
        3: rgb_ram_tmp <= {8'd32,  8'd32,  8'd32};
        endcase
     end
end
*/
///*
wire v_zoom_test_H  = de_in &&
                     (v_cnt >= (y_start + ZOOM_H )) && (v_cnt < ((y_start + ZOOM_H ) + (zoom_out_h/2)));
wire en_test_H;
assign en_test_H = de_in &&
               (v_cnt >= y_start+5) && (v_cnt < (y_start + (ZOOM_H/2)-5));
assign en_test = de_in &&
               (h_cnt >= x_start+5) && (h_cnt < (x_start + ZOOM_W-5)) && 
               (v_cnt >= y_start+5) && (v_cnt < (y_start + ZOOM_H-5));
reg [23:0]  rgb_in_00;
reg [10:0] cnt_debug;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)begin
        cnt_debug[10:0] <=0;
    end else if(en_test==1)begin
        cnt_debug[10:0] <= cnt_debug[10:0] +8;
    end else begin
        cnt_debug[10:0] <=0;
    end
end
reg en_test_00;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)begin
        rgb_in_00[23:0] <= 0;
        en_test_00 <= 0;
    //end else if(en_test_00==1)begin
        //rgb_in_00[23:0] <= rgb_in[23:0];//{cnt_debug[7:0],cnt_debug[7:0],cnt_debug[7:0]};//{8'd255,8'd255,8'd255};//{8'd255,8'd255,8'd255};
        //en_test_00 <= en_test;
    end else begin
        rgb_in_00[23:0] <= rgb_in[23:0];//{8'd20,8'd20,8'd20};
        en_test_00 <= en_test;
    end
end
wire [7:0] r_in_00,g_in_00, b_in_00;
assign r_in_00[7:0] = rgb_in_00[23:16];
assign g_in_00[7:0] = rgb_in_00[15: 8];
assign b_in_00[7:0] = rgb_in_00[ 7: 0];

ram_4096_2 r_00 
(
    .re ( area_zoom ),
    .we ( buf_wr_en_00 ),
    .reset ( !rst_n ),
    .waddr ( add_we ),
    .wdata_a ( r_in_00[1:0] ),
    .rdata_b ( r_ram[1:0]),
    .raddr ( add_rd ),
    .clk ( clk )
);
ram_4096_2 r_01 
(
    .re ( area_zoom ),
    .we ( buf_wr_en_00 ),
    .reset ( !rst_n ),
    .waddr ( add_we ),
    .wdata_a ( r_in_00[3:2] ),
    .rdata_b ( r_ram[3:2]),
    .raddr ( add_rd ),
    .clk ( clk )
);
ram_4096_2 r_02 
(
    .re ( area_zoom ),
    .we ( buf_wr_en_00 ),
    .reset ( !rst_n ),
    .waddr ( add_we ),
    .wdata_a ( r_in_00[5:4] ),
    .rdata_b ( r_ram[5:4]),
    .raddr ( add_rd ),
    .clk ( clk )
);
ram_4096_2 r_03 
(
    .re ( area_zoom ),
    .we ( buf_wr_en_00 ),
    .reset ( !rst_n ),
    .waddr ( add_we ),
    .wdata_a ( r_in_00[7:6] ),
    .rdata_b ( r_ram[7:6]),
    .raddr ( add_rd ),
    .clk ( clk )
);
///////////////////////
ram_4096_2 g_00 
(
    .re ( area_zoom ),
    .we ( buf_wr_en_00 ),
    .reset ( !rst_n ),
    .waddr ( add_we ),
    .wdata_a ( g_in_00[1:0] ),
    .rdata_b ( g_ram[1:0]),
    .raddr ( add_rd ),
    .clk ( clk )
);
ram_4096_2 g_01 
(
    .re ( area_zoom ),
    .we ( buf_wr_en_00 ),
    .reset ( !rst_n ),
    .waddr ( add_we ),
    .wdata_a ( g_in_00[3:2] ),
    .rdata_b ( g_ram[3:2]),
    .raddr ( add_rd ),
    .clk ( clk )
);
ram_4096_2 g_02 
(
    .re ( area_zoom ),
    .we ( buf_wr_en_00 ),
    .reset ( !rst_n ),
    .waddr ( add_we ),
    .wdata_a ( g_in_00[5:4] ),
    .rdata_b ( g_ram[5:4]),
    .raddr ( add_rd ),
    .clk ( clk )
);
ram_4096_2 g_03 
(
    .re ( area_zoom ),
    .we ( buf_wr_en_00 ),
    .reset ( !rst_n ),
    .waddr ( add_we ),
    .wdata_a ( g_in_00[7:6] ),
    .rdata_b ( g_ram[7:6]),
    .raddr ( add_rd ),
    .clk ( clk )
);
////////////////
ram_4096_2 b_00 
(
    .re ( area_zoom ),
    .we ( buf_wr_en_00 ),
    .reset ( !rst_n ),
    .waddr ( add_we ),
    .wdata_a ( b_in_00[1:0] ),
    .rdata_b ( b_ram[1:0]),
    .raddr ( add_rd ),
    .clk ( clk )
);
ram_4096_2 b_01 
(
    .re ( area_zoom ),
    .we ( buf_wr_en_00 ),
    .reset ( !rst_n ),
    .waddr ( add_we ),
    .wdata_a ( b_in_00[3:2] ),
    .rdata_b ( b_ram[3:2]),
    .raddr ( add_rd ),
    .clk ( clk )
);
ram_4096_2 b_02 
(
    .re ( area_zoom ),
    .we ( buf_wr_en_00 ),
    .reset ( !rst_n ),
    .waddr ( add_we ),
    .wdata_a ( b_in_00[5:4] ),
    .rdata_b ( b_ram[5:4]),
    .raddr ( add_rd ),
    .clk ( clk )
);
ram_4096_2 b_03 
(
    .re ( area_zoom ),
    .we ( buf_wr_en_00 ),
    .reset ( !rst_n ),
    .waddr ( add_we ),
    .wdata_a ( b_in_00[7:6] ),
    .rdata_b ( b_ram[7:6]),
    .raddr ( add_rd ),
    .clk ( clk )
);
//*/

endmodule