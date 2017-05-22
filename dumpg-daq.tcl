#!/bin/sh
# the next line restarts using the correct interpreter \
exec wish "$0" "$@"

# package require math
source autoplotm.tcl
source daqu.tcl

# The terminal bindings
if {$tcl_platform(platform) == "windows" } {
	set ConfPort "\\.\\\\COM1"
} else {
	set ConfPort "/dev/ttyUSB0"
}

set ConfFile "dump9.dat"


# windows
frame .t

frame .toolbar -bd 2 -relief flat

button .toolbar.cons  -text Console -relief flat -overrelief raised -command {catch {console show}}
button .toolbar.clear -text Clear   -relief flat -overrelief raised -command {cmd_clr}
button .toolbar.conn  -text Connect -relief flat -overrelief raised -command {cmd_conn}
entry  .toolbar.port                -relief sunken                 -textvariable ConfPort -width 10
button .toolbar.open  -text "  Open" -relief flat -overrelief raised -command {cmd_open}
label  .toolbar.anim  -relief flat
entry  .toolbar.file                -relief sunken                 -textvariable ConfFile -width 26
button .toolbar.fsel  -text "..."   -relief raised                 -command {cmd_fsel ConfFile}

pack   .toolbar.cons  -side left -padx 2 -pady 2
pack   .toolbar.clear -side left -padx 2 -pady 2
pack   .toolbar.conn  -side left -padx 2 -pady 2
pack   .toolbar.port  -side left
pack   .toolbar.open  -side left -padx 2 -pady 2
pack   .toolbar.anim  -side left
pack   .toolbar.file  -side left
pack   .toolbar.fsel  -side left

# The toolbar is packed to the root window. It is horizontally stretched.
pack .toolbar -fill x

canvas .t.c -relief groove

grid .t.c -sticky news
grid rowconfigure    .t 0 -weight 1
grid columnconfigure .t 0 -weight 1

pack .t -side top -fill both -expand true

set chart [::AutoPlotM::create .t.c]

proc read_data {self} {
    global  dumpfl
    global  chart
    global  n
    incr n

    set clk [clock seconds]
    foreach {ach volt sens} [$self decode] {break}
    if {![info exists sens]} {return}

    $chart $n $volt set1
#   puts "$clk $ach $volt $sens"
   if {[info exist dumpfl]} {
	animate .toolbar.anim 25
	puts $dumpfl "$clk $ach $volt $sens"
   }
   
#   $chart $xnew $y2new set2
#   $chart $xnew $y3new set3

}

set n 0

proc cmd_open {} {

   global  dumpfl
   global  ConfFile

   if {[info exist dumpfl]} {
         set m $dumpfl
         unset dumpfl
         close $m
         .toolbar.open configure -text "  Open"
   } else {
         set dumpfl [open $ConfFile w+]
         .toolbar.open configure -text "  Close"
   }

}

proc cmd_clr {} {
    global  n
    set n 0
    ::AutoPlotM::clear .t.c
    animate .toolbar.anim
}

proc cmd_conn {} {
   global chu
  
   $chu restart
}

proc cmd_fsel {fvar} {
	upvar #0 $fvar sf
	set types {
	    {{Data Files}       {.dat}        }
	    {{Text Files}       {.txt}        }
	    {{All Files}        *             }
	}

	set filename [tk_getSaveFile -filetypes $types -defaultextension {.dat}]

	if { $filename != "" } { set sf $filename }
}

proc animate {w {divisor 4}} {
    global AnimateImg

    incr AnimateImg($w,n)
    if {$AnimateImg($w,n) > $divisor} {
	set AnimateImg($w,n) 0
    } else {return}
    set i $AnimateImg($w,idx)
    $w configure -bitmap [lindex $AnimateImg($w,icons) $i]
    set AnimateImg($w,idx) [expr ($AnimateImg($w,idx) + 1) % 4]
}


proc setanimate {w icons} {
    global AnimateImg

    set AnimateImg($w,idx) 0
    set AnimateImg($w,n) 0
    foreach bm $icons {
	lappend AnimateImg($w,icons) $bm
    }
    $w configure -bitmap [lindex $AnimateImg($w,icons) 0]
}

set ::AutoPlotM::plotcols(set1)  green
set ::AutoPlotM::plotcols(set2)  darkblue
set ::AutoPlotM::plotcols(set3)  pink

setanimate .toolbar.anim {gray12 gray50 gray75 gray50}

set chu [::DAQU::channel 1 read_data]
$chu port $ConfPort
catch {$chu open}

catch {console hide}
