//uart_cmd
module cmd_parser(
    input           clk,            // 系统时钟
    input           rst_n,          // 复位信号，低有效
   	input	        clken_16bps,    //clk_bps * 16
    input           flag_rxd,       // 串口接收数据有效
    input   [7:0]   rxd_data,       // 串口接收数据

    output          flag_cmd_new,
    output          flag_led_on,
    output          en_zoom_on,
    output          en_digi_on,
    output          en_wb_on,
    output          en_dm_on,     
    output          en_ds_on,  
    
    
    output [7:0]    cont_value,
    output [7:0]    ae_value,
    output [7:0]    edge_value,
    output [7:0]    gama_value,
    output [7:0]    zoom_x,
    output [7:0]    zoom_y,
    output [7:0]    cmd_new,
    output [7:0]    cmd_data  
);
// 指令关键字定义
localparam TIME_OUT = 16 * 16 * 2;  // 单字节时钟数 * 16个字节
localparam cmd_led  = 1; 
localparam cmd_zoom = 2; 
localparam cmd_zmx  = 3;
localparam cmd_zmy  = 4;
localparam cmd_digi = 5; 
localparam cmd_wb   = 6; 
localparam cmd_gama = 7; 
localparam cmd_dm   = 8; 
localparam cmd_ds   = 9; 
localparam cmd_edge = 10;
localparam cmd_ae   = 11; 
localparam cmd_cont = 12;

localparam zoom    = "zoom";//e.g., zoom01\r\n:zoom ON; zoom00\r\n:zoom OFF
localparam zmx     = "zmx"; //e.g., zmx04\r\n: start_x = 4*64
localparam zmy     = "zmy"; //e.g., zmy05\r\n: start_y = 5*64
localparam led     = "led";//e.g., led0201\r\n:LED2 ON;  led0200\r\n: LED2 OFF
localparam digi    = "digi";//e.g., digi01\r\n: digi_ovevrlay_ON; digi00\r\n: digi_ovevrlay_OFF
localparam wb      = "wb";//e.g., wb01\r\n:wb ON; wb00\r\n:wb OFF
localparam gama    = "gama";//e.g., gama11\r\n:gama 1.1 ON;gama22\r\n:gama 2.2 ON; gama00\r\n:gama OFF
localparam cont    = "cont";//e.g., cont60\r\n:contrast = 0x60;
localparam dm      = "dm";//e.g., dm01\r\n:dm ON; dm00\r\n:dm OFF
localparam ds      = "ds";//e.g., ds01\r\n:ds ON; ds00\r\n:ds OFF
localparam ae      = "ae";//e.g., ae31\r\n:ae_value = 0x31
localparam _edge    = "edge";//e.g., edge11\r\n:edge_value = 11 


// 内部寄存器
reg [7:0]   char_buf [0:7];  // 指令缓存，最大16字节


//led_on_data[7:4] <= ascii_to_hex(char_buf[7]);
//led_on_data[3:0] <= ascii_to_hex(char_buf[8]);


reg [7:0] cmd_new,cmd_data;
reg  flag_cmd_new;
wire  [63:0] cmd_in;
assign cmd_in[63:0] = {char_buf[7],char_buf[6],char_buf[5],char_buf[4],char_buf[3],char_buf[2],char_buf[1],char_buf[0]};
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        flag_cmd_new<=0;
        cmd_new<=0;
        cmd_data<=0;
        char_buf[0]<=0;char_buf[1]<=0;char_buf[2]<=0;char_buf[3]<=0;char_buf[4]<=0;char_buf[5]<=0;char_buf[6]<=0;char_buf[7]<=0;
    end else if(flag_rxd) begin
        if(rxd_data==8'd13)begin ///r
            if(cmd_in[39:16]==led)begin cmd_new<=cmd_led; flag_cmd_new<=1;end
            else if(cmd_in[47:16]==zoom)begin cmd_new<=cmd_zoom; flag_cmd_new<=1;end
            else if(cmd_in[47:16]==digi)begin cmd_new<=cmd_digi; flag_cmd_new<=1;end
            else if(cmd_in[47:16]==gama)begin cmd_new<=cmd_gama; flag_cmd_new<=1;end
            else if(cmd_in[47:16]==cont)begin cmd_new<=cmd_cont; flag_cmd_new<=1;end
            else if(cmd_in[47:16]==_edge)begin cmd_new<=cmd_edge;flag_cmd_new<=1;end
            else if(cmd_in[39:16]==zmx)begin cmd_new<=cmd_zmx; flag_cmd_new<=1;end
            else if(cmd_in[39:16]==zmy)begin cmd_new<=cmd_zmy; flag_cmd_new<=1;end
            else if(cmd_in[31:16]==wb)begin cmd_new<=cmd_wb; flag_cmd_new<=1;end
            else if(cmd_in[31:16]==dm)begin cmd_new<=cmd_dm; flag_cmd_new<=1;end
            else if(cmd_in[31:16]==ds)begin cmd_new<=cmd_ds; flag_cmd_new<=1;end
            else if(cmd_in[31:16]==ae)begin cmd_new<=cmd_ae; flag_cmd_new<=1;end
            else begin cmd_new<=cmd_new;flag_cmd_new<=0;end
            cmd_data[7:0] <= hex_temp;//cmd_in[15:8];//ascii_to_hex(cmd_in[7:0]);
        end else if(rxd_data==8'd10)begin ///n
            char_buf[0]<=0;char_buf[1]<=0;char_buf[2]<=0;char_buf[3]<=0;char_buf[4]<=0;char_buf[5]<=0;char_buf[6]<=0;char_buf[7]<=0;
            flag_cmd_new<=0;
            cmd_new<=cmd_new;
            cmd_data<=cmd_data;
        end else begin
            flag_cmd_new<=0;
            char_buf[7]<=char_buf[6];char_buf[6]<=char_buf[5];
            char_buf[5]<=char_buf[4];char_buf[4]<=char_buf[3];char_buf[3]<=char_buf[2];
            char_buf[2]<=char_buf[1];char_buf[1]<=char_buf[0];char_buf[0]<=rxd_data;
            cmd_new<=cmd_new;
            cmd_data<=cmd_data;
        end
    end else  begin
        flag_cmd_new<=0;
        char_buf[0]<=char_buf[0];char_buf[1]<=char_buf[1];char_buf[2]<=char_buf[2];char_buf[3]<=char_buf[3];
        char_buf[4]<=char_buf[4];char_buf[5]<=char_buf[5];char_buf[6]<=char_buf[6];char_buf[7]<=char_buf[7];
        cmd_new<=cmd_new;
        cmd_data<=cmd_data;
    end
end


reg [7:0]   zoom_x,zoom_y,gama_value,ae_value,edge_value,cont_value;
reg  flag_led_on,en_zoom_on,en_digi_on;
reg  en_wb_on,en_dm_on,en_ds_on;    

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin 
        en_ds_on <= 1;
    end else if(flag_cmd_new==1)begin
        if(cmd_new==cmd_ds) en_ds_on<=cmd_data[0]; else en_ds_on <= en_ds_on;
    end else begin
        en_ds_on <= en_ds_on;    
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin 
        en_dm_on <= 1;
    end else if(flag_cmd_new==1)begin
        if(cmd_new==cmd_dm) en_dm_on<=cmd_data[0]; else en_dm_on <= en_dm_on;
    end else begin
        en_dm_on <= en_dm_on;    
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin 
        en_wb_on <= 1;
    end else if(flag_cmd_new==1)begin
        if(cmd_new==cmd_wb) en_wb_on<=cmd_data[0]; else en_wb_on <= en_wb_on;
    end else begin
        en_wb_on <= en_wb_on;    
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin 
        flag_led_on <= 0;
    end else if(flag_cmd_new==1)begin
        if(cmd_new==cmd_led) flag_led_on<=cmd_data[0]; else flag_led_on <= flag_led_on;
    end else begin
        flag_led_on <= flag_led_on;    
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        en_zoom_on <= 1;
    end else if(flag_cmd_new==1)begin
        if(cmd_new==cmd_zoom) en_zoom_on<=cmd_data[0]; else en_zoom_on<=en_zoom_on;
    end else begin
        en_zoom_on <= en_zoom_on;    
    end    
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        en_digi_on <= 1;
    end else if(flag_cmd_new==1)begin
        if(cmd_new==cmd_digi) en_digi_on<=cmd_data[0]; else en_digi_on<=en_digi_on;
    end else begin
        en_digi_on <= en_digi_on;    
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) zoom_x <= 16;  else if(flag_cmd_new==1 && cmd_new==cmd_zmx)  zoom_x     <= cmd_data; else zoom_x    <= zoom_x;    
    if (!rst_n) zoom_y <= 6;  else if(flag_cmd_new==1 && cmd_new==cmd_zmy)  zoom_y     <= cmd_data; else zoom_y    <= zoom_y;
    if (!rst_n) gama_value<=8'h18;else if(flag_cmd_new==1 && cmd_new==cmd_gama) gama_value <=cmd_data;  else gama_value <= gama_value;
    if (!rst_n) cont_value<=8'h80;else if(flag_cmd_new==1 && cmd_new==cmd_cont) cont_value <=cmd_data;  else cont_value <= cont_value;
    if (!rst_n) edge_value<=0;  else if(flag_cmd_new==1 && cmd_new==cmd_edge)   edge_value <=cmd_data;  else edge_value <= edge_value;
    if (!rst_n) ae_value<=0;  else if(flag_cmd_new==1 && cmd_new==cmd_ae)   ae_value  <=cmd_data;  else ae_value  <=ae_value;
end

wire [7:0] hex_temp;
ascii_to_hex_converter u_ascii_to_hex (
    .digi_h      (char_buf[1]),  // 高位ASCII码输入（如字符'3'对应十六进制高4位）
    .digi_l      (char_buf[0]),   // 低位ASCII码输入（如字符'F'对应十六进制低4位）
    .ascii_to_hex(hex_temp)     // 转换后的8位十六进制结果（如3F）
);

endmodule

module ascii_to_hex_converter (
    input wire [7:0] digi_h,      // 输入的ASCII码所在的命令数据
    input wire [7:0] digi_l,      // 输入的ASCII码所在的命令数据
    output reg [7:0] ascii_to_hex // 转换后的4位十六进制数
);
always @(*) begin
    if (digi_l >= 8'd48 && digi_l <= 8'd57) begin  // 数字0-9 (digi_l:48-57)
        ascii_to_hex[3:0] = digi_l - 8'd48;
    end else if (digi_l >= 8'd65 && digi_l <= 8'd70) begin  // 大写字母A-F (digi_l:65-70)
        ascii_to_hex[3:0] = digi_l - 8'd55;  // 65-55=10 (对应0xA), 以此类推
    end else if (digi_l >= 8'd97 && digi_l <= 8'd102) begin  // 小写字母a-f (digi_l:97-102)
        ascii_to_hex[3:0] = digi_l - 8'd87;  // 97-87=10 (对应0xA), 以此类推
    end else begin  // 无效字符，输出0
        ascii_to_hex[3:0] = 4'h0;
    end
    if (digi_h >= 8'd48 && digi_h <= 8'd57) begin  // 数字0-9 (digi_l:48-57)
        ascii_to_hex[7:4] = digi_h - 8'd48;
    end else if (digi_h >= 8'd65 && digi_h <= 8'd70) begin  // 大写字母A-F (digi_l:65-70)
        ascii_to_hex[7:4] = digi_h - 8'd55;  // 65-55=10 (对应0xA), 以此类推
    end else if (digi_h >= 8'd97 && digi_h <= 8'd102) begin  // 小写字母a-f (digi_l:97-102)
        ascii_to_hex[7:4] = digi_h - 8'd87;  // 97-87=10 (对应0xA), 以此类推
    end else begin  // 无效字符，输出0
        ascii_to_hex[7:4] = 4'h0;
    end
end

endmodule