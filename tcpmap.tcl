set tcpport 5050
set comport /dev/ttyS0; #"/dev/ttyUSB0"
if {$tcl_platform(platform) eq "windows" } { set comport "\\\\.\\COM7" } 
set comopts {-mode 9600,n,8,1 -handshake none}
#set serveonce 1
    
array set clients {}
set server ""
set serial ""

proc frames {} {
	wm title . "Serial to TCP gateway"

	entry .eport -textvariable tcpport
	entry .sport -textvariable comport
	label .status
	button .bexit -text "Exit" -command {catch {stopServer; closeall}; exit}
	button .bdisconnect -text "Disconnect" -command {closeall}
	button .brestart -text "Restart" -command {startServer $tcpport}
	button .bcons -text "Console" -command {console show}

	grid [label .l1 -text "TCP port"] .eport .brestart -padx 10 -pady 5 -sticky news
	grid [label .l2 -text "Serial port"] .sport x -padx 10 -pady 5 -sticky news
	grid .status - - -sticky news
	grid .bexit .bdisconnect .bcons  -padx 10 -pady 5 -sticky news

	grid columnconfigure . all -weight 1
	grid rowconfigure . all -weight 1
}

proc msg {s} {
	puts $s
	.status configure -text $s
}

proc stopServer {} {
	global server

	if {$server ne ""} {catch {close $server}}
	set server ""
}

proc startServer {port} {
	global server

	stopServer
	catch {set server [socket -server acceptConnection $port]} err
	if {$server ne ""} {msg "Now listening on $port"} else {msg "$err"}
}

proc port_open {} {
	global serial

	set serial [open $::comport r+]
	fconfigure $serial -blocking 0 -buffering none -translation binary {*}$::comopts
	fileevent $serial  readable "passMData \$serial"
}

proc port_close {} {
	global serial

	catch {close $serial}
	set serial ""
}

proc closeall {} {
	global clients

	msg "Close all.."
	foreach a [array names clients] {
		catch {close $a}
		unset -nocomplain clients($a)
	}
}

proc acceptConnection {channel peer peerport} {
	global clients
	global serial

	flush $channel
	fconfigure $channel -blocking 0 -buffering none -translation binary

	if {$serial eq ""} {port_open}

	set clients($channel) $channel
	fileevent $channel readable "passData $channel \$serial"
	msg "Client $peer connected."
}

proc lostConnection {in out} {
	global clients
	global serial

	if ($serial ne "" && $in eq $serial) {
		msg "Serial close disconnect."
		port_close
		closeall
	} else {
		msg "Client disconnect."

		catch {close $in}
		unset -nocomplain clients($in)
		if {[array size clients] == 0} {port_close}
	}
	#if {$::serveonce} {set ::forever now}
}

proc passData {in out} {
# CL suspects that this is backwards. [eof] needs to be tested *after* reading.
	if {[eof $in]} {lostConnection $in $out} else {
		puts -nonewline $out [read $in]
	} 
}

proc passMData {in} {
	global clients
	if {[eof $in]} {lostConnection $in ""} else {
		set src [read $in]
		foreach c [array names clients] {puts -nonewline $c $src}
	}
}

frames
catch {console hide}
startServer $tcpport

# vwait forever; msg "Done."
