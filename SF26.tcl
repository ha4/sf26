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
source configsave.tcl

set sf26cc_version "3.0"
set sf26cc_date "20170522"

# --- Widgets SETUP
frames

catch {console hide}
raise .

catch {source $config_file}

set chu [::DAQU::channel 1 data_dispatcher]
$chu port $config_port
catch {$chu open}
