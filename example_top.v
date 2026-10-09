`timescale 1ns/1ps

//`include "ddr3_controller.vh"


module example_top 
(
	////////////////////////////////////////////////////////////////
	//	External Clock & Reset
	//input 			nrst, 			//	Button K2
	input 			clk_24m,			//	24MHz Crystal
	input 			clk_25m,			//	25MHz Crystal 
	
	
	////////////////////////////////////////////////////////////////
	//	System Clock
	output 			sys_pll_rstn_o, 		
	
	input 			clk_sys,			//	Sys PLL 96MHz 
	input 			clk_pixel,			//	Sys PLL 74.25MHz
	input 			clk_pixel_2x,		//	Sys PLL 148.5MHz
	input 			clk_pixel_10x,		//	Sys PLL 742.5MHz
	
	input 			sys_pll_lock,		//	Sys PLL Lock
	
	////////////////////////////////////////////////////////////////
	//	MIPI-DSI Clock & Reset
	output 			dsi_pll_rstn_o,
	
	input 			dsi_refclk_i,		//	48MHz Reference Clock (for DSI PLL)
	input 			dsi_byteclk_i,		//	DSI Byte Clock (1X)
	input 			dsi_serclk_i,		//	DSI Serial Clock (4X 45)
	input 			dsi_txcclk_i,		//	DSI Serial Clock (4X 135)
	
	input 			dsi_pll_lock,
	
	////////////////////////////////////////////////////////////////
	//	DDR Clock
	output 			ddr_pll_rstn_o, 
	
	input 			tdqss_clk,			
	input 			core_clk,			//	DDR PLL 200MHz
	input 			tac_clk,			
	input 			twd_clk,			
	
	input 			ddr_pll_lock,		//	DDR PLL Lock
	
	////////////////////////////////////////////////////////////////
	//	DDR PLL Phase Shift Interface
	output 	[2:0] 	shift,
	output 	[4:0] 	shift_sel,
	output 			shift_ena,
	
	
	
	////////////////////////////////////////////////////////////////
	//	LVDS Clock
	output 			lvds_pll_rstn_o, 
	
	input 			clk_lvds_1x, 
	input 			clk_lvds_7x, 
	input 			clk_27m, 			//	RGB 1X Clock (16MHz)
	input 			clk_54m, 			//	RGB 2X Clock (32MHz, for export control)
	
	input 			lvds_pll_lock, 
	
	
	
	////////////////////////////////////////////////////////////////
	//	DDR Interface Ports
	output 	[15:0] 	addr,
	output 	[2:0] 	ba,
	output 			we,
	output 			reset,
	output 			ras,
	output 			cas,
	output 			odt,
	output 			cke,
	output 			cs,
	
	//	DQ I/O
	input 	[15:0] 	i_dq_hi,
	input 	[15:0] 	i_dq_lo,
	
	output 	[15:0] 	o_dq_hi,
	output 	[15:0] 	o_dq_lo,
	output 	[15:0] 	o_dq_oe,
	
	//	DM O
	output 	[1:0] 	o_dm_hi,
	output 	[1:0] 	o_dm_lo,
	
	//	DQS I/O
	input 	[1:0] 	i_dqs_hi,
	input 	[1:0] 	i_dqs_lo,
	
	input 	[1:0] 	i_dqs_n_hi,
	input 	[1:0] 	i_dqs_n_lo,
	
	output 	[1:0] 	o_dqs_hi,
	output 	[1:0] 	o_dqs_lo,
	
	output 	[1:0] 	o_dqs_n_hi,
	output 	[1:0] 	o_dqs_n_lo,
	
	output 	[1:0] 	o_dqs_oe,
	output 	[1:0] 	o_dqs_n_oe,
	
	//	CK
	output 			clk_p_hi, 
	output 			clk_p_lo, 
	output 			clk_n_hi, 
	output 			clk_n_lo, 
	
	
	
	////////////////////////////////////////////////////////////////
	//	MIPI-CSI Ctl / I2C
	output 			csi_ctl0_o,
	output 			csi_ctl0_oe,
	input 			csi_ctl0_i,
	
	output 			csi_ctl1_o,
	output 			csi_ctl1_oe,
	input 			csi_ctl1_i,
	
	output 			csi_scl_o,
	output 			csi_scl_oe,
	input 			csi_scl_i,
	
	output 			csi_sda_o,
	output 			csi_sda_oe,
	input 			csi_sda_i,
	
	//	MIPI-CSI RXC 
	input 			csi_rxc_lp_p_i,
	input 			csi_rxc_lp_n_i,
	output 			csi_rxc_hs_en_o,
	output 			csi_rxc_hs_term_en_o,
	input 			csi_rxc_i,
	
	//	MIPI-CSI RXD0
	output 			csi_rxd0_rst_o,
	output 			csi_rxd0_hs_en_o,
	output 			csi_rxd0_hs_term_en_o,
	
	input 			csi_rxd0_lp_p_i,
	input 			csi_rxd0_lp_n_i,
	input 	[7:0] 	csi_rxd0_hs_i,
	
	//	MIPI-CSI RXD1
	output 			csi_rxd1_rst_o,
	output 			csi_rxd1_hs_en_o,
	output 			csi_rxd1_hs_term_en_o,
	
	input 			csi_rxd1_lp_n_i,
	input 			csi_rxd1_lp_p_i,
	input 	[7:0] 	csi_rxd1_hs_i,
	
	//	MIPI-CSI RXD2
	output 			csi_rxd2_rst_o,
	output 			csi_rxd2_hs_en_o,
	output 			csi_rxd2_hs_term_en_o,
	
	input 			csi_rxd2_lp_p_i,
	input 			csi_rxd2_lp_n_i,
	input 	[7:0] 	csi_rxd2_hs_i,
	
	//	MIPI-CSI RXD3
	output 			csi_rxd3_rst_o,
	output 			csi_rxd3_hs_en_o,
	output 			csi_rxd3_hs_term_en_o,
	
	input 			csi_rxd3_lp_p_i,
	input 			csi_rxd3_lp_n_i,
	input 	[7:0] 	csi_rxd3_hs_i,
	
	//output 			csi_rxd0_fifo_rd_o, 
	//input 			csi_rxd0_fifo_empty_i, 
	//output 			csi_rxd1_fifo_rd_o, 
	//input 			csi_rxd1_fifo_empty_i, 
	//output 			csi_rxd2_fifo_rd_o, 
	//input 			csi_rxd2_fifo_empty_i, 
	//output 			csi_rxd3_fifo_rd_o, 
	//input 			csi_rxd3_fifo_empty_i, 
	
	
	
	////////////////////////////////////////////////////////////////
	//	DSI PWM & Reset Control 
	output 			dsi_pwm_o,			//	MIPI-DSI LCD PWM
	output 			dsi_resetn_o,		//	MIPI-DSI LCD Reset
	
	//	MIPI-DSI TXC / TXD
	output 			dsi_txc_rst_o,
	output 			dsi_txc_lp_p_oe,
	output 			dsi_txc_lp_p_o,
	output 			dsi_txc_lp_n_oe,
	output 			dsi_txc_lp_n_o,
	output 			dsi_txc_hs_oe,
	output 	[7:0] 	dsi_txc_hs_o,
	
	output 			dsi_txd0_rst_o,
	output 			dsi_txd0_hs_oe,
	output 	[7:0] 	dsi_txd0_hs_o,
	output 			dsi_txd0_lp_p_oe,
	output 			dsi_txd0_lp_p_o,
	output 			dsi_txd0_lp_n_oe,
	output 			dsi_txd0_lp_n_o,
	
	output 			dsi_txd1_rst_o,
	output 			dsi_txd1_lp_p_oe,
	output 			dsi_txd1_lp_p_o,
	output 			dsi_txd1_lp_n_oe,
	output 			dsi_txd1_lp_n_o,
	output 			dsi_txd1_hs_oe,
	output 	[7:0] 	dsi_txd1_hs_o,
	
	output 			dsi_txd2_rst_o,
	output 			dsi_txd2_lp_p_oe,
	output 			dsi_txd2_lp_p_o,
	output 			dsi_txd2_lp_n_oe,
	output 			dsi_txd2_lp_n_o,
	output 			dsi_txd2_hs_oe,
	output 	[7:0] 	dsi_txd2_hs_o,
	
	output 			dsi_txd3_rst_o,
	output 			dsi_txd3_lp_p_oe,
	output 			dsi_txd3_lp_p_o,
	output 			dsi_txd3_lp_n_oe,
	output 			dsi_txd3_lp_n_o,
	output 			dsi_txd3_hs_oe,
	output 	[7:0] 	dsi_txd3_hs_o,
	
	input 			dsi_txd0_lp_p_i,
	input 			dsi_txd0_lp_n_i,
	input 			dsi_txd1_lp_p_i,
	input 			dsi_txd1_lp_n_i,
	input 			dsi_txd2_lp_p_i,
	input 			dsi_txd2_lp_n_i,
	input 			dsi_txd3_lp_p_i,
	input 			dsi_txd3_lp_n_i,
	
	
	////////////////////////////////////////////////////////////////
	//	UART Interface
	input 		 	uart_rx_i,			//	Support 460800-8-N-1. 
	output 		 	uart_tx_o, 
	
	
	output 	[5:0] 	led_o,			//	
	
	
	////////////////////////////////////////////////////////////////
	//	CMOS Sensor
	output 			cmos_sclk,
	input 			cmos_sdat_IN,
	output 			cmos_sdat_OUT,
	output 			cmos_sdat_OE,
	
	//	CMOS Interface
	input 			cmos_pclk,
	input 			cmos_vsync,
	input 			cmos_href,
	input 	[7:0] 	cmos_data,
	input 			cmos_ctl1,
	output 			cmos_ctl2,
	output 			cmos_ctl3,
	
	
	////////////////////////////////////////////////////////////////
	//	HDMI Interface
	output 			hdmi_txc_oe,
	output 			hdmi_txd0_oe,
	output 			hdmi_txd1_oe,
	output 			hdmi_txd2_oe,
	
	output 			hdmi_txc_rst_o,
	output 			hdmi_txd0_rst_o,
	output 			hdmi_txd1_rst_o,
	output 			hdmi_txd2_rst_o,
	
	output 	[9:0] 	hdmi_txc_o,
	output 	[9:0] 	hdmi_txd0_o,
	output 	[9:0] 	hdmi_txd1_o,
	output 	[9:0] 	hdmi_txd2_o,
	
	
	////////////////////////////////////////////////////////////////
	//	LVDS Interface
	output 			lvds_txc_oe,
	output 	[6:0] 	lvds_txc_o,
	output 			lvds_txc_rst_o,
	
	output 			lvds_txd0_oe,
	output 	[6:0] 	lvds_txd0_o,
	output 			lvds_txd0_rst_o,
	
	output 			lvds_txd1_oe,
	output 	[6:0] 	lvds_txd1_o,
	output 			lvds_txd1_rst_o,
	
	output 			lvds_txd2_oe,
	output 	[6:0] 	lvds_txd2_o,
	output 			lvds_txd2_rst_o,
	
	output 			lvds_txd3_oe,
	output 	[6:0] 	lvds_txd3_o,
	output 			lvds_txd3_rst_o,
	
	
	////////////////////////////////////////////////////////////////
	//	RGB LCD 5Inch 800x480
	output 			lcd_tp_sda_o,		//	TP SDA
	output 			lcd_tp_sda_oe,
	input 			lcd_tp_sda_i,
	
	output 			lcd_tp_scl_o,		//	TP SCL
	output 			lcd_tp_scl_oe,
	input 			lcd_tp_scl_i,
	
	output 			lcd_tp_int_o,		//	TP INT
	output 			lcd_tp_int_oe,
	input 			lcd_tp_int_i,
	
	output 			lcd_tp_rst_o,		//	TP RST
	
	output 			lcd_pwm_o,			//	Backlight
	output 			lcd_blen_o,
	
	//output 			lcd_pclk_o,			//	PCLK & SCK Mux
	output 			lcd_vs_o,			//	VS & SSN Mux. Fixed to 1. Use DE-Only mode. 
	output 			lcd_hs_o,			//	HS. Fixed to 1. Use DE-Only mode. 
	output 			lcd_de_o,			//	DE. 

	output 	[7:0] 	lcd_b7_0_o,			//	B7:B0. 
	output 	[7:0] 	lcd_g7_0_o,			//	G7:G0. Must output 8'hFF when access SPI. 
	output 	[7:0] 	lcd_r7_0_o,			//	R7:R0. 
	
	output 	[7:0] 	lcd_b7_0_oe,		//	B7:B0. 
	output 	[7:0] 	lcd_g7_0_oe,		//	G7:G0. Must output 8'hFF when access SPI. 
	output 	[7:0] 	lcd_r7_0_oe,		//	R7:R0. 

	input 	[7:0] 	lcd_b7_0_i,			//	B7:B0. 
	input 	[7:0] 	lcd_g7_0_i,			//	G7:G0. Must output 8'hFF when access SPI. 
	input 	[7:0] 	lcd_r7_0_i,			//	R7:R0. 
	
	//	SPI Pins
	output 			spi_sck_o, 
	output 			spi_ssn_o 			
);
	
	wire 			csi_rxd0_fifo_rd_o; 
	wire 			csi_rxd0_fifo_empty_i = 0;  
	wire 			csi_rxd1_fifo_rd_o;  
	wire 			csi_rxd1_fifo_empty_i = 0;  
	wire 			csi_rxd2_fifo_rd_o;  
	wire 			csi_rxd2_fifo_empty_i = 0;  
	wire 			csi_rxd3_fifo_rd_o;  
	wire 			csi_rxd3_fifo_empty_i = 0;  
	
	
	parameter 	SIM_DATA 	= 0; 
	
	//	Hardware Configuration
	assign clk_p_hi = 1'b0;	//	DDR3 Clock requires 180 degree shifted. 
	assign clk_p_lo = 1'b1;
	assign clk_n_hi = 1'b1;
	assign clk_n_lo = 1'b0; 
	
	//	System Clock Tree Control
	assign sys_pll_rstn_o = 1'b1; 	//	nrst; 	//	Reset whole system when nrst (K2) is pressed. 
	
	assign dsi_pll_rstn_o = sys_pll_lock; 
	assign ddr_pll_rstn_o = sys_pll_lock; 
	assign lvds_pll_rstn_o = sys_pll_lock; 
	
	wire 			w_pll_lock = sys_pll_lock && dsi_pll_lock && ddr_pll_lock && lvds_pll_lock; 
	
	//	Synchronize System Resets. 
	reg 			rstn_sys = 0, rstn_pixel = 0; 
	wire 			rst_sys = ~rstn_sys, rst_pixel = ~rstn_pixel; 
	
	reg 			rstn_dsi_refclk = 0, rstn_dsi_byteclk = 0; 
	wire 			rst_dsi_refclk = ~rstn_dsi_refclk, rst_dsi_byteclk = ~rstn_dsi_byteclk; 
	
	reg 			rstn_lvds_1x = 0; 
	wire 			rst_lvds_1x = ~rstn_lvds_1x; 
	
	reg 			rstn_27m = 0, rstn_54m = 0; 
	wire 			rst_27m = ~rstn_27m, rst_54m = ~rstn_54m; 
	
	//	Clock Gen
	always @(posedge clk_27m or negedge w_pll_lock) begin if(~w_pll_lock) rstn_27m <= 0; else rstn_27m <= 1; end
	always @(posedge clk_54m or negedge w_pll_lock) begin if(~w_pll_lock) rstn_54m <= 0; else rstn_54m <= 1; end
	always @(posedge clk_sys or negedge w_pll_lock) begin if(~w_pll_lock) rstn_sys <= 0; else rstn_sys <= 1; end
	always @(posedge clk_pixel or negedge w_pll_lock) begin if(~w_pll_lock) rstn_pixel <= 0; else rstn_pixel <= 1; end
	always @(posedge dsi_refclk_i or negedge w_pll_lock) begin if(~w_pll_lock) rstn_dsi_refclk <= 0; else rstn_dsi_refclk <= 1; end
	always @(posedge dsi_byteclk_i or negedge w_pll_lock) begin if(~w_pll_lock) rstn_dsi_byteclk <= 0; else rstn_dsi_byteclk <= 1; end
	always @(posedge clk_lvds_1x or negedge w_pll_lock) begin if(~w_pll_lock) rstn_lvds_1x <= 0; else rstn_lvds_1x <= 1; end
	
	
	localparam 	CLOCK_MAIN 	= 96000000; 	//	System clock using 96MHz. 
	
	
	
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//	Flash Burner Control
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	wire 			w_ustick, w_mstick; 
	
	wire  [7:0] 	w_dev_index_o;  
	wire  [7:0] 	w_dev_cmd_o;  
	wire  [31:0] 	w_dev_wdata_o;  
	wire  		w_dev_wvalid_o;  
	wire  		w_dev_rvalid_o;  
	wire 	[31:0] 	w_dev_rdata_i;  
	
	wire 			w_spi_ssn_o, w_spi_sck_o; 
	wire 	[3:0] 	w_spi_data_o, w_spi_data_oe; 
	wire 	[3:0] 	w_spi_data_i; 
	
	//	Flash Control
	reg 			r_flash_en = 0; 		//	0x00:0x00 Enable Flash
	
	always @(posedge clk_sys) begin
		r_flash_en <= (w_dev_wvalid_o && (w_dev_index_o == 8'h00) && (w_dev_cmd_o == 8'h00)) ? w_dev_wdata_o : r_flash_en; 
	end
	
	
	
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//	LCD Data Mux
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	wire 	[7:0] 	w_lcd_b_o, w_lcd_g_o, w_lcd_r_o; 
	
	assign lcd_b7_0_o = r_flash_en ? {4'b0, w_spi_data_o[3:2], 2'b0} : w_lcd_b_o; 
	assign lcd_g7_0_o = r_flash_en ? {6'h0, w_spi_data_o[1:0]} : w_lcd_g_o; 
	assign lcd_r7_0_o = r_flash_en ? {8'h00} : w_lcd_r_o; 
	
	assign lcd_b7_0_oe = r_flash_en ? {4'b0, w_spi_data_oe[3:2], 2'b0} : 8'hFF; 
	assign lcd_g7_0_oe = r_flash_en ? {6'h0, w_spi_data_oe[1:0]} : 8'hFF; 
	assign lcd_r7_0_oe = r_flash_en ? {8'h00} : 8'hFF; 
	
	assign spi_sck_o = w_spi_sck_o; 
	assign spi_ssn_o = w_spi_ssn_o; 
	assign w_spi_data_i = {lcd_b7_0_i[3:2], lcd_g7_0_i[1:0]}; 
	
	
	
	
	
	
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//	DDR3 Controller
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	wire			w_ddr3_ui_clk = clk_sys;
	wire			w_ddr3_ui_rst = rst_sys;
	wire			w_ddr3_ui_areset = rst_sys;
	wire			w_ddr3_ui_aresetn = rstn_sys;
	

	//	General AXI Interface 
	wire	[3:0] 	w_ddr3_awid;
	wire	[31:0]	w_ddr3_awaddr;
	wire	[7:0]		w_ddr3_awlen;
	wire			w_ddr3_awvalid;
	wire			w_ddr3_awready;
	
	wire 	[3:0]  	w_ddr3_wid;
	wire 	[127:0] 	w_ddr3_wdata;
	wire 	[15:0]	w_ddr3_wstrb;
	wire			w_ddr3_wlast;
	wire			w_ddr3_wvalid;
	wire			w_ddr3_wready;
	
	wire 	[3:0] 	w_ddr3_bid;
	wire 	[1:0] 	w_ddr3_bresp;
	wire			w_ddr3_bvalid;
	wire			w_ddr3_bready;
	
	wire	[3:0] 	w_ddr3_arid;
	wire	[31:0]	w_ddr3_araddr;
	wire	[7:0]		w_ddr3_arlen;
	wire			w_ddr3_arvalid;
	wire			w_ddr3_arready;
	
	wire 	[3:0] 	w_ddr3_rid;
	wire 	[127:0] 	w_ddr3_rdata;
	wire			w_ddr3_rlast;
	wire			w_ddr3_rvalid;
	wire			w_ddr3_rready;
	wire 	[1:0] 	w_ddr3_rresp;
	
	
	//	AXI Interface Request
	wire 	[3:0] 	w_ddr3_aid;
	wire 	[31:0] 	w_ddr3_aaddr;
	wire 	[7:0]  	w_ddr3_alen;
	wire 	[2:0]  	w_ddr3_asize;
	wire 	[1:0]  	w_ddr3_aburst;
	wire 	[1:0]  	w_ddr3_alock;
	wire			w_ddr3_avalid;
	wire			w_ddr3_aready;
	wire			w_ddr3_atype;
	
	wire 			w_ddr3_cal_done, w_ddr3_cal_pass; 
	
	//	Do not issue DDR read / write when ~cal_done. 
	reg 			r_ddr_unlock = 0; 
	always @(posedge w_ddr3_ui_clk or negedge w_ddr3_ui_aresetn) begin
		if(~w_ddr3_ui_aresetn)
			r_ddr_unlock <= 0; 
		else
			r_ddr_unlock <= w_ddr3_cal_done; 
	end
	
	DdrCtrl ddr3_ctl_axi (	
		.core_clk		(core_clk),
		.tac_clk		(tac_clk),
		.twd_clk		(twd_clk),	
		.tdqss_clk		(tdqss_clk),
		
		.reset		(reset),
		.cs			(cs),
		.ras			(ras),
		.cas			(cas),
		.we			(we),
		.cke			(cke),    
		.addr			(addr),
		.ba			(ba),
		.odt			(odt),
		
		.o_dm_hi		(o_dm_hi),
		.o_dm_lo		(o_dm_lo),
		
		.i_dq_hi		(i_dq_hi),
		.i_dq_lo		(i_dq_lo),
		.o_dq_hi		(o_dq_hi),
		.o_dq_lo		(o_dq_lo),
		.o_dq_oe		(o_dq_oe),
		
		.i_dqs_hi		(i_dqs_hi),
		.i_dqs_lo		(i_dqs_lo),
		.i_dqs_n_hi		(i_dqs_n_hi),
		.i_dqs_n_lo		(i_dqs_n_lo),
		.o_dqs_hi		(o_dqs_hi),
		.o_dqs_lo		(o_dqs_lo),
		.o_dqs_n_hi		(o_dqs_n_hi),
		.o_dqs_n_lo		(o_dqs_n_lo),
		.o_dqs_oe		(o_dqs_oe),
		.o_dqs_n_oe		(o_dqs_n_oe),
		
		.clk			(w_ddr3_ui_clk),
		.reset_n		(w_ddr3_ui_aresetn),
		
		.axi_avalid		(w_ddr3_avalid && r_ddr_unlock),	//	Enable command only when unlocked. 
		.axi_aready		(w_ddr3_aready),
		.axi_aaddr		(w_ddr3_aaddr),
		.axi_aid		(w_ddr3_aid),
		.axi_alen		(w_ddr3_alen),
		.axi_asize		(w_ddr3_asize),
		.axi_aburst		(w_ddr3_aburst),
		.axi_alock		(w_ddr3_alock),
		.axi_atype		(w_ddr3_atype),
		
		.axi_wid		(w_ddr3_wid),
		.axi_wvalid		(w_ddr3_wvalid),
		.axi_wready		(w_ddr3_wready),
		.axi_wdata		(w_ddr3_wdata),
		.axi_wstrb		(w_ddr3_wstrb),
		.axi_wlast		(w_ddr3_wlast),
		
		.axi_bvalid		(w_ddr3_bvalid),
		.axi_bready		(w_ddr3_bready),
		.axi_bid		(w_ddr3_bid),
		.axi_bresp		(w_ddr3_bresp),
		
		.axi_rvalid		(w_ddr3_rvalid),
		.axi_rready		(w_ddr3_rready),
		.axi_rdata		(w_ddr3_rdata),
		.axi_rid		(w_ddr3_rid),
		.axi_rresp		(w_ddr3_rresp),
		.axi_rlast		(w_ddr3_rlast),
		
		.shift		(shift),
		.shift_sel		(),
		.shift_ena		(shift_ena),
		
		.cal_ena		(1'b1),
		.cal_done		(w_ddr3_cal_done),
		.cal_pass		(w_ddr3_cal_pass)
	);
	
	assign w_ddr3_bready = 1'b1; 
	assign shift_sel = 5'b00100; 		//	ddr_tac_clk always use PLLOUT[2]. 
	
	
	AXI4_AWARMux #(.AID_LEN(4), .AADDR_LEN(32)) axi4_awar_mux (
		.aclk_i			(w_ddr3_ui_clk), 
		.arst_i			(w_ddr3_ui_rst), 
		
		.awid_i			(w_ddr3_awid),
		.awaddr_i			(w_ddr3_awaddr),
		.awlen_i			(w_ddr3_awlen),
		.awvalid_i			(w_ddr3_awvalid),
		.awready_o			(w_ddr3_awready),
		
		.arid_i			(w_ddr3_arid),
		.araddr_i			(w_ddr3_araddr),
		.arlen_i			(w_ddr3_arlen),
		.arvalid_i			(w_ddr3_arvalid),
		.arready_o			(w_ddr3_arready),
		
		.aid_o			(w_ddr3_aid),
		.aaddr_o			(w_ddr3_aaddr),
		.alen_o			(w_ddr3_alen),
		.atype_o			(w_ddr3_atype),
		.avalid_o			(w_ddr3_avalid),
		.aready_i			(w_ddr3_aready)
	);
	
	assign w_ddr3_asize = 4; 		//	Fixed 128 bits (16 bytes, size = 4)
	assign w_ddr3_aburst = 1; 
	assign w_ddr3_alock = 0; 
	
	//assign led_o[1:0] = {w_ddr3_cal_pass, w_ddr3_cal_done}; 
    //assign led_o[5:0] = 6'b100111;
	
	
	
	
	////////////////////////////////////////////////////////////////
	//	I2C Config (SC130GS)
	
	//  i2c timing controller module of 16Bit
    //wire en_i2c_config_ae;
    //wire [23:0]  a2020_config_00,a2020_config_01,a2020_config_02;
	wire            [ 7:0]          sc130_i2c_config_index;
	wire            [23:0]          sc130_i2c_config_data;
	wire            [ 7:0]          sc130_i2c_config_size;
	wire                            sc130_i2c_config_done;
	wire            [5:0]           debug_out;
	i2c_timing_ctrl_16bit
	#(
	    .CLK_FREQ           (CLOCK_MAIN),                              //  100 MHz
	    .I2C_FREQ           (10_000    )                               //  10 KHz(<= 400KHz)
	) u_i2c_timing_ctrl_16bit (
	    //  global clock
	    .clk                (clk_sys                 ),                          //  96MHz
	    .rst_n              (rstn_sys                ),                          //  system reset

	    //  i2c interface
	    .i2c_sclk           (csi_scl_o               ),                          //  i2c clock
	    .i2c_sdat_IN        (csi_sda_i               ),
	    .i2c_sdat_OUT       (csi_sda_o               ),
	    .i2c_sdat_OE        (csi_sda_oe              ),

	    //  i2c config data
	    .i2c_config_index   (sc130_i2c_config_index        ),                          //  i2c config reg index, read 2 reg and write xx reg
	    .i2c_config_data    ({8'h6a, sc130_i2c_config_data}),                     //  i2c config data
	    .i2c_config_size    (sc130_i2c_config_size         ),                          //  i2c config data counte
	    .i2c_config_done    (sc130_i2c_config_done         ),                          //  i2c config timing complete
        .en_i2c_config_ext  ( en_i2c_config_ae  ),
	    .config_data_ext00 ({8'h6a, a2020_config_00}),
	    .config_data_ext01 ({8'h6a, a2020_config_01}),
	    .config_data_ext02 ({8'h6a, a2020_config_02}),
        .debug_out           (debug_out),
		.config_clk                        (w_csi_rx_clk                ),
		.config_data                       (config_data               ),
		.config_data_valid                 (config_data_valid         ) 
	
		);
	assign csi_scl_oe = 1; 
	//  I2C Configure Data of SC130GS
	I2C_AD2020_1280960_FPS60_1Lane_Config u_I2C_AD2020_1280960_FPS60_1Lane_Config 
	(
	    .LUT_INDEX  (sc130_i2c_config_index   ),
	    .LUT_DATA   (sc130_i2c_config_data    ),
	    .LUT_SIZE   (sc130_i2c_config_size    )
	);



	
	//	Output LED
	reg 	[3:0]		r_cmos_fv_o = 0; 
	reg 	[1:0] 	r_cmos_rx_vsync0_in = 0; 
	always @(posedge cmos_pclk) begin
		r_cmos_rx_vsync0_in <= {r_cmos_rx_vsync0_in, cmos_vsync}; 
		r_cmos_fv_o <= r_cmos_fv_o + ((r_cmos_rx_vsync0_in == 2'b01) ? 1 : 0); 
	end

	
	
	////////////////////////////////////////////////////////////////
	//	System Control. Can be removed for public. 
	
	localparam 	CLK_FREQ 	= 96_000_000; 	//	clk_sys is 96MHz. 
	localparam 	BAUD_RATE 	= 460_800; 		//	Use 460800-8-N-1. 
	
	
	//	SFR I/O Interface
	wire 	[7:0] 	w_sfr_addr_o; 	//	SFR Address (0xFF00 ~ 0xFFFF). 00:Power; 40~5F:Stream0; 60~7F:Stream1. 
	wire 	[7:0] 	w_sfr_wdata_o; 	//	SFR Write Data. 
	wire 			w_sfr_we_o; 		//	SFR WE. 
	reg 	[7:0] 	w_sfr_rdata_i; 	//	Must be valid after sfr_rd_o. 
	wire 			w_sfr_rd_o; 		//	SFR RD. 
	
	
	//	System Control Registers
	reg 			r_dsi_tx_rstn = 0; 	//	DSI TX Reset
	reg 	[7:0] 	r_dsi_pwm = 64; 		//	[6:0]PWM, [7]Pol
	reg 			r_dsi_resetn_o = 0; 	//	DSI Panel Reset
	reg 			r_dsi_data_rstn = 0; 	//	DSI TX Reset
	
	reg 	[3:0] 	r_dsi_lp_p_ovr = 0; 	
	reg 	[3:0] 	r_dsi_lp_n_ovr = 0; 	
	
	
	
	//	AXI-Lite Interface Bridge
	localparam 	CSI_AXILITE_ID 	= 0; 				//	Select DSI_TX when r_axi_sel = DSI_AXILITE_ID. 
	localparam 	DSI_AXILITE_ID 	= 1; 				//	Select DSI_TX when r_axi_sel = DSI_AXILITE_ID. 
	
	reg 	[7:0] 	r_axi_addr = 8'h18; 		//	0xE0 (RW)
	reg 	[31:0] 	r_axi_wdata = 32'h0000000A; 	//	0xE1~0xE4 (RW)
	wire 	[31:0] 	w_axi_rdata; 			//	0xE5~0xE8 (RO)
	reg 	[0:0] 	r_axi_sel = 1; 			//	0xE9[7:2] (RW)
	reg 			r_axi_r1w0 = 0; 			//	0xE9[1] (RW)
	reg 			r_axi_req = 0; 			//	0xE9[0] (WO, Single Cycle)
	reg 			r_axi_req_o = 0; 			//	Delayed of r_axi_req. 
	
	
	//	Buffered AXI Read Data
	reg 	[31:0] 	r_axi_rdata = 0; 		//	Use state machine
	reg 			r_axi_idle = 0; 		//	AXI Idle 
	
	reg 	[3:0] 	rs_axilite = 0; 		//	AXI Access
	wire 	[3:0] 	ws_axilite_idle = 0; 		
	wire 	[3:0] 	ws_axilite_write = 1; 
	wire 	[3:0] 	ws_axilite_read = 2; 
	wire 	[3:0] 	ws_axilite_endread = 3; 
	
	reg 			r_axi_awvalid = 0, r_axi_wvalid = 0, r_axi_arvalid = 0; 
	wire 			w_axi_awready, w_axi_wready, w_axi_arready, w_axi_rvalid; 
	
	
	reg 	[3:0] 	rc_axi_init = 0; 

	always @(posedge clk_sys or posedge rst_sys) begin
		if(rst_sys) begin
			r_dsi_tx_rstn <= 0; 
			r_dsi_pwm <= 64; 
			r_axi_req <= 0; 
			r_dsi_resetn_o <= 0; 
			r_dsi_data_rstn <= 0; 
			
			rs_axilite <= 0; 
			r_axi_awvalid <= 0; 
			r_axi_wvalid <= 0;
			r_axi_arvalid <= 0; 
			
			r_dsi_lp_p_ovr <= 0; 
			r_dsi_lp_n_ovr <= 0; 
			
			rc_axi_init <= 0; 
			r_axi_idle <= 0; 
			
		end else begin
			r_dsi_tx_rstn <= 1; 
			r_dsi_resetn_o <= 1; 
			r_dsi_data_rstn <= 1; 
			
		end
	end
	
	assign dsi_resetn_o = r_dsi_resetn_o; 
	
	assign csi_ctl0_oe = 0; 
	assign csi_ctl1_oe = 0; 
	
	
	PWMLite dsi_pwm (		//	#(.ENABLE_TICK(0), .PWM_BITS(7)) 
		.clk_i			(clk_sys),
		.rst_i			(rst_sys),
		.pwm_i			(r_dsi_pwm[6:0]),
		.pol_i			(r_dsi_pwm[7]), 
		.pwm_o			(dsi_pwm_o)
	);






	////////////////////////////////////////////////////////////////
	//	MIPI CSI RX
	wire                                    empty_o                    ;
wire                                    wr_en                      ;
wire                   [  31:0]         wr_data                    ;
wire                   [   7:0]         rd_data                    ;
wire                                    prepare_vsync              ;
wire                                    prepare_valid              ;
wire                   [   7:0]         prepare_data               ;
wire                   [  10:0]         rd_count                   ;
reg                                     rd_en                      ;
reg                    [  10:0]         pixel_cnt                  ;
	
	//	The CSI RXC shall not be inverted. Data can be inverted with swapped LP data and flipped HS data. 
	// localparam 	CSI_RXD_INV 	= 4'b1111; 
	// localparam 	CSI_RXD_INV 	= 4'b0000; 
	localparam 	CSI_RXD_INV 	= 4'b0000; 
	// localparam 	CSI_RXD_INV 	= 4'b0001; 
	localparam 	CSI_DATA_WIDTH 	= 8; 			
	localparam 	CSI_STRB_WIDTH 	= CSI_DATA_WIDTH / 8; 

	//	Current implementation supports RAW8 only. 
	wire 			w_csi_rx_clk; 

	wire 			w_csi_rx_vsync0, w_csi_rx_hsync0, w_csi_rx_dvalid; 
	wire 	[63:0] 	w_csi_rx_data; 
	wire 	[47:0] 	w_csi_rx_data_rel_raw; 
	
	//	AXI Interface
	wire 	[31:0] 	w_csi_axi_rdata; 
	wire 			w_csi_axi_awready, w_csi_axi_wready, w_csi_axi_arready, w_csi_axi_rvalid; 
	
	
	
	
	
	wire [7:0] data_typer;
	//	Reset pixel 16 cycles after ~vsync. 
	reg 			r_reset_pixen_n = 0; 
	reg 	[1:0] 	r_csi_rx_vsync0_i = 0; 
	reg 	[3:0] 	rc_csi_rx_vsync0_f = 0; 
	always @(posedge w_csi_rx_clk or negedge rstn_sys) begin
		if(~rstn_sys) begin
			r_reset_pixen_n <= 0; 
			r_csi_rx_vsync0_i <= 0; 
			rc_csi_rx_vsync0_f <= 0; 
		end else begin
			r_csi_rx_vsync0_i <= {r_csi_rx_vsync0_i, w_csi_rx_vsync0}; 
			if(r_csi_rx_vsync0_i == 2'b10) 
				rc_csi_rx_vsync0_f <= 1; 
			else
				rc_csi_rx_vsync0_f <= rc_csi_rx_vsync0_f + (|rc_csi_rx_vsync0_f); 
			r_reset_pixen_n <= (&rc_csi_rx_vsync0_f) ? 0 : 1; 
		end
	end

	// `define PRI_IP
	`ifdef PRI_IP
	wire 	[7:0] 	w_mipi_d0 = (CSI_RXD_INV[0] ? 8'hFF : 8'h00) ^ csi_rxd0_hs_i; 
	wire 	[7:0] 	w_mipi_d1 = (CSI_RXD_INV[1] ? 8'hFF : 8'h00) ^ csi_rxd1_hs_i; 
	wire 	[7:0] 	w_mipi_d2 = (CSI_RXD_INV[2] ? 8'hFF : 8'h00) ^ csi_rxd2_hs_i; 
	wire 	[7:0] 	w_mipi_d3 = (CSI_RXD_INV[3] ? 8'hFF : 8'h00) ^ csi_rxd3_hs_i; 
	MIPIRx1LaneFre mipi0_rx (
		.sclk_i			(clk_sys), 
		.srst_i			(rst_sys), 
		
		.mipi_rx_byteclk_i	(csi_rxc_i), 
		.mipi_rx_d0_i		({w_mipi_d0[0], w_mipi_d0[1], w_mipi_d0[2], w_mipi_d0[3], w_mipi_d0[4], w_mipi_d0[5], w_mipi_d0[6], w_mipi_d0[7]}), 
		.mipi_rx_d1_i		({w_mipi_d1[0], w_mipi_d1[1], w_mipi_d1[2], w_mipi_d1[3], w_mipi_d1[4], w_mipi_d1[5], w_mipi_d1[6], w_mipi_d1[7]}), 
		.mipi_rx_d2_i		({w_mipi_d2[0], w_mipi_d2[1], w_mipi_d2[2], w_mipi_d2[3], w_mipi_d2[4], w_mipi_d2[5], w_mipi_d2[6], w_mipi_d2[7]}), 
		.mipi_rx_d3_i		({w_mipi_d3[0], w_mipi_d3[1], w_mipi_d3[2], w_mipi_d3[3], w_mipi_d3[4], w_mipi_d3[5], w_mipi_d3[6], w_mipi_d3[7]}), 
		.mipi_rx_clk_lp_p_i	(csi_rxc_lp_p_i), 
		.mipi_rx_clk_lp_n_i	(csi_rxc_lp_n_i), 
		.mipi_rx_d0_lp_p_i	(CSI_RXD_INV[0] ? csi_rxd0_lp_n_i : csi_rxd0_lp_p_i), 
		.mipi_rx_d0_lp_n_i	(CSI_RXD_INV[0] ? csi_rxd0_lp_p_i : csi_rxd0_lp_n_i), 
		.mipi_rx_rst_o		(), 
		.mipi_rx_rst_n_o		(), 
		.mipi_rx_clk_hs_en_o	(csi_rxc_hs_en_o), 
		.mipi_rx_dat_hs_en_o	(csi_rxd0_hs_en_o), 
		.mipi_rx_clk_term_en_o	(csi_rxc_hs_term_en_o), 
		.mipi_rx_dat_term_en_o	(csi_rxd0_hs_term_en_o), 
		
		.CLK				(w_csi_rx_clk), 
		.VSYNC			(w_csi_rx_vsync0), 
		.HSYNC			(w_csi_rx_hsync0), 
		.DE				(w_csi_rx_dvalid), 
		.DAT				(w_csi_rx_data_rel_raw)
	);
	assign w_csi_rx_data = {2{w_csi_rx_data_rel_raw[47:40], w_csi_rx_data_rel_raw[35:28], w_csi_rx_data_rel_raw[23:16], w_csi_rx_data_rel_raw[11:4]}}; 
	assign {csi_rxd3_hs_en_o, csi_rxd2_hs_en_o, csi_rxd1_hs_en_o} = {3{csi_rxd0_hs_en_o}}; 
	assign {csi_rxd3_hs_term_en_o, csi_rxd2_hs_term_en_o, csi_rxd1_hs_term_en_o} = {3{csi_rxd0_hs_term_en_o}}; 
assign wr_data = {w_csi_rx_data_rel_raw[39:32], w_csi_rx_data_rel_raw[29:22],w_csi_rx_data_rel_raw[19:12], w_csi_rx_data_rel_raw[9:2]} ;

`else
	
	assign w_csi_rx_clk = clk_sys; 
    csi_rx mipi_rx_0(
    .reset_n                           (rstn_sys                  ),
    .clk                               (w_csi_rx_clk              ),
    .reset_byte_HS_n                   (rstn_sys                  ),
    .clk_byte_HS                       (csi_rxc_i                 ),
    .reset_pixel_n                     (r_reset_pixen_n           ),//rstn_sys), 
    .clk_pixel                         (w_csi_rx_clk              ),
    // .Rx_LP_CLK_P                       (    csi_rxc_lp_n_i        ),
    // .Rx_LP_CLK_N                       (    csi_rxc_lp_p_i        ),
    .Rx_LP_CLK_P                       (csi_rxc_lp_p_i         ),
    .Rx_LP_CLK_N                       (csi_rxc_lp_n_i         ),

    .Rx_HS_enable_C                    (csi_rxc_hs_en_o           ),
    .LVDS_termen_C                     (csi_rxc_hs_term_en_o      ),
		
		//	Lane inversion affects HS & LP data only. 
    .Rx_LP_D_P                         ({CSI_RXD_INV[3] ? csi_rxd3_lp_n_i : csi_rxd3_lp_p_i, CSI_RXD_INV[2] ? csi_rxd2_lp_n_i : csi_rxd2_lp_p_i, CSI_RXD_INV[1] ? csi_rxd1_lp_n_i : csi_rxd1_lp_p_i, CSI_RXD_INV[0] ? csi_rxd0_lp_n_i : csi_rxd0_lp_p_i}),
    .Rx_LP_D_N                         ({CSI_RXD_INV[3] ? csi_rxd3_lp_p_i : csi_rxd3_lp_n_i, CSI_RXD_INV[2] ? csi_rxd2_lp_p_i : csi_rxd2_lp_n_i, CSI_RXD_INV[1] ? csi_rxd1_lp_p_i : csi_rxd1_lp_n_i, CSI_RXD_INV[0] ? csi_rxd0_lp_p_i : csi_rxd0_lp_n_i}),
    .Rx_HS_D_0                         ((CSI_RXD_INV[0] ? 8'hFF : 8'h00) ^ csi_rxd0_hs_i),
    .Rx_HS_D_1                         ((CSI_RXD_INV[1] ? 8'hFF : 8'h00) ^ csi_rxd1_hs_i),
    .Rx_HS_D_2                         ((CSI_RXD_INV[2] ? 8'hFF : 8'h00) ^ csi_rxd2_hs_i),
    .Rx_HS_D_3                         ((CSI_RXD_INV[3] ? 8'hFF : 8'h00) ^ csi_rxd3_hs_i),
    .Rx_HS_D_4                         (                          ),
    .Rx_HS_D_5                         (                          ),
    .Rx_HS_D_6                         (                          ),
    .Rx_HS_D_7                         (                          ),
		
    .Rx_HS_enable_D                    ({csi_rxd3_hs_en_o, csi_rxd2_hs_en_o, csi_rxd1_hs_en_o, csi_rxd0_hs_en_o}),
    .LVDS_termen_D                     ({csi_rxd3_hs_term_en_o, csi_rxd2_hs_term_en_o, csi_rxd1_hs_term_en_o, csi_rxd0_hs_term_en_o}),
    .fifo_rd_enable                    ({csi_rxd3_fifo_rd_o, csi_rxd2_fifo_rd_o, csi_rxd1_fifo_rd_o, csi_rxd0_fifo_rd_o}),
    .fifo_rd_empty                     ({csi_rxd3_fifo_empty_i, csi_rxd2_fifo_empty_i, csi_rxd1_fifo_empty_i, csi_rxd0_fifo_empty_i}),
    .DLY_enable_D                      (                          ),
    .DLY_inc_D                         (                          ),
    .u_dly_enable_D                    (0                         ),
    .u_dly_inc_D                       (                          ),
		
    .vsync_vc1                         (                          ),
    .vsync_vc15                        (                          ),
    .vsync_vc12                        (                          ),
    .vsync_vc9                         (                          ),
    .vsync_vc7                         (                          ),
    .vsync_vc14                        (                          ),
    .vsync_vc13                        (                          ),
    .vsync_vc11                        (                          ),
    .vsync_vc10                        (                          ),
    .vsync_vc8                         (                          ),
    .vsync_vc6                         (                          ),
    .vsync_vc4                         (                          ),
    .vsync_vc0                         (w_csi_rx_vsync0           ),
    .vsync_vc5                         (                          ),
    .vsync_vc3                         (                          ),
    .vsync_vc2                         (                          ),
	
    .irq                               (                          ),
		
    .pixel_data_valid                  (w_csi_rx_dvalid           ),
    .pixel_data                        (w_csi_rx_data             ),
    .pixel_per_clk                     (                          ),
    .datatype                          (data_typer                ),
    .shortpkt_data_field               (                          ),
    .word_count                        (                          ),
    .vcx                               (                          ),
    .vc                                (                          ),
    .hsync_vc3                         (                          ),
    .hsync_vc2                         (                          ),
    .hsync_vc8                         (                          ),
    .hsync_vc12                        (                          ),
    .hsync_vc7                         (                          ),
    .hsync_vc10                        (                          ),
    .hsync_vc1                         (                          ),
    .hsync_vc0                         (w_csi_rx_hsync0           ),
    .hsync_vc13                        (                          ),
    .hsync_vc4                         (                          ),
    .hsync_vc11                        (                          ),
    .hsync_vc6                         (                          ),
    .hsync_vc9                         (                          ),
    .hsync_vc15                        (                          ),
    .hsync_vc14                        (                          ),
    .hsync_vc5                         (                          ),
		
    .axi_clk                           (clk_sys                   ),
    .axi_reset_n                       (rstn_sys                  ),
		
    .axi_awaddr                        (r_axi_addr                ),
    .axi_awvalid                       ((r_axi_sel == CSI_AXILITE_ID) && r_axi_awvalid),
    .axi_awready                       (w_csi_axi_awready         ),
	
    .axi_wvalid                        ((r_axi_sel == CSI_AXILITE_ID) && r_axi_wvalid),
    .axi_wdata                         (r_axi_wdata               ),
    .axi_wready                        (w_csi_axi_wready          ),
	
    .axi_bvalid                        (                          ),
    .axi_bready                        (1                         ),
		
    .axi_araddr                        (r_axi_addr                ),
    .axi_arvalid                       ((r_axi_sel == CSI_AXILITE_ID) && r_axi_arvalid),
    .axi_arready                       (w_csi_axi_arready         ),
		
    .axi_rready                        (1                         ),
    .axi_rvalid                        (w_csi_axi_rvalid          ),
    .axi_rdata                         (w_csi_axi_rdata           ) 
		
    );
assign wr_data = {w_csi_rx_data[39:32], w_csi_rx_data[29:22],w_csi_rx_data[19:12], w_csi_rx_data[9:2]} ;

`endif 
	assign csi_rxd0_rst_o = rst_sys; 
	assign csi_rxd1_rst_o = rst_sys; 
	assign csi_rxd2_rst_o = rst_sys; 
	assign csi_rxd3_rst_o = rst_sys; 
	
	
	//	Output LED
	reg 	[5:0]		r_csi_fv_o = 0; 
	reg 	[1:0] 	r_csi_rx_vsync0_in = 0; 
	always @(posedge w_csi_rx_clk) begin
		r_csi_rx_vsync0_in <= {r_csi_rx_vsync0_in, w_csi_rx_vsync0}; 
		r_csi_fv_o <= r_csi_fv_o + ((r_csi_rx_vsync0_in == 2'b01) ? 1 : 0); 
	end
	//assign led_o[4] = r_csi_fv_o[5]; 



wire [10:0] cnt_pixel;
wire [10:0] cnt_row;

Row_Line_Counter  u_Row_Line_Counter (
    .Data_clk                          (w_csi_rx_clk               ),
    .Data_rst_n                        (rstn_sys             ),
    .Data_vsync                        (w_csi_rx_vsync0         ),
    .Data_hsync                        (w_csi_rx_hsync0         ),//用于统计行
    .Data_valid                        (w_csi_rx_dvalid         ),//用于统计每一行的像素

    .cnt_pixel                         (cnt_pixel   [10:0]),
    .cnt_row                           (cnt_row     [10:0]) 
);
// =========================================================================================================================================
// data 32 to 8
// ========================================================================================================================================= 

//c1
// assign wr_data = {w_csi_rx_data[9:2], w_csi_rx_data[19:12], w_csi_rx_data[29:22], w_csi_rx_data[39:32]} ;
assign wr_en = w_csi_rx_hsync0 && w_csi_rx_dvalid;

always@(posedge w_csi_rx_clk or negedge rstn_sys)
begin
	if(!rstn_sys)
		begin
			rd_en   <=  'd0 ;
		end
	else if(pixel_cnt == 1279)
		begin
			rd_en   <=  'd0 ;
		end
	else if(rd_count >=1280)
		begin
			rd_en   <=  1;
		end
	else
		begin
			rd_en   <=  rd_en ;
		end
end
always@(posedge w_csi_rx_clk or negedge rstn_sys)
begin
	if(!rstn_sys)
		begin
			pixel_cnt   <=  'd0 ;
		end
	else if(pixel_cnt == 1279)
		begin
			pixel_cnt   <=  'd0 ;
		end
	else if(rd_en)
		begin
			pixel_cnt   <=  pixel_cnt + 1 ;
		end
	else
		begin
			pixel_cnt   <=  'd0 ;
		end
end
//c2
afifo_w32r8_reshape u_afifo_w32r8_reshape
(
	.full_o                            (                          ),
    .rst_busy                          (                          ),
	.empty_o                           (empty_o                   ),
    .a_rst_i                           (~rstn_sys              ),
   
    .wr_clk_i                          (w_csi_rx_clk                ),
    .wdata                             (wr_data                   ),
    .wr_en_i                           (wr_en                     ),
    .wr_datacount_o                    (                          ),
    
    .rd_clk_i                          (w_csi_rx_clk                ),
    .rd_en_i                           (rd_en                     ),
    .rdata                             (rd_data                   ),
    .rd_datacount_o                    (rd_count                  ) 
);
//c3
wire                                    delay_vsync                ;
delay_reg #(.delay_level(1280),.reg_width(1)) DR0(
    .clk                               (w_csi_rx_clk                ),
    .rst                               (~rstn_sys              ),
    .din                               (w_csi_rx_vsync0      ),

    .dout                              (delay_vsync               ) 
);
assign prepare_vsync = delay_vsync;
assign prepare_valid = rd_en;
assign prepare_data = rd_data;
// =========================================================================================================================================
// DPC
// ========================================================================================================================================= 
// wire                                    post_frame_vsync           ;
// wire                                    post_frame_href            ;
// wire                                    post_frame_hsync           ;
// wire                   [   7:0]         final_data                 ;
// bad_dot_improve #(
//     .IMG_HDISP                         (1280                      ),
//     .IMG_VDISP                         (960 )                     ) 
//  u_bad_dot_improve (
//     .clk                               (w_csi_rx_clk                ),
//     .rst_n                             (rstn_sys               ),
//     .per_frame_vsync                   (prepare_vsync             ),
//     .per_frame_href                    (prepare_valid             ),
//     .per_frame_hsync                   (prepare_valid             ),
//     .per_img_RAW                       (prepare_data       [   7:0]),

//     .post_frame_vsync                  (post_frame_vsync          ),
//     .post_frame_href                   (post_frame_href           ),
//     .post_frame_hsync                  (post_frame_hsync          ),
//     .final_data                        (final_data        [   7:0]) 
// );
// =========================================================================================================================================
// XYCrop
// ========================================================================================================================================= 
	wire			XYCrop_frame_vsync; 
	wire			XYCrop_frame_href;
	wire			XYCrop_frame_de;
	wire	[7:0]	XYCrop_frame_Gray;

    Sensor_Image_XYCrop
    #(
    .IMAGE_HSIZE_SOURCE                (1280 / CSI_STRB_WIDTH     ),
    .IMAGE_VSIZE_SOURCE                (960                       ),
    .IMAGE_HSIZE_TARGET                (1280 / CSI_STRB_WIDTH     ),
    .IMAGE_YSIZE_TARGET                (720                       ),
    .PIXEL_DATA_WIDTH                  (8                        ) //	32		 )
    )
    u_Sensor_Image_XYCrop
    (
		//	globel clock
    .clk                               (w_csi_rx_clk              ),//	image pixel clock
    .rst_n                             (rstn_sys                  ),//	system reset
		
		//CMOS Sensor interface
    .image_in_vsync                    (prepare_vsync           ),//H : Data Valid; L : Frame Sync(Set it by register)
    .image_in_href                     (prepare_valid       ),//H : Data vaild, L : Line Sync
    .image_in_de                       (prepare_valid            ),//H : Data Enable, L : Line Sync
    .image_in_data                     (prepare_data),//8 bits cmos data input
    // .image_in_vsync                    (post_frame_vsync           ),//H : Data Valid; L : Frame Sync(Set it by register)
    // .image_in_href                     (post_frame_href &&    post_frame_hsync        ),//H : Data vaild, L : Line Sync
    // .image_in_de                       (post_frame_href &&    post_frame_hsync             ),//H : Data Enable, L : Line Sync
    // .image_in_data                     (final_data),//8 bits cmos data input
		
    .image_out_vsync                   (XYCrop_frame_vsync        ),//H : Data Valid; L : Frame Sync(Set it by register)
    .image_out_href                    (XYCrop_frame_href         ),//H : Data vaild, L : Line Sync
    .image_out_de                      (XYCrop_frame_de           ),//H : Data Enable, L : Line Sync
    .image_out_data                    (XYCrop_frame_Gray         ) //8 bits cmos data input	
    );

	reg			r_XYCrop_frame_vsync = 0; 
	reg			r_XYCrop_frame_href = 0;
	reg			r_XYCrop_frame_de = 0;
	reg	[63:0]	r_XYCrop_frame_Gray = 0;
	
	always @(posedge w_csi_rx_clk) begin
		r_XYCrop_frame_vsync <= XYCrop_frame_vsync; 
		r_XYCrop_frame_href <= XYCrop_frame_href;
		r_XYCrop_frame_de <= XYCrop_frame_de;
		r_XYCrop_frame_Gray <= XYCrop_frame_Gray;
	end
	
	//	Data Write Assignment
	wire			cmos_frame_vsync = r_XYCrop_frame_vsync;                     //  cmos frame data vsync valid signal
	wire			cmos_frame_href = r_XYCrop_frame_href && r_XYCrop_frame_de;	 //  cmos frame data href vaild  signal
	wire	[7:0]	cmos_frame_Gray = r_XYCrop_frame_Gray; 

	//c1 crop data
wire                                    crop_vsync                 ;
wire                                    crop_valid                 ;
wire                   [   7:0]         crop_data                  ;
assign crop_vsync = r_XYCrop_frame_vsync;
assign crop_valid = cmos_frame_href ;
assign crop_data = cmos_frame_Gray;
// =========================================================================================================================================
// P1_Bayer2rgb
// ========================================================================================================================================= 
wire 			w_rgb_vsync, w_rgb_hsync, w_rgb_href; 
wire 	[7:0] 	w_rgb_r, w_rgb_g, w_rgb_b; 
wire [11:0] cnt_bayer_pixel;
wire [11:0] cnt_bayer_row  ;
VIP_RAW8_RGB888 #(.IMG_HDISP(1280), .IMG_VDISP(720)) ori_bayer2rgb (
    .clk                               (w_csi_rx_clk                ),//cmos video pixel clock
    .rst_n                             (rstn_sys               ),//global reset
	
    .mirror                            (2'b11                     ),

		//CMOS YCbCr444 data output
    .per_frame_vsync                   (crop_vsync                ),//Prepared Image data vsync valid signal. Reset on falling edge. 
    .per_frame_hsync                   (crop_valid                ),//Prepared Image data href vaild  signal
    .per_frame_href                    (crop_valid                ),//Prepared Image data href vaild  signal
    .per_img_RAW                       (crop_data                 ),//Prepared Image data 8 Bit RAW Data

    .post_frame_vsync                  (w_rgb_vsync               ),//Processed Image data vsync valid signal
    .post_frame_hsync                  (w_rgb_hsync               ),//Processed Image data href vaild  signal
    .post_frame_href                   (w_rgb_href                ),//Processed Image data href vaild  signal
    .post_img_red                      (w_rgb_r                   ),//Prepared Image green data to be processed 
    .post_img_green                    (w_rgb_g                   ),//Prepared Image green data to be processed
    .post_img_blue                     (w_rgb_b                   ) //Prepared Image blue data to be processed
);
// =========================================================================================================================================
//P2_MWB
// ========================================================================================================================================= 
//c1
wire                                    rgb_vsync                  ;
wire                                    rgb_valid                  ;
wire                   [  23:0]         rgb_data                   ;
wire                   [   7:0]         w_mwb_rgb_r                ;
wire                   [   7:0]         w_mwb_rgb_g                ;
wire                   [   7:0]         w_mwb_rgb_b                ;
wire     [17:0]     w_rgb_r_mult = w_rgb_r * 409; 
wire     [17:0]     w_rgb_b_mult = w_rgb_b * 384; 
assign w_mwb_rgb_r = w_rgb_r_mult[17:16] ? 8'hFF : w_rgb_r_mult[15: 8]; 
assign w_mwb_rgb_g = w_rgb_g; 
assign w_mwb_rgb_b = w_rgb_b_mult[17:16] ? 8'hFF : w_rgb_b_mult[15: 8]; 
//c2
assign rgb_vsync = w_rgb_vsync;
assign rgb_valid = w_rgb_href;
assign rgb_data = {w_mwb_rgb_r,w_mwb_rgb_g,w_mwb_rgb_b};

// =========================================================================================================================================
// DDR Ctrl
// ========================================================================================================================================= 
	wire                            lcd_de;
	wire                            lcd_hs;      
	wire                            lcd_vs;
	wire 					  lcd_request; 
	wire            [7:0]           lcd_red, lcd_red2;
	wire            [7:0]           lcd_green, lcd_green2;
	wire            [7:0]           lcd_blue, lcd_blue2;
	wire            [31:0]          lcd_data;


	assign w_ddr3_awid = 0; 
	assign w_ddr3_wid = 0; 
	
	wire 			w_wframe_vsync; 
	wire 	[7:0] 	w_axi_tp; 
	
	axi4_ctrl #(.C_RD_END_ADDR(1280 * 720 *4), .C_W_WIDTH(32), .C_R_WIDTH(32), .C_ID_LEN(4)) u_axi4_ctrl (

		.axi_clk        (w_ddr3_ui_clk            ),
		.axi_reset      (w_ddr3_ui_rst            ),

		.axi_awaddr     (w_ddr3_awaddr       ),
		.axi_awlen      (w_ddr3_awlen        ),
		.axi_awvalid    (w_ddr3_awvalid      ),
		.axi_awready    (w_ddr3_awready      ),

		.axi_wdata      (w_ddr3_wdata        ),
		.axi_wstrb      (w_ddr3_wstrb        ),
		.axi_wlast      (w_ddr3_wlast        ),
		.axi_wvalid     (w_ddr3_wvalid       ),
		.axi_wready     (w_ddr3_wready       ),

		.axi_bid        (0          ),
		.axi_bresp      (0        ),
		.axi_bvalid     (1       ),

		.axi_arid       (w_ddr3_arid         ),
		.axi_araddr     (w_ddr3_araddr       ),
		.axi_arlen      (w_ddr3_arlen        ),
		.axi_arvalid    (w_ddr3_arvalid      ),
		.axi_arready    (w_ddr3_arready      ),

		.axi_rid        (w_ddr3_rid          ),
		.axi_rdata      (w_ddr3_rdata        ),
		.axi_rresp      (0        ),
		.axi_rlast      (w_ddr3_rlast        ),
		.axi_rvalid     (w_ddr3_rvalid       ),
		.axi_rready     (w_ddr3_rready       ),

		.wframe_pclk    (w_csi_rx_clk          ),
		.wframe_vsync   (rgb_vsync), //w_wframe_vsync   ),		//	Writter VSync. Flush on rising edge. Connect to EOF. 
		.wframe_data_en (rgb_valid   ),
		.wframe_data    ({8'b0,rgb_data} ),
		
		.rframe_pclk    (clk_pixel            ),
		.rframe_vsync   (~lcd_vs             ),		//	Reader VSync. Flush on rising edge. Connect to ~EOF. 
		.rframe_data_en (lcd_request             ),
		.rframe_data    (lcd_data           ),
		
		.tp_o 		(w_axi_tp)
	);
	//assign led_o[3:0] = w_axi_tp; 
// =========================================================================================================================================
// lcd_driver
// ========================================================================================================================================= 
	
wire [11:0] x_pos;
wire [11:0] y_pos;
wire [23:0] char_data;
wire data_enable;
wire data_enable2;


    lcd_driver u_lcd_driver
    (
	    //  global clock
    .clk                               (clk_pixel                 ),
    .rst_n                             (rstn_pixel                ),
	    
	    //  lcd interface
    .lcd_dclk                          (                          ),
    .lcd_blank                         (                          ),
    .lcd_sync                          (                          ),
    .lcd_request                       (lcd_request               ),//	Request data 1 cycle ahead. 
    .lcd_hs                            (lcd_hs                    ),
    .lcd_vs                            (lcd_vs                    ),
    .lcd_en                            (lcd_de                    ),
    .lcd_rgb                           ({lcd_red2,lcd_green2,lcd_blue2, lcd_red,lcd_green,lcd_blue}),
	    
	    //  user interface
    .lcd_data                          ({lcd_data[23:0] ,lcd_data[23:0]}),
    .lcd_xpos                          (x_pos                     ),
    .lcd_ypos                          (y_pos                     ) 
    );
	
	// wire [23:0] hdmi_data = (data_enable||data_enable2)? char_data : {lcd_red,lcd_green,lcd_blue}    ;
	wire [23:0] hdmi_data =  {lcd_red,lcd_green,lcd_blue}    ;
// =========================================================================================================================================
// BoundCrop
// ========================================================================================================================================= 

wire                                    w_rgb_vs_o, w_rgb_hs_o, w_rgb_de_o;
wire                   [  23:0]         w_rgb_data_o               ;
FrameBoundCrop #(.SKIP_ROWS(4),.SKIP_COLS(2),.TOTAL_ROWS(720),.TOTAL_COLS(1280)) inst_FrameCrop(
    .clk_i                             (clk_pixel                 ),
    .rst_i                             (~rstn_pixel                ),
	
    .hs_i                              (lcd_hs              ),
    .vs_i                              (lcd_vs              ),
    .de_i                              (lcd_de              ),
    .data_i                            (hdmi_data           ),
	
    .vs_o                              (w_rgb_vs_o          ),
    .hs_o                              (w_rgb_hs_o          ),
    .de_o                              (w_rgb_de_o          ),
    .data_o                            (w_rgb_data_o        ) 
);

// =========================================================================================================================================
// line_delay
// ========================================================================================================================================= 
wire  all_valid;
wire [7:0]  avg_00, avg_01, avg_02, avg_03, avg_04, avg_05;
wire [7:0]  avg_10, avg_11, avg_12, avg_13, avg_14, avg_15;
wire [7:0]  avg_20, avg_21, avg_22, avg_23, avg_24, avg_25;
wire [7:0]  avg_30, avg_31, avg_32, avg_33, avg_34, avg_35;
wire [7:0] debug_24;

video_24region_avg_8bit u_video_24region_avg_8bit (
    .clk        (clk_pixel),       // 像素时钟(74.25MHz)
    .rst_n      (rstn_pixel),      // 模块复位(高电平有效)
    
    // RGB视频输入
    .rgb_in(w_rgb_data_o), // 输入RGB数据（R[23:16], G[15:8], B[7:0])
    // 视频同步信号
    .vsync      (w_rgb_vs_o),       // 场同步信号(与输入时序匹配)
    .hsync      (w_rgb_hs_o),       // 行同步信号(与输入时序匹配)
    .de         (w_rgb_de_o),          // 数据有效信号
    
    // 24区域8bit平均亮度输出
    .avg_00     (avg_00),            // 第(0行,0列)区域亮度
    .avg_01     (avg_01),            // 第(0行,1列)区域亮度
    .avg_02     (avg_02),            // 第(0行,2列)区域亮度
    .avg_03     (avg_03),            // 第(0行,3列)区域亮度
    .avg_04     (avg_04),            // 第(0行,4列)区域亮度
    .avg_05     (avg_05),            // 第(0行,5列)区域亮度
    
    .avg_10     (avg_10),            // 第(1行,0列)区域亮度
    .avg_11     (avg_11),            // 第(1行,1列)区域亮度
    .avg_12     (avg_12),            // 第(1行,2列)区域亮度
    .avg_13     (avg_13),            // 第(1行,3列)区域亮度
    .avg_14     (avg_14),            // 第(1行,4列)区域亮度
    .avg_15     (avg_15),            // 第(1行,5列)区域亮度
    
    .avg_20     (avg_20),            // 第(2行,0列)区域亮度
    .avg_21     (avg_21),            // 第(2行,1列)区域亮度
    .avg_22     (avg_22),            // 第(2行,2列)区域亮度
    .avg_23     (avg_23),            // 第(2行,3列)区域亮度
    .avg_24     (avg_24),            // 第(2行,4列)区域亮度
    .avg_25     (avg_25),            // 第(2行,5列)区域亮度
    
    .avg_30     (avg_30),            // 第(3行,0列)区域亮度
    .avg_31     (avg_31),            // 第(3行,1列)区域亮度
    .avg_32     (avg_32),            // 第(3行,2列)区域亮度
    .avg_33     (avg_33),            // 第(3行,3列)区域亮度
    .avg_34     (avg_34),            // 第(3行,4列)区域亮度
    .avg_35     (avg_35)            // 第(3行,5列)区域亮度
    
    //.debug_24  (debug_24)          // 所有输出有效信号
);


// =========================================================================================================================================
// video_denoising
// ========================================================================================================================================= 
wire  vsync_out_dn,hsync_out_dn,de_out_dn;    // 输出垂直同步
wire [23:0] rgb_out_dn; // 输出RGB数据

video_denoising dnoise_001(
    .clk(clk_pixel              ), // 像素时钟（约74.25 MHz for 720p60）
    .rst_n(rstn_pixel           ), // 异步复位（低电平有效）
    .rgb_in(w_rgb_data_o        ), // 输入RGB数据（R[23:16], G[15:8], B[7:0]）
    .vsync_in(w_rgb_vs_o        ), // 垂直同步信号（帧开始）
    .hsync_in(w_rgb_hs_o        ), // 水平同步信号（行开始）
    .de_in(w_rgb_de_o           ),  
    
    .en_ds_on       (en_ds_on),
    
    .rgb_out(rgb_out_dn         ), // 输出RGB数据（R[23:16], G[15:8], B[7:0]）
    .vsync_out(vsync_out_dn     ), // 输出垂直同步
    .hsync_out(hsync_out_dn     ), // 输出水平同步
    .de_out(de_out_dn           )  // 输出水平同步
);

wire  vsync_out_gm,hsync_out_gm,de_out_gm;    // 输出垂直同步
wire [23:0] rgb_out_gm; // 输出RGB数据
rgb_gama rgb_gm_001(
    .clk(clk_pixel              ), // 像素时钟（约74.25 MHz for 720p60）
    .rst_n(rstn_pixel           ), // 异步复位（低电平有效）
    .rgb_in(rgb_out_dn          ), // 输入RGB数据（R[23:16], G[15:8], B[7:0]）
    .vsync_in(vsync_out_dn      ), // 垂直同步信号（帧开始）
    .hsync_in(hsync_out_dn      ), // 水平同步信号（行开始）
    .de_in(de_out_dn            ),  
    
    .gama_value     (gama_value   ),
    
    .rgb_out(rgb_out_gm         ), // 输出RGB数据（R[23:16], G[15:8], B[7:0]）
    .vsync_out(vsync_out_gm     ), // 输出垂直同步
    .hsync_out(hsync_out_gm     ), // 输出水平同步
    .de_out(de_out_gm           )  // 输出水平同步
);

// =========================================================================================================================================
// video_dimming
// ========================================================================================================================================= 
wire  vsync_out_dm,hsync_out_dm,de_out_dm;    // 输出垂直同步
wire [23:0] rgb_out_dm; // 输出RGB数据
wire [7:0]  dim_factor;
assign dim_factor = 255;
video_dimming dm_001(
    .clk            (clk_pixel    ), // 像素时钟（约74.25 MHz for 720p60）
    .rst_n          (rstn_pixel   ), // 异步复位（低电平有效）
    .dim_factor     (dim_factor   ),     // 消光因子(0-255, 255=无消光)     
    //.rgb_in       (w_rgb_data_o ), // 输入RGB数据（R[23:16], G[15:8], B[7:0]）
    //.vsync_in     (w_rgb_vs_o   ), // 垂直同步信号（帧开始）
    //.hsync_in     (w_rgb_hs_o   ), // 水平同步信号（行开始）
    //.de_in        (w_rgb_de_o   ),  
    .rgb_in         (rgb_out_gm   ), // 输入RGB数据（R[23:16], G[15:8], B[7:0]）
    .vsync_in       (vsync_out_gm ), // 垂直同步信号（帧开始）
    .hsync_in       (hsync_out_gm ), // 水平同步信号（行开始）
    .de_in          (de_out_gm    ),  
    
    .en_dm_on       (en_dm_on),
    
    .rgb_out        (rgb_out_dm   ), // 输出RGB数据（R[23:16], G[15:8], B[7:0]）
    .vsync_out      (vsync_out_dm ), // 输出垂直同步
    .hsync_out      (hsync_out_dm ), // 输出水平同步
    .de_out         (de_out_dm    )  // 输出水平同步
);

// =========================================================================================================================================
// auto_exposure
// ========================================================================================================================================= 
wire  vsync_out_ae,hsync_out_ae,de_out_ae;    // 输出垂直同步
wire [23:0] rgb_out_ae; // 输出RGB数据

wire [23:0]   a2020_config_00,a2020_config_01,a2020_config_02; 
wire  en_i2c_config_ae;
auto_exposure ae_001(
    .clk(clk_pixel              ), // 像素时钟（约74.25 MHz for 720p60）
    .rst_n(rstn_pixel           ), // 异步复位（低电平有效）
    .rgb_in(rgb_out_dm          ), // 输入RGB数据（R[23:16], G[15:8], B[7:0]）
    .vsync_in(vsync_out_dm      ), // 垂直同步信号（帧开始）
    .hsync_in(hsync_out_dm      ), // 水平同步信号（行开始）
    .de_in(de_out_dm            ),
  
    //.ae_Y(ae_value),
    .ae_Y(avg_13),
    
    .rgb_out(rgb_out_ae         ),  // 输出RGB数据（R[23:16], G[15:8], B[7:0]）
    .vsync_out(vsync_out_ae     ), // 输出垂直同步
    .hsync_out(hsync_out_ae     ), // 输出水平同步
    .de_out(de_out_ae           ), // 输出水平同步

    .en_i2c_config_ae(en_i2c_config_ae),
    .a2020_config_00 (a2020_config_00),
    .a2020_config_01 (a2020_config_01),
    .a2020_config_02 (a2020_config_02)
);
    
// =========================================================================================================================================
// WB
// ========================================================================================================================================= 
wire  vsync_out_wb,hsync_out_wb,de_out_wb;    // 输出垂直同步
wire [23:0] rgb_out_wb; // 输出RGB数据
wire [15:0] r_gain,g_gain,b_gain;

wb_adjust wba_001(
    .clk(clk_pixel            ), // 像素时钟（约74.25 MHz for 720p60）
    .rst_n(rstn_pixel       ), // 异步复位（低电平有效）
    .rgb_in(rgb_out_ae        ), // 输入RGB数据（R[23:16], G[15:8], B[7:0]）
    .vsync_in(vsync_out_ae       ), // 垂直同步信号（帧开始）
    .hsync_in(hsync_out_ae       ), // 水平同步信号（行开始）
    .de_in(de_out_ae          ),  
    
    //.rgb_in(w_rgb_data_o), // 输入RGB数据（R[23:16], G[15:8], B[7:0])
    //.vsync_in(w_rgb_vs_o),       // 场同步信号(与输入时序匹配)
    //.hsync_in(w_rgb_hs_o),       // 行同步信号(与输入时序匹配)
    //.de_in(w_rgb_de_o),          // 数据有效信号    
    
    .en_wb_on(en_wb_on),    

    .r_gain(r_gain),
    .g_gain(g_gain),
    .b_gain(b_gain),
    
    .rgb_out(rgb_out_wb       ),  // 输出RGB数据（R[23:16], G[15:8], B[7:0]）
    .vsync_out(vsync_out_wb   ), // 输出垂直同步
    .hsync_out(hsync_out_wb   ), // 输出水平同步
    .de_out(de_out_wb         ) // 输出水平同步
);

// =========================================================================================================================================
// edge_enhancement
// ========================================================================================================================================= 

wire [23:0] rgb_out_edge;
wire vsync_out_edge,hsync_out_edge,de_out_edge;
edge_enhancement edge_enhanc_001(
    .clk(clk_pixel             ),                  // 像素时钟 (720p60约需74.25MHz)
    .rst_n(rstn_pixel          ),                // 异步复位，低有效
    
    //.rgb_in(w_rgb_data_o),       // 输入RGB数据（R[23:16], G[15:8], B[7:0])
    //.vsync_in(w_rgb_vs_o),       // 场同步信号(与输入时序匹配)
    //.hsync_in(w_rgb_hs_o),       // 行同步信号(与输入时序匹配)
    //.de_in(w_rgb_de_o),          // 数据有效信号    
    
    .rgb_in(rgb_out_wb            ),    // 输入RGB数据（R[23:16], G[15:8], B[7:0]）
    .vsync_in(vsync_out_wb        ),    // 输入场同步 
    .hsync_in(hsync_out_wb        ),    // 输入行同步 
    .de_in(de_out_wb              ),    // 输入数据有效 
    
    .edge_value(edge_value),
    
    .rgb_out(rgb_out_edge         ),    // 输出RGB数据（R[23:16], G[15:8], B[7:0]） 
    .vsync_out(vsync_out_edge     ),    // 输出场同步 
    .hsync_out(hsync_out_edge     ),    // 输出行同步 
    .de_out(de_out_edge           )     // 输出数据有效 
);


// =========================================================================================================================================
// contrast_adjuster
// ========================================================================================================================================= 
wire [23:0] rgb_out_const;
wire vsync_out_const,hsync_out_const,de_out_const;
wire contrast_level;
contrast_adjuster   contrast_001(
    .clk(clk_pixel             ),                  // 像素时钟 (720p60约需74.25MHz)
    .rst_n(rstn_pixel          ),                // 异步复位，低有效
    
    //.rgb_in(rgb_out_wb         ),    // 输入RGB数据（R[23:16], G[15:8], B[7:0]）
    //.vsync_in(vsync_out_wb     ),    // 输入场同步 
    //.hsync_in(hsync_out_wb     ),    // 输入行同步 
    //.de_in(de_out_wb           ),    // 输入数据有效 
    .rgb_in(rgb_out_edge       ),    // 输入RGB数据（R[23:16], G[15:8], B[7:0]）
    .vsync_in(vsync_out_edge   ),    // 输入场同步 
    .hsync_in(hsync_out_edge   ),    // 输入行同步 
    .de_in(de_out_edge         ),    // 输入数据有效 
    
    .contrast_level(cont_value ),
    
    .rgb_out(rgb_out_const     ),    // 输出RGB数据（R[23:16], G[15:8], B[7:0]） 
    .vsync_out(vsync_out_const ),    // 输出场同步 
    .hsync_out(hsync_out_const ),    // 输出行同步 
    .de_out(de_out_const       )     // 输出数据有效 
);

// =========================================================================================================================================
// video_zoom
// ========================================================================================================================================= 

wire [23:0] rgb_out_zm;
wire vsync_out_zm,hsync_out_zm,de_out_zm;
video_zoom u_video_zoom (
    .clk        (clk_pixel),         // 像素时钟(74.25MHz)
    .rst_n      (rstn_pixel),        // 异步复位(低有效)
    
    // 输入视频信号
    .rgb_in     (rgb_out_const),      // 输入RGB数据
    .vsync_in   (vsync_out_const),    // 输入场同步
    .hsync_in   (hsync_out_const),    // 输入行同步
    .de_in      (de_out_const),       // 输入数据有效
    
    //.rgb_in     (rgb_out_wb),      // 输入RGB数据
    //.vsync_in   (vsync_out_wb),    // 输入场同步
    //.hsync_in   (hsync_out_wb),    // 输入行同步
    //.de_in      (de_out_wb),       // 输入数据有效
    
    //.rgb_in(w_rgb_data_o), // 输入RGB数据（R[23:16], G[15:8], B[7:0])
    //.vsync_in(w_rgb_vs_o),       // 场同步信号(与输入时序匹配)
    //.hsync_in(w_rgb_hs_o),       // 行同步信号(与输入时序匹配)
    //.de_in(w_rgb_de_o),          // 数据有效信号    

    .en_zoom_on(en_zoom_on),        
    .zoom_x(zoom_x),
    .zoom_y(zoom_y),
        
    .rgb_out    (rgb_out_zm),     // 输出RGB数据
    .vsync_out  (vsync_out_zm),   // 输出场同步
    .hsync_out  (hsync_out_zm),   // 输出行同步
    .de_out     (de_out_zm)       // 输出数据有效
);

// =========================================================================================================================================
// digit_overlay
// ========================================================================================================================================= 
wire signed [7:0]  x,y,z,k;
assign x = 23;
assign y = 45;
assign k = x-y;
wire signed [7:0]  l,m,n;
assign m = -3;
assign n = 9;
assign l = m * n;
wire [23:0] overlay_data;
wire hs_overlay_o,vs_overlay_o,de_overlay_o;
wire [47:0]  digits_0,digits_1,digits_2,digits_3;
//assign digits_0 = {r_gain[15:8],r_gain[7:0],g_gain[15:8],g_gain[7:0],b_gain[15:8],b_gain[7:0]};
//assign digits_0 = {cmd_new,cmd_data,ae_value ,a2020_config_00[23:16],a2020_config_00[15:8],a2020_config_00[7:0]};
assign digits_0 = {avg_00,avg_01,avg_02,avg_03,avg_04,avg_05};
assign digits_1 = {avg_10,avg_11,avg_12,avg_13,avg_14,avg_15};
assign digits_2 = {avg_20,avg_21,avg_22,avg_23,avg_24,avg_25};
assign digits_3 = {ae_value,edge_value,avg_12,k,x+y,l};
//assign digits_3 = {avg_30,avg_31,avg_32,avg_33,avg_34,avg_35};

digit_overlay do_001(
    .clk(clk_pixel                ),    // 像素时钟 
    .rst(~rstn_pixel              ),    // 复位信号 
    
    //.rgb_in(w_rgb_data_o), // 输入RGB数据（R[23:16], G[15:8], B[7:0])
    //.vsync_in(w_rgb_vs_o),       // 场同步信号(与输入时序匹配)
    //.hsync_in(w_rgb_hs_o),       // 行同步信号(与输入时序匹配)
    //.de_in(w_rgb_de_o),          // 数据有效信号 
    
    .rgb_in(rgb_out_zm            ),    // 输入像素数据 (24位)
    .vsync_in(vsync_out_zm        ),    // 输入场同步 
    .hsync_in(hsync_out_zm        ),    // 输入行同步 
    .de_in(de_out_zm              ),    // 输入数据有效

    //.rgb_in(rgb_out_edge            ),    // 输入像素数据 (24位)
    //.vsync_in(vsync_out_edge        ),    // 输入场同步 
    //.hsync_in(hsync_out_edge        ),    // 输入行同步 
    //.de_in(de_out_edge              ),    // 输入数据有效
    
    .en_digi_on(en_digi_on),
    
    .digits_0(digits_0     ),    // 8个数字（每个数字4位，digits[3:0]为最左数字）
    .digits_1(digits_1     ),    // 8个数字（每个数字4位，digits[3:0]为最左数字）
    .digits_2(digits_2     ),    // 8个数字（每个数字4位，digits[3:0]为最左数字）
    .digits_3(digits_3     ),    // 8个数字（每个数字4位，digits[3:0]为最左数字）
    .rgb_out(overlay_data         ),    // 输出像素数据 
    .vsync_out(vs_overlay_o       ),    // 输出场同步 
    .hsync_out(hs_overlay_o       ),    // 输出行同步 
    .de_out(de_overlay_o         )     // 输出数据有效 
);

// =========================================================================================================================================
// HDMI Interface
// ========================================================================================================================================= 
	assign hdmi_txd0_rst_o = rst_pixel; 
	assign hdmi_txd1_rst_o = rst_pixel; 
	assign hdmi_txd2_rst_o = rst_pixel; 
	assign hdmi_txc_rst_o = rst_pixel; 
	
	assign hdmi_txd0_oe = 1'b1; 
	assign hdmi_txd1_oe = 1'b1; 
	assign hdmi_txd2_oe = 1'b1; 
	assign hdmi_txc_oe = 1'b1; 
	
	//-------------------------------------
	//Digilent HDMI-TX IP Modified by CB elec.
    rgb2dvi #(.ENABLE_OSERDES(0)) u_rgb2dvi
    (
    .oe_i                              (1                        ),//	Always enable output
    .bitflip_i                         (4'b0000                  ),//	Reverse clock & data lanes. 
		
    .aRst                              (1'b0                     ),
    .aRst_n                            (1'b1                     ),
		
    .PixelClk                          (clk_pixel                ),//pixel clk = 74.25M
    .SerialClk                         (                         ),//pixel clk *5 = 371.25M
		
    .vid_pVSync                        (vs_overlay_o            ),
    .vid_pHSync                        (hs_overlay_o            ),
    .vid_pVDE                          (de_overlay_o            ),
    .vid_pData                         (overlay_data            ),
 
    //.vid_pVSync                        (w_rgb_vs_o             ),
    //.vid_pHSync                        (w_rgb_hs_o             ),
    //.vid_pVDE                          (w_rgb_de_o             ),
    //.vid_pData                         (w_rgb_data_o           ),
    
    //.vid_pVSync                        (vsync_out_dn           ),
    //.vid_pHSync                        (hsync_out_dn           ),
    //.vid_pVDE                          (de_out_dn              ),
    //.vid_pData                         (rgb_out_dn             ),
		
    //.vid_pVSync                        (vsync_out_edge           ),
    ///.vid_pHSync                        (hsync_out_edge           ),
    //.vid_pVDE                          (de_out_edge              ),
    //.vid_pData                         (rgb_out_edge             ),
    
    .txc_o                             (hdmi_txc_o               ),
    .txd0_o                            (hdmi_txd0_o              ),
    .txd1_o                            (hdmi_txd1_o              ),
    .txd2_o                            (hdmi_txd2_o              ) 
    );
		
// ===========================================================================
// 
// ===========================================================================
reg [31:0]  cnt_frame;
reg vs_01,vs_02,edge_HL_vs;
always @(posedge clk_pixel or negedge rstn_sys) begin
    if (!rstn_sys) begin
        vs_01 <=0; vs_02 <= 0;
        edge_HL_vs <=0;
    end else begin
        vs_01 <= w_rgb_vs_o; vs_02 <= vs_01;
        edge_HL_vs = vs_02 & !vs_01;
    end
end
always@(posedge clk_pixel or negedge rstn_sys)
begin
	if(!rstn_sys)
        cnt_frame<=0;
    else if(edge_HL_vs==1)
            cnt_frame<=cnt_frame+1;
        else
            cnt_frame<=cnt_frame;
end
//-----------------------------------------
wire [9:0]  counter_state_main;
counter_state_with_fram cswf_001(
    .clk_sys(clk_sys),   // 96MHz输入时钟
    .rstn_sys(rstn_sys),     // 低电平有效复位 (reset_n=0时复位)
    .trigger_frame(edge_HL_vs),
    .counter_state_main(counter_state_main)
);
//-----------------------------------------
wire [23:0] A2020_i2c_dataCurrent00,A2020_i2c_dataCurrent01,A2020_i2c_dataCurrent02;
wire  manual_i2c_access;
//assign A2020_i2c_dataCurrent00 = {8‘d0,8‘d0,sensor_gain[7:0]};
//assign A2020_i2c_dataCurrent01 = {8‘d0,8‘d0,sensor_gain[7:0]};
//assign A2020_i2c_dataCurrent02 = {8‘d0,8‘d0,8‘d0};
/*
config_i2c_manual cim_001(
    .clk_sys(clk_sys),   // 96MHz输入时钟
    .rstn_sys(rstn_sys),     // 低电平有效复位 (reset_n=0时复位)
    .counter_state_main(counter_state_main),
    .manual_i2c_access(manual_i2c_access),
    .A2020_i2c_dataCurrent00(A2020_i2c_dataCurrent00),
    .A2020_i2c_dataCurrent01(A2020_i2c_dataCurrent01),
    .A2020_i2c_dataCurrent02(A2020_i2c_dataCurrent02)
);
*/
assign led_o[5:0] = zoom_x[5:0];
//////////////////////////////////////////////////////////
//Precise clk divider
wire	divide_clken;
integer_divider	
#(
	.DEVIDE_CNT	(52)	//115200bps * 16
//	.DEVIDE_CNT	(625)	//9600bps * 16
)
u_integer_devider
(
	.clk				(clk_sys),		//96MHz clock
	.rst_n				(rstn_sys),    //global reset
	.divide_clken		(divide_clken)
);
wire	clken_16bps = divide_clken;
//---------------------------------
//Data receive for PC to FPGA.
wire			flag_rxd;
wire	[7:0]	rxd_data;
uart_receiver	u_uart_receiver
(
	.clk			(clk_sys),
	.rst_n			(rstn_sys),
	.clken_16bps	(clken_16bps),	//clk_bps * 16
	.rxd			(fpga_rxd),		//uart txd interface
	.rxd_data		(rxd_data),		//uart data receive
	.flag_rxd		(flag_rxd)  	//uart data receive done
);
//---------------------------------
//Data receive for PC to FPGA.
assign uart_tx_o = fpga_txd;
assign fpga_rxd = uart_rx_i;

uart_transfer	u_uart_transfer
(
	.clk			(clk_sys),
	.rst_n			(rstn_sys),
	.clken_16bps	(clken_16bps),	//clk_bps * 16
	.txd			(fpga_txd),  	//uart txd interface
	.txd_en			(flag_cmd_new),		//uart data transfer enable
	.txd_data		(zoom_x), 	//uart transfer data	
	.txd_flag		() 			    //uart data transfer done
);

wire  [7:0]     cmd_new,cmd_data;
wire  [7:0]     zoom_x,zoom_y,gama_value,ae_value,edge_value,cont_value;
wire    flag_cmd_new,flag_led_on,en_zoom_on,en_digi_on,en_wb_on;
wire    en_gama_on,en_dm_on,en_ds_on;

wire [7:0] cmd_buf;
assign cmd_buf[7:0] = {0,en_ds_on,en_dm_on,en_wb_on,en_digi_on,en_zoom_on,flag_led_on,flag_cmd_new};

cmd_parser      u_cmd_parser
(
	.clk			(clk_sys),
	.rst_n			(rstn_sys),
	.clken_16bps	(clken_16bps),	//clk_bps * 16
	.flag_rxd		(flag_rxd),		//uart data transfer enable
	.rxd_data		(rxd_data), 	//uart transfer data
    .flag_cmd_new   (flag_cmd_new),
    .flag_led_on    (flag_led_on),
    .en_zoom_on     (en_zoom_on),
    .en_digi_on     (en_digi_on),
    .en_wb_on       (en_wb_on),
    .en_dm_on       (en_dm_on),     
    .en_ds_on       (en_ds_on),
    
    .cont_value     (cont_value),
    .ae_value       (ae_value),
    .edge_value     (edge_value),
    .gama_value     (gama_value),
    .zoom_x         (zoom_x),
    .zoom_y         (zoom_y),
    .cmd_new        (cmd_new),
    .cmd_data       (cmd_data)
);

endmodule



