# --------------------
# --- WINDOWS

proc hr {w} {frame $w -height 2 -borderwidth 1 -relief sunken}

proc frames {} {
global chart
global sysbg
wm title . "SF-26"
wm protocol . WM_DELETE_WINDOW [list .mbar.fl invoke [mc Exit]]
menu  .mbar
. configure -menu .mbar

menu .mbar.fl -tearoff 0
menu .mbar.plt -tearoff 0
menu .mbar.dat -tearoff 0

.mbar add cascade -menu .mbar.fl -label [mc File] -underline 0
.mbar add cascade -menu .mbar.plt -label [mc Plot] -underline 0
.mbar add cascade -menu .mbar.dat -label [mc Data] -underline 0
.mbar add command -label [mc About] -underline 0 -command { cmd_about }

foreach {n c} [list [mc "Save as.."] {cmd_fsel config_logfile} [mc "Record"] {cmd_open} \
[mc "Stop Recording"] {cmd_close}  [mc "Replay File.."] {cmd_fread} \
[mc "Layer 2 File.."] {cmd_f2read} [mc "Console"] {cmd_cons}] {
  .mbar.fl add command -label $n -command $c
}
.mbar.fl add separator
.mbar.fl add command -label [mc Exit] -command { cmd_exit }

.mbar.plt add command -label [mc "Clear"] -command { cmd_clear }
.mbar.plt add separator
.mbar.plt add radiobutton -label [mc "Plot Transition %"] -value "t" -variable config_tplot    -command { cmd_clear }
.mbar.plt add radiobutton -label [mc "Plot Optical Density"] -value "d" -variable config_tplot -command { cmd_clear }

.mbar.dat add command -label [mc "Connect"] -command { cmd_conn }
.mbar.dat add command -label [mc "Mark"] -command { cmd_mark }
.mbar.dat add command -label [mc "Integration.."] -command { cmd_intg }
.mbar.dat add checkbutton -label [mc "Extended data.."] -onvalue 1 -offvalue 0 -variable vShowEx -command {showex $vShowEx}
.mbar.dat add checkbutton -label [mc "Cuvette calibration"] -onvalue 1 -offvalue 0 -variable dataCAL
.mbar.dat add checkbutton -label [mc "Scale corrections"] -onvalue 1 -offvalue 0 -variable dataCORR

# .c is beige ivory {floral white} seashell black
frame .toolbar -bd 2 -relief flat
canvas .c -relief sunken -bg ivory -borderwidth 1
frame .toolbarl -bd 2 -relief flat


# An exit button with an image is created.
# image create photo img -file "exit.png"
# button .toolbar.exitButton -image img -relief flat -command {cmd_exit}

# An exit button with a text
button .toolbarl.conn  -text [mc "Connect"] -borderwidth 1 -relief flat -overrelief raised -command {cmd_conn}
entry  .toolbarl.port                -relief sunken                 -textvariable config_port -width 20
foreach q {1 2 3 4} {label  .toolbarl.dset$q  -relief flat -text $q -state disabled}
entry  .toolbarl.dvolt  -relief sunken -textvariable datavolt -width 10
label  .toolbarl.dz     -relief sunken -text " Z "
label  .toolbarl.ds     -relief sunken -text " S "
entry  .toolbarl.dc     -relief groove -textvariable dataConv -width 8 -state disabled

pack   .toolbarl.conn  -side left
pack   .toolbarl.port  -side left
foreach q {set1 set2 set3 set4 volt} {pack .toolbarl.d$q  -side left}
pack   .toolbarl.dz  -side left -padx 4
pack   .toolbarl.ds  -side left -padx 4
pack   .toolbarl.dc  -side left


label  .toolbar.l1 -text [mc "IN"]
entry  .toolbar.din   -relief sunken -textvariable dataDi -width 10
label  .toolbar.l2 -text [mc "OUT"]
entry  .toolbar.dout  -relief sunken -textvariable dataDo -width 10

button .toolbar.open  -text [mc "Record"] -width 8 -relief raised -overrelief raised -command {cmd_open}
label  .toolbar.anim  -relief flat
entry  .toolbar.file                -relief sunken                 -textvariable config_logfile -width 26
button .toolbar.fsel  -text "..."   -relief raised                 -command {cmd_fsel config_logfile}
label  .toolbar.l3 -text [mc {Ozone [mmol]}]
entry  .toolbar.ozon                -relief sunken                 -textvariable intg(delta) -width 10
button .toolbar.mark  -text [mc "Mark"]  -relief raised -width 6        -command {cmd_mark}

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
pack   .toolbar.ozon -side left
pack   .toolbar.mark -side left -padx 3

pack .toolbar -fill x -expand false
pack .c -side top -fill both -expand true
pack .toolbarl -fill x -expand false


set chart [::AutoPlotM::create .c]
set ::AutoPlotM::dset(setnone,color)  black
set ::AutoPlotM::dset(setsrcin,color)  darkblue
set ::AutoPlotM::dset(setsrccal,color)  darkred
set ::AutoPlotM::dset(setsrcout,color)  darkgreen
set ::AutoPlotM::dset(setsrcd,color)  darkgrey

setanimate .toolbar.anim {gray12 gray50 gray75 gray50} 1
set sysbg [.toolbarl.port cget -bg]


toplevel .ex -bd 2 -relief flat
set _ {-bd 2 -relief groove -text}
labelframe .ex.cv {*}$_ [mc "Current values"]
labelframe .ex.cp {*}$_ [mc "Current parameters"]
labelframe .ex.sp {*}$_ [mc "Setup parameters"]
labelframe .ex.in {*}$_ [mc "Integration"]

set _ {-relief sunken -width 8 -textvariable}

foreach {o v} {.ex.cv.vTm dataTm  .ex.cv.vDin dataDi  .ex.cv.vDout dataDo} {entry $o {*}$_ $v}
grid   [label .ex.cv.l1 -an e -text [mc "time"]] .ex.cv.vTm   -sticky ew -padx 4
grid   [label .ex.cv.l2 -an e -text [mc "Din"]]  .ex.cv.vDin  -sticky ew -padx 4
grid   [label .ex.cv.l3 -an e -text [mc "Dout"]] .ex.cv.vDout -sticky ew -padx 4
grid columnconfigure    .ex.cv 1 -weight 1

foreach {o v} {.ex.cp.vTd dataTd  .ex.cp.vTin dataTi  .ex.cp.vTout dataTo  \
 .ex.cp.vTc dataTc  .ex.cp.vCz par_tz  .ex.cp.vCk par_tk  .ex.cp.con dataConv \
} {entry $o {*}$_ $v}
checkbutton .ex.cp.vCOR -variable dataCORR
checkbutton .ex.cp.vCAL -variable dataCAL
grid   [label .ex.cp.l1 -an e -text [mc "T% dark"]]  .ex.cp.vTd   -sticky ew -padx 4
grid   [label .ex.cp.l2 -an e -text [mc "T% in"]]    .ex.cp.vTin  -sticky ew -padx 4
grid   [label .ex.cp.l3 -an e -text [mc "T% out"]]   .ex.cp.vTout -sticky ew -padx 4
grid   [label .ex.cp.l4 -an e -text [mc "T% corr"]]  .ex.cp.vTc   -sticky ew -padx 4
grid   [label .ex.cp.l5 -an e -text [mc "T% zero"]]  .ex.cp.vCz   -sticky ew -padx 4
grid   [label .ex.cp.l6 -an e -text [mc "T% scale"]] .ex.cp.vCk   -sticky ew -padx 4
grid   [label .ex.cp.l7 -an e -text [mc "convergence"]] .ex.cp.con -sticky ew -padx 4
grid   [label .ex.cp.l8 -an e -text [mc "correction"]] .ex.cp.vCOR -sticky w -padx 4
grid   [label .ex.cp.l9 -an e -text [mc "calibrate"]]  .ex.cp.vCAL -sticky w -padx 4
grid columnconfigure    .ex.cp 1 -weight 1

foreach {o v} {.ex.sp.nSk par_sskip  .ex.sp.nSd par_srcd  .ex.sp.nSin par_srcin \
 .ex.sp.nSout par_srcout  .ex.sp.nSc par_srccal  .ex.sp.vC par_setcal \
 .ex.sp.vTinmax par_ticorr  .ex.sp.vToutmax par_tocorr  .ex.sp.vAlph par_alpha \
} {entry $o {*}$_ $v}
grid   [label .ex.sp.l1 -an e -text [mc "Skip samples"]] .ex.sp.nSk -sticky ew -padx 4
grid   [label .ex.sp.l2 -an e -text [mc "Dark src"]] .ex.sp.nSd     -sticky ew -padx 4
grid   [label .ex.sp.l3 -an e -text [mc "IN src"]]   .ex.sp.nSin    -sticky ew -padx 4
grid   [label .ex.sp.l4 -an e -text [mc "OUT src"]]  .ex.sp.nSout   -sticky ew -padx 4
grid   [label .ex.sp.l5 -an e -text [mc "Corr src"]] .ex.sp.nSc     -sticky ew -padx 4
grid   [label .ex.sp.l6 -an e -text [mc "Corr T%"]]  .ex.sp.vC      -sticky ew -padx 4
grid   [label .ex.sp.l7 -an e -text [mc "TinCorr"]]  .ex.sp.vTinmax -sticky ew -padx 4
grid   [label .ex.sp.l8 -an e -text [mc "ToutCorr"]] .ex.sp.vToutmax -sticky ew -padx 4
grid   [label .ex.sp.l9 -an e -text [mc "Smooth"]]   .ex.sp.vAlph   -sticky ew -padx 4
grid columnconfigure    .ex.sp 1 -weight 1

checkbutton .ex.in.en -variable par_integrate
foreach {o v} {.ex.in.ia intg(srcin,s)  .ex.in.in intg(srcin,n)  .ex.in.oa intg(srcout,s) \
.ex.in.on intg(srcout,n)  .ex.in.oz intg(delta)} {entry $o {*}$_ $v}
grid   [label .ex.in.l1 -an e -text [mc Enable]]   .ex.in.en -sticky w  -padx 4
grid   [label .ex.in.l2 -an e -text [mc input]]    .ex.in.ia -sticky ew -padx 4
grid   [label .ex.in.l3 -an e -text [mc {[mmol]}]] .ex.in.in -sticky ew -padx 4
grid   [label .ex.in.l4 -an e -text [mc output]]   .ex.in.oa -sticky ew -padx 4
grid   [label .ex.in.l5 -an e -text [mc {[mmol]}]] .ex.in.on -sticky ew -padx 4
grid   [label .ex.in.l6 -an e -text [mc Delta]]    .ex.in.oz -sticky ew -padx 4
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

	foreach {w _} [split [array names AnimImg *,n] ,] break
	if {[incr AnimImg($w,n)] < $AnimImg($w,div)} return
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
	foreach q {1 2 3 4} {
	 .toolbarl.dset$q configure -state [if {$n == $q} {set _ active} else {set _ disabled}]
	}
}

proc showex {showit} {
	global vShowEx

	if $showit {
	   wm manage .ex
	   wm protocol .ex WM_DELETE_WINDOW {showex 0}
	   wm attributes .ex -topmost 1
	   wm title .ex [mc "Extended data"]
	} else {wm forget .ex}
   set vShowEx $showit
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
	if {$s eq "srcin"}  {set _ lightblue} else {set _ $sysbg}
	.ex.cp.vTin configure -bg $_
	.toolbar.din configure -bg $_
	if {$s eq "srcout"} {set _ lightgreen} else {set _ $sysbg}
	.ex.cp.vTout configure -bg $_
	.toolbar.dout configure -bg $_
	.ex.cp.vTd configure -bg [if {$s eq "srcd"} {set _ lightgray } else {set sysbg}]
	.ex.cp.vTc configure -bg [if {$s=="srccal"} {set _ IndianRed1} else {set sysbg}]
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

proc progress_frame {} {
	toplevel .progress
	button .progress.stop -command {unset -nocomplain prog_perc} -text [mc "Cancel"] -width 8
	canvas .progress.prog -width 200 -height 20 -bd 1 -relief sunken -highlightt 0
	.progress.prog create rectangle 0 0 0 20 -tags bar -fill navy

	grid .progress.prog -sticky ew -padx 10 -pady 10
	grid .progress.stop -pady 10
	wm title .progress [mc "Reading..."]
	wm resizable .progress 0 0
	wm protocol .progress WM_DELETE_WINDOW {unset -nocomplain prog_perc}
	focus .progress.stop
}

proc progress {v} {
	global prog_perc

	if {![winfo exists .progress] && $v ne ""} {progress_frame; set prog_perc ""}

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

proc showmk {n} {.toolbar.mark configure -text "[mc "Mark"] $n"}
