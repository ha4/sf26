#!/bin/sh
# the next line restarts using the correct interpreter \
exec wish "$0" "$@"

# package require math
source autoplotm.tcl

set ConfFile "dump.dat"

global  chart
global  n

# windows
frame .t
canvas .t.c -relief groove
grid .t.c -sticky news
grid rowconfigure    .t 0 -weight 1
grid columnconfigure .t 0 -weight 1

pack .t -side top -fill both -expand true

set chart [::AutoPlotM::create .t.c]

proc getdata {clk ach volt sens} {
    global  chart
    global  n
    incr n

   $chart $n $volt set1

#   $chart $xnew $y2new set2
#   $chart $xnew $y3new set3

}

catch { console show }

set ::AutoPlotM::plotcols(set1)  green
set ::AutoPlotM::plotcols(set2)  darkblue
set ::AutoPlotM::plotcols(set3)  pink

set n 0
set chan [open $ConfFile r]
fconfigure $chan -buffering line

# fileevent  $chan readable [list getstrdata $chan]


while {-1 != [gets $chan a]} {
	 foreach {clk chn volt sens} [split $a " "] {break}
         getdata $clk $chn $volt $sens
         update
     }

