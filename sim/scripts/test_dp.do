
vlib work
vmap work work

vcom -work ./work ../src/register.vhd
vcom -work ./work ../src/operators.vhd
vcom -work ./work ../src/butterfly_dp.vhd
vcom -work ./work ../src/butterfly_cu.vhd
vcom -work ./work ../src/butterfly.vhd

vcom -work ./work ../tb/tb_butterfly.vhd


vsim work.tb_butterfly_dp -voptargs=+acc

add wave -noupdate -divider "Test Butterfly"
add wave -noupdate tb_butterfly/*


add wave -noupdate -divider "Datapath Internals"
add wave -noupdate tb_butterfly/DUT/DATAPATH/*

add wave -noupdate -divider "Control Unit"
add wave -noupdate tb_FMC/DUT/CONTROL_UNIT/*


run 200 ns