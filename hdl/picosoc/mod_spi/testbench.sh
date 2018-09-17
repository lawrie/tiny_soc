#!/bin/bash
iverilog -o testbench.exe testbench.v mod_spi.v `yosys-config --datdir/ice40/cells_sim.v`
vvp -N testbench.exe
rm -f testbench.exe
