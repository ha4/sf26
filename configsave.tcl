proc config_save {filename varlist} {
  set f [open $filename w+]
  foreach v $varlist {
    global $v
    set w [set $v]
    foreach {r s} {\\\\ \\\\\\\\ \\\[ \\\[ \\\] \\\] \\\" \\\" \n \\n \t \\t} {
      regsub -all $r $w $s w
    }
    puts $f "set $v \"$w\""
  }
#  set v data_in
#  puts $f "proc $v \{[info args $v]\} \{ [info body $v]\}"
  close $f
}
