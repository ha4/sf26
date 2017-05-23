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
  global config_file config_vars
  set retc [tk_messageBox -message "Really exit?" -type yesno -icon warning -title "SF-26 Exit"]
  if {$retc == yes} {
     config_save $config_file $config_vars
     exit
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
   global  config_logfile

   if {[info exist dumpfl]} {
	cmd_close
	return
   }

   if {[file exist $config_logfile]} {
     set retc [tk_messageBox -message "File EXIST.\n Overwrite??" -type yesno -icon warning -title "Data File Overwrite"]
     if { $retc != "yes" } { return }
   }

   set dumpfl [open $config_logfile w+]
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
   global config_port
   global chu

   $chu port $config_port
   $chu restart
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

