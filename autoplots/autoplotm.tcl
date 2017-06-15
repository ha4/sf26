#
# Auto Multi Plot with common axis
#

namespace eval ::AutoPlotM {
# scale  x/y (name, ab amin amax astep vmin vmax)
# scale param(name, fmt offset anchor color gcolor)
# dset    : mix axis and data (dset, xaxis yaxis color)
# pixel=ab[1]*value+ab[0]
# functions create, clear, createaxis, PlotData
  variable scale
  variable pscale
  variable dset
  variable lastpt
}

proc ::AutoPlotM::masaxis {dmin dmax} {
# MASHTAB AXIS
# Result: List of three elements: low, high, step

# min degree of range
  if {$dmax > $dmin} {
	set ords [expr {floor(log10($dmax-$dmin))}]
  } elseif {$dmax == $dmin} {
	set ords -1
  } else { return [list] }

# prelim. step degree is less by degree
  set ddd [expr pow(10,$ords-1)]

# calculate max num of entries
  set ordax [expr {ceil(($dmax-$dmin)/$ddd)}]

  set astp [expr {$ddd*(($ordax<10)?1:(($ordax<20)?2:(($ordax<50)?5:10)))}]
  set amin [expr {$astp * floor($dmin / $astp)}]
  set amax [expr {$astp *  ceil($dmax / $astp)}]

  return [list $amin $amax $astp]
}                                                                               

proc ::AutoPlotM::scaler {dmin dmax pixels} {
  set a [expr {($dmin==$dmax)?$pixels:($pixels/($dmax-$dmin))}]
  set b [expr {-$dmin*$a - (($pixels<0)?$pixels:0)}]
  return [list $b $a]
}                                                                               

proc ::AutoPlotM::rescaler {name new} {
  variable scale

  foreach {nb na} $new break
  set rc {0 1}
  if [info exist scale($name,ab)] {
	foreach {b a} $scale($name,ab) break

	set s [expr {$na/$a}]
	set o [if {$s==1} {expr {$b-$nb}} else {expr {($b*$s-$nb)/($s-1.0)}}]

	set rc [list $o $s]
  }
  set scale($name,ab) [list $nb $na]
  return $rc
}

proc ::AutoPlotM::toPixel {ab coord} {
  foreach {b a} $ab break
  expr int($a * $coord + $b)
}

# draw axis/grid, size:in pixels,
# sel: {0 1} for x or {1 2} for y - coordinate selection
proc ::AutoPlotM::DrawAxis {wnd sel size fixed atg} {
  variable scale
  variable pscale

  set v  $scale($atg,amin)
  set out [expr {$scale($atg,amax)+0.5*$scale($atg,astep)}]
  set ta [list -tag $atg]
  set ga [list -dash {2 2} -tag $atg]
  set ad 0
  if [info exist pscale($atg,gcolor)] {lappend ga -fill $pscale($atg,gcolor)}
  if [info exist pscale($atg,tcolor)] {lappend ta -fill $pscale($atg,tcolor)}
  if [info exist pscale($atg,anchor)] {lappend ta -anchor $pscale($atg,anchor)}
  if [info exist pscale($atg,offset)] {
   set fixed [expr {$fixed+$pscale($atg,offset)}]}
  if [info exist pscale($atg,fmt)] {set fmt $pscale($atg,fmt)}

  while { $v < $out } {
	set vpix [toPixel $scale($atg,ab) $v]
	foreach {x y} [lrange [list $vpix $fixed $vpix] {*}$sel] break
	set atxt [if [info exist fmt] {format $fmt $v} else {set v}]
	set v [expr {$v+$scale($atg,astep)}]

	$wnd create line {*}[lrange [list $x 0 $y] {*}$sel] \
		{*}[lrange [list $x $size $y] {*}$sel] {*}$ga
	$wnd create text [expr {$x+3}] [expr {$y-3}] -text $atxt {*}$ta
  }
}

proc ::AutoPlotM::nfirst {i} {lindex [split $i ,] 0}

# return list of data sets for axis
proc ::AutoPlotM::getset {axis} {
  variable dset

  if {$axis eq "all"} {return [list all]}
  set l {{0 1}}
  foreach v [array names dset *,xaxis] {
	if {$dset($v) eq $axis} {lappend l [nfirst $v]}
  }
  if {[llength $l] > 1} { return $l }
  set l {{1 2}}
  foreach v [array names dset *,yaxis] {
	if {$dset($v) eq $axis} {lappend l [nfirst $v]}
  }
  if {[llength $l] > 1} { return $l }
  return [list]
}

proc ::AutoPlotM::replot { wnd {atg "all"} } {
  variable dset
  variable scale

# total rescale
  if {$atg eq "all"} {
    foreach v [array names scale *,ab] {replot $wnd [nfirst $v]}
    return
  }

  if {![info exist scale($atg,vmin)] ||
      ![info exist scale($atg,vmax)] } return

  foreach {p q r} [masaxis $scale($atg,vmin) $scale($atg,vmax)] break
  array set scale [list $atg,amin $p $atg,amax $q $atg,astep $r]

  set wheight [winfo height $wnd]
  set wwidth  [winfo width $wnd]

  set typ  [getset $atg]
  if {[llength $typ] == 0} return
  set slst [lrange $typ 1 end]
  set typ  [lindex $typ 0]

  $wnd delete $atg
  if {![info exist scale($atg,amin)]} return

  set pix [if [lindex $typ 0] {expr {-$wheight}} else {set wwidth}]
  set tmp [scaler $scale($atg,amin) $scale($atg,amax) $pix]

  foreach {mov sc} [rescaler $atg $tmp] break
  foreach tg $slst {
	$wnd scale $tg {*}[lrange [list $mov 0 $mov] {*}$typ] \
	{*}[lrange [list $sc 1 $sc] {*}$typ]
  }

  set p [if [lindex $typ 0] {list $wwidth 0} else {list $wheight $wheight}]
  DrawAxis $wnd $typ {*}$p $atg
  $wnd lower $atg
}


proc ::AutoPlotM::clear { wnd } {
  variable scale
  variable lastpt

  $wnd delete all

  unset -nocomplain lastpt
  unset -nocomplain scale

  bind $wnd <Configure> [list ::AutoPlotM::DoResize $wnd]
}

proc ::AutoPlotM::createaxis {xy {dstg set1} {fmt %g} {anchor w} } {
  variable scale
  variable pscale
  variable dset

  switch [string range $xy 0 0] {"x" {set a xaxis} "y" {set a yaxis} \
     default return}
  set dset($dstg,$a) $xy
  set pscale($xy,fmt) $fmt
  set pscale($xy,anchor) $anchor
  set pscale($xy,tcolor) black
  set pscale($xy,gcolor) darkgray
}

proc ::AutoPlotM::create {wnd} {
  variable scale
  variable dset

  set newplot "automchart_$wnd"
  interp alias {} $newplot {} ::AutoPlotM::PlotData $wnd

  clear $wnd
  createaxis x set1 %g s 
  createaxis y

  return $newplot
}

proc ::AutoPlotM::DoResize {wnd} {
  global redo

  if [info exists redo($wnd)] {after cancel $redo($wnd)}
  set redo($wnd) [after 50 [list ::AutoPlotM::replot $wnd]]
}

# Draw the line piece
proc ::AutoPlotM::plotXYline {wnd x y dtg cfil xsc ysc} {
  variable lastpt

  if {![info exists lastpt($dtg)]} return

  set px [toPixel $xsc $x]
  set py [toPixel $ysc $y]

  set pxp [toPixel $xsc [lindex $lastpt($dtg) 0]]
  set pyp [toPixel $ysc [lindex $lastpt($dtg) 1]]
  $wnd create line $pxp $pyp $px $py -fill $cfil -tag $dtg
}

# Draw the cross point
proc ::AutoPlotM::plotXYdot {wnd x y dtg cfil xsc ysc} {
  set px [toPixel $xsc $x]
  set py [toPixel $ysc $y]

  set pym [expr $py-1]
  set pyp [expr $py+1]
  set pxm [expr $px-1]
  set pxp [expr $px+1]
  $wnd create line $px $pym $px $pyp -fill $cfil -tag $dtg
  $wnd create line $pxm $py $pxp $py -fill $cfil -tag $dtg
}

proc ::AutoPlotM::minmax {v vmin vmax} {
  upvar $vmin mi
  upvar $vmax ma

  if {[info exist ma]==0 || [info exist mi]==0} {
	set ma [set mi $v]; return true
  }
  if {$v > $ma} {set ma $v; return true }
  if {$v < $mi} {set mi $v; return true }

  return false
}

proc ::AutoPlotM::qset {vn vv} {
  upvar $vn v; if [info exist v] {set v} else {set v $vv}}
 
# PlotData -- real data insert/draw
proc ::AutoPlotM::PlotData {wnd xcoord ycoord {dstg set1} {typ line}} {
  variable dset
  variable scale
  variable lastpt

  set xn [qset dset($dstg,xaxis) x]
  set yn [qset dset($dstg,yaxis) y]

# is any changes in data range? is scale factor changed?
  minmax $xcoord scale($xn,vmin) scale($xn,vmax)
  if [minmax $xcoord scale($xn,amin) scale($xn,amax)] {replot $wnd $xn}

  minmax $ycoord scale($yn,vmin) scale($yn,vmax)
  if [minmax $ycoord scale($yn,amin) scale($yn,amax)] {replot $wnd $yn}

  set c [qset dset($dstg,color) black]

  if {[info exist scale($xn,ab)] && [info exist scale($yn,ab)]} {
    plotXY$typ $wnd $xcoord $ycoord $dstg $c $scale($xn,ab) $scale($yn,ab)
  }
  set lastpt($dstg) [list $xcoord $ycoord]
}
