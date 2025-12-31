
vlib work
vmap work work

vcom -work ./work ../src/operators.vhd
vcom -work ./work ../tb/tb_adder.vhd

vsim work.tb_adder -voptargs=+acc

add wave -noupdate -divider "Testbench"
add wave -noupdate tb_adder/*

add wave -noupdate -divider "Datapath Internals"
add wave -noupdate tb_adder/DUT/

run 5 us