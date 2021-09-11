# VHDL UART
## Description
A VHDL UART communicating over a serial link with an FPGA. This repository has the description of the UART protocol in VHDL found on https://www.nandland.com/vhdl/modules/module-uart-serial-port-rs232.html and testbench files to test the modules Tx and Rx.

The link settings are Baund Rate 115200, 8 Bits, Parity none, Stop Bit 1. For now, the VHDL code isn't well parametrized, so the link settings are shouldn't be modified to immediate use.  

The constant c_CLK_PER_BIT was setting considering a board with 50Mhz of clock. For different clocks, this constant should be changed by:

c_CLK_PER_BIT = Board Clock/Baund Rate
