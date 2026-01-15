
vlib work
vmap work work

vcom -2008 -work ./work ../src/register.vhd
vcom -2008 -work ./work ../src/operators.vhd
vcom -2008 -work ./work ../src/butterfly_sequencer.vhd
vcom -2008 -work ./work ../src/butterfly_command.vhd
vcom -2008 -work ./work ../src/butterfly_dp.vhd
vcom -2008 -work ./work ../src/butterfly_cu.vhd
vcom -2008 -work ./work ../src/butterfly.vhd
vcom -2008 -work ./work ../tb/tb_butterfly.vhd


vsim work.tb_butterfly -voptargs=+acc

add wave -noupdate -divider "Test Butterfly"
add wave -noupdate tb_butterfly/*


add wave -noupdate -divider "Datapath Internals"
add wave -noupdate tb_butterfly/DUT/DATAPATH/*

add wave -noupdate -divider "Control Unit"
add wave -noupdate tb_butterfly/DUT/CONTROL_UNIT/*

run 600 ns