

`timescale 100ps/100ps

//SDRAM Commands (cs, ras, cas, we)
`define CMD_NOP (4'b1111)
`define CMD_PRE (4'b0010)
`define CMD_REF (4'b0001)
`define CMD_MRS (4'b0000)
`define CMD_ACT (4'b0011)
`define CMD_WR  (4'b0100)
`define CMD_RD  (4'b0101)

module sdram_controller_7_advanced (write_in, read_in, clk_in, rst_in, addr_in, data_inout, clk_out, cke_out, cs_out, ras_out, cas_out, we_out, dqm_out, addr_out, ba_out, data_bus);

//state

//initialization states
parameter [4:0]init_s00 = 5'd0; // NOP
parameter [4:0]init_s01 = 5'd1; // NOP
parameter [4:0]init_s02 = 5'd2;    // PRE
parameter [4:0]init_s03 = 5'd3; // REF  8 times
parameter [4:0]init_s04 = 5'd4; // NOP  8 times
parameter [4:0]init_s05 = 5'd5;    // MRS
parameter [4:0]init_s06 = 5'd6; // NOP

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

//initial auto refresh counter => 8 times, 3bit
reg [2:0]ref_counter_n;
reg [2:0]ref_counter_p;

//initial autorefresh interval => 3 clock. 2bit
reg [1:0]interval_counter_n;
reg [1:0]interval_counter_p;


//flipflops
always @(posedge clk_in)begin
	if(rst_in)begin
		
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
	if (rst_in)begin
		p_state <= init_s00;
		// refresh counter for initialzation
		ref_counter_p <= 3'd0;
		// refresh_interval counter for initialization
		interval_counter_p <= 2'd0;

	end
	else begin
		p_state <= n_state;

		ref_counter_p <= ref_counter_n;

		interval_counter_p <= interval_counter_n;
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
	ref_counter_n = ref_counter_p;
	interval_counter_n = interval_counter_p;
	case (p_state)		
			// initialization
			init_s00 : begin
				 	n_state = init_s01;
					cke_out = 1'b0;
			end
			init_s01 : n_state = init_s02;
			init_s02 : begin
					n_state = init_s03;
					cmd = `CMD_PRE;
					addr_out = 13'h0400;
			end
			init_s03 : begin
					n_state = init_s04;
					cmd = `CMD_REF;
			end
			init_s04 : begin
					// 8times refresh complete
					if(ref_counter_p == 3'd7) begin 
						if(interval_counter_p == 2'd2) begin
							n_state = init_s05;
						end
						else begin
							n_state = init_s04;
							interval_counter_n = interval_counter_p + 1;
						end
					end
					// need more refresh
					else begin
						if(interval_counter_p == 2'd2) begin
							n_state = init_s03;
							ref_counter_n = ref_counter_p + 1;
							interval_counter_n = 2'd0; 
						end
						else begin
							n_state = init_s04;
							interval_counter_n = interval_counter_p + 1;
						end
					end
					
					
			end
			init_s05 : begin
					n_state = init_s06;
					cmd = `CMD_MRS;
					addr_out = 13'h0021;
			end
			init_s06 : n_state = IDLE;

			//IDLE
			IDLE : 
				// wirte == 1
				if (write_in) begin
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
assign dqm_out = 2'b0;
assign data_bus = (data_e)?data:16'hzzzz;
assign clk_out = clk_in;

assign {data_load_1, data_load_2} = data_load;
assign {addr_load_row, addr_load_col, ba_load} = addr_load;

assign data_inout = (cpu_data_e)?cpu_data:32'hzzzz_zzzz;

endmodule