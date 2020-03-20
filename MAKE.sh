#!/bin/bash 

ghdl -c --ieee=synopsys -fexplicit --work=altera_mf /export/opt/altera/12.1/quartus/eda/sim_lib/altera*.vhd pacbench.vhd pacman.vhd sync.vhd env_rom.vhd -r pacbench --vcd=pacbench.vcd
