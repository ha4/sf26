#!/bin/sh
# the next line restarts using the correct interpreter \
exec wish "$0" "$@"

namespace eval timeliner {
   variable ""
   array set "" {-zoom 1  -from 0 -to 2000}
}

proc timeliner::create {w args} {
   variable ""
   array set "" $args
   #-- draw time scale
   for {set x [expr ($(-from)/50)*50]} {$x<=$(-to)} {incr x 10} {
       if {$x%50 == 0} {
           $w create line $x 8 $x 0
           $w create text $x 8 -text $x -anchor n
       } else {
           $w create line $x 5 $x 0
       }
   }
   bind $w <Motion> {timeliner::title %W %x ; timeliner::movehair %W %x}
   bind $w <1> {timeliner::zoom %W %x 1.25}
   bind $w <2> {timeliner::hair %W %x}
   bind $w <3> {timeliner::zoom %W %x 0.8}
}

proc timeliner::movehair {w x} {
   variable ""
   if {[llength [$w find withtag hair]]} {
       set x [$w canvasx $x]
       $w move hair [expr {$x - $(x)}] 0
       set (x) $x
   }
}
proc timeliner::hair {w x} {
   variable ""
   if {[llength [$w find withtag hair]]} {
       $w delete hair
   } else {
       set (x) [$w canvasx $x]
       $w create line $(x) 0 $(x) [$w cget -height] \
                 -tags hair -width 1 -fill red
   }
}

proc timeliner::title {w x} {
   variable ""
   wm title . [expr int([$w canvasx $x]/$(-zoom))]
}

proc timeliner::zoom {w x factor} {
   variable ""
   $w scale all 0 0 $factor 1
   set (-zoom) [expr {$(-zoom)*$factor}]
   $w config -scrollregion [$w bbox all]
   if {[llength [$w find withtag hair]]} {
       $w delete hair
       set (x) [$w canvasx $x]
       $w create line $(x) 0 $(x) [$w cget -height] \
                 -tags hair -width 1 -fill red
   }
}

# This command adds an object to the canvas. The code for "item" took
# me some effort, as it had to locate a free "slot" on the canvas,
# searching top-down:

proc timeliner::add {w type name time args} {
   variable ""
   regexp {(\d+)(-(\d+))?} $time -> from - to
   if {$to eq ""} {set to $from}
   set x0 [expr {$from*$(-zoom)}]
   set x1 [expr {$to*$(-zoom)}]
   switch -- $type {
       era    {set fill yellow; set outline black; set y0 20; set y1 40}
       bgitem {set fill gray; set outline {}; set y0 40; set y1 1024}
       item   {
           set fill orange
           set outline yellow
           for {set y0 60} {$y0<400} {incr y0 20} {
               set y1 [expr {$y0+18}]
               if {[$w find overlap [expr $x0-5] $y0 $x1 $y1] eq ""} break
           }
       }
   }
   set id [$w create rect $x0 $y0 $x1 $y1 -fill $fill -outline $outline]
   if {$type eq "bgitem"} {$w lower $id}
   set x2 [expr {$x0+5}]
   set y2 [expr {$y0+2}]
   set tid [$w create text $x2 $y2 -text $name -anchor nw]
   foreach arg $args {
#       if {$arg eq "!"} {
#           $w itemconfig $tid -font "[$w itemcget $tid -font] bold"
#       }
   }
   $w config -scrollregion [$w bbox all]
}

# Here's a sample application, featuring a concise history of music 
# in terms of composers:

scrollbar .x -ori hori -command {.c xview}
pack      .x -side bottom -fill x
canvas    .c -bg white -width 600 -height 300 -xscrollcommand {.x set}
pack      .c -fill both -expand 1
timeliner::create .c -from 1400 -to 2000

# These nifty shorthands for adding items make data specification
# a breeze - compare the original call, and the shorthand:

#   timeliner::add .c item Purcell 1659-1695
#   - Purcell 1659-1695

# With an additional "!" argument you can make the text of an item bold:

foreach {shorthand type} {* era x bgitem - item} {
   interp alias {} $shorthand {} timeliner::add .c $type
}

# Now for the data to display (written pretty readably):

* {Middle Ages} 1400-1450
- Dufay 1400-1474
* Renaissance    1450-1600
- Desprez 1440-1521
- Luther 1483-1546
- {Columbus discovers America} 1492
- Palestrina 1525-1594 !
- Lasso 1532-1594
- Byrd 1543-1623
* Baroque        1600-1750
- Dowland 1563-1626
- Monteverdi 1567-1643
- Schìtz 1585-1672
- Purcell 1659-1695
- Telemann 1681-1767
- Rameau 1683-1764
- Bach,J.S. 1685-1750 !
- H¤ndel 1685-1759
x {30-years war} 1618-1648
* {Classic era}  1750-1810
- Haydn 1732-1809 !
- Boccherini 1743-1805
- Mozart 1756-1791 !
- Beethoven 1770-1828 !
* {Romantic era} 1810-1914
- {Mendelssohn Bartholdy} 1809-1847
- Chopin 1810-1849
- Liszt 1811-1886
- Verdi 1813-1901
x {French revolution} 1789-1800
* {Modern era}   1914-2000
- Ravel 1875-1937 !
- Bartãk 1881-1945
- Stravinskij 1882-1971
- Var¨se 1883-1965
- Prokof'ev 1891-1953
- Milhaud 1892-1974
- Honegger 1892-1955
- Hindemith 1895-1963
- Britten 1913-1976
x WW1 1914-1918
x WW2 1938-1945
