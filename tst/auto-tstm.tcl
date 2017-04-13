#!/bin/sh
# the next line restarts using the correct interpreter \
exec wish "$0" "$@"

# package require math
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

proc gendata {chart x y1 y2 y3} {
   set xnew  [expr {$x+5.0}]
   set y1new  [expr {$y1+(rand()-0.5)*3000.0}]
   set y2new  [expr {$y2+(rand()-0.5)*3000.0}]
   set y3new  [expr {$y3+(rand()-0.5)*3000.0}]

   $chart $xnew $y1new set1 point
   $chart $xnew $y2new set2
   $chart $xnew $y3new set3

   after 100 [list gendata $chart $xnew $y1new $y2new $y3new]
}

   set ::AutoPlotM::plotcols(set1)  green
   set ::AutoPlotM::plotcols(set2)  darkblue
   set ::AutoPlotM::plotcols(set3)  pink


after 100 [list gendata $s 0.0 50000.0 40000.0 30000.0]

catch { console show }