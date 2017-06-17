# --------------------
# --- WINDOWS

proc hr {w} {frame $w -height 2 -borderwidth 1 -relief sunken}
proc lb {w t} {global llc; label $w.l[incr llc] -an e -text $t}

proc frames {} {
global chart
global sysbg
wm title . "SF-26"
wm protocol . WM_DELETE_WINDOW [list .mbar.fl invoke [mc Exit]]

# menu part
menu  .mbar
. configure -menu .mbar

foreach {n o} {File fl  Plot plt  Data  dat} {
.mbar add cascade -menu [menu .mbar.$o -tearoff 0] -label [mc $n] -underline 0}
.mbar add command -label [mc About] -underline 0 -command { cmd_about }

foreach {n c} {"Save as.." {cmd_fsel config_logfile} "Record" cmd_open \
"Stop Recording" cmd_close   "Replay File.." cmd_fread \
"Layer 2 File.." cmd_f2read  "Console" cmd_cons} {
.mbar.fl add command -label [mc $n] -command $c}
.mbar.fl add separator
.mbar.fl add command -label [mc Exit] -command cmd_exit

.mbar.plt add command -label [mc "Clear"] -command cmd_clear
.mbar.plt add separator
.mbar.plt add radiobutton -label [mc "Plot Transition %"] -value "t" \
  -variable config_tplot    -command { cmd_clear }
.mbar.plt add radiobutton -label [mc "Plot Optical Density"] -value "d" \
  -variable config_tplot -command { cmd_clear }

foreach {n c} {"Connect" cmd_conn  "Mark" cmd_mark "Integration.." cmd_intg } {
.mbar.dat add command -label [mc $n] -command $c}
.mbar.dat add checkbutton -label [mc "Extended data.."] -onvalue 1 -offvalue 0\
  -variable vShowEx -command {showex $vShowEx}
foreach {n v} {"Cuvette calibration" dataCAL "Scale corrections" dataCORR} {
.mbar.dat add checkbutton -label [mc $n] -onvalue 1 -offvalue 0 -variable $v}

# .c is beige ivory {floral white} seashell black
frame .toolbar -bd 2 -relief flat
canvas .c -relief sunken -bg ivory -borderwidth 1
frame .toolbarl -bd 2 -relief flat

# An exit button with an image is created.
# image create photo img -file "exit.png"
# button .toolbar.exitButton -image img -relief flat -command {cmd_exit}

label  .toolbar.l1 -text [mc "IN"]
entry  .toolbar.din   -relief sunken -textvariable dataDi -width 10
label  .toolbar.l2 -text [mc "OUT"]
entry  .toolbar.dout  -relief sunken -textvariable dataDo -width 10
button .toolbar.open  -text [mc "Record"] -width 8 -relief raised \
   -overrelief raised -command {cmd_open}
label  .toolbar.anim  -relief flat
entry  .toolbar.file  -relief sunken -textvariable config_logfile -width 26
button .toolbar.fsel  -text "..." -relief raised -command {cmd_fsel config_logfile}
label  .toolbar.l3 -text [mc {Ozone [mmol]}]
entry  .toolbar.ozon  -relief sunken -textvariable intg(delta) -width 10
button .toolbar.mark  -text [mc "Mark"] -relief raised -width 6 -command {cmd_mark}
foreach s {1 2 3 4 5 6} {label .toolbar.s$s -text {} -borderwidth 0 -width 2 -padx 0}
foreach o {s1 l1 din  s2 l2 dout  s3 open s4  anim file fsel  s5 l3 ozon s6  mark} {
pack .toolbar.$o -side left}

button .toolbarl.conn  -text [mc "Connect"] -borderwidth 1 -relief flat \
  -overrelief raised -command {cmd_conn}
entry  .toolbarl.port  -relief sunken -textvariable config_port -width 20
foreach q {1 2 3 4} {label .toolbarl.dset$q -relief flat -text $q -state disabled}
entry .toolbarl.dvolt  -relief sunken -textvariable datavolt -width 10
label .toolbarl.lm -text {} -borderwidth 0 -width 2 -padx 0
label .toolbarl.dz -relief sunken -text " Z "
label .toolbarl.ds -relief sunken -text " S "
entry .toolbarl.dc -relief groove -textvariable dataConv -width 8 -state disabled
foreach q {conn port dset1 dset2 dset3 dset4 dvolt lm dz ds dc} {
pack .toolbarl.$q -side left -padx 2}

pack .toolbar -fill x -expand false
pack .c -side top -fill both -expand true
pack .toolbarl -fill x -expand false


set chart [::AutoPlotM::create .c]
array set ::AutoPlotM::dset {setnone,color black   setsrccal,color darkred \
  setsrcin,color darkblue   setsrcout,color darkgreen  setsrcd,color darkgrey}

setanimate .toolbar.anim {gray12 gray50 gray75 gray50} 1
set sysbg [.toolbarl.port cget -bg]

set _ {-bd 2 -relief groove -text}
toplevel .ex -bd 2 -relief flat
foreach {t f} {"Current values" cv "Current parameters" cp "Setup parameters" \
sp "Integration" in} {labelframe .ex.$f {*}$_ [mc $t]}

set _ {-relief sunken -width 8 -textvariable}
set q {-sticky ew -padx 4}

foreach {t v} {"time" dataTm "Din" dataDi "Dout" dataDo \
} {grid [lb .ex.cv [mc $t]] [entry .ex.cv.v$v {*}$_ $v] {*}$q}
grid columnconfigure    .ex.cv 1 -weight 1

foreach {t v} {"T% dark" dataTd  "T% in" dataTi "T% out" dataTo  "T% corr" \
dataTc "T% zero" par_tz  "T% scale" par_tk  "convergence" dataConv} {
grid [lb .ex.cp [mc $t]] [entry .ex.cp.v$v {*}$_ $v] {*}$q}
checkbutton .ex.cp.vCOR -variable dataCORR
checkbutton .ex.cp.vCAL -variable dataCAL
grid   [lb .ex.cp [mc "correction"]] .ex.cp.vCOR -sticky w -padx 4
grid   [lb .ex.cp [mc "calibrate"]]  .ex.cp.vCAL -sticky w -padx 4
grid columnconfigure    .ex.cp 1 -weight 1

foreach {t v} {"Skip samples" par_sskip  "Dark src" par_srcd  "IN src" \
par_srcin   "OUT src" par_srcout  "Corr src" par_srccal  "Corr T%" par_setcal \
"TinCorr" par_ticorr "ToutCorr" par_tocorr "Smooth" par_alpha} {
grid [lb .ex.sp [mc $t]] [entry .ex.sp.v$v {*}$_ $v] {*}$q}
grid columnconfigure    .ex.sp 1 -weight 1

checkbutton .ex.in.en -variable par_integrate
grid   [lb .ex.in [mc Enable]]   .ex.in.en -sticky w  -padx 4
foreach {t o v} {input ia intg(srcin,s) {[mmol]} in intg(srcin,n) \
output oa intg(srcout,s) {[mmol]} on intg(srcout,n) Delta oz intg(delta)} {
grid [lb .ex.in [mc $t]] [entry .ex.in.$o {*}$_ $v] {*}$q}
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
	 .toolbarl.dset$q configure -state [if {$n == $q} \
		{set _ active} else {set _ disabled}]}
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

proc showstatus {s} {global sysbg; .toolbarl.port configure \
	-bg [if {$s ne "connected"} {set _ pink } else {set sysbg}]}

proc setbutton {s} {.toolbar.open configure -text $s}

proc inputdata {s} {
	global sysbg
	if {$s eq "srcin"}  {set _ lightblue} else {set _ $sysbg}
	.ex.cp.vdataTi configure -bg $_
	.toolbar.din configure -bg $_
	if {$s eq "srcout"} {set _ lightgreen} else {set _ $sysbg}
	.ex.cp.vdataTo configure -bg $_
	.toolbar.dout configure -bg $_
	.ex.cp.vdataTd configure -bg [if {$s eq "srcd"} {set _ lightgray } else {set sysbg}]
	.ex.cp.vdataTc configure -bg [if {$s=="srccal"} {set _ IndianRed1} else {set sysbg}]
}

proc flashscale {s} {
	global sysbg
	if {$s eq "s"} {set c "IndianRed1"} else {set c "darkgray"}
	if {[.toolbarl.d$s cget -bg] eq $c} {set c $sysbg}
	.toolbarl.d$s configure -bg $c
}

proc progress_frame {} {
	toplevel .progress
	button .progress.stop -command {progress ""} -text [mc "Cancel"] -width 8
	canvas .progress.prog -width 200 -height 20 -bd 1 -relief sunken -highlightt 0
	.progress.prog create rectangle 0 0 0 20 -tags bar -fill navy

	grid .progress.prog -sticky ew -padx 10 -pady 10
	grid .progress.stop -pady 10
	wm title .progress [mc "Reading..."]
	wm resizable .progress 0 0
	wm protocol .progress WM_DELETE_WINDOW {progress ""}
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

proc showmk {n} {.toolbar.mark configure -text "[mc Mark] $n"}
