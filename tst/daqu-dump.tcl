#!/bin/sh
# the next line restarts using the correct interpreter \
exec wish "$0" "$@"

source daqu.tcl

global dumpfl

# The terminal bindings
if {$tcl_platform(platform) == "windows" } {
	set ConfPort "\\.\\\\COM1"
} else {
	set ConfPort "/dev/ttyUSB0"
}

	set ConfFile "dump.dat"


proc read_data {clk chan volt bits} {
        global dumpfl
	puts "$clk $chan $volt $bits"
	puts $dumpfl "$clk $chan $volt $bits"
}


set dumpfl [open $ConfFile w+]

catch {console show}

::DAQU::start $ConfPort read_data
