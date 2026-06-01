`timescale 100ps/100ps




module sdram_controller_pro(write_in, read_in, clk_in, rst_in, addr_in, data_inout, clk_out, cke_out, cs_out, ras_out, cas_out, we_out, dqm_out, addr_out, ba_out, data_bus);


//Controller Input
input         write_in;
input         read_in;
input         clk_in;
input         rst_in;
input [24:0]  addr_in;

//Controller inout
inout [31:0]  data_inout;

//Controller Output
output        clk_out;
output        cke_out;
output        cs_out;
output        ras_out;
output        cas_out;
output        we_out;
output [1:0]  dqm_out;
output [1:0]  ba_out;
output [12:0] addr_out;
inout [15:0] data_bus;

//Initialze Module Component
wire          cke_out_1;
wire          cs_out_1;
wire          ras_out_1;
wire          cas_out_1;
wire          we_out_1;
wire [1:0]    dqm_out_1;
wire [1:0]    ba_out_1;
wire [12:0]   addr_out_1;

//Command Module Component
wire          cke_out_2;
wire          cs_out_2;
wire          ras_out_2;
wire          cas_out_2;
wire          we_out_2;
wire [1:0]    dqm_out_2;
wire [1:0]    ba_out_2;
wire [12:0]   addr_out_2;

//Mux Component
wire [21:0]  out_init;
wire [21:0]  out_command;
wire         init_done;
wire [21:0]  controller_out;

//38bit Mux
sdram_multiplexer mux
(
	.a(out_init), 
	.b(out_command), 
	.s(init_done), 
	.w(controller_out)
);

//Initialize Module
sdram_init_block init
(
	.rst_in(rst_in), 
	.clk_in(clk_in), 
	.init_done(init_done), 
	.cke_out(cke_out_1), 
	.cs_out(cs_out_1), 
	.ras_out(ras_out_1), 
	.cas_out(cas_out_1), 
	.we_out(we_out_1), 
	.dqm_out(dqm_out_1), 
	.ba_out(ba_out_1), 
	.addr_out(addr_out_1)
);

//Command Module
sdram_command_block command
(
	.write_in(write_in), 
	.read_in(read_in), 
	.clk_in(clk_in), 
	.rst_in(rst_in), 
	.init_done_in(init_done), 
	.addr_in(addr_in), 
	.data_inout(data_inout), 
	.clk_out(), 
	.cke_out(cke_out_2), 
	.cs_out(cs_out_2), 
	.ras_out(ras_out_2), 
	.cas_out(cas_out_2), 
	.we_out(we_out_2), 
	.dqm_out(dqm_out_2), 
	.addr_out(addr_out_2), 
	.ba_out(ba_out_2), 
	.data_bus(data_bus)
);

// Mux wire connection
assign out_init = {cke_out_1, cs_out_1, ras_out_1, cas_out_1, we_out_1, dqm_out_1, addr_out_1, ba_out_1};
assign out_command = {cke_out_2, cs_out_2, ras_out_2, cas_out_2, we_out_2, dqm_out_2, addr_out_2, ba_out_2};
assign {cke_out, cs_out, ras_out, cas_out, we_out, dqm_out, addr_out, ba_out} = controller_out;
assign clk_out = clk_in;



endmodule