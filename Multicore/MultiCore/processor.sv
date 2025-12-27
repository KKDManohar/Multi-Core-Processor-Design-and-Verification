import pkg::*;	
	
module multi_processor(
	input wire clk,rst,
	input wire [7:0] A,B,
	input wire start_op,
	input opcode op_sel,
	input wire [11:0] address_in,
	input wire [7:0] data_in,
	input wire hit,gnt,
	inout wire [7:0] data_cache,
	output reg [15:0] result,
	output reg rw,
	output reg end_op,
	output reg valid,
	output reg [11:0] address_cache
);
	
	logic start_load;
	logic end_load;
	logic start_store;
	logic end_store;
	logic start_alu;
	logic end_alu;
	
	logic valid_load, valid_store;
	
	wire [15:0] result_alu, result_load, result_store;
	
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

	assign address_cache = address_cache_load | address_cache_store;
	
	always_comb begin
		if(op_sel == LOAD) begin
			result = result_load;
			end_op = end_load;
		end
		
		else if(op_sel == STORE) begin
			result = result_store;
			end_op = end_store;
		end
		
		else if(!(op_sel == LOAD) && !(op_sel == STORE)) begin
			result = result_alu;
			end_op = end_alu;
		end
		
		else begin
			end_op = 0;
			result = 0;
		end
		
	end
		
endmodule