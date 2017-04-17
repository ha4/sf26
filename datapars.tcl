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

# create or increment counter and return it
proc chk_incr {v} {
	upvar $v cnt

	if { [info exist cnt] } {
		incr cnt
	} else {
		set cnt 0
	}
	return $cnt
}


proc q2name {q} {
	global par

	if {$q == $par(srcin)}  { return srcin  }
	if {$q == $par(srcout)} { return srcout }
	if {$q == $par(srcd)}   { return srcd   }
	if {$q == $par(srccal)} { return srccal }

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
# -- PARAMETERS variables
# par(sskip) par(srcd) par(srcin) par(srcout) par(srccal) par(setcal) par(ticorr) par(tocorr) par(alpha)

# time, quvette number, intensity%
proc data_process {t q dataI} {
	global par

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
		set dataTd [smooth_a $dataI $par(alpha) fil0]
	} else {
		set dataI [expr $dataI-$dataTd]
	}

	if {$inq == "srcin"} {
		if {$dataCAL} {
			set par(ticorr) [smooth_a $dataI $par(alpha) fil1] 
		}
		set dataI  [expr $dataTk*$dataI*100.0/$par(ticorr)]
		set dataTi $dataI
		set dataDi [t2d $dataI]
	}
		
	if {$inq == "srcout"} {
		if {$dataCAL} {
			set par(tocorr) [smooth_a $dataI $par(alpha) fil1] 
		}
		set dataI [expr $dataTk*$dataI*100.0/$par(tocorr)]
		set dataTo $dataI
		set dataDo [t2d $dataI]
	}

        if {$inq == "srccal"} { set dataTc [smooth_a $dataI $par(alpha) filk] }
        if {$dataCORR} {
	  switch $inq srccal - srcd { set dataTk [expr $dataTc/$par(setcal)] }
	}

# plot	different type with different plot
	if {$par(tplot) == "d"} {
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

  	 	animate .toolbar.anim 0
	}
}


#
# preliminary data handler
#

proc data_dispatcher {clk chan volt bits} {
	global StartT
	global Qprev
	global Tprev
	global fil
	global fil1

	global par
	global skippedsmp

	global dataTm
	global datavolt

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
	if { [chk_incr skippedsmp] < $par(sskip) } { return }

# convert to Intensity%
	set ul [expr $ul*100.0]

	data_process $t $quvette $ul
}

