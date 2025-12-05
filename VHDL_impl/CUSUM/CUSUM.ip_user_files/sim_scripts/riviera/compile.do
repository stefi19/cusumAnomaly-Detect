transcript off
onbreak {quit -force}
onerror {quit -force}
transcript on

vlib work
vlib riviera/xpm
vlib riviera/axis_infrastructure_v1_1_1
vlib riviera/axis_data_fifo_v2_0_15
vlib riviera/xil_defaultlib

vmap xpm riviera/xpm
vmap axis_infrastructure_v1_1_1 riviera/axis_infrastructure_v1_1_1
vmap axis_data_fifo_v2_0_15 riviera/axis_data_fifo_v2_0_15
vmap xil_defaultlib riviera/xil_defaultlib

vlog -work xpm  -incr "+incdir+../../ipstatic/hdl" -l xpm -l axis_infrastructure_v1_1_1 -l axis_data_fifo_v2_0_15 -l xil_defaultlib \
"D:/Vivado/Vivado/2024.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
"D:/Vivado/Vivado/2024.2/data/ip/xpm/xpm_fifo/hdl/xpm_fifo.sv" \
"D:/Vivado/Vivado/2024.2/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \

vcom -work xpm -93  -incr \
"D:/Vivado/Vivado/2024.2/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work axis_infrastructure_v1_1_1  -incr -v2k5 "+incdir+../../ipstatic/hdl" -l xpm -l axis_infrastructure_v1_1_1 -l axis_data_fifo_v2_0_15 -l xil_defaultlib \
"../../ipstatic/hdl/axis_infrastructure_v1_1_vl_rfs.v" \

vlog -work axis_data_fifo_v2_0_15  -incr -v2k5 "+incdir+../../ipstatic/hdl" -l xpm -l axis_infrastructure_v1_1_1 -l axis_data_fifo_v2_0_15 -l xil_defaultlib \
"../../ipstatic/hdl/axis_data_fifo_v2_0_vl_rfs.v" \

vlog -work xil_defaultlib  -incr -v2k5 "+incdir+../../ipstatic/hdl" -l xpm -l axis_infrastructure_v1_1_1 -l axis_data_fifo_v2_0_15 -l xil_defaultlib \
"../../../CUSUM.gen/sources_1/ip/axis_data_fifo_0/sim/axis_data_fifo_0.v" \

vcom -work xil_defaultlib -93  -incr \
"../../../../adder.vhd" \
"../../../CUSUM.srcs/sources_1/new/broadcaster.vhd" \
"../../../CUSUM.srcs/sources_1/new/cusum_top.vhd" \
"../../../CUSUM.srcs/sources_1/new/maximum.vhd" \
"../../../../subtractor.vhd" \
"../../../CUSUM.srcs/sources_1/new/threshold_exceeding_comparator.vhd" \
"../../../CUSUM.srcs/sources_1/new/cusum_top_tb.vhd" \

vlog -work xil_defaultlib \
"glbl.v"

