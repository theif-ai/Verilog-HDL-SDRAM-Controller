





`timescale 100ps/100ps

//SDRAM Commands (cs, ras, cas, we)
`define CMD_NOP (4'b1111)
`define CMD_PRE (4'b0010)
`define CMD_REF (4'b0001)
`define CMD_MRS (4'b0000)
`define CMD_ACT (4'b0011)
`define CMD_WR  (4'b0100)
`define CMD_RD  (4'b0101)

module sdram_command_block (write_in, read_in, clk_in, rst_in, init_done_in, addr_in, data_inout, clk_out, cke_out, cs_out, ras_out, cas_out, we_out, dqm_out, addr_out, ba_out, data_bus);

//state

//wiat unti initialization finsh
parameter [4:0]ready = 5'd0; // wait until finish Initailize

//IDLE state
parameter [4:0]IDLE = 5'd7; // NOP

//write states
parameter [4:0]wr_s00 = 5'd8;   // ACT
parameter [4:0]wr_s01 = 5'd9; // NOP
parameter [4:0]wr_s02 = 5'd10;  // WR
parameter [4:0]wr_s03 = 5'd11; // NOP
parameter [4:0]wr_s04 = 5'd12; // NOP
parameter [4:0]wr_s05 = 5'd13;  // PRE

//read states
parameter [4:0]rd_s00 = 5'd14;  // ACT
parameter [4:0]rd_s01 = 5'd15; // NOP
parameter [4:0]rd_s02 = 5'd16;  // RD
parameter [4:0]rd_s03 = 5'd17; // NOP
parameter [4:0]rd_s04 = 5'd18; // NOP
parameter [4:0]rd_s05 = 5'd19; // NOP
parameter [4:0]rd_s06 = 5'd20;   //PRE

//refresh_state
parameter [4:0]ref_s00 = 5'd21; //ref
parameter [4:0]ref_s01 = 5'd22; // NOP

//flipflop_data I/O
reg [31:0]data_load;

wire [15:0]data_load_1;
wire [15:0]data_load_2;

//flipflop_addr I/O
reg [24:0]addr_load;

wire [12:0]addr_load_row;
wire [9:0]addr_load_col;
wire [1:0]ba_load;

//flipflop_data from sdram I/O
wire [31:0]sdram_data_load;
wire [31:0]sdram_data_in;

reg [15:0]sdram_data_load_tmp;

//state variable
reg [4:0]p_state = 5'd0;
reg [4:0]n_state = 5'd0;
reg [3:0]cmd;
reg data_e = 1'b0;
reg [15:0]data;
reg [12:0]addr;

// controller input
input write_in;
input read_in;
input clk_in;
input rst_in;
input [24:0]addr_in;
inout [31:0]data_inout;
input init_done_in;

// cpu <-> controller datainout control
reg cpu_data_e;
reg [31:0]cpu_data;


// controller output
output clk_out;
output cs_out;
output ras_out;
output cas_out;
output we_out;
output [1:0]dqm_out;
inout [15:0]data_bus;

output reg cke_out;
output reg [12:0]addr_out;
output reg [1:0]ba_out;

// control flipflop
reg sdram_data_save_tmp;
reg sdram_data_save_final;
reg data_save;
reg addr_save;

//refresh_counter
reg [8:0]ref_counter;
reg refresh_rq;
reg [1:0]p_interval_counter;
reg [1:0]n_interval_counter;

always @(posedge clk_in) begin

	if(~init_done_in) begin
	ref_counter <= 9'd0;
	refresh_rq <= 1'b0;
	end
	else if(ref_counter >= 9'd390) begin 
	refresh_rq <= 1'b1;
	ref_counter <= 9'd0;
	end
	else if(p_state == ref_s00)begin
 	refresh_rq <= 1'b0;
	ref_counter <= ref_counter + 1;
	end
	else ref_counter <= ref_counter + 1;
	 
end


//flipflops
always @(posedge clk_in)begin
	if(~init_done_in)begin
		
		// flipflop for cpu->controller data 32 bit
		data_load <= 32'd0;

		// flipflop for cpu->controller addr 26bit
		addr_load <= 25'd0;

		// flipflop for load data from sdram
		// 16 bit data1
		sdram_data_load_tmp <= 16'd0;

		//32 bit final data_out
		cpu_data <= 32'd0;
	end
	else begin
		if(data_save)data_load <= data_inout;

		if(addr_save) addr_load <= addr_in;

		if(sdram_data_save_tmp)sdram_data_load_tmp <= data_bus;

		if(sdram_data_save_final)cpu_data <= {sdram_data_load_tmp, data_bus};
	end
end

// Seuqential 
always @(posedge clk_in)begin
	if (~init_done_in)begin
		p_state <= ready;
		p_interval_counter <= 2'd0;
		

	end
	else begin
		p_state <= n_state;
		p_interval_counter <= n_interval_counter;
	end
end

// Combinational
always @(*)begin
	//intialize component
	cmd = `CMD_NOP;
	cke_out = 1'b1;
	addr_out = 13'h0000;
	data_e = 1'b0;
	data = 16'hzzzz;
	ba_out = 2'b0;
	n_state = IDLE;
	data_save = 1'b0;
	addr_save = 1'b0;
	sdram_data_save_tmp = 1'b0;
	sdram_data_save_final = 1'b0;
	cpu_data_e = 1'b0;
	n_interval_counter = p_interval_counter;
	case (p_state)	
			// wait until finsh Initialize
			ready : 
				if(init_done_in) begin
					n_state = IDLE;
				end
				else begin
					n_state = ready;
				end

			//IDLE
			IDLE : 
				// refresh_rq == 1
				if (refresh_rq) begin
						n_state = ref_s00;
				end
				// wirte == 1
				else if (write_in) begin
						n_state = wr_s00;
						data_save = 1'b1;
						addr_save = 1'b1;
				end
				// read == 1
				else if (read_in) begin
						n_state = rd_s00;
						addr_save = 1'b1;
				end
				// no_input
				else n_state = IDLE;
			
			ref_s00: begin
					n_state = ref_s01;
					cmd = `CMD_REF;
			end
	
			ref_s01: begin
					if(p_interval_counter < 2'd3)begin
					n_state = ref_s01;
					n_interval_counter = p_interval_counter + 1;
					end
					else begin
 					n_state = IDLE;
					n_interval_counter = 2'd0;
					end
			end
			
			//write
			wr_s00 : begin
					n_state = wr_s01;
					cmd = `CMD_ACT;
					addr_out = addr_load_row;
					ba_out = ba_load;
			end
			wr_s01 : n_state = wr_s02;
			wr_s02 : begin
					n_state = wr_s03;
					cmd = `CMD_WR;
					addr_out = { 2'b00 , 1'b0, addr_load_col};
					data = data_load_1;
					data_e = 1'b1;
					ba_out = ba_load;
			end
			wr_s03 : begin
					n_state = wr_s04;
					data = data_load_2;
					data_e = 1'b1;
			end
			wr_s04 : n_state = wr_s05;
			wr_s05 : begin
					n_state = IDLE;
					cmd = `CMD_PRE;
					ba_out = ba_load;
			end

			//read
			rd_s00 : begin
					n_state = rd_s01;
					cmd = `CMD_ACT;
					addr_out = addr_load_row;
					ba_out = ba_load;
			end
			rd_s01 : n_state = rd_s02;
			rd_s02 : begin
					n_state = rd_s03;
					cmd = `CMD_RD;
					addr_out ={ 2'b00 , 1'b0, addr_load_col};
					ba_out = ba_load;
			end
			rd_s03 : n_state = rd_s04;
			rd_s04 : begin
					n_state = rd_s05;
					sdram_data_save_tmp = 1'b1;
			end
			rd_s05 : begin
					n_state = rd_s06;
					sdram_data_save_final = 1'b1;	
			end
			rd_s06 :begin 
				 	n_state = IDLE;
				 	cmd = `CMD_PRE;
					ba_out = ba_load;
					cpu_data_e = 1'b1;
			end

			//deafault
			default : n_state = IDLE;

	endcase
end


// wire connection
assign {cs_out, ras_out, cas_out, we_out} = cmd;
assign dqm_out = 2'h0;
assign data_bus = (data_e)?data:16'hzzzz;
assign clk_out = clk_in;

assign {data_load_1, data_load_2} = data_load;
assign {addr_load_row, addr_load_col, ba_load} = addr_load;

assign data_inout = (cpu_data_e)?cpu_data:32'hzzzz_zzzz;


endmodule