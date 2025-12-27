`include "uvm_macros.svh"
import uvm_pkg::*;
import pkg::*;

class base_transaction extends uvm_sequence_item;
`uvm_object_utils(base_transaction)

	function new(input string path = "base_transaction");
		super.new(path);
	endfunction
	
	rand bit [7:0] A;
	rand bit [7:0] B;
	rand bit start_op;
	rand bit [3:0] op_sel;
	bit [15:0] result;
	bit end_op;
	
endclass

class single_cycle_item extends base_transaction;
`uvm_object_utils(single_cycle_item)

	function new(input string path = "single_cycle_gen");
		super.new(path);
	endfunction
	
	constraint c1 {
		op_sel inside {0,1,2,3,7,8,13,14,15};
	}
	
endclass

class multi_cycle_item extends base_transaction;
`uvm_object_utils(multi_cycle_item);

	function new(input string path = "multi_cycle_item");
		super.new(path);
	endfunction
	
	constraint c2 {
		op_sel inside {4,9,10,11,12};
	}
	
endclass


class single_cycle_multi_cycle_mix extends base_transaction;
`uvm_object_utils(single_cycle_multi_cycle_mix)

	rand bit a;
	static int count;
	
	constraint c1 {
		(count % 2 == 0) -> a == 0;
		(count % 2 == 1) -> a == 1;
		
		if (a == 1) {
			op_sel inside {0,1,2,3,7,8,13,14,15};
		}
		else {
			op_sel inside {4,9,10,11,12};
		}
	}
	
	function void post_randomize();
		count++;
	endfunction
	
endclass

class single_cycle_gen extends uvm_sequence#(single_cycle_item);
`uvm_object_utils(single_cycle_gen)

	single_cycle_item tr;
	int no_of_transactions;

	function new(input string path = "single_cycle_gen");
		super.new(path);
	endfunction
	
	virtual task body();
		repeat(no_of_transactions) begin
			tr = single_cycle_item::type_id::create("tr");
			start_item(tr);
			assert(tr.randomize());
			tr.start_op = 1;
			`uvm_info("Test1",$sformatf("A = %0d,B = %0d,start_op = %0d,op_sel = %0d",tr.A,tr.B,tr.start_op,tr.op_sel),UVM_NONE)
			finish_item(tr);
		end
	endtask
	
endclass

class multi_cycle_gen extends uvm_sequence#(multi_cycle_item);
`uvm_object_utils(multi_cycle_gen)

	multi_cycle_item tr;
	int no_of_transactions;

	function new(input string path = "multi_cycle_gen");
		super.new(path);
	endfunction
	
	virtual task body();
		repeat(no_of_transactions) begin
			tr = multi_cycle_item::type_id::create("tr");
			start_item(tr);
			assert(tr.randomize());
			tr.start_op = 1;
			`uvm_info("Test2",$sformatf("A = %0d,B = %0d,start_op = %0d,op_sel = %0d",tr.A,tr.B,tr.start_op,tr.op_sel),UVM_NONE)
			finish_item(tr);
		end
	endtask
endclass


class single_cycle_mix_multi_gen extends uvm_sequence#(single_cycle_multi_cycle_mix);
`uvm_object_utils(single_cycle_mix_multi_gen)

	single_cycle_multi_cycle_mix tr;
	static int no_of_transactions;
	
	function new(input string path = "single_cycle_mix_multi_gen");
		super.new(path)
	endfunction
	
	virtual task body();
		repeat(no_of_transactions) begin
			tr = single_cycle_multi_cycle_mix::type_id::create("tr");
			start_item(tr);
			assert(tr.randomize())
			tr.start_op = 1
			`uvm_info("Test3",$sformatf("A = %0d,B = %0d,start_op = %0d,op_sel = %0d",tr.A,tr.B,tr.start_op,tr.op_sel),UVM_NONE)
			finish_item(tr);
		end
	endfunction
	
endclass
				
			
class base_sequencer extends uvm_sequencer#(base_transaction);
`uvm_component_utils(base_sequencer);

	function new(input string path = "base_sequencer",uvm_component parent = null);
		super.new(path);
	endfunction
	
endclass

class drv extends uvm_driver#(base_transaction);
`uvm_component_utils(drv)

	base_transaction tr;
	
	virtual proc_intf pintf;

	function new(input string path = "drv", uvm_component parent = null);
		super.new(path,parent);
	endfunction
	
	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		
		if(!uvm_config_db#(virtual proc_intf)::get(this,"","pintf",pintf))
			`uvm_error("DRV","unnable to access the interface");
		
	endfunction
	
	virtual task run_phase(uvm_phase phase);
		super.run_phase(phase);
		
		forever begin
			tr = base_transaction::type_id::create("tr");
			seq_item_port.get_next_item(tr);
			pintf.A <= tr.A;
			pintf.B <= tr.B;
			pintf.op_sel <= tr.op_sel;
			pintf.start_op <= tr.start_op;
			`uvm_info("DRV",$sformatf("A = %0d, B = %0d, start_op = %0d, op_sel = %0d",tr.A,tr.B,tr.start_op,tr.op_sel),UVM_NONE)
			seq_item_port.item_done();
			repeat(5) @(posedge pintf.clk);
		end
		
	endtask
	
endclass


class mon extends uvm_monitor;
`uvm_component_utils(mon)

	function new(input string path = "mon",uvm_component parent = null);
		super.new(path,parent);
	endfunction
	
	base_transaction tr;
	uvm_analysis_port#(base_transaction) send;
	
	virtual proc_intf pintf;
	
	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		
		send = new("send", this);
		
		if(!uvm_config_db#(virtual proc_intf)::get(this,"","pintf",pintf))
			`uvm_error("mon","unable to acess the driver")
		
	endfunction
	
	virtual task run_phase(uvm_phase phase);
		super.run_phase(phase);
		
		forever begin
			repeat(5) @(posedge pintf.clk);
			tr = base_transaction::type_id::create("tr");
			tr.A = pintf.A;
			tr.B = pintf.B;
			tr.op_sel = pintf.op_sel;
			tr.start_op = pintf.start_op;
			tr.result = pintf.result;
			tr.end_op = pintf.end_op;
			`uvm_info("DRV",$sformatf("A = %0d, B = %0d, start_op = %0d, op_sel = %0d,result = %0d,end_op = %0d",
				tr.A,tr.B,tr.start_op,tr.op_sel,tr.result,tr.end_op),UVM_NONE)
			send.write(tr);
		end
	
	endtask
	
endclass


// class scb extends uvm_scoreboard;
// `uvm_component_utils(scb)

// 	uvm_analysis_imp#(base_transaction,scb) recv;
	
// 	function new(input string path = "scb",uvm_component parent = null);
// 		super.new(path,parent);
// 	endfunction
	
// 	virtual function void build_phase(uvm_phase phase);
// 		super.build_phase(phase);
		
// 		recv = new("recv",this);
// 	endfunction
	
// 	virtual function void write(base_transaction tr);
// 		case(tr.op_sel)
// 			4'b0000	: begin
// 						if(tr.result == 0)
// 							`uvm_info("Scb",$sformatf("Test Bench Passed A = %0d, B = %0d, start_op = %0d, op_sel = %0d,result = %0d,end_op = %0d",
// 							 tr.A,tr.B,tr.start_op,tr.op_sel,tr.result,tr.end_op),UVM_NONE)
// 						else
// 							`uvm_info("Scb",$sformatf("Test Bench Passed A = %0d, B = %0d, start_op = %0d, op_sel = %0d,result = %0d,end_op = %0d",
// 							 tr.A,tr.B,tr.start_op,tr.op_sel,tr.result,tr.end_op),UVM_NONE)
// 					  end
// 			4'b0001	: begin
// 						if(tr.result == tr.A + tr.B)
// 							`uvm_info("Scb",$sformatf("Test Bench Passed A = %0d, B = %0d, start_op = %0d, op_sel = %0d,result = %0d,end_op = %0d",
// 							 tr.A,tr.B,tr.start_op,tr.op_sel,tr.result,tr.end_op),UVM_NONE)
// 						else
// 							`uvm_info("Scb",$sformatf("Test Bench Passed A = %0d, B = %0d, start_op = %0d, op_sel = %0d,result = %0d,end_op = %0d",
// 							 tr.A,tr.B,tr.start_op,tr.op_sel,tr.result,tr.end_op),UVM_NONE)
// 					  end
// 			4'b0010	: begin
// 						if(tr.result == tr.A & tr.B)
// 							`uvm_info("Scb",$sformatf("Test Bench Passed A = %0d, B = %0d, start_op = %0d, op_sel = %0d,result = %0d,end_op = %0d",
// 							 tr.A,tr.B,tr.start_op,tr.op_sel,tr.result,tr.end_op),UVM_NONE)
// 						else
// 							`uvm_info("Scb",$sformatf("Test Bench Passed A = %0d, B = %0d, start_op = %0d, op_sel = %0d,result = %0d,end_op = %0d",
// 							 tr.A,tr.B,tr.start_op,tr.op_sel,tr.result,tr.end_op),UVM_NONE)
// 					  end
// 			4'b0011	: begin
// 						if(tr.result == tr.A - tr.B)
// 							`uvm_info("Scb",$sformatf("Test Bench Passed A = %0d, B = %0d, start_op = %0d, op_sel = %0d,result = %0d,end_op = %0d",
// 							 tr.A,tr.B,tr.start_op,tr.op_sel,tr.result,tr.end_op),UVM_NONE)
// 						else
// 							`uvm_info("Scb",$sformatf("Test Bench Passed A = %0d, B = %0d, start_op = %0d, op_sel = %0d,result = %0d,end_op = %0d",
// 							 tr.A,tr.B,tr.start_op,tr.op_sel,tr.result,tr.end_op),UVM_NONE)
// 					  end
// 			4'b0100	: begin
// 						if(tr.result == tr.A * tr.B)
// 							`uvm_info("Scb",$sformatf("Test Bench Passed A = %0d, B = %0d, start_op = %0d, op_sel = %0d,result = %0d,end_op = %0d",
// 							 tr.A,tr.B,tr.start_op,tr.op_sel,tr.result,tr.end_op),UVM_NONE)
// 						else
// 							`uvm_info("Scb",$sformatf("Test Bench Passed A = %0d, B = %0d, start_op = %0d, op_sel = %0d,result = %0d,end_op = %0d",
// 							 tr.A,tr.B,tr.start_op,tr.op_sel,tr.result,tr.end_op),UVM_NONE)
// 					  end
// 			4'b0111	: begin
// 						if(tr.result == {tr.A,tr.B} >> 1)
// 							`uvm_info("Scb",$sformatf("Test Bench Passed A = %0d, B = %0d, start_op = %0d, op_sel = %0d,result = %0d,end_op = %0d",
// 							 tr.A,tr.B,tr.start_op,tr.op_sel,tr.result,tr.end_op),UVM_NONE)
// 						else
// 							`uvm_info("Scb",$sformatf("Test Bench Passed A = %0d, B = %0d, start_op = %0d, op_sel = %0d,result = %0d,end_op = %0d",
// 							 tr.A,tr.B,tr.start_op,tr.op_sel,tr.result,tr.end_op),UVM_NONE)
// 					  end
// 			4'b1000	: begin
// 						if(tr.result == {tr.A,tr.B} << 1)
// 							`uvm_info("Scb",$sformatf("Test Bench Passed A = %0d, B = %0d, start_op = %0d, op_sel = %0d,result = %0d,end_op = %0d",
// 							 tr.A,tr.B,tr.start_op,tr.op_sel,tr.result,tr.end_op),UVM_NONE)
// 						else
// 							`uvm_info("Scb",$sformatf("Test Bench Passed A = %0d, B = %0d, start_op = %0d, op_sel = %0d,result = %0d,end_op = %0d",
// 							 tr.A,tr.B,tr.start_op,tr.op_sel,tr.result,tr.end_op),UVM_NONE)
// 					  end
// 			4'b1001	: begin
// 						if(tr.result == (tr.A * tr.B) - tr.A)
// 							`uvm_info("Scb",$sformatf("Test Bench Passed A = %0d, B = %0d, start_op = %0d, op_sel = %0d,result = %0d,end_op = %0d",
// 							 tr.A,tr.B,tr.start_op,tr.op_sel,tr.result,tr.end_op),UVM_NONE)
// 						else
// 							`uvm_info("Scb",$sformatf("Test Bench Passed A = %0d, B = %0d, start_op = %0d, op_sel = %0d,result = %0d,end_op = %0d",
// 							 tr.A,tr.B,tr.start_op,tr.op_sel,tr.result,tr.end_op),UVM_NONE)
// 					  end
// 			4'b1010	: begin
// 						if(tr.result == (tr.A * 4 * tr.B) - tr.A)
// 							`uvm_info("Scb",$sformatf("Test Bench Passed A = %0d, B = %0d, start_op = %0d, op_sel = %0d,result = %0d,end_op = %0d",
// 							 tr.A,tr.B,tr.start_op,tr.op_sel,tr.result,tr.end_op),UVM_NONE)
// 						else
// 							`uvm_info("Scb",$sformatf("Test Bench Passed A = %0d, B = %0d, start_op = %0d, op_sel = %0d,result = %0d,end_op = %0d",
// 							 tr.A,tr.B,tr.start_op,tr.op_sel,tr.result,tr.end_op),UVM_NONE)
// 					  end
// 			4'b1011	: begin
// 						if(tr.result == (tr.A * tr.B) + tr.A)
// 							`uvm_info("Scb",$sformatf("Test Bench Passed A = %0d, B = %0d, start_op = %0d, op_sel = %0d,result = %0d,end_op = %0d",
// 							 tr.A,tr.B,tr.start_op,tr.op_sel,tr.result,tr.end_op),UVM_NONE)
// 						else
// 							`uvm_info("Scb",$sformatf("Test Bench Passed A = %0d, B = %0d, start_op = %0d, op_sel = %0d,result = %0d,end_op = %0d",
// 							 tr.A,tr.B,tr.start_op,tr.op_sel,tr.result,tr.end_op),UVM_NONE)
// 					  end
// 			4'b1100	: begin
// 						if(tr.result == (tr.A * 3))
// 							`uvm_info("Scb",$sformatf("Test Bench Passed A = %0d, B = %0d, start_op = %0d, op_sel = %0d,result = %0d,end_op = %0d",
// 							 tr.A,tr.B,tr.start_op,tr.op_sel,tr.result,tr.end_op),UVM_NONE)
// 						else
// 							`uvm_info("Scb",$sformatf("Test Bench Passed A = %0d, B = %0d, start_op = %0d, op_sel = %0d,result = %0d,end_op = %0d",
// 							 tr.A,tr.B,tr.start_op,tr.op_sel,tr.result,tr.end_op),UVM_NONE)
// 					  end
// 			4'b0000	: begin
// 						if(tr.result == tr.A ^ tr.B)
// 							`uvm_info("Scb",$sformatf("Test Bench Passed A = %0d, B = %0d, start_op = %0d, op_sel = %0d,result = %0d,end_op = %0d",
// 							 tr.A,tr.B,tr.start_op,tr.op_sel,tr.result,tr.end_op),UVM_NONE)
// 						else
// 							`uvm_info("Scb",$sformatf("Test Bench Passed A = %0d, B = %0d, start_op = %0d, op_sel = %0d,result = %0d,end_op = %0d",
// 							 tr.A,tr.B,tr.start_op,tr.op_sel,tr.result,tr.end_op),UVM_NONE)
// 					  end
// 			4'b0000	: begin
// 						if(tr.result == tr.A | tr.B)
// 							`uvm_info("Scb",$sformatf("Test Bench Passed A = %0d, B = %0d, start_op = %0d, op_sel = %0d,result = %0d,end_op = %0d",
// 							 tr.A,tr.B,tr.start_op,tr.op_sel,tr.result,tr.end_op),UVM_NONE)
// 						else
// 							`uvm_info("Scb",$sformatf("Test Bench Passed A = %0d, B = %0d, start_op = %0d, op_sel = %0d,result = %0d,end_op = %0d",
// 							 tr.A,tr.B,tr.start_op,tr.op_sel,tr.result,tr.end_op),UVM_NONE)
// 					  end
// 			4'b0000	: begin
// 						if(tr.result == tr.A ^ ~tr.B)
// 							`uvm_info("Scb",$sformatf("Test Bench Passed A = %0d, B = %0d, start_op = %0d, op_sel = %0d,result = %0d,end_op = %0d",
// 							 tr.A,tr.B,tr.start_op,tr.op_sel,tr.result,tr.end_op),UVM_NONE)
// 						else
// 							`uvm_info("Scb",$sformatf("Test Bench Passed A = %0d, B = %0d, start_op = %0d, op_sel = %0d,result = %0d,end_op = %0d",
// 							 tr.A,tr.B,tr.start_op,tr.op_sel,tr.result,tr.end_op),UVM_NONE)
// 					  end
// 		endcase
		
// 		$display("--------------------------------------------------");
// 	endfunction
	
// endclass

import "DPI-C" function int reference_model(byte A, byte B, byte op_sel);

class scb extends uvm_scoreboard;
`uvm_component_utils(scb)

	uvm_analysis_imp#(base_transaction, scb) recv;

	function new(input string path = "scb", parent = null);
		super.new(path,parent);
	endfunction

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase)
		recv = new("recv",this);
	endfunction

	virtual function void write(base_transaction tr);
		int expected;

		expected = reference_model(tr.A,tr.b,tr.op_sel);

		if(tr.result == expected) begin
			`uvm_info("Scb",$sformatf("Test Bench Passed A = %0d, B = %0d, start_op = %0d, op_sel = %0d,result = %0d,end_op = %0d",
 							 tr.A,tr.B,tr.start_op,tr.op_sel,tr.result,tr.end_op),UVM_NONE)
		end
		else begin
			`uvm_info("Scb",$sformatf("Test Bench Failed A = %0d, B = %0d, start_op = %0d, op_sel = %0d,result = %0d,end_op = %0d",
 							 tr.A,tr.B,tr.start_op,tr.op_sel,tr.result,tr.end_op),UVM_NONE)
		end

	endfunction

endclass



class agent extends uvm_agent;
`uvm_component_utils(agent)

	drv d;
	base_sequencer seqr;
	mon m;

	function new(input string path = "agent",uvm_component parent);
		super.new(path,parent);
	endfunction
	
	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		
		seqr = base_sequencer::type_id::create("seqr",this);
		d = drv::type_id::create("d",this);
		m = mon::type_id::create("m",this);
		
	endfunction
	
	
	virtual function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		
		d.seq_item_port.connect(seqr.seq_item_export);
		
	endfunction
	
endclass


class env extends uvm_env;
`uvm_component_utils(env)

	agent a;
	scb s;

	function new(input string path = "env",uvm_component parent);
		super.new(path,parent);
	endfunction
	
	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		
		a = agent::type_id::create("a",this);
		s = scb::type_id::create("s",this);
		
	endfunction
	
	virtual function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		
		a.m.send.connect(s.recv);
		
	endfunction
	
endclass

class test extends uvm_test;
`uvm_component_utils(test)

	env e;
	single_cycle_gen seq1;
	multi_cycle_gen seq2;
	bit seq1_done;
	bit seq2_done;
	

	function new(input string path = "test",uvm_component parent);
		super.new(path,parent);
	endfunction
	
	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		
		e = env::type_id::create("e",this);
		seq1 = single_cycle_gen::type_id::create("seq1");
		seq2 = multi_cycle_gen::type_id::create("seq2");
		
		seq1.no_of_transactions = 5;
		seq2.no_of_transactions = 5;
		
	endfunction
	
	virtual task run_phase(uvm_phase phase);
		
		// phase.raise_objection(this);
		// seq1.start(e.a.seqr);
		// #40;
		// seq2.start(e.a.seqr);
		// #40;
		// phase.drop_objection(this);
		phase.raise_objection(this);
		
		fork 
			begin
				seq1.start(e.a.seqr);
				seq1_done = 1;
			end
			begin
				#40;
				seq2.start(e.a.seqr);
				seq2_done = 1;
			end
		join_none
		// wait(seq1_done && seq2_done);
		phase.drop_objection(phase);
	endtask
	
	// virtual function bit phase_ready_to_end();
		// return seq1_done && seq2_done;
	// endfunction
	
	// virtual task final_phase(uvm_phase phase);
		// phase.drop_objection(phase);
	// endtask
	
	// virtual function void phase_ready_to_end(uvm_phase phase);
        // // Returns 1 only when all sequences have completed
        // if (seq1_done && seq2_done) begin
            // phase.drop_objection(this); // Drop objection automatically
        // end
    // endfunction
	
endclass


module tb;

	proc_intf pintf();
	

	
	multi_processor DUT(.clk(pintf.clk),.rst(pintf.rst),.A(pintf.A),.B(pintf.B),.start_op(pintf.start_op),.op_sel(opcode'(pintf.op_sel)),
						.address_in(pintf.address_in),.data_in(pintf.data_in),.hit(pintf.hit),.gnt(pintf.gnt),.rw(pintf.rw),.data_cache(pintf.data_cache),
						.result(pintf.result),.end_op(pintf.end_op),.valid(pintf.valid),.address_cache(pintf.address_cache));
						
	
	initial begin
		string test_name;
		if(!$value$plusargs("test1 = %s",test_name))
			$display("test_name = %s, compnent is not passed correctly",test_name);
		uvm_config_db#(virtual proc_intf)::set(null,"*","pintf",pintf);
		run_test(test_name);
	end
	
	initial begin
		pintf.clk = 0;
		forever #5 pintf.clk = ~pintf.clk;
	end
	
	initial begin
	
		pintf.rst = 1;
		#20;
		pintf.rst = 0;
		
	end
	
endmodule							
