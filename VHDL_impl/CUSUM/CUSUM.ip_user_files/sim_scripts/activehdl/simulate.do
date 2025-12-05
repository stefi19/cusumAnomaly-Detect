transcript off
onbreak {quit -force}
onerror {quit -force}
transcript on

asim +access +r +m+cusum_top_tb  -L xil_defaultlib -L xpm -L axis_infrastructure_v1_1_1 -L axis_data_fifo_v2_0_15 -L unisims_ver -L unimacro_ver -L secureip -O5 xil_defaultlib.cusum_top_tb xil_defaultlib.glbl

do {cusum_top_tb.udo}

run 1000ns

endsim

quit -force
