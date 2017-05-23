
# -- PARAMETERS variables
set config_port "/dev/ttyUSB0"
if {$tcl_platform(platform) == "windows" } { set config_port "\\\\.\\COM12" } 

set config_logfile "o3.sf.dat"
set par_sskip   5
set par_srcd    4
set par_srcin   3
set par_srcout  1
set par_srccal  2
set par_setcal  53.4
set par_ticorr  100.0
set par_tocorr  100.0
set par_alpha   0.18
set config_tplot   "t"

set config_file ".sf26.conf"
set config_vars {config_port config_logfile config_tplot par_sskip par_srcd par_srcin par_srcout par_srccal par_setcal par_ticorr par_tocorr par_alpha}

# -- DATASET variables
set datavolt 0
set dataDi 0
set dataDo 0
set dataTm 0
set dataTd 0
set dataTi 0
set dataTo 0
set dataTc $par_setcal
set dataTk 1.0
set dataCAL 0
set dataCORR 1

# -- PLOT/SAVE variables
set vShowEx 0
global chart
global dumpfl

