#!/usr/bin/wish

# ZetCode Tcl/Tk tutorial
#
# In this code example, we create 
# a toolbar.
#
# author: Jan Bodnar
# last modified: March 2011
# website: www.zetcode.com

package require Img

menu .mbar
. configure -menu .mbar

menu .mbar.fl -tearoff 0
.mbar add cascade -menu .mbar.fl -label File \
    -underline 0

# A toolbar is created. It is a frame.
# We created a raised border, so that
# the boundaries of a toolbar are visible.        
frame .toolbar -bd 1 -relief raised

# An exit button with an image is created.
# image create photo img -file "exit.png"
# button .toolbar.exitButton -image img -relief flat -command {exit}

# An exit button with a text
button .toolbar.exitButton -text Exit -relief flat -command {exit}

pack .toolbar.exitButton -side left -padx 2 -pady 2
# The toolbar is packed to the root window. It is horizontally stretched.
pack .toolbar -fill x

wm title . toolbar
wm geometry . 250x150+300+300
