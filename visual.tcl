# --------------------
# --- WINDOWS

proc hr {w} {frame $w -height 2 -borderwidth 1 -relief sunken}

proc frames {} {
global chart
wm title . "SF-26"
menu  .mbar
frame .t
. configure -menu .mbar

menu .mbar.fl -tearoff 0
menu .mbar.plt -tearoff 0
menu .mbar.dat -tearoff 0

.mbar add cascade -menu .mbar.fl -label File -underline 0
.mbar add cascade -menu .mbar.plt -label Plot -underline 0
.mbar add cascade -menu .mbar.dat -label Data -underline 0
.mbar add command -label About -underline 0 -command { cmd_about }

.mbar.fl add command -label "Save as.." -command { cmd_fsel config_logfile }
.mbar.fl add command -label "Capture"   -command { cmd_open }
.mbar.fl add command -label "Stop"      -command { cmd_close }
.mbar.fl add command -label "Console"   -command { cmd_cons }
.mbar.fl add separator
.mbar.fl add command -label Exit -command { cmd_exit }

.mbar.plt add command -label "Clear" -command { cmd_clear }
.mbar.plt add radiobutton -label "Plot Transition %" -value "t" -variable config_tplot    -command { cmd_clear }
.mbar.plt add radiobutton -label "Plot Optical Density" -value "d" -variable config_tplot -command { cmd_clear }

.mbar.dat add command -label "Connect" -command { cmd_conn }
.mbar.dat add checkbutton -label "Cell T100% correction" -onvalue 1 -offvalue 0 -variable dataCAL -command {unset -nocomplain fil1}
.mbar.dat add checkbutton -label "Auto corrections" -onvalue 1 -offvalue 0 -variable dataCORR

frame .toolbar -bd 2 -relief flat


# An exit button with an image is created.
# image create photo img -file "exit.png"
# button .toolbar.exitButton -image img -relief flat -command {cmd_exit}

# An exit button with a text
button .toolbar.conn  -text "Connect" -relief flat -overrelief raised -command {cmd_conn}
entry  .toolbar.port                -relief sunken                 -textvariable config_port -width 10

label  .toolbar.dset1  -relief flat -text "1" -state disabled
label  .toolbar.dset2  -relief flat -text "2" -state disabled
label  .toolbar.dset3  -relief flat -text "3" -state disabled
label  .toolbar.dset4  -relief flat -text "4" -state disabled
entry  .toolbar.dvolt  -relief sunken -textvariable datavolt -width 10

button .toolbar.open  -text "  Open" -relief flat -overrelief raised -command {cmd_open}
label  .toolbar.anim  -relief flat
entry  .toolbar.file                -relief sunken                 -textvariable config_logfile -width 26
button .toolbar.fsel  -text "..."   -relief raised                 -command {cmd_fsel config_logfile}
checkbutton .toolbar.shex -text "Show Data" -relief flat -variable vShowEx -command {showex $vShowEx}

pack   .toolbar.conn  -side left
pack   .toolbar.port  -side left
pack   .toolbar.dset1  -side left
pack   .toolbar.dset2  -side left
pack   .toolbar.dset3  -side left
pack   .toolbar.dset4  -side left
pack   .toolbar.dvolt  -side left

pack   .toolbar.open  -side left -padx 2 -pady 2
pack   .toolbar.anim  -side left
pack   .toolbar.file  -side left
pack   .toolbar.fsel  -side left
pack   .toolbar.shex  -side left

# pack   .toolbar.exitButton -side left -padx 2 -pady 2
# pack   .toolbar.clrButton  -side left -padx 2 -pady 2
# pack   .toolbar.consButton -side left -padx 2 -pady 2

pack .toolbar -fill x -expand false

canvas .t.c -relief groove -bg beige

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


set chart [::AutoPlotM::create .t.c]
set ::AutoPlotM::plotcols(setnone)  black
set ::AutoPlotM::plotcols(setsrcin)  darkgreen
set ::AutoPlotM::plotcols(setsrccal)  darkblue
set ::AutoPlotM::plotcols(setsrcout)  darkred
set ::AutoPlotM::plotcols(setsrcd)  darkgrey

grid .t.c -sticky news
grid rowconfigure    .t 0 -weight 1
grid columnconfigure .t 0 -weight 1

pack .t -side top -fill both -expand true

setanimate .toolbar.anim {gray12 gray50 gray75 gray50}
wm protocol . WM_DELETE_WINDOW { .mbar.fl invoke Exit }


toplevel .toolbar2 -bd 2 -relief flat

entry  .toolbar2.vDin  -text 0     -relief sunken -textvariable dataDi -width 6
entry  .toolbar2.vDout -text 0     -relief sunken -textvariable dataDo -width 6
entry  .toolbar2.vTm   -text 0     -relief sunken -textvariable dataTm -width 6

entry  .toolbar2.vTd   -text 0     -relief sunken -textvariable dataTd -width 6
entry  .toolbar2.vTin  -text 0     -relief sunken -textvariable dataTi -width 6
entry  .toolbar2.vTout -text 0     -relief sunken -textvariable dataTo -width 6
entry  .toolbar2.vTc   -text 0     -relief sunken -textvariable dataTc -width 6
entry  .toolbar2.vCk   -text 0     -relief sunken -textvariable dataTk -width 6

entry  .toolbar2.nSk      -relief sunken -textvariable par_sskip -width 3
entry  .toolbar2.nSd      -relief sunken -textvariable par_srcd -width 3
entry  .toolbar2.nSin     -relief sunken -textvariable par_srcin -width 3
entry  .toolbar2.nSout    -relief sunken -textvariable par_srcout -width 3
entry  .toolbar2.nSc      -relief sunken -textvariable par_srccal -width 3
entry  .toolbar2.vC       -relief sunken -textvariable par_setcal -width 6
entry  .toolbar2.vTinmax  -relief sunken -textvariable par_ticorr -width 6
entry  .toolbar2.vToutmax -relief sunken -textvariable par_tocorr -width 6
entry  .toolbar2.vAlpha   -relief sunken -textvariable par_alpha -width 5

# The toolbar is packed to the root window. It is horizontally stretched.
grid   [label .toolbar2.lp1 -an center -text "Current values"] - -sticky ew -padx 4
grid   [label .toolbar2.lTm -an e -text "time"] .toolbar2.vTm -sticky ew -padx 4
grid   [label .toolbar2.lDi -an e -text "Din"] .toolbar2.vDin -sticky ew -padx 4
grid   [label .toolbar2.lDo -an e -text "Dout"] .toolbar2.vDout -sticky ew -padx 4
grid   [hr .toolbar2.hr1] - -sticky ew -padx 4 -pady 5
grid   [label .toolbar2.lp2 -an center -text "Current parameters"] - -sticky ew -padx 4
grid   [label .toolbar2.lTd -an e -text "T% dark"] .toolbar2.vTd  -sticky ew -padx 4
grid   [label .toolbar2.lTi -an e -text "Tin%"]     .toolbar2.vTin -sticky ew -padx 4
grid   [label .toolbar2.lTo -an e -text "Tout%"]     .toolbar2.vTout -sticky ew -padx 4
grid   [label .toolbar2.lTc -an e -text "T% corr"] .toolbar2.vTc  -sticky ew -padx 4
grid   [label .toolbar2.lTcc -an e -text "T%koeff"] .toolbar2.vCk -sticky ew -padx 4
grid   [hr .toolbar2.hr2]  - -sticky ew -padx 4 -pady 5
grid   [label .toolbar2.lp3 -an center -text "Setup parameters"] - -sticky ew -padx 4
grid   [label .toolbar2.lsk -an e -text "Skip samples"] .toolbar2.nSk -sticky ew -padx 4
grid   [label .toolbar2.lSd -an e -text "Dark src"] .toolbar2.nSd  -sticky ew -padx 4
grid   [label .toolbar2.lSi -an e -text "IN src"]  .toolbar2.nSin  -sticky ew -padx 4
grid   [label .toolbar2.lSo -an e -text "OUT src"]  .toolbar2.nSout -sticky ew -padx 4
grid   [label .toolbar2.lSc -an e -text "Corr src"] .toolbar2.nSc  -sticky ew -padx 4
grid   [label .toolbar2.lCv -an e -text "Corr T%"]  .toolbar2.vC  -sticky ew -padx 4
grid   [label .toolbar2.lCti -an e -text "TinCorr"]  .toolbar2.vTinmax -sticky ew -padx 4
grid   [label .toolbar2.lCto -an e -text "ToutCorr"]  .toolbar2.vToutmax -sticky ew -padx 4
grid   [label .toolbar2.lAlph -an e -text "SmoothAlpha"]  .toolbar2.vAlpha -sticky ew -padx 4

#grid columnconfigure    .toolbar2 0 -weight 1
grid columnconfigure    .toolbar2 1 -weight 1

# pack .toolbar2 -side top -fill y

}

# --------------------
# -- WINDOWS animation


proc animate {w {divisor 4}} {
    global AnimateImg

    incr AnimateImg($w,n)
    if {$AnimateImg($w,n) > $divisor} {
	set AnimateImg($w,n) 0
    } else {return}
    set i $AnimateImg($w,idx)
    $w configure -bitmap [lindex $AnimateImg($w,icons) $i]
    set AnimateImg($w,idx) [expr ($AnimateImg($w,idx) + 1) % 4]
}


proc setanimate {w icons} {
    global AnimateImg

    set AnimateImg($w,idx) 0
    set AnimateImg($w,n) 0
    foreach bm $icons {
	lappend AnimateImg($w,icons) $bm
    }
    $w configure -bitmap [lindex $AnimateImg($w,icons) 0]
}

# activate one of  four flags
proc show_dset {n} {
	if {$n == 1} { .toolbar.dset1 configure -state active } else { .toolbar.dset1 configure -state disabled  }
	if {$n == 2} { .toolbar.dset2 configure -state active } else { .toolbar.dset2 configure -state disabled  }
	if {$n == 3} { .toolbar.dset3 configure -state active } else { .toolbar.dset3 configure -state disabled  }
	if {$n == 4} { .toolbar.dset4 configure -state active } else { .toolbar.dset4 configure -state disabled  }
}

proc showex {showit} {
	global vShowEx

	if { $showit } {
	   wm manage .toolbar2
	   wm protocol .toolbar2 WM_DELETE_WINDOW { showex 0 }
	   wm attributes .toolbar2 -topmost 1
	   wm title .toolbar2 "Extended data"
	   set vShowEx 1
	} else {
	   wm forget .toolbar2
	   set vShowEx 0
	}
}

proc showstatus {s} {
  if {$s != "connected"} {
	.toolbar.port configure -bg pink
  } else {
	.toolbar.port configure -bg [. cget -background]
  }
}
