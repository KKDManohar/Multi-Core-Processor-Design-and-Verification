`include "uvm_macros.svh"
import uvm_pkg::*


class transaction extends uvm_sequence_item;
`uvm_object_uitls(transaction)

    rand bit [2:0] req_arb;
    logic [2:0] gnt_arb;

    function new(input string path = "transaction");
        super.new(path,parent);
    endfunction

    constraint c1 {
        unique{req_arb};
    }

endclass

class generator extends uvm_sequence#(transaction);
`uvm_object_utils(generator)

    transaction tr;
    static int no_of_transactions;

    function new(input string path = "generator");
        super.new(path)
    endfunction

    virtual task body();

        //Funtional test cases cover
        repeat(no_of_transactions) begin
            tr = transaction::type_id::create("tr");
            assert(tr.randomize());
            repeat($countones(tr.req_arb)) begin
                start+item(tr);
                `uvm_info("Gen",$sformatf("req_arb = %0p",tr.req_arb),UVM_NONE)
                finish_item(tr);
            end
        end

        // priorioty rotation test case

        req_item = transaction::type_id::create("req_item");
        req_item.req_arb = 3'b111;

        repeat(4) begin
            start_item(req_item);
            `uvm_info("priorioty rotation test case",$sformatf("req_arb = %0p",tr.req_arb),UVM_NONE)
            finish_item(req_item);
        end

        //edge and corner cases
        req_item.req_arb = 3'b010;
        start_item(req_item);
        `uvm_info("edge and corner cases",$sformatf("req_arb = %0p",tr.req_arb),UVM_NONE)
        finish_item(req_arb)

        req_item.req_arb = 3'b101;
        start_item(req_arb);
        `uvm_info("edge and corner cases",$sformatf("req_arb = %0p",tr.req_arb),UVM_NONE)
        finish_item(req_arb);

    endtask

endclass


import "DPI-C" function int arbiter_ref(byte req_arb);

class scb extends uvm_scoreboard();
`uvm_component_utils(scb)

    uvm_analysis_imp#(transaction,scb) recv;

    function new(input string path = "scb",parent = null);
        super.new(path,parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);

        super.build_phase(phase)
        recv = new("recv",this);

    endfunction

    virtual function vois write(transaction tr);

        scb_grnt_arb[3];

        scb_grnt_arb = arbiter_ref(tr.req_arb);

        if(tr.gnt_arb == scb_grnt_arb) begin
            `uvm_info("SCOREBOARD", $sformatf("PASS: req=%b, grant=%b",tr.req, tr.grant), UVM_LOW)
        end
        else begin
            `uvm_info("SCOREBOARD", $sformatf("FAIL: req=%b, grant=%b",tr.req, tr.grant), UVM_LOW)
        end
        
    endfunction


endclass
















            





