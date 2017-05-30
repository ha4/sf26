#!/bin/sh
# the next line restarts using the correct interpreter \
exec wish "$0" "$@"

package require Tk

# Purpose:
#    Dialog for editing an array.
#
# Description:
#    Creates a dialog showing each key and value of an array.
#    You can edit the values directly, or delete one or more
#    keys by checking the corresponding checkboxes and then
#    clicking on "Delete checked." You can also add new keys
#    one at a time by typing in the name and value at the bottom,
#    then clicking "Add". Click "Reset" to undo all changes and
#    start over, or "Commit" to save your changes and exit.
#
# Arguments:
#    arr       The name of the array.
#
# Returns:
#    null
#
# Example:
#    TK_editArray env

proc TK_editArray {arr} {
    global __copy_of_array__ __aux_array__
    upvar $arr A

    # We store a temporary copy of the array in __copy_of_array__.
    # __aux_array__ holds the checkbox states and the new name and
    # value if supplied by the user. Both of these need to be global
    # as they are textvariables linked to Tk entries.
    catch {unset __copy_of_array__}
    array set __copy_of_array__ [array get A]

    # Help message
    set Help "This dialog allows you to edit your \"$arr\" array. To delete entries, click on one or more checkboxes, then click \"Delete checked\". To add entries, move to the \"New:\" line at the bottom (using the vertical scrollbar if necessary) and type the name in the left field and the value in the right, then click \"Add\". Click \"Reset\" if you want to discard your changes and start over. When you are finished editing, click \"Commit\". Click \"Cancel\" to exit without changing the \"$arr\" array."
    # Start creating the dialog.
    catch {destroy .ea}
    toplevel .ea
    wm title .ea "Editing $arr"
    frame .ea.f
    set c [canvas .ea.f.c -yscrollcommand ".ea.f.sb set"]
    scrollbar .ea.f.sb -orient vert -command "$c yview"
    pack $c .ea.f.sb -side left -fill y -expand 1
    frame .ea.fb
    button .ea.fb.b1 -text "Add" -command \
            {set __aux_array__(__action__) "Add"}
    button .ea.fb.b2 -text "Commit" -command \
            {set __aux_array__(__action__) "Commit"}
    button .ea.fb.b3 -text "Reset" -command \
            {set __aux_array__(__action__) "Reset"}
    button .ea.fb.b4 -text "Delete checked" -command \
            {set __aux_array__(__action__) "Delete"}
    button .ea.fb.b5 -text Help -command [list tk_messageBox -message $Help \
            -title "Editing $arr"]
    button .ea.fb.b6 -text Cancel -command {set __aux_array__(__action__) "Cancel"}
    pack .ea.fb.b1 .ea.fb.b2 .ea.fb.b3 .ea.fb.b4 .ea.fb.b5 .ea.fb.b6 -side left \
            -fill x -expand 1 -padx 1 -pady 1
    pack .ea.f .ea.fb -side top -fill x -expand 1
    
    # Make sure we exit cleanly if the user destroys the window.
    wm protocol .ea WM_DELETE_WINDOW {set __aux_array__(__action__) "Cancel"}
    set f "$c.f0"

    # Stay in a loop until the user clicks "Commit" to exit.
    while (1) {
        catch {destroy $f}
        catch {unset __aux_array__}
        frame $f
        set ii 1
        set tag [$c create window 0 0 -anchor nw -window $f]
        foreach var [lsort [array names __copy_of_array__]] {
            set __aux_array__($var) 0
            checkbutton $f.cb$ii -text "" -variable __aux_array__($var) \
                    -onvalue $ii
            label $f.l$ii -text $var
            frame $f.f$ii
            entry $f.f$ii.e -textvariable __copy_of_array__($var) \
                    -xscrollcommand "$f.f$ii.sb set"
            scrollbar $f.f$ii.sb -orient horiz -command "$f.f$ii.e xview"
            pack $f.f$ii.e $f.f$ii.sb -side top -fill x -expand 1
            grid $f.cb$ii $f.l$ii $f.f$ii -sticky news
            incr ii
        } ;# end loop

        # Add entries to allow the user to add a new key and value.
        label $f.lnew -text "New:"
        entry $f.ename  -textvariable __aux_array__(name)
        entry $f.evalue -textvariable __aux_array__(value)
        grid $f.lnew $f.ename $f.evalue -sticky news
        update idletasks

        # Resize the dialog.
        set bbox [$c bbox $tag]
        $c config -scrollregion $bbox
        $c config -width [lindex $bbox 2]

        # Wait for the user to click a button.
        tkwait variable __aux_array__(__action__)
        switch -exact $__aux_array__(__action__) {
            Add {

                # Add a new key and value.
                if {[info exists __aux_array__(name)] && \
                        [info exists __aux_array__(value)]} {
                    set name  $__aux_array__(name)
                    set value $__aux_array__(value)
                    if {$name != "" && $value != ""} {
                        set __copy_of_array__($name) $value
                    }
                }
            }
            Commit {

                # Save changes and exit the dialog.
                if [array exists A] { unset A }
                array set A [array get __copy_of_array__]
                destroy .ea
                catch {unset __aux_array__ __copy_of_array__}
                return
            }
            Cancel {

                # Exit the dialog.
                destroy .ea
                catch {unset __aux_array__ __copy_of_array__}
                return
            }
            Reset {

                # Undo all changes. NB we must break the
                # "textvariable" links, otherwise the
                # array entries will reappear as soon as
                # they are unset.
                for {set jj 1} {$jj < $ii} {incr jj} {
                    $f.f$jj.e config -textvariable {}
                }
                unset __copy_of_array__
                array set __copy_of_array__ [array get A]
            }
            Delete {

                # Delete one or more keys. As before we must
                # break the "textvariable" links.
                foreach var [array names __copy_of_array__] {
                    if {$__aux_array__($var) != 0} {
                        set jj $__aux_array__($var)
                        $f.f$jj.e config -textvariable {}
                        unset __copy_of_array__($var)
                    }
                } ;# end loop
            }
        } ;# end switch
    } ;# end loop
}

# Demo:
if {$::argv0 eq [info script]} {
    array set A { Red 0  Green 11  Blue 222  Black 9999  Name John  City York }
    TK_editArray A
}
