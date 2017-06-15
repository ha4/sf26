#!/bin/sh
# the next line restarts using the correct interpreter \
exec wish "$0" "$@"

# tutorial from:
# http://www.tkdocs.com/tutorial/index.html
# http://www.icanprogram.com/09tk/main.html
# http://wiki.tcl.tk/969
package require msgcat
namespace import msgcat::mc
set sf26cc_version "3.3"
set sf26cc_date "20170612"
set sf26dir [file dirname [info script]]
source $sf26dir/daqu.tcl
source $sf26dir/lowpass.tcl
source $sf26dir/autoplotm.tcl
source $sf26dir/visual.tcl
source $sf26dir/commands.tcl
source $sf26dir/datapars.tcl
source $sf26dir/defaults.tcl
catch {source $config_file}
source $sf26dir/configsave.tcl
source $sf26dir/tkinputer.tcl

set dataTc $par_setcal

::msgcat::mclocale ru
::msgcat::mcload $sf26dir

::DAQU::channel chu data_dispatcher
chu port $config_port
# --- Widgets SETUP
frames
showex $vShowEx
cmd_clear

raise .
catch {console hide}
catch {chu open}
