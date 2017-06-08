#!/bin/sh
# the next line restarts using the correct interpreter \
exec wish "$0" "$@"

# tutorial from:
# http://www.tkdocs.com/tutorial/index.html
# http://www.icanprogram.com/09tk/main.html
# http://wiki.tcl.tk/969

set sf26cc_version "3.2"
set sf26cc_date "20170608"
source daqu.tcl
source lowpass.tcl
source autoplotm.tcl
source visual.tcl
source commands.tcl
source datapars.tcl
source defaults.tcl
catch {source $config_file}
source configsave.tcl
source tkinputer.tcl
::DAQU::channel chu data_dispatcher
chu port $config_port

# --- Widgets SETUP
frames
showex $vShowEx
cmd_clear

raise .
catch {console hide}
catch {chu open}
