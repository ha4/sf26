
# -- PARAMETERS variables
set par(port) "/dev/ttyUSB0"
if {$tcl_platform(platform) == "windows" } { set par(port) "\\\\.\\COM12" } 

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
set vShowEx 0
global chart
global dumpfl

