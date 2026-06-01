`timescale 100ps/100ps

//38bit multiplexer

module sdram_multiplexer(a, b, s, w);

//input
input [21:0] a;
input [21:0] b;
input s;

// output
output reg [21:0] w;

always @(a,b,s) begin
	if(s)
		w = b;
	else
		w = a;
end

endmodule
