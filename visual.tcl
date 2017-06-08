# --------------------
# --- WINDOWS

proc hr {w} {frame $w -height 2 -borderwidth 1 -relief sunken}

proc frames {} {
global chart
global sysbg
wm title . "SF-26"
wm protocol . WM_DELETE_WINDOW { .mbar.fl invoke Exit }
menu  .mbar
. configure -menu .mbar

menu .mbar.fl -tearoff 0
menu .mbar.plt -tearoff 0
menu .mbar.dat -tearoff 0

.mbar add cascade -menu .mbar.fl -label File -underline 0
.mbar add cascade -menu .mbar.plt -label Plot -underline 0
.mbar add cascade -menu .mbar.dat -label Data -underline 0
.mbar add command -label About -underline 0 -command { cmd_about }

.mbar.fl add command -label "Save as.." -command { cmd_fsel config_logfile }
.mbar.fl add command -label "Record"   -command { cmd_open }
.mbar.fl add command -label "Stop Recording" -command { cmd_close }
.mbar.fl add command -label "Replay File.." -command { cmd_fread }
.mbar.fl add command -label "Layer 2 File.." -command { cmd_f2read }
.mbar.fl add command -label "Console"   -command { cmd_cons }
.mbar.fl add separator
.mbar.fl add command -label Exit -command { cmd_exit }

.mbar.plt add command -label "Clear" -command { cmd_clear }
.mbar.plt add separator
.mbar.plt add radiobutton -label "Plot Transition %" -value "t" -variable config_tplot    -command { cmd_clear }
.mbar.plt add radiobutton -label "Plot Optical Density" -value "d" -variable config_tplot -command { cmd_clear }

.mbar.dat add command -label "Connect" -command { cmd_conn }
.mbar.dat add command -label "Integration.." -command { cmd_intg }
.mbar.dat add checkbutton -label "Quvette corrections" -onvalue 1 -offvalue 0 -variable dataCAL
.mbar.dat add checkbutton -label "Scale corrections" -onvalue 1 -offvalue 0 -variable dataCORR

frame .toolbar -bd 2 -relief flat
canvas .c -relief sunken -bg beige -borderwidth 1
frame .toolbarl -bd 2 -relief flat


# An exit button with an image is created.
# image create photo img -file "exit.png"
# button .toolbar.exitButton -image img -relief flat -command {cmd_exit}

# An exit button with a text
button .toolbarl.conn  -text "Connect" -borderwidth 1 -relief flat -overrelief raised -command {cmd_conn}
entry  .toolbarl.port                -relief sunken                 -textvariable config_port -width 20

label  .toolbarl.dset1  -relief flat -text "1" -state disabled
label  .toolbarl.dset2  -relief flat -text "2" -state disabled
label  .toolbarl.dset3  -relief flat -text "3" -state disabled
label  .toolbarl.dset4  -relief flat -text "4" -state disabled
entry  .toolbarl.dvolt  -relief sunken -textvariable datavolt -width 10
label  .toolbarl.dz     -relief sunken -text " Z "
label  .toolbarl.ds     -relief sunken -text " S "
entry  .toolbarl.dc     -relief groove -textvariable dataConv -width 8 -state disabled

pack   .toolbarl.conn  -side left
pack   .toolbarl.port  -side left
pack   .toolbarl.dset1  -side left
pack   .toolbarl.dset2  -side left
pack   .toolbarl.dset3  -side left
pack   .toolbarl.dset4  -side left
pack   .toolbarl.dvolt  -side left
pack   .toolbarl.dz  -side left -padx 4
pack   .toolbarl.ds  -side left -padx 4
pack   .toolbarl.dc  -side left



label  .toolbar.l1 -text "IN"
entry  .toolbar.din   -relief sunken -textvariable dataDi -width 10
label  .toolbar.l2 -text "OUT"
entry  .toolbar.dout  -relief sunken -textvariable dataDo -width 10

button .toolbar.open  -text "Record" -width 8 -relief raised -overrelief raised -command {cmd_open}
label  .toolbar.anim  -relief flat
entry  .toolbar.file                -relief sunken                 -textvariable config_logfile -width 26
button .toolbar.fsel  -text "..."   -relief raised                 -command {cmd_fsel config_logfile}
label  .toolbar.l3 -text {Ozone [mmol]}
entry  .toolbar.ozon                -relief sunken                 -textvariable intg(delta) -width 10
checkbutton .toolbar.shex -text "Show Data" -relief flat -variable vShowEx -command {showex $vShowEx}

pack    [label .toolbar.s1 -text {} -borderwidth 0 -width 2 -padx 0] -side left
pack   .toolbar.l1  -side left
pack   .toolbar.din -side left
pack    [label .toolbar.s2 -text {} -borderwidth 0 -width 2 -padx 0] -side left
pack   .toolbar.l2  -side left
pack   .toolbar.dout -side left
pack    [label .toolbar.s3 -text {} -borderwidth 0 -width 2 -padx 0] -side left
pack   .toolbar.open  -side left -ipadx 10 -padx 4 -anchor center
pack   .toolbar.anim  -side left
pack   .toolbar.file  -side left
pack   .toolbar.fsel  -side left
pack    [label .toolbar.s4 -text {} -borderwidth 0 -width 2 -padx 0] -side left
pack   .toolbar.l3  -side left
pack   .toolbar.ozon  -side left
pack   .toolbar.shex  -side right

# pack   .toolbar.exitButton -side left -padx 2 -pady 2
# pack   .toolbar.clrButton  -side left -padx 2 -pady 2
# pack   .toolbar.consButton -side left -padx 2 -pady 2

pack .toolbar -fill x -expand false
pack .c -side top -fill both -expand true
pack .toolbarl -fill x -expand false


# -xscrollincrement 1
#    -scrollregion {0 0 80000 0} 

#    -xscrollcommand [list .t.xscroll set] \
#    -yscrollcommand [list .t.yscroll set] \

# scrollbar .t.xscroll -orient horizontal \
#     -command [list .t.c xview]
# scrollbar .t.yscroll -orient vertical \
#    -command [list .t.c yview]
#
# grid .t.c       .t.yscroll -sticky news
# grid .t.xscroll x          -sticky news


set chart [::AutoPlotM::create .c]
set ::AutoPlotM::plotcols(setnone)  black
set ::AutoPlotM::plotcols(setsrcin)  darkblue
set ::AutoPlotM::plotcols(setsrccal)  darkred
set ::AutoPlotM::plotcols(setsrcout)  darkgreen
set ::AutoPlotM::plotcols(setsrcd)  darkgrey

setanimate .toolbar.anim {gray12 gray50 gray75 gray50} 1
set sysbg [.toolbarl.port cget -bg]


toplevel .ex -bd 2 -relief flat
labelframe .ex.cv -bd 2 -relief groove -text {Current values}
labelframe .ex.cp -bd 2 -relief groove -text {Current parameters}
labelframe .ex.sp -bd 2 -relief groove -text {Setup parameters}
labelframe .ex.in -bd 2 -relief groove -text {Integration}

entry  .ex.cv.vTm   -relief sunken -textvariable dataTm -width 8
entry  .ex.cv.vDin  -relief sunken -textvariable dataDi -width 8
entry  .ex.cv.vDout -relief sunken -textvariable dataDo -width 8
grid   [label .ex.cv.l1 -an e -text "time"] .ex.cv.vTm   -sticky ew -padx 4
grid   [label .ex.cv.l2 -an e -text "Din"]  .ex.cv.vDin  -sticky ew -padx 4
grid   [label .ex.cv.l3 -an e -text "Dout"] .ex.cv.vDout -sticky ew -padx 4
grid columnconfigure    .ex.cv 1 -weight 1

entry  .ex.cp.vTd   -relief sunken -textvariable dataTd -width 8
entry  .ex.cp.vTin  -relief sunken -textvariable dataTi -width 8
entry  .ex.cp.vTout -relief sunken -textvariable dataTo -width 8
entry  .ex.cp.vTc   -relief sunken -textvariable dataTc -width 8
entry  .ex.cp.vCz   -relief sunken -textvariable dataTz -width 8
entry  .ex.cp.vCk   -relief sunken -textvariable dataTk -width 8
entry  .ex.cp.con -relief sunken -textvariable dataConv -width 8
checkbutton .ex.cp.vCOR -variable dataCORR
checkbutton .ex.cp.vCAL -variable dataCAL
grid   [label .ex.cp.l1 -an e -text "T% dark"]  .ex.cp.vTd   -sticky ew -padx 4
grid   [label .ex.cp.l2 -an e -text "T% in"]    .ex.cp.vTin  -sticky ew -padx 4
grid   [label .ex.cp.l3 -an e -text "T% out"]   .ex.cp.vTout -sticky ew -padx 4
grid   [label .ex.cp.l4 -an e -text "T% corr"]  .ex.cp.vTc   -sticky ew -padx 4
grid   [label .ex.cp.l5 -an e -text "T% zero"]  .ex.cp.vCz   -sticky ew -padx 4
grid   [label .ex.cp.l6 -an e -text "T% scale"] .ex.cp.vCk   -sticky ew -padx 4
grid   [label .ex.cp.l7 -an e -text "convergence"] .ex.cp.con -sticky ew -padx 4
grid   [label .ex.cp.l8 -an e -text "correction"] .ex.cp.vCOR -sticky w -padx 4
grid   [label .ex.cp.l9 -an e -text "calibrate"]  .ex.cp.vCAL -sticky w -padx 4
grid columnconfigure    .ex.cp 1 -weight 1

entry  .ex.sp.nSk      -relief sunken -textvariable par_sskip -width 3
entry  .ex.sp.nSd      -relief sunken -textvariable par_srcd -width 3
entry  .ex.sp.nSin     -relief sunken -textvariable par_srcin -width 3
entry  .ex.sp.nSout    -relief sunken -textvariable par_srcout -width 3
entry  .ex.sp.nSc      -relief sunken -textvariable par_srccal -width 3
entry  .ex.sp.vC       -relief sunken -textvariable par_setcal -width 8
entry  .ex.sp.vTinmax  -relief sunken -textvariable par_ticorr -width 8
entry  .ex.sp.vToutmax -relief sunken -textvariable par_tocorr -width 8
entry  .ex.sp.vAlph    -relief sunken -textvariable par_alpha -width 5
grid   [label .ex.sp.l1 -an e -text "Skip samples"] .ex.sp.nSk -sticky ew -padx 4
grid   [label .ex.sp.l2 -an e -text "Dark src"] .ex.sp.nSd     -sticky ew -padx 4
grid   [label .ex.sp.l3 -an e -text "IN src"]   .ex.sp.nSin    -sticky ew -padx 4
grid   [label .ex.sp.l4 -an e -text "OUT src"]  .ex.sp.nSout   -sticky ew -padx 4
grid   [label .ex.sp.l5 -an e -text "Corr src"] .ex.sp.nSc     -sticky ew -padx 4
grid   [label .ex.sp.l6 -an e -text "Corr T%"]  .ex.sp.vC      -sticky ew -padx 4
grid   [label .ex.sp.l7 -an e -text "TinCorr"]  .ex.sp.vTinmax -sticky ew -padx 4
grid   [label .ex.sp.l8 -an e -text "ToutCorr"] .ex.sp.vToutmax -sticky ew -padx 4
grid   [label .ex.sp.l9 -an e -text "Smooth"]   .ex.sp.vAlph   -sticky ew -padx 4
grid columnconfigure    .ex.sp 1 -weight 1

checkbutton .ex.in.en -variable par_integrate
entry  .ex.in.ia   -relief sunken -textvariable intg(srcin,s) -width 8
entry  .ex.in.in   -relief sunken -textvariable intg(srcin,n) -width 8
entry  .ex.in.oa   -relief sunken -textvariable intg(srcout,s) -width 8
entry  .ex.in.on   -relief sunken -textvariable intg(srcout,n) -width 8
entry  .ex.in.oz   -relief sunken -textvariable intg(delta) -width 8
grid   [label .ex.in.l1 -an e -text Enable]   .ex.in.en -sticky w  -padx 4
grid   [label .ex.in.l2 -an e -text input]    .ex.in.ia -sticky ew -padx 4
grid   [label .ex.in.l3 -an e -text {[mmol]}] .ex.in.in -sticky ew -padx 4
grid   [label .ex.in.l4 -an e -text output]   .ex.in.oa -sticky ew -padx 4
grid   [label .ex.in.l5 -an e -text {[mmol]}] .ex.in.on -sticky ew -padx 4
grid   [label .ex.in.l6 -an e -text Delta]    .ex.in.oz -sticky ew -padx 4
grid columnconfigure    .ex.in 1 -weight 1

grid .ex.cv .ex.in -sticky news -padx 5 -pady 5
grid .ex.cp .ex.sp -sticky news -padx 5 -pady 5
grid columnconfigure .ex all -weight 1
grid rowconfigure    .ex all -weight 1
}

# --------------------
# -- WINDOWS animation


proc animate {} {
	global AnimImg

	foreach {w _} [split [array names AnimImg *,n] ,] {break}
	if {[incr AnimImg($w,n)] < $AnimImg($w,div)} {return}
	set AnimImg($w,n) 0

	if {[incr AnimImg($w,i)] >= $AnimImg($w,ni)} {set AnimImg($w,i) 0}
	$w configure -bitmap [lindex $AnimImg($w,icons) $AnimImg($w,i)]
}


proc setanimate {w icons {divisor 4}} {
	global AnimImg

	set AnimImg($w,ni) 0
	set AnimImg($w,div) $divisor
	set AnimImg($w,n) $divisor

	foreach bm $icons {
		lappend AnimImg($w,icons) $bm
		incr AnimImg($w,ni)
	}
	set AnimImg($w,i) $AnimImg($w,ni)
	animate
}

# activate one of  four flags
proc show_dset {n} {
	if {$n == 1} { .toolbarl.dset1 configure -state active } else { .toolbarl.dset1 configure -state disabled  }
	if {$n == 2} { .toolbarl.dset2 configure -state active } else { .toolbarl.dset2 configure -state disabled  }
	if {$n == 3} { .toolbarl.dset3 configure -state active } else { .toolbarl.dset3 configure -state disabled  }
	if {$n == 4} { .toolbarl.dset4 configure -state active } else { .toolbarl.dset4 configure -state disabled  }
}

proc showex {showit} {
	global vShowEx

	if { $showit } {
	   wm manage .ex
	   wm protocol .ex WM_DELETE_WINDOW { showex 0 }
	   wm attributes .ex -topmost 1
	   wm title .ex "Extended data"
	   set vShowEx 1
	} else {
	   wm forget .ex
	   set vShowEx 0
	}
}

proc showstatus {s} {
	global sysbg
	if {$s != "connected"} {
		.toolbarl.port configure -bg pink
	} else {
		.toolbarl.port configure -bg $sysbg
	}
}

proc setbutton {s} {
	.toolbar.open configure -text $s
}

proc inputdata {s} {
	global sysbg
	if {$s=="srcin"}  { .ex.cp.vTin configure -bg lightblue; .toolbar.din configure -bg lightblue} else { .ex.cp.vTin configure -bg $sysbg; .toolbar.din configure -bg $sysbg }
	if {$s=="srcout"} { .ex.cp.vTout configure -bg lightgreen; .toolbar.dout configure -bg lightgreen} else { .ex.cp.vTout configure -bg $sysbg; .toolbar.dout configure -bg $sysbg }
	if {$s=="srcd"}   { .ex.cp.vTd configure -bg lightgray } else { .ex.cp.vTd configure -bg $sysbg}
	if {$s=="srccal"} { .ex.cp.vTc configure -bg IndianRed1} else { .ex.cp.vTc configure -bg $sysbg}
}

proc flashscale {s} {
	global sysbg
	if {$s eq "s"} {set c "IndianRed1"} elseif {$s eq "z"} {set c "darkgray"} else return
	if {[.toolbarl.d$s cget -bg] eq $c} {
		.toolbarl.d$s configure -bg $sysbg
	} else {
		.toolbarl.d$s configure -bg $c
	}
}

proc progress {v} {
	global prog_perc

	if {![winfo exists .progress] && $v ne ""} {
		toplevel .progress
		button .progress.stop -command {unset -nocomplain prog_perc} -text "Cancel" -width 8
		canvas .progress.prog -width 200 -height 20 -bd 1 -relief sunken -highlightt 0
		.progress.prog create rectangle 0 0 0 20 -tags bar -fill navy

		grid .progress.prog -sticky ew -padx 10 -pady 10
		grid .progress.stop -pady 10
		wm title .progress "Reading..."
		wm resizable .progress 0 0
		wm protocol .progress WM_DELETE_WINDOW {unset -nocomplain prog_perc}
		set prog_perc ""
		focus .progress.stop
	}

	if {$v eq ""} {
		catch {destroy .progress}
		unset -nocomplain prog_perc
		return 0
	}

	if {![info exists prog_perc]} {return 0}
	if {$prog_perc eq $v} {return 1}
	.progress.prog coords bar 0 0 [expr {int($v * 2)}] 20
	set prog_perc $v
	update
	return 1
}
