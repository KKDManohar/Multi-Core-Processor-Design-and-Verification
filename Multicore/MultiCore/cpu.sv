import pkg::*;

module cpu (
			input clk,rst,
			input [7:0] A,B,
			input start_op,
			input opcode op_sel,
			input [11:0] address_in,
			input [7:0] data_in,
			input gnt_arb,
			output reg [15:0] result,
			output reg end_op,
			output reg req_arb
			);
			
	wire rw,valid,hit,gnt;
	wire [7:0] data_cache; 
	wire [11:0] address_cache;
	
	multi_processor pro1 (.clk(clk),.rst(rst),.A(A),.B(B),.start_op(start_op),.op_sel(op_sel),.address_in(address_in),
							.data_in(data_in),.hit(hit),.gnt(gnt),.data_cache(data_cache),
							.result(result),.rw(rw),.end_op(end_op),.valid(valid),.address_cache(address_cache));
						
	cache cache2 (.clk(clk),.rst(rst),.valid(valid),.data_cache(data_cache),.address_cache(address_cache),
				    .rw(rw),.hit(hit),.cpu_gnt(gnt),.gnt_arb(gnt_arb),.req_arb(req_arb));
					
					
endmodule