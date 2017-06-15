
#
# Auto Plot
#

namespace eval ::AutoPlot {
   variable yfactor
   variable xfactor
   variable yoffset
   variable xoffset

   variable xmax
   variable xmin
   variable xstep
   variable xold

   variable ymax
   variable ymin
   variable ystep
   variable yold

   variable wwidth
   variable wheight
   variable wplot
   variable wbg
   variable waxis

   namespace export    create replot toPixel
# service: masaxis minmax scaler range DoResize PlotDate
}

proc ::AutoPlot::masaxis {dmin dmax} {
# MASHTAB AXIS
# Result: List of three elements: step, low, high

	# degree of range
	set ords [expr ($dmax > $dmin)?floor(log10($dmax-$dmin)):0.0]

	# prelim. step is less by degree
	set ddd [expr pow(10,$ords-1)]

	# calculate num of entries
	set ordax [expr ceil(($dmax-$dmin)/$ddd)]

	set lastp [expr $ddd * (($ordax < 10)?1:\
			    (($ordax < 20)?2:\
			    (($ordax < 50)?5:10)))]
	set lamin [expr $lastp * floor($dmin / $lastp)]
	set lamax [expr $lastp *  ceil($dmax / $lastp)]

	return [list $lastp $lamin $lamax]
}                                                                               


proc ::AutoPlot::minmax {dval amin amax prev} {
# return 1 if changed, modify upvar

	upvar $amin mi5
	upvar $amax ma6

	set chg $prev

	if { [info exist ma6] } {
          if {$dval > $ma6} {
		set ma6  $dval 
		set chg true
	  }
	  if {$dval < $mi5} { 
		set mi5  $dval
		set chg true
	  }
        } else {
		set mi5  $dval
		set ma6  $dval
		set chg true
        }

	return $chg
}

proc ::AutoPlot::scaler {dmin dmax pixels} {

	if { $dmin == $dmax } {
		set a 1
	} else {
		set a [expr $pixels/($dmax-$dmin)]
	}

	if { $pixels < 0 } {
		set b [expr -$dmin * $a - $pixels]
	} else {
		set b [expr -$dmin * $a]
	}

	return [list $a $b]
}                                                                               

proc ::AutoPlot::range { wnd xnfactor xnoffset ynfactor ynoffset} {

	variable yfactor
	variable xfactor
	variable yoffset
	variable xoffset

    if { [info exists xfactor] } {

        set xs [expr $xnfactor/$xfactor]
       	set ys [expr $ynfactor/$yfactor]

	if {$xs==1} {
		set xoffs 0
	} else {
   		set xoffs [expr ($xoffset*$xs-$xnoffset)/($xs-1.0)]
	}

	if {$ys==1} {
		set yoffs 0
	} else {
	   	set yoffs [expr ($yoffset*$ys-$ynoffset)/($ys-1.0)]
	}
        $wnd scale data $xoffs $yoffs $xs $ys
    }
	set xfactor $xnfactor
	set xoffset $xnoffset
	set yfactor $ynfactor
	set yoffset $ynoffset

	$wnd delete axis
	DrawXaxis $wnd
	DrawYaxis $wnd
	$wnd lower axis
}

proc ::AutoPlot::toPixel { xcrd ycrd } {
# Result: List of two elements, x- and y-coordinates in pixels

   variable yfactor
   variable xfactor
   variable yoffset
   variable xoffset

   set xpix [expr int($xfactor * $xcrd + $xoffset)]
   set ypix [expr int($yfactor * $ycrd + $yoffset)]

   return [list $xpix $ypix]
}


proc ::AutoPlot::DrawXaxis { wnd } {
   variable ymin
   variable xmax
   variable xmin
   variable xstep

   variable wheight
   variable waxis

   set x $xmin
   set xout [expr $xmax+0.5*$xstep]
   while { $x < $xout } {
      foreach {xcrd ycrd} [toPixel $x $ymin] {break}
      set xhlp [expr $xcrd + 3]
      set yhlp [expr $ycrd - 6]
      $wnd create line $xcrd 0 $xcrd $wheight -fill $waxis -tag axis -dash { 2 2 }

      $wnd create text $xhlp $yhlp -text $x -fill $waxis -anchor s -tag axis
      set x [expr $x+$xstep]
   }
}

proc ::AutoPlot::DrawYaxis { wnd } {
   variable xmin
   variable ymax
   variable ymin
   variable ystep

   variable wwidth
   variable waxis

   set y $ymin
   set yout [expr $ymax+0.5*$ystep]
   while { $y < $yout } {
      foreach {xcrd ycrd} [toPixel $xmin $y] {break}

      set xhlp [expr $xcrd + 3]
      set yhlp [expr $ycrd - 6]
      $wnd create line 0 $ycrd $wwidth $ycrd -fill $waxis -tag axis -dash { 2 2 }

      $wnd create text $xhlp $yhlp -text $y -fill $waxis -anchor w -tag axis
      set y [expr $y+$ystep]
   }
}


proc ::AutoPlot::DoResize { wnd } {
    global redo

    if { [info exists redo] } {
        after cancel $redo
    }

#    $wnd delete all  # or use _path_ SCALE

    set redo [after 50 [list ::AutoPlot::replot $wnd]]
}


proc ::AutoPlot::replot { wnd } {
   variable wwidth
   variable wheight
   variable xmin
   variable xmax
   variable ymin
   variable ymax

#   set wnew  [winfo width $wnd]
#   set hnew  [winfo height $wnd]

   set wwidth  [winfo width $wnd]
   set wheight [winfo height $wnd]

   if { [info exists xmin] } {
        foreach {xnfactor xnoffset} [scaler $xmin $xmax $wwidth] {break}
        foreach {ynfactor ynoffset} [scaler $ymin $ymax [expr -$wheight]] {break}

        range $wnd $xnfactor $xnoffset $ynfactor $ynoffset
   }

#   if { [info exist wwidth] } {
#	   set xs [expr (0.0+$wnew)/$wwidth]
#	   set ys [expr (0.0+$hnew)/$wheight]
#	   set offs [expr $ys*$wheight-$hnew]
#	   set offs [expr $hnew/$ys-$wheight]
#	   $wnd scale data 0 $offs $xs $ys
#   }

#   set wwidth  $wnew
#   set wheight $hnew


# replot here ?

}


proc ::AutoPlot::PlotData { wnd xcrd ycrd } {
# PlotData --
#    wnd         Name of the canvas
#    xcrd        Next x coordinate
#    ycrd        Next y coordinate


   variable xmax
   variable xstep
   variable xmin
   variable xold
   variable ymax
   variable ystep
   variable ymin
   variable yold
   variable wwidth
   variable wheight
   variable wplot
   variable xfactor
   variable yfactor
   variable xoffset
   variable yoffset

   set ch [minmax $xcrd xmin xmax false]
   set ch [minmax $ycrd ymin ymax $ch]

   # is any changes in data range?
   if { $ch } {
      foreach {xstep xmin xmax} [masaxis $xmin $xmax] {break}
      foreach {ystep ymin ymax} [masaxis $ymin $ymax] {break}
   }

   # is scale factor changed?
   if { $ch || [info exists xfactor] == 0} {

      foreach {xnfactor xnoffset} [scaler $xmin $xmax $wwidth] {break}
      foreach {ynfactor ynoffset} [scaler $ymin $ymax [expr -$wheight]] {break}
      range $wnd $xnfactor $xnoffset $ynfactor $ynoffset
   }

   # Draw the line piece
   if { [info exists xold] } {
      foreach {pxold pyold} [toPixel $xold $yold] {break}
      foreach {pxcrd pycrd} [toPixel $xcrd $ycrd] {break}
      $wnd create line $pxold $pyold $pxcrd $pycrd -fill $wplot -tag data 
   }
   set xold $xcrd
   set yold $ycrd

}


proc ::AutoPlot::create { wnd } {
   variable waxis
   variable wplot
   variable wbg
   variable xmin
   variable ymin
   variable xfactor
   variable yfactor


   set newplot "autochart_$wnd"
   interp alias {} $newplot {} ::AutoPlot::PlotData $wnd

   set wplot  black
   set wbg    white
   set waxis  red

   $wnd configure -background $wbg

   unset -nocomplain xmin ymin
   unset -nocomplain xfactor yfactor

   replot  $wnd

   bind $wnd <Configure> [list ::AutoPlot::DoResize $wnd]

   return $newplot
}

