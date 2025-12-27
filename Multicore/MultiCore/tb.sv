import pkg::*;

module tb_top();

logic clk = 1,rst;
logic [7:0] A[2:0],B[2:0];
logic start_op[2:0];
opcode op_sel[2:0];
logic [11:0] address_in[2:0];
logic [7:0] data_in[2:0];
logic end_op[2:0];
logic [15:0] result[2:0];

top top1 (.clk(clk),.rst(rst),.A(A),.B(B),.start_op(start_op),.op_sel(op_sel),.address_in(address_in),
		 .data_in(data_in),.end_op(end_op),.result(result));

always #5 clk = ~clk;

initial begin
	rst = 1;  
	#20; rst = 0;
	A[0] = 8'h01;
	B[0] = 8'h05;
	start_op[0] = 1;
	op_sel[0] = ADD;
	$display("result = %0p, end_op = %0p at time t = %0t",result[0],end_op[0],$time);
	#50;
	start_op[0] = 0;	
	// A[0] = 8'hFF; 
	// B[0] = 8'hFE; 
	// start_op[0] = 1; 
	// address_in[0] = 12'h011;
	// data_in[0] = 8'hFE;
	// op_sel[0] = STORE;
	// $display("result = %0p, end_op = %0p at time t = %0t",result[0],end_op[0],$time);
	// #50;
	// start_op[0] = 0;
	// #220;
	// start_op[1] = 1;
	// A[1] = 8'hFF; 
	// B[1] = 8'hFE; 
	// op_sel[1] = ADD;
	// $display("result = %0p, end_op = %0p at time t = %0t",result[1],end_op[1],$time);
	// #30;
	// start_op[1] = 0;
	// #20;
	// A[0] = 8'h01; 
	// B[0] = 8'h11; 
	// start_op[0] = 1; 
	// address_in[0] = 12'h101;
	// //data_in[0] = 8'hFE;
	// op_sel[0] = LOAD;
	// $display("result = %0p, end_op = %0p at time t = %0t",result[0],end_op[0],$time);
	// #20;
	// address_in[0] = 12'h111;
	// //data_in[0] = 8'hFE;
	// op_sel[0] = LOAD;
		// $display("result = %0p, end_op = %0p at time t = %0t",result[0],end_op[0],$time);
	// #20;
	// start_op[0] = 0;
	#500; $finish;	
	end
	
initial begin
	$dumpfile("dump.vcd");
	$dumpvars;
end

//initial $monitor("result = %0p, end_op = %0p at time t = %0t",result,end_op,$time);

endmodule