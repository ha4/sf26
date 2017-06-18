foreach t {1 2 3} {pack [text .t$t -height 1] -fill x
 bind .t$t <ButtonRelease-3> {plumb %W %x %y}}
canvas .c -bg ivory
pack .c -fill both -expand 1 -after .t2

foreach m {f p d} {menu .m$m -tearoff 0}
foreach {m n c} {f "Save as.." {} f Record {} f "Stop Record" {}\
 f "Replay file.." {} f Console {console show} f {} {} f Exit exit\
 p "Clear" {} p {} {} d "Connect" {}  d "Mark" {} d "Integration.." cmd_intg} {
if {$n ne ""} {.m$m add command -label $n -command $c} else {.m$m add separator}}
foreach {n t c} {"Plot Transition %" t {}  "Plot Optical Density" d {}} {
.mp add radiobutton -label $n -value "d" -variable config_tplot -command $c}
.md add checkbutton -label  "Extended data.." -onvalue 1 -offvalue 0 \
  -variable vShowEx -command {showex $vShowEx}
foreach {n v} {"Cuvette calibration" dataCAL "Scale corrections" dataCORR} {
.md add checkbutton -label $n -onvalue 1 -offvalue 0 -variable $v}

#{.mf post %X %Y}
#{.mf post [expr [winfo %w rootx]+%x] [expr [winfo %w rooty] + %y]}
array set plumber {File {msh .mf} Plot {msh .mp} Data {msh .md} About About\
 | fsel  Connect {}  Mark {}  Record {}  Stop {}}
proc msh {m} {global plumber; $m post $plumber(a,X) $plumber(a,Y)}
proc About {} {tk_messageBox -message "SF-26 Data Acustion System\n ver. 4" -type ok -title "SF-26"}

proc plumb {w x y} {global plumber 
	set c [if [llength [$w tag ranges sel]] {$w get sel.first sel.last
	} else  {$w get @$x,${y}wordstart @$x,${y}wordend}]
	array set plumber [list a,cmd $c a,w $w, a,x $x a,y $y a,X \
		[expr [winfo rootx $w]+$x] a,Y [expr [winfo rooty $w]+$y]]
	if [info exist plumber($c)] {{*}$plumber($c)}
}

.t1 insert end "File Plot Data About"
.t2 insert end "Connect \\\\.\\com1 Mark Record Stop | ."

proc fsel {} {
	set filename [tk_getSaveFile -filetypes {{"Data Files" .sf.dat}\
		{"Text Files" .txt} {"All Files" *}} \
		-defaultextension .sf.dat]
	set q [.t2 search | 0.0]
	if [llength q] {.t2 delete $q end; .t2 insert end "| $filename"}
}
