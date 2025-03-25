import pkg::*;

module top(
			input logic clk,rst,
			input logic [7:0] A,B,
			input logic start_op,
			input opcode op_sel,
			input logic [11:0] address_in,
			input logic [7:0] data_in,
			output logic end_op,
			output logic [15:0] result
			);
			
	wire hit,gnt,valid;
	wire rw;
	wire [11:0] address_cache;
	
	wire req_arb, gnt_arb;
	
	wire [7:0] data_cache;
	
	multi_processor pro1 (.clk(clk),.rst(rst),.A(A),.B(B),.start_op(start_op),.op_sel(op_sel),.address_in(address_in),.data_in(data_in),.hit(hit),
						.gnt(gnt),.data_cache(data_cache),.result(result),.rw(rw),.end_op(end_op),.valid(valid),.address_cache(address_cache));
						
	cache cache2 (.clk(clk),.rst(rst),.valid(valid),.data_cache(data_cache),.address_cache(address_cache),.rw(rw),.hit(hit),.cpu_gnt(gnt),
				  .gnt_arb(gnt_arb),.req_arb(req_arb));
				  
	arbiter arb3 (.clk(clk),.rst(rst),.req_arb(req_arb),.gnt_arb(gnt_arb));
				
endmodule