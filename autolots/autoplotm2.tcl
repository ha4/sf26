
#
# Auto Multi Plot with common axis
#

namespace eval ::AutoPlotM {
# k,o,hi,low,d, fmt:axis label format
	variable xaxis
	variable yaxis
	variable yext
	variable yset2

	variable prevpt

# define per plot colors
	variable plotcols
# default color for plot
	variable wplot
# background color
	variable wbg
# axis grid and text colors
	variable waxis
	variable taxis

namespace export    create PlotData replot toPixel plotcols clear xaxis yaxis yext
# service: masaxis minmax scaler rescale DoResize 
}

proc ::AutoPlotM::masaxis {dmin dmax} {
# MASHTAB AXIS
# Result: List of three elements: step, low, high

	# min degree of range
	if {$dmax > $dmin} {
		set ords [expr floor(log10($dmax-$dmin))]
	} elseif {$dmax == $dmin} {
		set ords -1
	} else { return [list] }

	# prelim. step is less by degree
	set ddd [expr pow(10,$ords-1)]

	# calculate num of entries
	set ordax [expr ceil(($dmax-$dmin)/$ddd)]

	set astp [expr $ddd*(($ordax<10)?1:(($ordax<20)?2:(($ordax<50)?5:10)))]
	set amin [expr $astp * floor($dmin / $astp)]
	set amax [expr $astp *  ceil($dmax / $astp)]

	return [list $astp $amin $amax]
}                                                                               


proc ::AutoPlotM::minmax {v chg vmin vmax} {
	upvar $vmin mi
	upvar $vmax ma
	if {[info exist ma]==0} {set ma [set mi $v]; return true}
	if {$v > $ma} {set ma $v; return true }
	if {$v < $mi} {set mi $v; return true }
	return $chg
}


proc ::AutoPlotM::scaler {dmin dmax pixels} {

	set a [expr ($dmin == $dmax)?$pixels:($pixels/($dmax-$dmin))]
	set b [expr -$dmin * $a - (($pixels < 0)?($pixels):0)]

	return [list $b $a]
}                                                                               

proc ::AutoPlotM::rescaler {offset factor newofs newfac} {
        set sc [expr $newfac/$factor]

	set offs [expr ($sc==1)?0:(($offset*$sc-$newofs)/($sc-1.0))]
	return [list $offs $sc]
}

proc ::AutoPlotM::replot { wnd {dtg "all"}} {
	variable xaxis
	variable yaxis
	variable yset2
	variable yext


	if {[info exists xaxis(low)] == 0} { return }

	set wheight [winfo height $wnd]
	set wwidth  [winfo width $wnd]

#	if {[info exist yext($dtg)]} { upvar $yext($dtg) yaxis }

       	set xtmp [scaler $xaxis(low) $xaxis(hi) $wwidth]
        set ytmp [scaler $yaxis(low) $yaxis(hi) [expr -$wheight]]

	if { [info exists yaxis(k)] } {
		foreach {xmov xs} [rescaler $xaxis(o) $xaxis(k) {*}$xtmp] {break}
		foreach {ymov ys} [rescaler $yaxis(o) $yaxis(k) {*}$ytmp] {break}
       		$wnd scale all $xmov $ymov $xs $ys
       		# $wnd scale $dtg $xmov $ymov $xs $ys
	}

	foreach {xaxis(o) xaxis(k)} $xtmp {break}
	foreach {yaxis(o) yaxis(k)} $ytmp {break}

	$wnd delete axis

	if {[info exists yaxis(d)] == 0} { return }
	DrawAxis $wnd $wheight {0 1} xaxis $xaxis(low) $yaxis(low)
	DrawAxis $wnd $wwidth  {1 2} yaxis $yaxis(low) $xaxis(low)
	$wnd lower axis
}


proc ::AutoPlotM::toPixel { ds xcrd ycrd } {
# Result: List of two elements, x- and y-coordinates in pixels
	variable xaxis
	variable yaxis
	variable yset2
	variable yext
# 	if {[info exist yext($ds)]} {upvar $yext($ds) yaxis}

	set xpix [expr int($xaxis(k) * $xcrd + $xaxis(o))]
	set ypix [expr int($yaxis(k) * $ycrd + $yaxis(o))]

	return [list $xpix $ypix]
}

proc ::AutoPlotM::DrawAxis {wnd size sel axis v fixed {dtg set1}} {
	upvar $axis this
	variable waxis
	variable taxis

	set out [expr $this(hi)+0.5*$this(d)]
	while { $v < $out } {
		foreach {x y} \
		  [toPixel $dtg {*}[lrange [list $v $fixed $v] {*}$sel]] {break}
		if {[info exist this(fmt)]} {set atxt [format $this(fmt) $v]} else {set atxt $v}
		if {[info exist this(anchor)]} {set ta [list -anchor $this(anchor)]} else {set ta {}}
		set v [expr $v+$this(d)]

		$wnd create line {*}[lrange [list $x 0 $y] {*}$sel] \
			{*}[lrange [list $x $size $y] {*}$sel] \
			-fill $waxis -tag axis -dash { 2 2 }
		$wnd create text [expr $x + 3] [expr $y - 6] -text $atxt \
			-fill $taxis -tag axis {*}$ta
	}
}

proc ::AutoPlotM::PlotData { wnd xcrd ycrd {dtg set1} {typ line} } {
# PlotData --
# wnd	Name of the canvas
# xcrd	Next x coordinate
# ycrd	Next y coordinate
# dtg	Plot tag
# typ	Line/Point

	variable xaxis
	variable yaxis
	variable yset2
	variable yext

	variable prevpt
	variable wplot
	variable plotcols

# 	if {[info exist yext($dtg)]} { upvar $yext($dtg) yaxis }

	set ch [minmax $xcrd false xaxis(low) xaxis(hi)]
	set ch [minmax $ycrd $ch   yaxis(low) yaxis(hi)]

# is any changes in data range? is scale factor changed?
	if { $ch } {
		foreach {xaxis(d) xaxis(low) xaxis(hi)} \
			[masaxis $xaxis(low) $xaxis(hi)] {break}
		foreach {yaxis(d) yaxis(low) yaxis(hi)} \
			[masaxis $yaxis(low) $yaxis(hi)] {break}
		replot $wnd $dtg
	}

# Get Colour
	if { [info exists plotcols($dtg)] } {
		set cfil $plotcols($dtg)} else {set cfil $wplot}

	foreach {px py} [toPixel $dtg $xcrd $ycrd] {break}

# Draw the line piece
	if { $typ == "line" } {
		if {[info exists prevpt($dtg)] } {
			$wnd create line {*}[toPixel $dtg {*}$prevpt($dtg)] \
				$px $py -fill $cfil -tag $dtg
		}
	} else {
# Draw the cross point
		set pym [expr $py-1]
		set pyp [expr $py+1]
		set pxm [expr $px-1]
		set pxp [expr $px+1]
		$wnd create line $px $pym $px $pyp -fill $cfil -tag $dtg
		$wnd create line $pxm $py $pxp $py -fill $cfil -tag $dtg
	}
	set prevpt($dtg) [list $xcrd $ycrd]
}

proc ::AutoPlotM::DoResize { wnd } {
	global redo

	if { [info exists redo] } { after cancel $redo }

	set redo [after 50 [list ::AutoPlotM::replot $wnd]]
}

proc ::AutoPlotM::create { wnd } {
	variable wplot
	variable waxis
	variable taxis
	variable wbg

	variable xaxis
	variable yaxis
	variable yext

	set newplot "automchart_$wnd"
	interp alias {} $newplot {} ::AutoPlotM::PlotData $wnd

	set wplot  black
	set wbg    white
	set waxis  darkgray
	set taxis  black
	set xaxis(fmt) "%g"
	set xaxis(anchor) s
	set yaxis(fmt) "%.2g"
	set yaxis(anchor) w
#	set yext {}

	clear $wnd

	return $newplot
}

proc ::AutoPlotM::clear { wnd } {
	variable xaxis
	variable yaxis
	variable yext
	variable wbg
	variable prevpt

   	$wnd delete all

	$wnd configure -background $wbg

	unset -nocomplain prevpt
	unset -nocomplain xaxis(low) xaxis(k) xaxis(d)
	unset -nocomplain yaxis(low) yaxis(k) yaxis(d)
	foreach m [array names yext] {
		upvar $yext(m) yaxis
		unset -nocomplain yaxis(low) yaxis(k) yaxis(d)
	}

	replot  $wnd

	bind $wnd <Configure> [list ::AutoPlotM::DoResize $wnd]
}
