`timescale 100ps/100ps

//SDRAM Commands (cs, ras, cas, we)
`define CMD_NOP (4'b1111)
`define CMD_PRE (4'b0010)
`define CMD_REF (4'b0001)
`define CMD_MRS (4'b0000)
`define CMD_ACT (4'b0011)
`define CMD_WR  (4'b0100)
`define CMD_RD  (4'b0101)

module sdram_init_block(rst_in, clk_in, init_done ,cke_out, cs_out, ras_out, cas_out, we_out, dqm_out, ba_out, addr_out);

//state

//initialization states
parameter [4:0]init_s00 = 5'd0; // NOP
parameter [4:0]init_s01 = 5'd1; // NOP
parameter [4:0]init_s02 = 5'd2;    // PRE
parameter [4:0]init_s03 = 5'd3; // REF 8 times
parameter [4:0]init_s04 = 5'd4; // NOP 8 times
parameter [4:0]init_s05 = 5'd5;    // MRS
parameter [4:0]init_s06 = 5'd6; // NOP

//states represenation
reg [4:0]p_state;
reg [4:0]n_state;

//reg 
reg [3:0]cmd;

//input
input rst_in;
input clk_in;

//output
output reg init_done;
output reg cke_out;
output cs_out;
output ras_out;
output cas_out;
output we_out;
output [1:0]dqm_out;
output [1:0]ba_out;
output reg [12:0]addr_out;

//auto_refresh 8times counter
reg [2:0]ref_counter_n;
reg [2:0]ref_counter_p;

//initial autorefresh interval => 3 clock. 2bit
reg [1:0]interval_counter_n;
reg [1:0]interval_counter_p;

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


//combinational
always @(*)begin
	//intialize component
	cmd = `CMD_NOP;
	cke_out = 1'b1;
	addr_out = 13'h0000;
	n_state = init_s00;
	init_done = 1'b0;
	ref_counter_n = ref_counter_p;
	interval_counter_n = interval_counter_p;
		case(p_state)
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
			init_s06 : begin
					n_state = init_s06;
					init_done = 1'b1;
			end
			default : n_state = init_s00;
		endcase
end

assign {cs_out, ras_out, cas_out, we_out} = cmd;
assign dqm_out = 2'b0;
assign ba_out = 2'b0;


endmodule