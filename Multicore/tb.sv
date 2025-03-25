import pkg::*;

module tb_top();

logic clk = 1,rst;
logic [7:0] A,B;
logic start_op;
opcode op_sel;
logic [11:0] address_in;
logic [7:0] data_in;
logic end_op;
logic [15:0] result;

top top1 (.clk(clk),.rst(rst),.A(A),.B(B),.start_op(start_op),.op_sel(op_sel),.address_in(address_in),
		 .data_in(data_in),.end_op(end_op),.result(result));

always #5 clk = ~clk;

initial begin
	rst = 1;  
	#20; rst = 0;
	A = 8'hFF; 
	B = 8'hFE; 
	start_op = 1; 
	address_in = 12'h011;
	op_sel = LOAD;
	$display("result = %0b, end_op = %0b at time t = %0t",result,end_op,$time);
	
	
	#500; $finish;	
	end
	
initial begin
	$dumpfile("dump.vcd");
	$dumpvars;
end

endmodule