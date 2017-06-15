#!/bin/sh
# the next line restarts using the correct interpreter \
exec wish "$0" "$@"

# package require math
source autoplotm.tcl
source lowpass.tcl

set ConfFile "dump.dat"
set ConfMode 0

global  chart
global  n

# windows
frame .t

frame .toolbar -bd 2 -relief flat

entry  .toolbar.file                -relief sunken                 -textvariable ConfFile -width 36
button .toolbar.fsel  -text "..."   -relief raised                 -command {cmd_fsel ConfFile}

radiobutton .toolbar.a   -text A   -value 0 -variable ConfMode
radiobutton .toolbar.ab  -text AB  -value 1 -variable ConfMode
radiobutton .toolbar.a-b -text A-B -value 2 -variable ConfMode
radiobutton .toolbar.c   -text color -value 3 -variable ConfMode
radiobutton .toolbar.tau -text tau -value 4 -variable ConfMode

button .toolbar.open  -text "Go!"   -relief flat -overrelief raised -command {cmd_go}

pack   .toolbar.file  -side left
pack   .toolbar.fsel  -side left

pack   .toolbar.a     -side left
pack   .toolbar.ab    -side left
pack   .toolbar.a-b   -side left
pack   .toolbar.c     -side left
pack   .toolbar.tau   -side left

pack   .toolbar.open  -side left -padx 2 -pady 2

# The toolbar is packed to the root window. It is horizontally stretched.
pack .toolbar -fill x

canvas .t.c -relief groove
grid .t.c -sticky news
grid rowconfigure    .t 0 -weight 1
grid columnconfigure .t 0 -weight 1

pack .t -side top -fill both -expand true

set chart [::AutoPlotM::create .t.c]



proc getdata {clk ach volt bits} {
    global  chart
    global  ConfMode
    global  n 
    global  flt
    global  svdata
    global  svdata2
    incr n

   set yn     [lowpass2 $volt flt]
   set qvt    [switch $bits 7 {expr {1}}  11 {expr {2}}  13 {expr {3}}  14 {expr {4}} default {expr {0}}]
   set q      "set$qvt"

#   two plots
   if {$ConfMode == 4} {
	SVpush svdata $volt
	set a0 [SVa0 svdata]
	set a1 [SVa1 svdata]
	set vc [tau_correct 950 $a0 $a1 0.031667]

	SVpush svdata2 $vc
	set b0 [SVa0 svdata2]

	$chart $n $b0 $q point
	$chart $n $a0 set5 point
	return
   }
   if {$ConfMode == 3} {
	$chart $n $volt $q point
	return
   }
   if {$ConfMode != 2} {$chart $n $volt set1}
   if {$ConfMode == 1} {$chart $n $yn   set2}
   if {$ConfMode == 2} {$chart $n [expr $volt-$yn] set3}

}

set ::AutoPlotM::dset(set0,color)  green
set ::AutoPlotM::dset(set1,color)  darkblue
set ::AutoPlotM::dset(set2,color)  red
set ::AutoPlotM::dset(set3,color)  black
set ::AutoPlotM::dset(set4,color)  grey
set ::AutoPlotM::dset(set5,color)  pink

proc getstrdata {chan} {
 if {-1 != [gets $chan a]} {
 	 foreach {clk chn volt sens} [split $a " "] {break}
         getdata $clk $chn $volt $sens
#         update
 } else {
        close $chan
 }
}

proc cmd_go {} {
 global ConfFile
 global n

 set n 0
 ::AutoPlotM::clear .t.c

 set chan [open $ConfFile r]
 fconfigure $chan -buffering line
# fileevent  $chan readable [list getstrdata $chan]
 while {-1 != [gets $chan a]} {
 	 foreach {clk chn volt sens} [split $a " "] {break}
         getdata $clk $chn $volt $sens
         update
     }
 close $chan
}

proc cmd_fsel {fvar} {
	upvar #0 $fvar sf
	set types {
	    {{Data Files}       {.dat}        }
	    {{Text Files}       {.txt}        }
	    {{All Files}        *             }
	}

	set filename [tk_getOpenFile -filetypes $types]

	if { $filename != "" } { set sf $filename }
}

catch { console hide }
