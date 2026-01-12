
vlib work
vmap work work

vcom -2008 -work ./work ../src/register.vhd
vcom -2008 -work ./work ../src/operators.vhd
vcom -2008 -work ./work ../src/butterfly_sequencer.vhd
vcom -2008 -work ./work ../src/butterfly_command.vhd
vcom -2008 -work ./work ../src/butterfly_dp.vhd
vcom -2008 -work ./work ../src/butterfly_cu.vhd
vcom -2008 -work ./work ../src/butterfly.vhd
vcom -2008 -work ./work ../src/fft.vhd
vcom -2008 -work ./work ../tb/tb_fft.vhd


vsim work.tb_fft -voptargs=+acc

add wave -noupdate -divider "Test FFT"
add wave -noupdate -color yellow  tb_fft/*


add wave -noupdate -divider "Internals"
add wave -noupdate tb_fft/DUT/*

run 1500 ns