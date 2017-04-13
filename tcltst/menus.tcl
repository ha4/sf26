#!/usr/bin/wish

# ZetCode Tcl/Tk tutorial
#
# In this code example, we create 
# a simple menu.
#
# author: Jan Bodnar
# last modified: March 2011
# website: www.zetcode.com


menu .mbar
. configure -menu .mbar

# A menubar is a special case of a menu. 
# The -tearoff option specifies that the menu
# cannot be removed from the menubar.
menu .mbar.fl -tearoff 0


.mbar add cascade -menu .mbar.fl -label File \
    -underline 0

.mbar.fl add command -label Exit -command { exit }

wm title . "Simple menu" 
wm geometry . 250x150+300+300
