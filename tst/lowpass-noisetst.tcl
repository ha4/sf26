#!/bin/sh
# the next line restarts using the correct interpreter \
exec wish "$0" "$@"

source lowpass.tcl

catch {console show}




for {
  set Ynm1 0
  set n 0
} {$n < 100} { incr n } {
  if {$n > 10} {set xn [expr {2.0*(rand()-0.5)}]} else {set xn 0}
  set Ynm1 [lowpass $xn $Ynm1 0.02]
  puts "$n	$xn	$Ynm1"
}