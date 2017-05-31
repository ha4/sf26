
#
# ad7705/tiny2313 Voltmeter DAQ
#

namespace eval ::DAQU {
	variable fd
	variable port
	variable rsp
	variable fu
	variable daqredo

	namespace export channel cmd req popen pclose restart status
# port_cmd -> req, start->popen, stop->pclose
}


proc ::DAQU::channel {chN funct} {
	variable fd
	variable fu

	if {[info exists fd($chN)]} {return [list] }

	interp alias {} $chN {} ::DAQU::cmd $chN

	set rsp($chN) ""
	set fd($chN) ""
	set fu($chN) $funct

	return $chN
}



proc ::DAQU::cmd {chN v args} {
	variable rsp

	switch $v {
	req  { ::DAQU::req $chN {*}$args}
	port { ::DAQU::port $chN {*}$args}
	open { ::DAQU::popen $chN }
	close { ::DAQU::pclose $chN }
	restart { ::DAQU::restart $chN }
	decode { ::DAQU::decode $rsp($chN) }
	rsp  { return $rsp($chN) }
	chN { return $chN }
	status { return [::DAQU::status $chN]}
	}
}

proc ::DAQU::status {chN} {
	variable fd

	if {![info exists fd($chN)]} {return "deleted"}
	if {$fd($chN) == ""} { return "disconnected" }
	if {[eof $fd($chN)]} { return "error" }
	return "connected"
}


proc ::DAQU::req {chN cmd} {
	variable fd
	variable rsp

	if {$fd($chN) == ""} {return}
	puts  $fd($chN) $cmd
	flush $fd($chN)
}


proc ::DAQU::decode {msg} {
	if {[regexp {^(5[0-9A-F]\s.*)} $msg -> ferr] } {
		puts "err $ferr"
	} elseif {[regexp {^(2[0-9A-F]\s.*)} $msg -> fok]} {
		puts "ok $fok"
	} elseif {[regexp {^(4[0-9A-F]\s.*)} $msg -> fbad]} {
		puts "bad $fbad"
	} elseif {[regexp {^10\s([0-9A-F])\s([0-9A-F]{4})\s([0-9A-F]{1,2})} $msg -> ach uhex pinb]} {
		return [list $ach [expr 2.5 * (0x$uhex-0x8000) / 0x8000 ] [expr 0x$pinb]]
	} else {
#	        req ?ch G1
	}
	return [list]
}

proc ::DAQU::port_in {chN} {
	variable fd
	variable fu
	variable rsp

        if {[eof $fd($chN)]} { return }
#	set rd [read $fd($chN)]
	if {[catch {set rd [read $fd($chN)]} errx]} {
	# error
	    puts "read error: $errx"
	    return
	}

	foreach ch [split $rd {}] {
	  switch -regexp $ch {
          \x07 { }
          [\x0A\x0D] {
		watchdog $chN
		$fu($chN) $chN
		set rsp($chN) ""
 		}
          default { append rsp($chN) $ch }
	  }
	}
}

proc ::DAQU::port {chN p} {
	variable fd
	variable port

	set port($chN) $p

	if {$fd($chN) != ""} {
		pclose $chN
		popen $chN
	}
}

proc ::DAQU::popen {chN} {
	variable fd
	variable fu
	variable rsp
	variable port

	if {$fd($chN) != ""} { pclose $chN }

	if {[regexp {(\d+\.\d+\.\d+\.\d+):(\d+)} $port($chN) -> ip iport]} {
		puts "connect ip $ip : $iport"
		if {![catch {set fd($chN) [socket $ip $iport]}]} {
		  fconfigure $fd($chN) -encoding binary -translation binary -blocking 0
		  fileevent $fd($chN) readable [list ::DAQU::port_in $chN]
		}
	} else {
		if {![catch {set fd($chN) [open $port($chN) r+]}]} {
		  fconfigure $fd($chN) -mode 9600,n,8,1 -translation binary \
	            -buffering none -blocking 0
		  fileevent $fd($chN) readable [list ::DAQU::port_in $chN]
		}
	}

	watchdog $chN

# generate first call
	set rsp($chN) ""
	$fu($chN) $chN
}

proc ::DAQU::pclose {chN} {
	variable daqredo
	variable fd
	variable fu

	if { [info exists daqredo($chN)] } { after cancel $daqredo($chN) }

	catch {close $fd($chN)}
	set fd($chN) ""
# last call
	set rsp($chN) ""
	$fu($chN) $chN
}

proc ::DAQU::watchdog {chN} {
	variable daqredo

	if { [info exists daqredo($chN)] } { after cancel $daqredo($chN) }
	set daqredo($chN) [after 2000 [list ::DAQU::restart $chN]]
}

proc ::DAQU::restart {chN} {
	pclose $chN
	popen $chN
}


# proc getx {self} { puts [$self decode] }
# set chu [::DAQU::channel chu1 getx]
# $chu port "\\\\.\\COM1"
# $chu open
# after 500
# $chu close
# #or# chu1 close

