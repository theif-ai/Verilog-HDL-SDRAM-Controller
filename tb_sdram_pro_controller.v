

`timescale 100ps/100ps

// SDRAM Timing Parameters
`define tCK  (200) // 20ns (50MHz)
`define tCKE (`tCK * 1) // >200us
`define tRP  (`tCK * 2) // 2CK
`define tRC  (`tCK * 3) // > 60ns
`define tMRD (`tCK * 1) // > 14ns
`define tRCD (`tCK * 1) // > 15ns
`define tCAC (`tCK * 2) // CAS Latency

module tb_sdram_controller_pro;

//in signal
reg write_tb;
reg read_tb;
reg clk_tb;
reg rst_tb;
reg [24:0]addr_tb =  {13'hzzzz, 13'hzzzz};

// for data inout
reg [31:0]data_tb =  {16'hzzzz, 16'hzzzz};
reg data_e;
wire [31:0]data_inout;


//controller I/O
wire 	   mc_clk_o;
wire 	   mc_cke_o;
wire 	   mc_cs_o;
wire 	   mc_ras_o;
wire 	   mc_cas_o;
wire 	   mc_we_o;
wire [1:0] mc_dqm_o;
wire [12:0]mc_addr_o;
wire [1:0] mc_ba_o;
wire [15:0]mc_data_o;

//SDRAM interface
wire 	   sdram_clk;
wire 	   sdram_cke;
wire 	   sdram_cs;
wire 	   sdram_ras;
wire 	   sdram_cas;
wire 	   sdram_we;
wire [1:0] sdram_dqm;
wire [12:0]sdram_addr;
wire [1:0] sdram_ba;

//INOUT interface controller <-> sdram
wire [15:0]data_bus;


//Controller 
sdram_controller_pro MC 
(
	.write_in(write_tb),
	.read_in(read_tb), 
	.clk_in(clk_tb),
	.rst_in(rst_tb),
	.data_inout(data_inout),
	.addr_in(addr_tb),
	.clk_out(mc_clk_o),
	.cke_out(mc_cke_o), 
	.cs_out(mc_cs_o),
	.ras_out(mc_ras_o),
	.cas_out(mc_cas_o), 
	.we_out(mc_we_o), 
	.dqm_out(mc_dqm_o), 
	.addr_out(mc_addr_o), 
	.ba_out(mc_ba_o), 
	.data_bus(data_bus)
);


//SDRAM (OUT)
IS42VM16400K u_ram
(
	.dq  (data_bus),
	.addr(sdram_addr),
	.ba  (sdram_ba),
	.clk (sdram_clk),
	.cke (sdram_cke),
	.csb (sdram_cs),
	.rasb(sdram_ras),
	.casb(sdram_cas),
	.web (sdram_we),
	.dqm (sdram_dqm)
);


initial begin
	clk_tb = 1'b0;
	forever #(`tCK/2)clk_tb = ~clk_tb;
end

initial begin
	rst_tb = 1'b1;
	#(`tCK) rst_tb = 1'b0;
end

initial begin
	data_e = 1'b0;
	write_tb = 1'b0;
	#(`tCK *45) write_tb = 1'b1; addr_tb = {13'h0088, 10'h0090, 2'b01}; data_e = 1'b1; data_tb = {16'h4321, 16'h8765};
	#(`tCK) write_tb = 1'b0; 
	addr_tb = {13'hzzzz, 10'hzzzz, 2'bzz}; data_e = 1'b0; data_tb = {16'hzzzz, 16'hzzzz}; 
end

initial begin
	read_tb = 1'b0;
	#(`tCK *60) read_tb = 1'b1; addr_tb = {13'h0088, 10'h0090, 2'b01};
	#(`tCK) read_tb = 1'b0; 
	addr_tb =  {13'hzzzz, 10'hzzzz, 2'bzz};
end


initial begin
	#(`tCK*500) $stop;
end

assign sdram_clk = mc_clk_o;
assign sdram_cke = mc_cke_o;
assign sdram_cs = mc_cs_o;
assign sdram_ras = mc_ras_o;
assign sdram_cas = mc_cas_o;
assign sdram_we = mc_we_o;
assign sdram_dqm = mc_dqm_o;
assign sdram_addr = mc_addr_o;
assign sdram_ba = mc_ba_o;
assign data_inout = (data_e)?data_tb:32'hzzzz_zzzz;

endmodule