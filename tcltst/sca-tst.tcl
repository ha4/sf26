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


.t.c create line 10 10 100 100
.t.c scale all 0 0 2 2

catch { console show }

