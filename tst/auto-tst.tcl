#!/bin/sh
# the next line restarts using the correct interpreter \
exec wish "$0" "$@"

# package require math
source autoplot.tcl

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

set s [::AutoPlot::create .t.c]

proc gendata {chart xold xd yold yd} {
   set xnew  [expr {$xold+$xd}]
   set ynew  [expr {$yold+(rand()-0.5)*$yd}]
   $chart $xnew $ynew
   after 100 [list gendata $chart $xnew $xd $ynew $yd]
}

after 100 [list gendata $s 0.0 5.0 50000.0 3000.0]

catch { console show }

