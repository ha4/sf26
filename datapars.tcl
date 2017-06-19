# --------------------
# -- DATA HANDLING


# quvette name translation
proc q2name {q} {foreach n {srcin srcout srcd srccal} {global par_$n
		if {$q == [set par_$n]} {return $n}}
		return none}

# transition to optical density conversion
proc t2d {t} {if {$t > 0.001} {expr {2.0-log10($t)}} else {expr 5.0}}

# weird calculation here: 
#       Tin= Tk*(T - Td)/Timax if src-in
#	Tout=Tk*(T - Td)/Tomax if src-out
#	Td=flt(alpha,T) if src-dark
#	Tcorr=flt(alpha,T-Td) if src-corr
#	Tk=Tcorr/Vcorr         if src-corr
#	Timax=flt(alpha,T-Td) if src-in  and 0-correction
#	Tomax=flt(alpha,T-Td) if src-out and 0-correction


# 
# main data handler
#

proc data_processL3 {t in out} {
	global config_tplot
	global chart
	global dumpfl
	global kmarkdo
	global par_integrate

	if {$config_tplot == "d"} {
		if {$in != "*"}  {$chart $t $in  "setsrcin"}
		if {$out != "*"} {$chart $t $out "setsrcout"}
	}

# store to file
        if {[info exist dumpfl]} {
		set s "$t $in $out"
		if {[info exists kmarkdo]} {
			append s " $kmarkdo"
			unset kmarkdo
		}
		puts $dumpfl $s
  	 	animate
	}

	if {$par_integrate && $in != "*"}  {integrate srcin  $t $in}
	if {$par_integrate && $out != "*"} {integrate srcout $t $out}
}

proc integrate {s t v} {
	global intg
	global par_gasflow
	global par_optolen
	global par_optoeps

	if [info exist intg($s,t)] {
		set i [expr {$intg($s,s)+($intg($s,v)+$v)*($t-$intg($s,t))/2.0}]
	} else {
		set i 0
	}
	set intg($s,s) $i
	set intg($s,t) $t
	set intg($s,v) $v
	set intg($s,n) [expr {$par_gasflow*$intg($s,s)/60.0/$par_optolen/$par_optoeps}]
	if {![string is double -strict $intg(srcin,n)]} {set intg(srcin,n) 0}
	if {![string is double -strict $intg(srcout,n)]} {set intg(srcout,n) 0}
	set intg(delta) [expr {$intg(srcin,n) -  $intg(srcout,n)}]
}

# time, cuvette, intensity%
proc data_processL2 {t s i} {
	global chart
	global config_tplot
	global par_setcal
	global par_alpha

	global fil0
	global fil1
	global filk
	global dataCAL
	global dataCORR

	global dataTd
	global dataTc
	global par_tk
	global par_tz
	global dataConv

	global par_ticorr
	global par_tocorr
	global fil1

	global dataTi
	global dataTo
	global dataDi
	global dataDo

	if {$s == "srcd"} {
		set dataTd [smooth_a $i $par_alpha fil0]
		set dataConv [expr {$i - $dataTd}]
		if {$dataCORR} {
			set par_tz $dataTd
			flashscale z
		}
	}
	set $i [expr {$i-$par_tz}]

        if {$s == "srccal"} {
		set dataTc [smooth_a $i $par_alpha filk]
		set dataConv [expr {$i - $dataTc}]
		if {$dataCAL} {set par_setcal [smooth_a $dataTc $par_alpha fil1]}
		if {$dataCORR} {
			set par_tk [expr {$dataTc/$par_setcal}]
			flashscale s
		}
	}
	set $i [expr {$i * $par_tk}]

	if {$config_tplot == "t"} {$chart $t $i "set$s"}

	if {$src == "srcin"} {
		if {$dataCAL} {set par_ticorr [smooth_a $trans $par_alpha fil1]}
		set dataTi [expr {$trans*100.0/$par_ticorr}]
		set dataDi [t2d $dataTi]
		data_processL3 $t $dataDi "*"
	}
		
	if {$src == "srcout"} {
		if {$dataCAL} {set par_tocorr [smooth_a $trans $par_alpha fil1]}
		set dataTo [expr {$trans*100.0/$par_tocorr}]
		set dataDo [t2d $dataTo]
		data_processL4 $t "*" $dataDo
	}
}


#
# preliminary data handler Layer1
#

proc data_processL1 {self} {
	global fil
	global fil1
	global StartT
	global Qprev
	global Qnow
	global Tprev
	global skippedsmp
	global dataTm
	global datavolt
	global par_sskip


	set clk [clock seconds]

	foreach {chan volt bits} [$self decode] break
	if {![info exists bits]} {
	   showstatus [$self status]
	   return [list]
	}

	# ignore $chan, read bits
	set cuvette [switch $bits 7 {expr 1} 11 {expr 2} 13 {expr 3} 14 {expr 4} default {expr 0}]
	lowpass_avg_put $volt fil

	if {![info exist StartT]} {set StartT $clk}
	set t [expr {$clk-$StartT}]
	if {![info exist Tprev] || $Tprev == $t} {
		set Tprev $t
		set timch 0
	} else {
		set Tprev $t
		set timch 1
	}

	if {![info exist Qprev] || $Qprev != $cuvette} {
		set Qprev $cuvette
		set Qnow [q2name $cuvette]
		set skippedsmp 0
		lowpass_avg_clean fil
		unset -nocomplain fil1
		show_dset $cuvette
		inputdata Qnow
		return [list]
	} 

	# once per second
	if {$timch} {
		set u [lowpass_avg_get fil]
		lowpass_avg_clean fil

		# display data
		set dataTm $t
		set datavolt "$u"
		if {$cuvette == 0} return
		# data stablilizer
		if { [incr skippedsmp] < $par_sskip } return

		data_processL2 $t $Qnow [expr {$u*100.0}]
	}
	return
}


proc data_dispatcher {self} {
	data_processL1 $self
}

proc l3data {a} {
	set d [split $a " "]
	if {[llength $d] != 3} return
	data_processL3 {*}$d
}

proc datafileread {filename lineproc pindicator} {
	if {[set m100 [file size $filename]] <= 0} return

	set fd [open $filename r]
	fconfigure $fd -buffering line
	# fileevent $fd readable [list getstrdata $chan]
	while {-1 != [gets $fd a]} {
		set m [tell $fd]
		$lineproc $a
		if {[$pindicator [expr {int($m*100.0/$m100)}]] != 1} break
	}
	close $fd
	$pindicator ""
}
