#!/bin/sh
# the next line restarts using the correct interpreter \
exec wish "$0" "$@"

source lowpass.tcl
source autoplotm.tcl

# windows

frame .t

# -xscrollincrement 1
#    -scrollregion {0 0 80000 0} 

canvas .t.c -relief groove

grid .t.c -sticky news
grid rowconfigure    .t 0 -weight 1
grid columnconfigure .t 0 -weight 1

pack .t -side top -fill both -expand true

set s [::AutoPlotM::create .t.c]

proc TtoD t {
	if {$t > 0} {
	  set d [expr -log10($t/100.0)]
	} else {
	  set d 2.0
	}
	if {$d > 2.0} {set d 2.0}
	return $d
}

proc gendata {chart n y} {

   global filt
   incr n

   if {$n > 20} {
      set xn 90.0
   } else {
      set xn 10
   }

   set xn [expr {$xn + 2.0*(rand()-0.5)}]

   set yn     [lowpass2 $xn filt]

#  set plot2 [TtoD $xn]
#  set plot3 [TtoD $yn]

  set plot2 $xn
  set plot3 $yn

   $chart $n $plot2 set2
   $chart $n $plot3 set3

   if {$n < 100} {
	   after 100 [list gendata $chart $n $yn]
   }
}

   set ::AutoPlotM::plotcols(set2)  black
   set ::AutoPlotM::plotcols(set3)  darkgreen


after 100 [list gendata $s 0 0]

catch { console show }

