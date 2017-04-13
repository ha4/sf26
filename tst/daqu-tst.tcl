#!/bin/sh
# the next line restarts using the correct interpreter \
exec wish "$0" "$@"

source daqu.tcl

# The terminal bindings
if {$tcl_platform(platform) == "windows" } {
	set ConfPort "\\.\\\\COM1"
} else {
	set ConfPort "/dev/ttyUSB0"
}


proc read_data {clk chan volt bits} {
	global StartT

	if { ![info exists StartT] } { set StartT $clk }
	set t [expr $clk-$StartT]

	puts "$t $chan $volt $bits"
}


catch {console show}

::DAQU::start $ConfPort read_data
