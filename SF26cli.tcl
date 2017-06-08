#!/bin/sh
# the next line restarts using the correct interpreter \
exec tclsh "$0" "$@"

set sf26cc_version "3.2"
set sf26cc_date "20170608"
set port "/dev/ttyUSB0"
if {$tcl_platform(platform) == "windows" } { set port "\\\\.\\COM12" } 
set logfile "o3.sf.dat"
set par_sskip   5
set par_srcd    4
set par_srcin   3
set par_srcout  1
set par_srccal  2
set par_setcal  53.4
set par_ticorr  100.0
set par_tocorr  100.0
set par_alpha   0.18
set par_optoeps 112
set par_optolen 5.2
set par_gasflow 60
# auto cuvette calibration
set dataCAL 0
# span/zero auto correction
set dataCORR 1

set dataTc $par_setcal
set dataTk 1.0
set dataTz 0.0


# alpha - smooth, 1st order low-pass
proc smooth_a {x a state} {upvar $state v
 set v(yn) [if [info exists v(yn)] {expr {$a*($x-$v(yn))+$v(yn)}} else {expr $x+0.0}]}

# transition to optical density conversion
proc t2d {t} {if {$t > 0.001} {expr {2.0-log10($t)}} else {expr 5.0}}

proc integrate {s t v kn} {global intg
 array set intg [list $s,t $t $s,v $v $s,s [if [info exist intg($s,t)] \
  {expr {$intg($s,s)+($intg($s,v)+$v)*($t-$intg($s,t))/2.0}} else {expr 0}]]
 set intg($s,n) [expr {$intg($s,s)*$kn}]
 set intg(delta) [expr {$intg(i,n)-$intg(o,n)}]
}

#command-line
catch {console show}
if {[llength $argv] < 2} {puts "usage: $argv0 <port> <file-to-save>"; return}
set port [lindex $argv 0]
set logfile [lindex $argv 1]

# open channels
if {[regexp {(\d+\.\d+\.\d+\.\d+):(\d+)} $port -> ip iport]} {
	puts "connect ip $ip : $iport"
	if {[catch {set fdin($chN) [socket $ip $iport]}]} return
	fconfigure $fdin -encoding binary -translation binary -blocking 0
} else {
	puts "open serial $port"
	if {[catch {set fdin [open $port r+]}]} return
	fconfigure $fdin -mode 9600,n,8,1 -translation binary -buffering none -blocking 0
}
puts "use file $logfile"
set dumpfl [open $logfile w+]
set rsp ""
set StartT [clock seconds]
set Tprev 0
set Qprev -1
set intg(i,n) 0
set intg(o,n) 0
set intg(delta) 0
set kn [expr {$par_gasflow/60.0/$par_optolen/$par_optoeps}]
#cycle
while {} {
        if {[catch [eof $fdin] errx] || [catch {set rd [read $fdin]} errx]} {puts "read error: $errx"; break}
	foreach ch [split $rd {}] { switch -regexp $ch {default {append rsp $ch; continue} \x07 {continue} [\x0A\x0D] break} }

	# decode
	set clk [clock seconds]
	if {[regexp {^(5[0-9A-F]\s.*)} $rsp -> ferr] } { puts "err $ferr"; continue } \
	elseif {[regexp {^(2[0-9A-F]\s.*)} $rsp -> fok]} { puts "ok $fok"; continue } \
	elseif {[regexp {^(4[0-9A-F]\s.*)} $rsp -> fbad]} { puts "bad $fbad"; continue } \
	elseif {![regexp {^10\s([0-9A-F])\s([0-9A-F]{4})\s([0-9A-F]{1,2})} $rsp -> ach uhex pinb]} { continue } \
	else continue

	# translation/filtering
	set volt [expr 2.5 * (0x$uhex-0x8000) / 0x8000]
	set bits [expr 0x$pinb]
	set cuvette [switch $bits 7 {expr 1}  11 {expr 2}  13 {expr 3} 14 {expr 4} default {expr 0}]
	# average filter
	if {![info exists fil(n)]} {set fil(n) 1; set fil(sum) $volt} else {incr fil(n); set fil(sum) [expr {$fil(sum)+$volt}]}
	set t [expr {$clk-$StartT}]
	if {$Qprev != $cuvette } {
		set Qprev $cuvette
		set skippedsmp 0
		unset -nocomplain fil(n)
		unset -nocomplain fil1
		puts "changed cuvette $cuvette"
		continue
	} 
	if {$Tprev == $t} continue else {set Tprev $t}

	#get avergage
	set u [if {![info exists fil(n)]} {expr 0} else {expr {$fil(sum)/$fil(n)}}]
	unset -nocomplain fil(n)
	if {$cuvette == 0} continue
	if {[incr skippedsmp] < $par_sskip} continue
	# data crunching
	set trans [expr {$u*100.0}]

	if {$cuvette == $par_srcd} {
		set dataTd [smooth_a $trans $par_alpha fil0]
		set dataConv [expr {$trans - $dataTd}]
		if {$dataCORR} {set dataTz $dataTd}
		puts "shadowSignal $trans convergence:$dataConv"
	}
	set $trans [expr {$trans-$dataTz}]
        if {$cuvette == $par_srccal} {
		set dataTc [smooth_a $trans $par_alpha filk]
		set dataConv [expr {$trans - $dataTc}]
		if {$dataCAL} {set par_setcal [smooth_a $dataTc $par_alpha fil1]}
		if {$dataCORR} {set dataTk [expr {$dataTc/$par_setcal}]}
		puts "referenceSignal $trans convergence:$dataConv"
	}
	set $trans [expr {$trans * $dataTk}]
	# final processing/integration
	if {$cuvette == $par_srcin} {
		if {$dataCAL} {set par_ticorr [smooth_a $trans $par_alpha fil1]}
		integrate i $t [t2d [expr {$trans*100.0/$par_ticorr}]] $kn
		set wr "$t $intg(i,v) *"
		puts "inletSignal $wr \[mmol i:$intg(i,n) o:$intg(o,n) D:$intg(delta)\]"
		puts $dumpfl $wr
	} elseif {$cuvette == $par_srcout} {
		if {$dataCAL} {set par_tocorr [smooth_a $trans $par_alpha fil1]}
		integrate o $t [t2d [expr {$trans*100.0/$par_tocorr}]] $kn
		set wr "$t * $intg(o,v)"
		puts "outletSignal $wr \[mmol i:$intg(i,n) o:$intg(o,n) D:$intg(delta)\]"
		puts $dumpfl $wr
	}
}

close $dumpfl
close $fdin
