vlib work

vlog  package.sv
vlog  alu.sv
vlog  processor.sv
vlog  proc_interface.sv
vlog  proc_uvm.sv

vsim work.tb +test1="test"

#add wave -r *
run -all