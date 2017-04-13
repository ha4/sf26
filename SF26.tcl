#!/bin/sh
# the next line restarts using the correct interpreter \
exec wish "$0" "$@"

source daqu.tcl
source lowpass.tcl
source autoplotm.tcl
set sf26cc_version "1.0"
set sf26cc_date "20130307"

# tutorial from:
# http://www.tkdocs.com/tutorial/index.html
# http://www.icanprogram.com/09tk/main.html
# http://wiki.tcl.tk/969


# --------------------
# VARIABLES
#

# -- PARAMETERS variables
set par(port) "/dev/ttyUSB0"
if {$tcl_platform(platform) == "windows" } { set par(port) "\\.\\\\COM4" } 
set par(file) "o3.sf.dat"
set par(sskip)   5
set par(srcd)    4
set par(srcin)   3
set par(srcout)  1
set par(srccal)  2
set par(setcal)  53.4
set par(ticorr)  100.0
set par(tocorr)  100.0
set par(alpha)   0.18
set par(tplot)   "t"


# -- DATASET variables
set datavolt 0
set dataDi 0
set dataDo 0
set dataTm 0
set dataTd 0
set dataTi 0
set dataTo 0
set dataTc $par(setcal)
set dataTk 1.0
set dataCAL 0
set dataCORR 1

# -- PLOT/SAVE variables
set vShowEx 1
global chart
global dumpfl


# --------------------
# --- WINDOWS

proc hr {w} {frame $w -height 2 -borderwidth 1 -relief sunken}

proc frames {} {
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

.mbar.fl add command -label "Save as.." -command { cmd_fsel par(file) }
.mbar.fl add command -label "Capture"   -command { cmd_open }
.mbar.fl add command -label "Stop"      -command { cmd_close }
.mbar.fl add command -label "Console"   -command { cmd_cons }
.mbar.fl add separator
.mbar.fl add command -label Exit -command { cmd_exit }

.mbar.plt add command -label "Clear" -command { cmd_clear }
.mbar.plt add radiobutton -label "Plot Transition %" -value "t" -variable par(tplot)    -command { cmd_clear }
.mbar.plt add radiobutton -label "Plot Optical Density" -value "d" -variable par(tplot) -command { cmd_clear }

.mbar.dat add command -label "Connect" -command { cmd_conn }
.mbar.dat add checkbutton -label "Cell T100% correction" -onvalue 1 -offvalue 0 -variable dataCAL -command {unset -nocomplain fil1}
.mbar.dat add checkbutton -label "Auto corrections" -onvalue 1 -offvalue 0 -variable dataCORR

frame .toolbar -bd 2 -relief flat

frame .toolbar2 -bd 2 -relief flat

# An exit button with an image is created.
# image create photo img -file "exit.png"
# button .toolbar.exitButton -image img -relief flat -command {cmd_exit}

# An exit button with a text
button .toolbar.conn  -text "Connect" -relief flat -overrelief raised -command {cmd_conn}
entry  .toolbar.port                -relief sunken                 -textvariable par(port) -width 10

label  .toolbar.dset1  -relief flat -text "1" -state disabled
label  .toolbar.dset2  -relief flat -text "2" -state disabled
label  .toolbar.dset3  -relief flat -text "3" -state disabled
label  .toolbar.dset4  -relief flat -text "4" -state disabled
entry  .toolbar.dvolt  -relief sunken -textvariable datavolt -width 7

button .toolbar.open  -text "  Open" -relief flat -overrelief raised -command {cmd_open}
label  .toolbar.anim  -relief flat
entry  .toolbar.file                -relief sunken                 -textvariable par(file) -width 26
button .toolbar.fsel  -text "..."   -relief raised                 -command {cmd_fsel par(file)}
checkbutton .toolbar.shex -text "Show" -relief flat -variable vShowEx -command {cmd_showex $vShowEx}

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


entry  .toolbar2.vDin  -text 0     -relief sunken -textvariable dataDi -width 6
entry  .toolbar2.vDout -text 0     -relief sunken -textvariable dataDo -width 6
entry  .toolbar2.vTm   -text 0     -relief sunken -textvariable dataTm -width 6

entry  .toolbar2.vTd   -text 0     -relief sunken -textvariable dataTd -width 6
entry  .toolbar2.vTin  -text 0     -relief sunken -textvariable dataTi -width 6
entry  .toolbar2.vTout -text 0     -relief sunken -textvariable dataTo -width 6
entry  .toolbar2.vTc   -text 0     -relief sunken -textvariable dataTc -width 6
entry  .toolbar2.vCk   -text 0     -relief sunken -textvariable dataTk -width 6

entry  .toolbar2.nSk      -relief sunken -textvariable par(sskip) -width 3
entry  .toolbar2.nSd      -relief sunken -textvariable par(srcd) -width 3
entry  .toolbar2.nSin     -relief sunken -textvariable par(srcin) -width 3
entry  .toolbar2.nSout    -relief sunken -textvariable par(srcout) -width 3
entry  .toolbar2.nSc      -relief sunken -textvariable par(srccal) -width 3
entry  .toolbar2.vC       -relief sunken -textvariable par(setcal) -width 6
entry  .toolbar2.vTinmax  -relief sunken -textvariable par(ticorr) -width 6
entry  .toolbar2.vToutmax -relief sunken -textvariable par(tocorr) -width 6
entry  .toolbar2.vAlpha   -relief sunken -textvariable par(alpha) -width 5

# -xscrollincrement 1
#    -scrollregion {0 0 80000 0} 

#    -xscrollcommand [list .t.xscroll set] \
#    -yscrollcommand [list .t.yscroll set] \

canvas .t.c -relief groove \
          -xscrollincrement 1 -bg beige

# scrollbar .t.xscroll -orient horizontal \
#     -command [list .t.c xview]
# scrollbar .t.yscroll -orient vertical \
#    -command [list .t.c yview]
#
# grid .t.c       .t.yscroll -sticky news
# grid .t.xscroll x          -sticky news

# The toolbar is packed to the root window. It is horizontally stretched.
pack .toolbar -fill x -expand false

grid .t.c -sticky news
grid rowconfigure    .t 0 -weight 1
grid columnconfigure .t 0 -weight 1

grid   [label .toolbar2.lTm -text "  time"] .toolbar2.vTm 
grid   [label .toolbar2.lDi -text "   Din"] .toolbar2.vDin
grid   [label .toolbar2.lDo -text "  Dout"] .toolbar2.vDout
grid   [hr .toolbar2.hr1]  -sticky we -columnspan 2 -padx 6 -pady 6
grid   [label .toolbar2.lTd -text "  T% dark"] .toolbar2.vTd 
grid   [label .toolbar2.lTi -text "   Tin%"]     .toolbar2.vTin
grid   [label .toolbar2.lTo -text "  Tout%"]     .toolbar2.vTout
grid   [label .toolbar2.lTc -text "  T% corr"] .toolbar2.vTc 
grid   [label .toolbar2.lTcc -text " T%koeff"] .toolbar2.vCk
grid   [hr .toolbar2.hr2]  -sticky we -columnspan 2 -padx 6 -pady 6
grid   [label .toolbar2.lsk -text "Skip samples"] .toolbar2.nSk
grid   [label .toolbar2.lSd -text "  Dark src"] .toolbar2.nSd 
grid   [label .toolbar2.lSi -text "    IN src"]  .toolbar2.nSin 
grid   [label .toolbar2.lSo -text "   OUT src"]  .toolbar2.nSout
grid   [label .toolbar2.lSc -text "  Corr src"] .toolbar2.nSc 
grid   [label .toolbar2.lCv -text "  Corr T%"]  .toolbar2.vC 
grid   [label .toolbar2.lCti -text "   TinCorr"]  .toolbar2.vTinmax
grid   [label .toolbar2.lCto -text "  ToutCorr"]  .toolbar2.vToutmax
grid   [label .toolbar2.lAlph -text "SmoothAlpha"]  .toolbar2.vAlpha

pack .toolbar2 -side right -fill y

pack .t -side top -fill both -expand true
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

# activate one of  four flags
proc show_dset {n} {
	if {$n == 1} { .toolbar.dset1 configure -state active } else { .toolbar.dset1 configure -state disabled  }
	if {$n == 2} { .toolbar.dset2 configure -state active } else { .toolbar.dset2 configure -state disabled  }
	if {$n == 3} { .toolbar.dset3 configure -state active } else { .toolbar.dset3 configure -state disabled  }
	if {$n == 4} { .toolbar.dset4 configure -state active } else { .toolbar.dset4 configure -state disabled  }
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



# --------------------
# -- PROGRAM COMMANDS

proc cmd_about {} {
  global sf26cc_version
  global sf26cc_date
  tk_messageBox -message "SF-26 Data Acustion System\nver $sf26cc_version at $sf26cc_date" -type ok -title "SF-26"
}

proc cmd_cons {} {
catch {console show}
}

proc cmd_exit {} {
  set retc [tk_messageBox -message "Really exit?" -type yesno -icon warning -title "SF-26 Exit"]
  switch -- $retc {
     yes  exit
  }
}

proc cmd_clear {} {
        global StartT
	::AutoPlotM::clear .t.c
	unset -nocomplain StartT
}

proc cmd_close {} {
   global  dumpfl

   set m $dumpfl
   unset dumpfl
   close $m
   .toolbar.open configure -text "  Open"
}

proc cmd_open {} {

   global  dumpfl
   global  par

   if {[info exist dumpfl]} {
	cmd_close
	return
   }

   if {[file exist $par(file)]} {
     set retc [tk_messageBox -message "File EXIST.\n Overwrite??" -type yesno -icon warning -title "Data File Overwrite"]
     if { $retc != "yes" } { return }
   }

   set dumpfl [open $par(file) w+]
   .toolbar.open configure -text "  Close"
}

proc cmd_clr {} {
    global  n
    set n 0
    ::AutoPlotM::clear .t.c
	animate .toolbar.anim
}

proc cmd_cell {} {
    unset -nocomplain fil1

}

proc cmd_conn {} {
   global par
   ::DAQU::restart $par(port) data_dispatcher
}

proc cmd_fsel {fvar} {
	upvar #0 $fvar sf
	set types {
	    {{Data Files}       {.sf.dat}        }
	    {{Text Files}       {.txt}        }
	    {{All Files}        *             }
	}

	set filename [tk_getSaveFile -filetypes $types -defaultextension {.sf.dat}]

	if { $filename != "" } { set sf $filename }
}

proc cmd_showex {showit} {
	if { $showit } {
	   pack forget .toolbar2
	} else {
	   pack .toolbar2 -side right -fill y
	}
}

# --------------------
# -- INITALIZATION

# --- Widgets SETUP
frames
set chart [::AutoPlotM::create .t.c]
set ::AutoPlotM::plotcols(setnone)  black
set ::AutoPlotM::plotcols(setsrcin)  darkgreen
set ::AutoPlotM::plotcols(setsrccal)  darkblue
set ::AutoPlotM::plotcols(setsrcout)  darkred
set ::AutoPlotM::plotcols(setsrcd)  darkgrey

setanimate .toolbar.anim {gray12 gray50 gray75 gray50}

catch {console hide}

raise .

catch {::DAQU::start $par(port) data_dispatcher}

