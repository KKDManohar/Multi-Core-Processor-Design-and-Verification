vlib work
vdel -all

vlib work
vlog -lint package.sv
vlog -lint alu.sv
vlog -lint cache.sv
vlog -lint processor.sv
vlog -lint cpu.sv
vlog -lint arbiter.sv

vlog -lint top.sv

vlog -lint tb.sv

vsim -c -voptargs=+acc work.tb_top

add wave sim:/tb_top/result
add wave sim:/tb_top/end_op
add wave sim:/tb_top/top1/result
add wave sim:/tb_top/top1/end_op

add wave -r *

run -all
