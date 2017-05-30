# --------------------
# -- PROGRAM COMMANDS

proc cmd_about {} {
	global sf26cc_version
	global sf26cc_date

	tk_messageBox -message "SF-26 Data Acustion System\nver $sf26cc_version\
 at $sf26cc_date" -type ok -title "SF-26"
}

proc cmd_cons {} {
	catch {console show}
}

proc cmd_exit {} {
	global config_file config_vars

	set retc [tk_messageBox -message "Really exit?" \
		-type yesno -icon warning -title "SF-26 Exit"]

	if {$retc == yes} {
		config_save $config_file $config_vars
		chu close
		exit
	}
}

proc cmd_clear {} {
	global StartT
	::AutoPlotM::clear .c
	unset -nocomplain StartT
}

proc cmd_close {} {
	global  dumpfl

	set m $dumpfl
	unset dumpfl
	close $m

	setbutton "Record"
}

proc cmd_open {} {
	global  dumpfl
	global  config_logfile

	if {[info exist dumpfl]} {
		cmd_close
		return
	}

	if {[file exist $config_logfile]} {
		set retc [tk_messageBox -message "File EXIST.\n Overwrite??" \
			-type yesno -icon warning -title "Data File Overwrite"]
	if { $retc != "yes" } { return }
	}

	set dumpfl [open $config_logfile w+]
	setbutton "Stop Rec"
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
	set types {
		{{Data Files}       {.sf.dat}     }
		{{Text Files}       {.txt}        }
		{{All Files}        *             }
	}

	set filename [tk_getOpenFile -filetypes $types \
		-defaultextension {.sf.dat}]

	if { $filename == "" } {return}

	set fd [open $filename r]
	fconfigure $fd -buffering line
	# fileevent $fd readable [list getstrdata $chan]
	while {-1 != [gets $fd a]} {
		foreach {t in out} [split $a " "] {break}
		data_out $t $in $out
		update
	}
	close $fd
}

proc cmd_int {} {
	global par_integrate
	global par_optoeps
	global par_optolen
	global par_gasflow
}
