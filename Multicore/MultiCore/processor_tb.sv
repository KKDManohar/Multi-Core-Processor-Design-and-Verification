import pkg::*;

module tb_processor_top();

	logic clk,rst;
	logic [7:0] A,B;
	logic start_op;
	opcode op_sel;
	logic [11:0] address_in;
	logic [7:0] data_in;
	logic hit,gnt;
	wire [7:0] data_cache;
	logic [7:0] tb_data_cache_drive;
	logic tb_drive_en;
	logic [15:0] result;
	logic rw;
	logic end_op;
	logic valid;
	logic [11:0] address_cache;
	
	assign data_cache = tb_drive_en ? tb_data_cache_drive : 8'bz;
	
	multi_processor DUT (.clk(clk),.rst(rst),.A(A),.B(B),.start_op(start_op),.op_sel(op_sel),.address_in(address_in),.data_in(data_in),.hit(hit),.gnt(gnt),
						.data_cache(data_cache),.result(result),.rw(rw),.end_op(end_op),.valid(valid),.address_cache(address_cache));
						
						
	initial begin
		clk = 1;
		forever #5 clk = ~clk;
	end
	
	
	initial begin
		rst = 1;
		tb_drive_en = 0;
		tb_data_cache_drive = '0;
		hit = 0;
		gnt = 0;
		#20 rst = 0;
		
		// ADD
        A = 8'd10; B = 8'd7; op_sel = ADD; start_op = 1;
        repeat(2) @(posedge clk); start_op = 0;
        wait (end_op);
        $display("[%0t] ADD: %0d", $time, result);
		#50;
		
		// AND
        A = 8'hF0; B = 8'hAA; op_sel = AND; start_op = 1;
        repeat(2) @(posedge clk); start_op = 0;
        wait (end_op);
        $display("[%0t] AND: %0h", $time, result);
		#50;
		
		// MUL
        A = 8'd4; B = 8'd6; op_sel = MUL; start_op = 1;
        repeat(4) @(posedge clk); start_op = 0;
        wait (end_op);
        $display("[%0t] MUL: %0d", $time, result);
		#50;
		
		// SHIFT_RIGHT
        A = 8'd10; B = 8'd2; op_sel = SHIFT_RIGHT; start_op = 1;
        repeat(2) @(posedge clk); start_op = 0;
        wait (end_op);
        $display("[%0t] SHIFT_RIGHT: %0d", $time, result);
		#50;
		
		// SHIFT_LEFT
        A = 8'd3; B = 8'd5; op_sel = SHIFT_LEFT; start_op = 1;
        repeat(2) @(posedge clk); start_op = 0;
        wait (end_op);
        $display("[%0t] SHIFT_LEFT: %0d", $time, result);
		#50;
		
		// SF1
        A = 8'd6; B = 8'd2; op_sel = SF1; start_op = 1;
        repeat(4) @(posedge clk); start_op = 0;
        wait (end_op);
        $display("[%0t] SF1: %0d", $time, result);
		#50;

        // SF2
        A = 8'd2; B = 8'd3; op_sel = SF2; start_op = 1;
        repeat(4) @(posedge clk); start_op = 0;
        wait (end_op);
        $display("[%0t] SF2: %0d", $time, result);
		#50;
		
		// SF3
        A = 8'd5; B = 8'd4; op_sel = SF3; start_op = 1;
        repeat(4) @(posedge clk);  @(posedge clk); start_op = 0;
        wait (end_op);
        $display("[%0t] SF3: %0d", $time, result);
		#50;

        // SF4
        A = 8'd7; B = 8'd1; op_sel = SF4; start_op = 1;
        repeat(4) @(posedge clk);  @(posedge clk); start_op = 0;
        wait (end_op);
        $display("[%0t] SF4: %0d", $time, result);
		#50;

        // RB1
        A = 8'h0F; B = 8'hF0; op_sel = RB1; start_op = 1;
        repeat(2) @(posedge clk);  @(posedge clk); start_op = 0;
        wait (end_op);
        $display("[%0t] RB1: %0h", $time, result);
		#50;

        // RB2
        A = 8'h11; B = 8'hAA; op_sel = RB2; start_op = 1;
        repeat(2) @(posedge clk); start_op = 0;
        wait (end_op);
        $display("[%0t] RB2: %0h", $time, result);
		#50;

        // RB3
        A = 8'h33; B = 8'h0F; op_sel = RB3; start_op = 1;
        repeat(2) @(posedge clk); start_op = 0;
        wait (end_op);
        $display("[%0t] RB3: %0h", $time, result);
		#50;

        $display("All ALU operations tested.");

		
		#500; $finish;
	end
	
endmodule
		
		
		
							

	