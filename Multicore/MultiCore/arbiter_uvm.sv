`include "uvm_macros.svh"
import uvm_pkg::*;

class transaction extends uvm_sequence_item;
`uvm_object_utils(transaction)

	function new(input string path = "transaction");
		super.new(path);
	endfunction
	
	rand logic [2:0] req_arb;
	logic [2:0] gnt_arb;
	int trans_id;
	
endclass


class generator extends uvm_sequence #(transaction);
`uvm_object_utils(generator)
//`uvm_declare_p_sequencer(uvm_sequencer #(generator))

	static int trans_id_counter = 0;
	uvm_event grants_verified;
	
	function new(input string path = "generator");
		super.new(path);
	endfunction
	
	virtual task body();
		transaction tr;
		grants_verified = uvm_event_pool::get_global("grants_verified");
		repeat(15) begin
			tr = transaction::type_id::create("tr");
			start_item(tr);
			assert(tr.randomize());
			tr.trans_id = trans_id_counter;
			`uvm_info("GEN",$sformatf("req_arb = %0p",tr.req_arb),UVM_NONE)
			trans_id_counter++;
			finish_item(tr);
			`uvm_info("GEN",$sformatf("Waiting for the grants to be verified trans_id = %0d",tr.trans_id),UVM_NONE);
			grants_verified.wait_trigger();
		end
	endtask
endclass

class driver extends uvm_driver#(transaction);
`uvm_component_utils(driver)

	transaction tr;
	virtual arbiter_if aif;
	logic [2:0] req_arb;
	bit req_active = 0;
	
	function new(input string path = "driver",uvm_component parent = null);
		super.new(path,parent);
	endfunction
	
	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if(!(uvm_config_db#(virtual arbiter_if)::get(this,"","aif",aif)))
			`uvm_error("DRV","Cant be able to access the interface")
	endfunction
	
	virtual task run_phase(uvm_phase phase);
		tr = transaction::type_id::create("tr");
		forever begin
			if(!req_active) begin
				seq_item_port.get_next_item(tr);
				aif.req_arb <= tr.req_arb;
				req_active = 1;
				aif.trans_id = tr.trans_id;
				`uvm_info("DRV",$sformatf("Driving new request trans_id = %0d, req_arb = %0p",tr.trans_id, tr.req_arb),UVM_NONE)
				seq_item_port.item_done();
				#40;
			end
			aif.req_arb = req_arb;
		end
	endtask
	
	function void clear_request();
		req_active = 0;
		req_arb = '{0,0,0};
	endfunction
	
endclass


class monitor extends uvm_monitor;
`uvm_component_utils(monitor)

	uvm_analysis_port#(transaction) send;
	transaction tr;
	virtual arbiter_if aif;

	function new(input string path = "monitor", uvm_component parent = null);
		super.new(path,parent);
	endfunction
	
	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		
		if(!(uvm_config_db#(virtual arbiter_if)::get(this,"","aif",aif)))
			`uvm_error("MON","Cant be able to access the interface")
		
		tr = transaction::type_id::create("tr");
		
		send = new("send",this);
		
	endfunction
	
	virtual task run_phase(uvm_phase phase);
		
		forever begin
			#40;
			tr.req_arb = aif.req_arb;
			tr.gnt_arb = aif.gnt_arb;
			tr.trans_id = aif.trans_id;
			`uvm_info("MON",$sformatf("req_arb = %0p, gnt_arb = %0p",aif.req_arb,aif.gnt_arb),UVM_NONE)
			send.write(tr);
		end
	endtask
	
endclass



class scoreboard extends uvm_scoreboard;
`uvm_component_utils(scoreboard)

	uvm_analysis_imp#(transaction,scoreboard) recv;
	logic [2:0] mask = 3'b100;  //the initial mask req_arb[0] has highest prioritys
	
	typedef struct {
		int trans_id;
		logic [2:0] req_arb;
		int expected_grants;
		int grant_count;
		logic [2:0] granted;
	} req_t;
	
	req_t current_req;
	bit has_current_req = 0;
	
	typedef struct {
		int trans_id;
		logic [2:0] gnt_arb;
	} gnt_t;
	
	gnt_t gnt_queue[$];

	function new(input string path = "scoreboard",uvm_component parent = null);
		super.new(path,parent);
	endfunction
	
	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		
		recv = new("recv",this);
		
	endfunction
	
	function int popcount(logic [2:0] vec);
		int count = 0;
		for(int i = 0; i < 3; i++)  begin
			if(vec[i]) begin
				count++;
			end
		end
		return count;
	endfunction
	
	virtual function void write(transaction tr);
	
		`uvm_info("SB_Mask", $sformatf("Current mask = %0b", mask), UVM_NONE);
		
		if(!has_current_req && |tr.req_arb) begin
			current_req.trans_id = tr.trans_id;
			current_req.req_arb = tr.req_arb;
			current_req.expected_grants = popcount(tr.req_arb);
			current_req.grant_count = 0;
			current_req.granted = '{0,0,0};
			has_current_req = 1;
			`uvm_info("SB_current_req",$sformatf("started processing request: trans_id = %0d, req=%p, expected_grants = %0d",
			current_req.trans_id, current_req.req_arb, current_req.expected_grants), UVM_MEDIUM)
		end
		
		if(|tr.gnt_arb) begin
			gnt_t gnt;
			gnt.trans_id = tr.trans_id;
			gnt.gnt_arb = tr.gnt_arb;
			gnt_queue.push_back(gnt);
			`uvm_info("SB_REQ_QUEUE", $sformatf("Pushed grant: trans_id = %0d, gnt = %p",gnt.trans_id, gnt.gnt_arb), UVM_NONE)
		end
		
		if(has_current_req && gnt_queue.size() > 0) begin
			gnt_t gnt = gnt_queue.pop_front();
			logic [2:0] expected_gnt = 3'b000;
			logic [2:0] masked_req;
			
			if(current_req.trans_id != gnt.trans_id) begin
				`uvm_info("SB_ID_MISMATCH",$sformatf("Transaction ID mismatch: req_trans_id = %0d, gnt_trans_id = %0d, req = %p, gnt = %p",
					current_req.trans_id, gnt.trans_id, current_req.req_arb, gnt.gnt_arb), UVM_NONE)
				return;
			end
			
			for(int i = 0; i < 3; i++) begin
				masked_req[i] = current_req.req_arb[i] & mask[i] & !current_req.granted[i];
			end
			
			for(int i = 0; i < 3; i++) begin
				if(masked_req[i]) begin
					expected_gnt[i] = 1'b1;
					break;
				end
			end
			
			if(expected_gnt == 3'b000) begin
				for(int i = 0; i < 3; i++) begin
					if(current_req.req_arb[i] && !current_req.granted[i]) begin
						expected_gnt[i] = 1'b1;
						break;
					end
				end
			end
			
			if(expected_gnt != gnt.gnt_arb) begin
				`uvm_info("SB_FAIL",$sformatf("Mismatch: trans_id = %0d, req = %p, mask = %b, granted = %p,grant_count = %0d, expected_grants = %p, actual_gnt = %p",
				current_req.trans_id, current_req.req_arb, mask, current_req.granted, current_req.grant_count, current_req.expected_grants, expected_gnt, gnt.gnt_arb),UVM_NONE)
			end
			else begin	
				`uvm_info("SB_FAIL",$sformatf("Mismatch: trans_id = %0d, req = %p, mask = %b, granted = %p,grant_count = %0d, expected_grants = %p, actual_gnt = %p",
				current_req.trans_id, current_req.req_arb, mask, current_req.granted, current_req.grant_count, current_req.expected_grants, expected_gnt, gnt.gnt_arb), UVM_NONE)
				
				current_req.grant_count++;
				
				for(int i = 0; i < 3; i++) begin
					if(gnt.gnt_arb[i]) begin
						current_req.granted[i] = 1;
					end
				end
			end
			
			mask = {mask[1], mask[2], mask[0]};
			
			if(current_req.grant_count == current_req.expected_grants) begin
				driver drv;
				uvm_event grants_verified = uvm_event_pool::get_global("grants_verified");
				
				
				if(current_req.grant_count != popcount(current_req.granted)) begin
					`uvm_info("SB_FAIL",$sformatf("Grant count mismatch: trans_id = %0d, granted = %p,grant_count = %0d, expected_grants = %p",
				current_req.trans_id, current_req.granted, current_req.grant_count, current_req.expected_grants), UVM_NONE)
				end
				`uvm_info("SB_FAIL",$sformatf("Complete requested: trans_id = %0d, req = %p, recieced %0d grants",
				current_req.trans_id, current_req.req_arb, current_req.grant_count), UVM_NONE)
				
				has_current_req = 0;
	
				grants_verified.trigger();
				
				if($cast(drv, get_parent().get_child("a").get_child("drv"))) begin
					drv.clear_request();
				end else begin
					`uvm_info("SB_CAST_FAIL",$sformatf("failed to cast the driver"), UVM_NONE)
				end
				
			end
			
		end
		
	endfunction
				
	
endclass

class agent extends uvm_agent;
`uvm_component_utils(agent);

	driver drv;
	monitor mon;
	uvm_sequencer#(transaction) seqr;
	
	function new(input string path = "agent",uvm_component parent = null);
		super.new(path,parent);
	endfunction
	
	virtual function void build_phase(uvm_phase phase);
		
		drv = driver::type_id::create("drv",this);
		
		mon = monitor::type_id::create("mon",this);
		
		seqr = uvm_sequencer#(transaction)::type_id::create("seqr",this);
		
	endfunction
	
	virtual function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		
		drv.seq_item_port.connect(seqr.seq_item_export);
		
	endfunction
	
endclass

class env extends uvm_env;
`uvm_component_utils(env)

	agent a;
	scoreboard scb;

	function new(input string path = "env",uvm_component parent = null);
		super.new(path,parent);
	endfunction
	
	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		
		a = agent::type_id::create("a",this);
		scb = scoreboard::type_id::create("scb",this);
		
	endfunction
	
	virtual function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);

		a.mon.send.connect(scb.recv);
		
	endfunction
	
endclass

class test extends uvm_test;
`uvm_component_utils(test);
	
	env e;
	generator gen;

	function new(input string path = "test",uvm_component parent = null);
		super.new(path,parent);
	endfunction
	
	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		
		e = env::type_id::create("e",this);
		gen = generator::type_id::create("gen");
		
	endfunction
	
	virtual task run_phase(uvm_phase phase);
		phase.raise_objection(this);
		#40;
		gen.start(e.a.seqr);
		#40;
		phase.drop_objection(this);
	endtask
	
endclass


module top;
	
	arbiter_if aif();
	
	round_robin_arbiter DUT(.clk(aif.clk),.rst(aif.rst),.req_arb(aif.req_arb),.gnt_arb(aif.gnt_arb));
	
	initial begin
		
		uvm_config_db#(virtual arbiter_if)::set(null,"*","aif",aif);
		
		run_test("test");
		
	end
	
	initial
		aif.clk = '1;
		
	always #5 aif.clk = ~aif.clk;
	
	initial
		begin
			
			aif.rst = '1;
			#10;
			aif.rst = '0;
		
		end
		
endmodule

	
	
	
	
			
			
	
	



	
		


	
	
		
		
	
	