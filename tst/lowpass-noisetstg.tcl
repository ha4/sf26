#!/bin/sh
# the next line restarts using the correct interpreter \
exec wish "$0" "$@"

source lowpass.tcl
source autoplotm.tcl

# windows

frame .t

# -xscrollincrement 1
#    -scrollregion {0 0 80000 0} 

canvas .t.c -relief groove \
    -xscrollcommand [list .t.xscroll set] \
    -yscrollcommand [list .t.yscroll set] \
          -xscrollincrement 1 -bg beige
scrollbar .t.xscroll -orient horizontal \
    -command [list .t.c xview]
scrollbar .t.yscroll -orient vertical \
    -command [list .t.c yview]

grid .t.c       .t.yscroll -sticky news
grid .t.xscroll x          -sticky news

grid rowconfigure    .t 0 -weight 1
grid columnconfigure .t 0 -weight 1

pack .t -side top -fill both -expand true

set s [::AutoPlotM::create .t.c]

proc gendata {chart n y} {

   incr n

   if {$n > 20} {
      set xn [expr {(rand()-0.5)*2.0}]
   } else {
      set xn 0.0
   }

   set yn     [lowpass $xn $y 0.02]

   $chart $n $xn set2
   $chart $n $yn set3

   after 100 [list gendata $chart $n $yn]
}

   set ::AutoPlotM::plotcols(set2)  darkblue
   set ::AutoPlotM::plotcols(set3)  darkgreen


after 100 [list gendata $s 0 0]

catch { console show }

