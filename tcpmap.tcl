set tcpport 5050
set comport /dev/ttyS0
set comopts {-mode 9600,n,8,1 -handshake none}
#set serveonce 1
    
set client [list]
set server ""
set serial ""

proc frames {} {
	wm title . "Serial to TCP gateway"

	entry .eport -textvariable tcpport
	entry .sport -textvariable comport
	label .status
	button .bexit -text "Exit" -command {close $server; exit}
	button .bdisconnect -text "Disconnect" -command {close $client}

	grid [label .l1 -text "TCP port"] .eport
	grid [label .l2 -text "Serial port"] .sport
	grid .status -
	grid .bexit .bdisconnect
}

proc msg {s} {
	puts $s
	.status configure -text $s
}


proc startServer {port} {
	global server
	set server [socket -server acceptConnection $port]
}

proc acceptConnection {channel peer peerport} {
	global client
	global serial

	msg "Connection from $peer"
	if {$client ne ""} {
		msg "Kindly refusing."
		close $channel
		return
	}

	set client $channel
	flush $client
	fconfigure $client -blocking 0 -buffering none -translation binary

	set serial [open $::comport r+]
	fconfigure $serial -blocking 0 -buffering none -translation binary
	foreach {opt val} $::comopts {fconfigure $serial $opt $val} 

	fileevent $client readable "passData $client $serial"
	fileevent $serial readable "passData $serial $client"
	msg "Client connected."
}

proc passData {in out} {
# CL suspects that this is backwards. [eof] needs to be tested *after* reading.
	if { ![eof $in] } {
		puts -nonewline $out [read $in]
	} else {
		msg "Client disconnected."
		close $in
		close $out
		set ::client ""
		#if {$::serveonce} {set ::forever now}
	}
}

frames
catch {console hide}
startServer $tcpport
msg "Now listening on $tcpport"

# vwait forever; msg "Done."
