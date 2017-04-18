#!/bin/sh
# the next line restarts using the correct interpreter \
exec wish "$0" "$@"

# tutorial from:
# http://www.tkdocs.com/tutorial/index.html
# http://www.icanprogram.com/09tk/main.html
# http://wiki.tcl.tk/969

source daqu.tcl
source lowpass.tcl
source autoplotm.tcl
source visual.tcl
source commands.tcl
source datapars.tcl
source defaults.tcl
set sf26cc_version "2.0"
set sf26cc_date "20170417"

# --- Widgets SETUP
frames

catch {console hide}
raise .
catch {::DAQU::start $par(port) data_dispatcher}
