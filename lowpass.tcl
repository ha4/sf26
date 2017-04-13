
#
# filter equation: 
#
#  y[i] := alpha * x[i] + (1-alpha) * y[i-1]
#  alpha = T/(tau+T) = (1/Ft)/(1/Fcut + 1/Ft) = 1/(Ft/Fcut + 1) = 1/(1/Omega+1)
#  tau = RC = 2*Pi*Fcut - integration period, T - quantisation period
#  T=0.02s, tau=1s; alpha=0.0196 1-alpha=0.9804
#  tau = 1/(2*Pi*RC)
#

proc lowpass {x yprev cutoff} {
	set Tau   [expr 1/(2.0*3.14159265*$cutoff)]
	set alpha [expr 1.0/($Tau + 1.0)]
	return    [expr $alpha * $x + ((1.0-$alpha) * $yprev)]
}


# second order lowpass
# 2nd order Gaussian type
# Ft=50Hz, Fcut=1Hz
#        0.007309z + 0.006765
# H(z)= ---------------------
#       z^2 - 1.779z + 0.7928

proc lowpass2_0 {xn state} {

	upvar $state v

	if {![info exist v(yn)]} {
	  set v(yn)  0.0
	  set v(yp)  0.0
	  set v(xp)  0.0
        }

        set yn  [expr {0.007309*$xn + 0.006765*$v(xp) + 1.779*$v(yn) - 0.7928*$v(yp)}]

	set v(yp)  $v(yn)
	set v(xp)  $xn
	set v(yn)  $yn

	return $yn
}

# second order lowpass
# 2nd order Gaussian type, impulse invariant
# Ft=50Hz, Fcut=1Hz
#        0.01407353z
# H(z)= ---------------------
#       z^2 - 1.778717z + 0.79279052

proc lowpass2_1 {xn state} {

	upvar $state v

	if {![info exist v(yn)]} {
	  set v(yn)  0.0
	  set v(yp)  0.0
        }

        set yn  [expr {0.01407353*$xn + 1.778717*$v(yn) - 0.79279052*$v(yp)}]

	set v(yp)  $v(yn)
	set v(yn)  $yn

	return $yn
}

# second order lowpass
# 2nd order Bessel type, impulse invariant
# Ft=50Hz, Fcut=1Hz
#        0.02221521z
# H(z)= ----------------------------
#       z^2 - 1.7358871z + 0.75815865

proc lowpass2 {xn state} {

	upvar $state v

	if {![info exist v(yn)]} {
	  set v(yn)  0.0
	  set v(yp)  0.0
        }

        set yn  [expr {0.02227155*$xn + 1.7358871*$v(yn) - 0.75815865*$v(yp)}]

	set v(yp)  $v(yn)
	set v(yn)  $yn

	return $yn
}

# second order lowpass
# 2nd order Bessel type, step invariant
# Ft=50Hz, Fcut=1Hz
#        0.011649388z + 0.010622133
# H(z)= ----------------------------
#       z^2 - 1.7358871z + 0.75815865


proc lowpass2_3 {xn state} {

	upvar $state v

	if {![info exist v(yn)]} {
	  set v(yn)  0.0
	  set v(yp)  0.0
	  set v(xn)  0.0
        }

        set yn  [expr {0.011649388*$xn + 0.010622133*$v(xn) + 1.7358871*$v(yn) - 0.75815865*$v(yp)}]

	set v(yp)  $v(yn)
	set v(yn)  $yn
	set v(xn)  $xn

	return $yn
}

#
# alpha - smooth, 1st order low-pass
#

proc smooth_a {x alpha state} {
	upvar $state v

	if {![info exist v(yn)]} {
		set v(yn) [expr 0.0 + $x]
	} else {
		set v(yn) [expr $alpha * $x + (1.0-$alpha)*$v(yn)]
	}

	return    $v(yn)
}


#
# mean average lowpass
#

proc lowpass_avg {xn n state} {
	upvar $state f

	if {![info exist f(n)]} {
		set f(n) 1
		set f(sum) $xn
		return -code return
	}
	incr f(n)

	set f(sum) [expr {$f(sum)+$xn}]

	if {$f(n) < $n} {
		return -code return
	}
	set reslt [expr {$f(sum)/$f(n)}]
	unset -nocomplain f(n)
	unset -nocomplain f(sum)
	return $reslt
}

proc lowpass_avg_clean {state} {
	upvar $state f

	unset -nocomplain f(n)
	unset -nocomplain f(sum)
}


proc lowpass_avg_get {state} {
	upvar $state f

	if {![info exist f(n)]} { return 0 }
	return [expr {$f(sum)/$f(n)}]
}

proc lowpass_avg_put {xn state} {
	upvar $state f

	if {![info exist f(n)]} {
		set f(n) 1
		set f(sum) $xn
	} else {
		incr f(n)
		set f(sum) [expr {$f(sum)+$xn}]
	}
}

#
# savitsky-golay filter 3x5
# 3-order, 5-point
#

proc SVpush {yvar x} {
	upvar $yvar y

	if {[info exist y(0)]} {
		set y(0) $y(1)
		set y(1) $y(2)
		set y(2) $y(3)
		set y(3) $y(4)
		set y(4) $x
        } else {
		set y(0) $x
		set y(1) $x
		set y(2) $x
		set y(3) $x
		set y(4) $x
	}
}

proc SVa0 {yvar} {
	upvar $yvar y

	return [expr (-3.0*$y(0)+12.0*$y(1)+17.0*$y(2)+12.0*$y(3)-3.0*$y(4))/35.0]
}


proc SVa1 {yvar} {
	upvar $yvar y

	return [expr (-2.0*$y(0)-$y(1)+$y(3)+2.0*$y(4))/10.0]
}

proc SVz0 {yvar}  {
	upvar $yvar y
	return $y(2)
}

proc SVzp1 {yvar}  {
	upvar $yvar y
	return $y(3)
}

proc SVzm1 {yvar}  {
	upvar $yvar y
	return $y(1)
}

proc tau_correct {hstep y dy tau} {
	return [expr ($y+$dy*($tau*$hstep))]
} 

#    SVpush(global_s,  strtofloat(Edit2.Text)); //signal
#    SVpush(global_tm, tnow); //time
#    tau = 0.95
#    h := SVz0(global_tm) - SVzm1(global_tm);
#    if h = 0 then tau:=0 else tau:=tau/h;
#    pnt[1,n]:=SVz0(global_tm);
#    pnt[4,n]:=SVa0(global_s)+tau*SVa1(global_s); //signal
