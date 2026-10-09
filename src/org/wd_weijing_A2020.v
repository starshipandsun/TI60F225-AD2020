`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/21
// Design Name: 
// Module Name: timer_system
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
//state machine
localparam  mConfig_i2c_mirror_non    =   10'd1;
localparam  mConfig_i2c_mirror_yes    =   10'd149;
localparam  mConfig_fram_00     =   10'd1;
localparam  mConfig_fram_01     =   10'd3;
localparam  mConfig_fram_02     =   10'd5;
localparam  mConfig_fram_10     =   10'd149;
localparam  mConfig_fram_11     =   10'd151;
localparam  mConfig_fram_12     =   10'd153;
localparam  mConfig_fram_20     =   10'd210;
//    Write I2C: {REG_Address[15:0], W_REG_Data[7:0]}
localparam  A2020_mirror_non    = {16'h3028, 8'h00}; 
localparam  A2020_mirror_yes    = {16'h3028, 8'h01}; 
localparam  A2020_Exposure_t00  = {16'h3048, 8'h08}; 
localparam  A2020_Exposure_t01  = {16'h3049, 8'h00}; 
localparam  A2020_Exposure_t02  = {16'h304a, 8'h00}; 

localparam  A2020_Exposure_t10  = {16'h3048, 8'h00}; 
localparam  A2020_Exposure_t11  = {16'h3049, 8'h07}; 
localparam  A2020_Exposure_t12  = {16'h304a, 8'h00};
localparam  A2020_BLACK_LEVEL  = {16'h3204, 8'h32};
localparam  A2020_Gain          = {16'h3110, 8'h00};
localparam  A2020_test_t00      = {16'h3048, 8'h00};
localparam  A2020_test_t10      = {16'h3049, 8'h70};
localparam  A2020_test_t20      = {16'h3049, 8'h00};
localparam  A2020_default       = {16'h0000, 8'h00};
module config_i2c_manual (
    input           clk_sys,   // 96MHz输入时钟
    input           rstn_sys,     // 低电平有效复位 (reset_n=0时复位)
    input  [ 9:0]   counter_state_main,
    output          manual_i2c_access,
    output [23:0]   A2020_i2c_dataCurrent00,
    output [23:0]   A2020_i2c_dataCurrent01,
    output [23:0]   A2020_i2c_dataCurrent02
);
reg             manual_i2c_access;
reg [23:0]    A2020_i2c_dataCurrent00,A2020_i2c_dataCurrent01,A2020_i2c_dataCurrent02;
always @(posedge clk_sys or negedge rstn_sys) begin
	if(~rstn_sys) begin manual_i2c_access <= 0;  A2020_i2c_dataCurrent00<= A2020_default; A2020_i2c_dataCurrent01<= A2020_default; A2020_i2c_dataCurrent02<= A2020_default;end
    else begin
        case(counter_state_main)
            mConfig_fram_00:  begin manual_i2c_access <= 1;  A2020_i2c_dataCurrent00<= A2020_Exposure_t02;  A2020_i2c_dataCurrent01<= A2020_Exposure_t01;  A2020_i2c_dataCurrent02<= A2020_Exposure_t00;end
            mConfig_fram_10:  begin manual_i2c_access <= 1;  A2020_i2c_dataCurrent00<= A2020_Exposure_t12;  A2020_i2c_dataCurrent01<= A2020_Exposure_t11;  A2020_i2c_dataCurrent02<= A2020_Exposure_t10;end
            //mConfig_fram_00:  begin manual_i2c_access <= 1;  A2020_i2c_dataCurrent00<= A2020_mirror_non;  A2020_i2c_dataCurrent01<= A2020_mirror_non;  A2020_i2c_dataCurrent02<= A2020_mirror_non;end
            //mConfig_fram_10:  begin manual_i2c_access <= 1;  A2020_i2c_dataCurrent00<= A2020_mirror_yes;  A2020_i2c_dataCurrent01<= A2020_mirror_yes;  A2020_i2c_dataCurrent02<= A2020_mirror_yes;end
            default:begin manual_i2c_access <= 0;  A2020_i2c_dataCurrent00<= A2020_i2c_dataCurrent00;A2020_i2c_dataCurrent01<= A2020_i2c_dataCurrent01;A2020_i2c_dataCurrent02<= A2020_i2c_dataCurrent02;end
        endcase
     end
end
endmodule
