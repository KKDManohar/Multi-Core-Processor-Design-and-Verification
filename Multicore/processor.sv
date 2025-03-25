import pkg::*;	
	
module multi_processor(
	input logic clk,rst,
	input logic [7:0] A,B,
	input logic start_op,
	input opcode op_sel,
	input logic [11:0] address_in,
	input logic [7:0] data_in,
	input logic hit,gnt,
	inout logic [7:0] data_cache,
	output logic [15:0] result,
	output logic rw,
	output logic end_op,
	output logic valid,
	output logic [11:0] address_cache
);
	
	logic start_load;
	logic end_load;
	logic start_store;
	logic end_store;
	logic start_alu;
	logic end_alu;
	
	logic valid_load, valid_store;
	
	logic [15:0] result_alu, result_load, result_store;
	
	logic [11:0] address_cache_load, address_cache_store;
	
	assign start_load = (start_op) && (op_sel == LOAD);
	assign start_store = (start_op) && (op_sel == STORE);
	assign start_alu = (start_op) && !(op_sel == LOAD) && !(op_sel == STORE);
	
	always_comb begin
		if(start_load && !start_alu && !start_store)
			rw = 1;
		
		else if(start_store && !start_alu && !start_load)
			rw = 0;
	end
	
	single_mult_op alu1 (.clk(clk),.rst(rst),.A(A),.B(B),.start_alu(start_alu),.op_sel(op_sel),.result_alu(result_alu),.end_alu(end_alu));
	
	load load2 (.clk(clk),.rst(rst),.address_in(address_in),.data_cache(data_cache),.start_load(start_load),.gnt(gnt),
				.hit(hit),.end_load(end_load),.valid_load(valid_load),.address_cache_load(address_cache_load),.result_load(result_load));
				
	store store3 (.clk(clk),.rst(rst),.address_in(address_in),.start_store(start_store),.data_in(data_in),.hit(hit),
				.address_cache_store(address_cache_store),.data_cache(data_cache),.gnt(gnt),.valid_store(valid_store),
				.end_store(end_store),.result_store(result_store));
	
	
	assign valid = valid_load || valid_store;
	
	assign result = result_alu | result_load | result_store;
	
	assign address_cache = address_cache_load | address_cache_store;
	
	assign end_op = end_load | end_store | end_alu;
	
endmodule