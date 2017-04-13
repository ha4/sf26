namespace eval ::DAQU {
   variable msg ""
   variable chan ""
   namespace export port_cmd process_msg start stop restart
}

proc ::DAQU::port_cmd {cmd} {
	variable chan

	puts  $chan $cmd
	flush $chan
}

proc ::DAQU::process_msg {msg func} {
	set tim [clock seconds]

	if {[regexp {^(5[0-9A-F]\s.*)} $msg -> ferr] } {
		puts "$tim $ferr"
	} elseif {[regexp {^(2[0-9A-F]\s.*)} $msg -> fok]} {
		puts "$tim $fok"
	} elseif {[regexp {^(4[0-9A-F]\s.*)} $msg -> fbad]} {
		puts "$tim $fbad"
	} elseif {[regexp {^10\s([0-9A-F])\s([0-9A-F]{4})\s([0-9A-F]{1,2})} $msg -> ach uhex pinb]} {
		$func $tim $ach [expr 2.5 * (0x$uhex-0x8000) / 0x8000 ] [expr 0x$pinb]
	} else {
#	        port_cmd G1
	}
}

proc ::DAQU::port_in {lchan port func} {
	variable msg

#	set rd [read $lchan]

	     if {[catch {set rd [read $lchan]} errx]} {
	# error
		puts "read error"
		return
	     }

	foreach ch [split $rd {}] {
	  switch -regexp $ch {
          \x07 { }
          [\x0A\x0D] {
		 watchdog $port $func
		 set str $msg
		 set msg ""
		 process_msg $str $func
 		}
          default { append msg $ch  }
	  }
	}
}

proc ::DAQU::start {v_port func} {
	variable chan

	set chan [open $v_port r+]
	fconfigure $chan -mode "9600,n,8,1" -translation binary \
            -buffering none -blocking 0

#	after 500

	fileevent $chan readable [list ::DAQU::port_in $chan $v_port $func]

}

proc ::DAQU::stop {} {
	variable chan
	global daqredo

	if { [info exists daqredo] } { after cancel $daqredo }

	if {$chan != ""} { close $chan }
}

proc ::DAQU::watchdog {port func} {
	global daqredo

	if { [info exists daqredo] } { after cancel $daqredo }
	set daqredo [after 2000 [list ::DAQU::restart $port $func]]

}

proc ::DAQU::restart {v_port v_func} {
	global daqredo

	stop
	start $v_port $v_func
	watchdog $v_port $v_func

	# generate first call
	process_msg "" $v_func
}
