# --------------------
# -- DATA HANDLING

#
# variable modify routines
#

# set only first time
proc chk_const {v x} {
	upvar $v k

	if {[info exist k]} {
		return 0
	} else {
		set k $x
		return 1
	}
}

# set and check if value new or updated
proc chk_set {v x} {
	upvar $v k

	if { [info exist k] && $k == $x } {
		return 0
	} else {
		set k $x
		return 1
	}
}

# set and check if different value
proc chk_change {v x} {
	upvar $v k

	if {(![info exist k]) || $k == $x} {
		set k $x
		return 0
	} else {
		set k $x
		return 1
	}
}

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
	  set d [expr 2.0-log10($t) ]
	  if {$d < 5.0} { return $d }
	} 
	return 5.0
}

# 
# main data handler
#

# -- DATASET variables
# dataDi dataDo dataTm   dataTd dataTi dataTo dataTc dataTk

# time, quvette number, intensity%
proc data_process {t q dataI} {
	global config_tplot
	global par_srcd
	global par_srcin
	global par_srcout
	global par_srccal
	global par_setcal
	global par_ticorr
	global par_tocorr
	global par_alpha


	global fil0
	global filk
	global fil1
	global dataCAL
	global dataCORR

	global chart
	global dumpfl

	global dataTd
	global dataTc
	global dataTk

	global dataTi
	global dataTo
	global dataDi
	global dataDo

# preleminary
	set inq [q2name $q]
	set dset "set$inq"

# weird calculation here: 
#       Tin= Tk*(T - Td)/Timax if src-in
#	Tout=Tk*(T - Td)/Tomax if src-out
#	Td=flt(alpha,T) if src-dark
#	Tcorr=flt(alpha,T-Td) if src-corr
#	Tk=Tcorr/Vcorr         if src-corr
#	Timax=flt(alpha,T-Td) if src-in  and 0-correction
#	Tomax=flt(alpha,T-Td) if src-out and 0-correction

	if {$inq == "srcd"} {
		set dataTd [smooth_a $dataI $par_alpha fil0]
	} else {
		set dataI [expr $dataI-$dataTd]
	}

	if {$inq == "srcin"} {
		if {$dataCAL} {
			set par_ticorr [smooth_a $dataI $par_alpha fil1] 
		}
		set dataI  [expr $dataTk*$dataI*100.0/$par_ticorr]
		set dataTi $dataI
		set dataDi [t2d $dataI]
	}
		
	if {$inq == "srcout"} {
		if {$dataCAL} {
			set par_tocorr [smooth_a $dataI $par_alpha fil1] 
		}
		set dataI [expr $dataTk*$dataI*100.0/$par_tocorr]
		set dataTo $dataI
		set dataDo [t2d $dataI]
	}

        if {$inq == "srccal"} { set dataTc [smooth_a $dataI $par_alpha filk] }
        if {$dataCORR} {
	  switch $inq srccal - srcd { set dataTk [expr $dataTc/$par_setcal] }
	}

# plot	different type with different plot
	if {$config_tplot == "d"} {
		switch $inq {
		srcin  { $chart $t $dataDi $dset }
		srcout { $chart $t $dataDo $dset }
		}
	} else {
		$chart $t $dataI  $dset
	}

# store to file
        if {[info exist dumpfl]} {
		switch -- $inq {
		"srcin"  { puts $dumpfl "$t $dataDi *" } 
		"srcout" { puts $dumpfl "$t * $dataDo" } 
		default  { puts $dumpfl "$t * *" }  }

  	 	animate
	}
}


#
# preliminary data handler
#

proc data_dispatcher {self} {
# unset -nocomplain fil1 #?? on dataCAL start
	global StartT
	global Qprev
	global Tprev
	global fil
	global fil1

	global par_sskip
	global skippedsmp

	global dataTm
	global datavolt

	set clk [clock seconds]
	foreach {chan volt bits} [$self decode] {break}
	if {![info exists bits]} {
	   showstatus [$self status]
	   return
	}

	# ignore $chan, read bits
	set quvette [switch $bits 7 {expr {1}}  11 {expr {2}}  13 {expr {3}}  14 {expr {4}} default {expr {0}}]
	lowpass_avg_put $volt fil

	chk_const StartT $clk
	set t [expr $clk-$StartT]

	set timch [chk_change Tprev $t]

	if { [chk_set Qprev $quvette] } {
		set skippedsmp 0
		lowpass_avg_clean fil
		unset -nocomplain fil1
		inputdata [q2name $quvette]
		return
	} 

	# once per second
	if {! $timch} { return }

	# filter here
	# if no data, exit here
	set ul [lowpass_avg_get fil]
		lowpass_avg_clean fil

# display data
	set dataTm $t
	set datavolt "$ul"
	show_dset $quvette

	if {$quvette == 0} { return }

# data stablilizer
	if { [incr skippedsmp] < $par_sskip } { return }

# convert to Intensity%
	set ul [expr $ul*100.0]

	data_process $t $quvette $ul
}

