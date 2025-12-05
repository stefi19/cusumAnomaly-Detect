vlib modelsim_lib/work
vlib modelsim_lib/msim

vlib modelsim_lib/msim/xpm
vlib modelsim_lib/msim/axis_infrastructure_v1_1_1
vlib modelsim_lib/msim/axis_data_fifo_v2_0_15
vlib modelsim_lib/msim/xil_defaultlib

vmap xpm modelsim_lib/msim/xpm
vmap axis_infrastructure_v1_1_1 modelsim_lib/msim/axis_infrastructure_v1_1_1
vmap axis_data_fifo_v2_0_15 modelsim_lib/msim/axis_data_fifo_v2_0_15
vmap xil_defaultlib modelsim_lib/msim/xil_defaultlib

vlog -work xpm  -incr -mfcu  -sv "+incdir+../../ipstatic/hdl" \
"D:/Vivado/Vivado/2024.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
"D:/Vivado/Vivado/2024.2/data/ip/xpm/xpm_fifo/hdl/xpm_fifo.sv" \
"D:/Vivado/Vivado/2024.2/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \

vcom -work xpm  -93  \
"D:/Vivado/Vivado/2024.2/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work axis_infrastructure_v1_1_1  -incr -mfcu  "+incdir+../../ipstatic/hdl" \
"../../ipstatic/hdl/axis_infrastructure_v1_1_vl_rfs.v" \

vlog -work axis_data_fifo_v2_0_15  -incr -mfcu  "+incdir+../../ipstatic/hdl" \
"../../ipstatic/hdl/axis_data_fifo_v2_0_vl_rfs.v" \

vlog -work xil_defaultlib  -incr -mfcu  "+incdir+../../ipstatic/hdl" \
"../../../CUSUM.gen/sources_1/ip/axis_data_fifo_0/sim/axis_data_fifo_0.v" \

vcom -work xil_defaultlib  -93  \
"../../../../adder.vhd" \
"../../../CUSUM.srcs/sources_1/new/broadcaster.vhd" \
"../../../CUSUM.srcs/sources_1/new/cusum_top.vhd" \
"../../../CUSUM.srcs/sources_1/new/maximum.vhd" \
"../../../../subtractor.vhd" \
"../../../CUSUM.srcs/sources_1/new/threshold_exceeding_comparator.vhd" \
"../../../CUSUM.srcs/sources_1/new/cusum_top_tb.vhd" \

vlog -work xil_defaultlib \
"glbl.v"

