# --------------------
# -- PROGRAM COMMANDS

proc cmd_about {} {
	global sf26cc_version
	global sf26cc_date

	tk_messageBox -message "[mc "SF-26 Data Acustion System"]\n\
[mc "ver."] $sf26cc_version\
[mc "date"] $sf26cc_date" -type ok -title "SF-26"
}

proc cmd_cons {} {
	catch {console show}
}

proc cmd_exit {} {
	global config_file config_vars

	set retc [tk_messageBox -message [mc "Really exit?"] \
		-type yesno -icon warning -title [mc "SF-26 Exit"]]

	if {$retc == yes} {
		config_save $config_file $config_vars
		chu close
		exit
	}
}

proc cmd_clear {} {
	global StartT
	global intg
	global kmarks

	::AutoPlotM::clear .c
	unset -nocomplain StartT
	unset -nocomplain intg(srcin,t)
	unset -nocomplain intg(srcout,t)
	showmk [set kmarks 1]
}

proc cmd_close {} {
	global  dumpfl

	catch {set _ $dumpfl
	unset -nocomplain dumpfl
	close $_}

	setbutton [mc "Record"]
}

proc cmd_open {} {
	global  dumpfl
	global  config_logfile

	if {[info exist dumpfl]} {
		cmd_close
		return
	}

	if {[file exist $config_logfile]} {
		set retc [tk_messageBox -message [mc "File EXIST.\n Overwrite??"] \
			-type yesno -icon warning -title [mc "Data File Overwrite"]]
	if { $retc != "yes" } { return }
	}

	set dumpfl [open $config_logfile w+]
	setbutton [mc "Stop Rec"]
}

proc cmd_conn {} {
	global config_port

	chu port $config_port
	chu restart
}

proc cmd_fsel {fvar} {
	upvar #0 $fvar sf
	set types {
		{{Data Files}       {.sf.dat}     }
		{{Text Files}       {.txt}        }
		{{All Files}        *             }
	}

	set filename [tk_getSaveFile -filetypes $types \
		-defaultextension {.sf.dat}]

	if { $filename != "" } { set sf $filename }
}

proc cmd_fread {} {
	global config_tplot
	set types {
		{{Data Files}       {.sf.dat}     }
		{{Text Files}       {.txt}        }
		{{All Files}        *             }
	}

	set filename [tk_getOpenFile -filetypes $types \
		-defaultextension {.sf.dat}]

	if { $filename == "" } {return}

	set config_tplot d
	cmd_clear
	datafileread $filename l3data progress
}

proc cmd_intg {} {
	global par_integrate
	global par_optoeps
	global par_optolen
	global par_gasflow

	set par [list $par_integrate $par_optoeps $par_optolen $par_gasflow]
	set names [list \
		[mc {Integration {1|0}}]\
		[mc {Extinction [1/M/cm]}]\
		[mc {Cell length [cm]}]\
		[mc {Gas flow [ml/min]}]\
	]

	set res [tk_inputer .intdia [mc "Concentration/Integration"] $names $par]
	foreach {par_integrate par_optoeps par_optolen par_gasflow} $res break
}

proc cmd_mark {} {
	global kmarks
	global kmarkdo
	if {![info exists kmarks]} {set kmarks 1}
	set kmarkdo $kmarks
	showmk [incr kmarks]
}

