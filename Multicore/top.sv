import pkg::*;

module top(
			input logic clk,rst,
			input logic [7:0] A[2:0],B[2:0],
			input logic start_op[2:0],
			input opcode op_sel[2:0],
			input logic [11:0] address_in[2:0],
			input logic [7:0] data_in[2:0],
			output logic end_op[2:0],
			output logic [15:0] result[2:0]
			);

	wire req_arb[2:0], gnt_arb[2:0];
	
	cpu cpu1 (.clk(clk),.rst(rst),.A(A[0]),.B(B[0]),.start_op(start_op[0]),.op_sel(op_sel[0]),.address_in(address_in[0]),
				.data_in(data_in[0]),.gnt_arb(gnt_arb[0]),.req_arb(req_arb[0]),.result(result[0]),.end_op(end_op[0]));
		
	cpu cpu2 (.clk(clk),.rst(rst),.A(A[1]),.B(B[1]),.start_op(start_op[1]),.op_sel(op_sel[1]),.address_in(address_in[1]),
				.data_in(data_in[1]),.gnt_arb(gnt_arb[1]),.req_arb(req_arb[1]),.result(result[1]),.end_op(end_op[1]));
				
	cpu cpu3 (.clk(clk),.rst(rst),.A(A[2]),.B(B[2]),.start_op(start_op[2]),.op_sel(op_sel[2]),.address_in(address_in[2]),
				.data_in(data_in[2]),.gnt_arb(gnt_arb[2]),.req_arb(req_arb[2]),.result(result[2]),.end_op(end_op[2]));
	
	arbiter arb (.clk(clk),.rst(rst),.req_arb(req_arb),.gnt_arb(gnt_arb));
				
endmodule