interface proc_intf();
	logic clk,rst;
	logic [7:0] A,B;
	logic start_op;
	logic [3:0] op_sel;
	logic [11:0] address_in;
	logic [7:0] data_in;
	logic hit,gnt;
	wire [7:0] data_cache;
	logic [15:0] result;
	logic rw;
	logic end_op;
	logic valid;
	logic [11:0] address_cache;
endinterface

