# --------------------
# -- DATA HANDLING


# quvette name translation
proc q2name {q} {
	global par_srcin
	global par_srcout
	global par_srcd
	global par_srccal

	if {$q == $par_srcin}  { return srcin  }
	if {$q == $par_srcout} { return srcout }
	if {$q == $par_srcd}   { return srcd   }
	if {$q == $par_srccal} { return srccal }

	return none
}

# transition to optical density conversion
proc t2d {t} {
	if {$t > 0} {
	  set d [expr {2.0-log10($t)}]
	  if {$d < 5.0} { return $d }
	} 
	return 5.0
}


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

proc data_out {t in out} {
	global config_tplot
	global chart
	global dumpfl

	if {$config_tplot == "d" && $in != "*"}  {$chart $t $in  "setsrcin"}
	if {$config_tplot == "d" && $out != "*"} {$chart $t $out "setsrcout"}

# store to file
        if {[info exist dumpfl]} {
		puts $dumpfl "$t $in $out" 
  	 	animate
	}
}

proc integrate {s t v} {
	global intg
	global par_integrate
	global par_gasflow
	global par_optolen
	global par_optoeps

	if {!$par_integrate} return
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

proc data_intg {t in out} {
	global par_integrate

	if {$in != "*"}  {integrate srcin  $t $in}
	if {$out != "*"} {integrate srcout $t $out}
}

# time, source quvette, transition%
proc data_processL4 {t src trans} {
	global par_ticorr
	global par_tocorr
	global fil1
	global par_alpha
	global dataCAL

	global dataTi
	global dataTo
	global dataDi
	global dataDo

	if {$src == "srcin"} {
		if {$dataCAL} {set par_ticorr [smooth_a $trans $par_alpha fil1]}
		set dataTi [expr {$trans*100.0/$par_ticorr}]
		set dataDi [t2d $dataTi]
		return [list $t $dataDi "*"]
	}
		
	if {$src == "srcout"} {
		if {$dataCAL} {set par_tocorr [smooth_a $trans $par_alpha fil1]}
		set dataTo [expr {$trans*100.0/$par_tocorr}]
		set dataDo [t2d $dataTo]
		return [list $t "*" $dataDo]
	}

	return [list]
}

# time, quvette number, intensity%
proc data_processL3 {t s i} {
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
	global dataTk
	global dataTz
	global dataConv

	inputdata $s
	if {$s == "srcd"} {
		set dataTd [smooth_a $i $par_alpha fil0]
		set dataConv [expr {$i - $dataTd}]
		if {$dataCORR} {
			set dataTz $dataTd
			flashscale z
		}
	}
	set $i [expr {$i-$dataTz}]

        if {$s == "srccal"} {
		set dataTc [smooth_a $i $par_alpha filk]
		set dataConv [expr {$i - $dataTc}]
		if {$dataCAL} {set par_setcal [smooth_a $dataTc $par_alpha fil1]}
		if {$dataCORR} {
			set dataTk [expr {$dataTc/$par_setcal}]
			flashscale s
		}
	}
	set $i [expr {$i * $dataTk}]

	if {$config_tplot == "t"} {$chart $t $i "set$s"}

	switch $s srcin - srcout {list $t $s $i} default {list}
}


#
# preliminary data handler Layer1
#

proc data_processL1 {self} {
	global fil
	global fil1
	global StartT
	global Qprev
	global Tprev
	global skippedsmp


	set clk [clock seconds]

	foreach {chan volt bits} [$self decode] {break}
	if {![info exists bits]} {
	   showstatus [$self status]
	   return [list]
	}

	# ignore $chan, read bits
	set quvette [switch $bits 7 {expr {1}}  11 {expr {2}}  13 {expr {3}}  \
		14 {expr {4}} default {expr {0}}]
	lowpass_avg_put $volt fil

	if {![info exist StartT]} { set StartT $clk }
	set t [expr {$clk-$StartT}]
	if {(![info exist Tprev]) || $Tprev == $t} {
		set Tprev $t
		set timch 0
	} else {
		set Tprev $t
		set timch 1
	}

	if { ![info exist Qprev] || $Qprev != $quvette } {
		set Qprev $quvette
		set skippedsmp 0
		lowpass_avg_clean fil
		unset -nocomplain fil1
		show_dset $quvette
		return [list]
	} 

	# once per second
	if {$timch} {
		set u [lowpass_avg_get fil]
		lowpass_avg_clean fil
		return [list $t $quvette $u]
	}
	return [list]
}

#
# data handler Layer2
#

proc data_processL2 {t q u} {
	global dataTm
	global datavolt
	global skippedsmp
	global par_sskip

# display data
	set dataTm $t
	set datavolt "$u"

	if {$q == 0} {return [list]}

# data stablilizer
	if { [incr skippedsmp] < $par_sskip } {return [list]}

	return [list $t [q2name $q] [expr {$u*100.0}]]
}

proc data_dispatcher {self} {
	if {[set l1data [data_processL1 $self]] == {}} {return}
	if {[set l2data [data_processL2 {*}$l1data]] == {}} {return}
	if {[set l3data [data_processL3 {*}$l2data]] == {}} {return}
	if {[set l4data [data_processL4 {*}$l3data]] == {}} {return}
	data_out {*}$l4data
	data_intg {*}$l4data
}

proc datafileread {filename progress} {
	if {[set m100 [file size $filename]] <= 0} return

	set fd [open $filename r]
	fconfigure $fd -buffering line
	# fileevent $fd readable [list getstrdata $chan]
	while {-1 != [gets $fd a]} {
		set m [tell $fd]
		foreach {t in out} [split $a " "] {break}
		data_out $t $in $out
		data_intg $t $in $out
		if {[progress [expr {int($m*100.0/$m100)}]] != 1} break
	}
	close $fd
	progress ""
}
