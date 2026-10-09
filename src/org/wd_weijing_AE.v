//AE_RGB
module auto_exposure (
    input clk,                  // 像素时钟 (720p60约需74.25MHz)
    input rst_n,                // 异步复位，低有效
    
    // 输入视频信号
    input [23:0] rgb_in,           // 输入红色分量
    input vsync_in,             // 输入场同步信号
    input hsync_in,             // 输入行同步信号
    input de_in,                // 输入数据有效信号

    input [7:0]  ae_Y,
    // 输出视频信号
    output [23:0] rgb_out,          // 输出红色分量
    output  vsync_out,            // 输出场同步信号
    output  hsync_out,            // 输出行同步信号
    output  de_out,                // 输出数据有效信号
    output reg [7:0]   analog_gain,      // 模拟增益控制 (0-0x50档)
    output reg [15:0]  shutter_speed,     // 曝光时间控制 (0-0x700行)
    
    output        en_i2c_config_ae,
    output [23:0]  a2020_config_00,
    output [23:0]  a2020_config_01,
    output [23:0]  a2020_config_02
);

wire [7:0] r_in,g_in, b_in;
assign r_in[7:0] = rgb_in[23:16];
assign g_in[7:0] = rgb_in[15: 8];
assign b_in[7:0] = rgb_in[ 7: 0];
reg [7:0] r_out,g_out,b_out;
assign rgb_out ={r_out[7:0],g_out[7:0],b_out[7:0]};

// 内部参数定义
localparam TARGET_BRIGHTNESS = 8'd128;  // 目标亮度值(0-255)
localparam BRIGHTNESS_TOLERANCE = 8'd02;// 亮度容差范围
localparam MAX_ANALOG_GAIN   = 8'h54;   // 最大模拟增益
localparam MIN_ANALOG_GAIN   = 8'h1;    // 最小模拟增益
localparam MAX_SHUTTER_SPEED = 16'h700; // 最大曝光时间
localparam MIN_SHUTTER_SPEED = 16'h08;  // 最小曝光时间
localparam GAIN_STEP         = 8'd1;    // 增益调整步长
localparam SHUTTER_STEP = 10'd20;       // 曝光时间调整步长
localparam FRAME_WIDTH   = 10'd1280;    // 720p宽度
localparam FRAME_HEIGHT  = 10'd720;     // 720p高度

// 状态机定义
localparam IDLE = 2'd0;
localparam ACCUMULATE = 2'd1;
localparam CALCULATE = 2'd2;
localparam ADJUST = 2'd3;
localparam ADD_SHUTTER_00  = 16'h3048;
localparam ADD_SHUTTER_01  = 16'h3049;
localparam ADD_SHUTTER_02  = 16'h304a;
localparam ADD_GAIN        = 16'h3110;

// 内部寄存器
reg [1:0] current_state, next_state;
reg [31:0] brightness_sum;              // 亮度总和
reg [20:0] pixel_count;                 // 像素计数
reg [7:0] avg_brightness;               // 平均亮度
reg vsync_d1, vsync_d2,vsync_out;                 // 同步信号边沿检测
reg hsync_d1,hsync_d2,hsync_out;
reg de_d1,de_d2,de_out;
//reg frame_valid;                        // 帧有效标志


// 边沿检测：检测vsync上升沿
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        vsync_out<=0; vsync_d2 <= 1'b0; vsync_d1 <= 1'b0;        
        hsync_out<=0; hsync_d2 <= 1'b0; hsync_d1 <= 1'b0;
        de_out<=0;    de_d2    <= 1'b0; de_d1    <= 1'b0;
    end else begin
        vsync_out <= vsync_d2; vsync_d2 <= vsync_d1; vsync_d1 <= vsync_in;
        hsync_out <= hsync_d2; hsync_d2 <= hsync_d1; hsync_d1 <= hsync_in;
        de_out    <= de_d2;    de_d2    <= de_d1;    de_d1    <= de_in;
    end
end

wire vsync_posedge = vsync_d1 & ~vsync_d2;  // vsync上升沿
//wire vsync_negedge = ~vsync_d1 & vsync_d2;  // vsync下降沿
//wire href_posedge = hsync_in & ~hsync_d1;        // href上升沿

// 状态机转换
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        current_state <= IDLE;
    end else begin
        current_state <= next_state;
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        pixel_count <= 0;
    end else if(vsync_posedge) begin
        pixel_count <= 0;
    end else if(de_in) begin
        pixel_count <= pixel_count + 1;
    end else begin
        pixel_count <= pixel_count;
    end
end
reg [3:0] cnt_frame;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cnt_frame <= 0;
    end else if(vsync_posedge) begin
        cnt_frame <= (cnt_frame == 3)? 0: cnt_frame +1;
    end else begin
        cnt_frame <= cnt_frame;
    end
end
// 状态机逻辑
always @(*) begin
    case (current_state)
        IDLE: begin
            // 检测到帧开始，进入累积状态
            if (vsync_posedge) begin
                next_state = ACCUMULATE;
            end else begin
                next_state = IDLE;
            end
        end
        ACCUMULATE: begin
            // 累积完一帧像素后进入计算状态
            if (pixel_count >= (FRAME_WIDTH * FRAME_HEIGHT)-1) begin
                next_state = CALCULATE;
            end else begin
                next_state = ACCUMULATE;
            end
        end
        CALCULATE: begin
            // 完成亮度计算后进入调整状态
            next_state = ADJUST;
        end
        ADJUST: begin
            // 完成曝光调整后回到空闲状态
            next_state = IDLE;
        end
        default: next_state = IDLE;
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        avg_brightness <= 0;
    end else if (vsync_posedge) begin
        avg_brightness <= ae_Y;
    end else begin
        avg_brightness <= avg_brightness;
    end
end
reg [7:0] analog_gain;
reg [15:0] shutter_speed;
reg  adj_brightness;
localparam ADJ_SHUTTER = 1;
localparam ADJ_GAIN    = 0;
// 自动曝光调整逻辑
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        analog_gain <= MIN_ANALOG_GAIN;
        adj_brightness <= 0;
        shutter_speed <= MIN_SHUTTER_SPEED;
    end else if (current_state == ADJUST && cnt_frame ==0) begin
            // 亮度低于目标值，增加曝光
            if (avg_brightness < 8'h80) begin
                // 优先调整曝光时间
                if (shutter_speed > MIN_SHUTTER_SPEED) begin
                    shutter_speed <= (shutter_speed > (MIN_SHUTTER_SPEED +SHUTTER_STEP)) ? shutter_speed - SHUTTER_STEP : MIN_SHUTTER_SPEED;
                    analog_gain <= analog_gain;
                    adj_brightness <= ADJ_SHUTTER;
                end else if (analog_gain <= MAX_ANALOG_GAIN) begin
                    shutter_speed <= shutter_speed;
                    analog_gain <= (analog_gain < (MAX_ANALOG_GAIN - GAIN_STEP)) ? analog_gain + GAIN_STEP : MAX_ANALOG_GAIN;
                    adj_brightness <= ADJ_GAIN;
                end else begin
                    analog_gain <= analog_gain;
                    shutter_speed <= shutter_speed;
                    adj_brightness <= adj_brightness;
                end
            end
            // 亮度高于目标值，减少曝光
            else if (avg_brightness > (TARGET_BRIGHTNESS + BRIGHTNESS_TOLERANCE)) begin
                // 优先降低增益
                if (analog_gain > MIN_ANALOG_GAIN) begin
                    analog_gain <= (analog_gain > (MIN_ANALOG_GAIN + GAIN_STEP)) ? analog_gain - GAIN_STEP : MIN_ANALOG_GAIN;
                    shutter_speed <= shutter_speed;
                    adj_brightness <= ADJ_GAIN;
                end else if (shutter_speed <= MAX_SHUTTER_SPEED) begin
                    shutter_speed <= (shutter_speed > (MAX_SHUTTER_SPEED - SHUTTER_STEP)) ? MAX_SHUTTER_SPEED : shutter_speed + SHUTTER_STEP;
                    analog_gain <= analog_gain;
                    adj_brightness <= ADJ_SHUTTER;
                end else begin
                    analog_gain <= analog_gain;
                    shutter_speed <= shutter_speed;
                    adj_brightness <= adj_brightness;
                end
            end else begin
                analog_gain <= analog_gain;
                shutter_speed <= shutter_speed;
                adj_brightness <= adj_brightness;
            end
            // 亮度在目标范围内，不调整
    end else begin
        analog_gain <= analog_gain;
        shutter_speed <= shutter_speed;
        adj_brightness <= adj_brightness;
    end
end
reg  en_i2c_config_ae;
reg [23:0] a2020_config_00,a2020_config_01,a2020_config_02;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        a2020_config_00 <= 0;
        a2020_config_01 <= 0;
        a2020_config_02 <= 0;
        en_i2c_config_ae <= 0;
    end else if (pixel_count < (FRAME_WIDTH * (FRAME_HEIGHT-100))) begin
        a2020_config_00 <= 0;
        a2020_config_01 <= 0;
        a2020_config_02 <= 0;
        en_i2c_config_ae <= 0;
    end else if (adj_brightness == ADJ_GAIN) begin
        a2020_config_00 <= {ADD_GAIN,analog_gain[7:0]};//8'haa;//
        a2020_config_01 <= 24'h0;//8'hcc;//
        //a2020_config_02 <= 24'h0;
        a2020_config_02 <= {analog_gain[7:0],shutter_speed[15:0]};//24'h0;
        en_i2c_config_ae <= 1;
    end else begin
        a2020_config_00 <= {ADD_SHUTTER_00,shutter_speed[7:0]};//8'haa;//
        a2020_config_01 <= {ADD_SHUTTER_01,shutter_speed[15:8]};//8'hcc;//
        a2020_config_02 <= {analog_gain[7:0],shutter_speed[15:0]};//24'h0;
        en_i2c_config_ae <= 1;
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        r_out <= 8'd0;
        g_out <= 8'd0;
        b_out <= 8'd0;
    end else begin
        r_out <= r_in;//8'd0;
        g_out <= g_in;//8'd0;
        b_out <= b_in;//8'd0;;
    end
end

endmodule