####################
# Animation system
#

package provide animation 0.0.0.0.0.0.0.1 ;# (ahem)
namespace eval animation {
    namespace export createAnimation
    namespace export deleteAnimation
    namespace export startAnimation
    namespace export stopAnimation

    array set AnimatedIcons {}
}

proc animation::createAnimation {w icons delay} {
    variable AnimatedIcons

    set AnimatedIcons($w,delay)    $delay
    set AnimatedIcons($w,icons)    $icons
    set AnimatedIcons($w,index)    0
    set AnimatedIcons($w,numIcons) [llength $icons]

    # animation::startAnimation $w
    return
}

proc animation::startAnimation {w} {
    DoFrame $w
}

proc animation::DoFrame {w} {
    variable AnimatedIcons

    set index $AnimatedIcons($w,index)
    $w configure -image [lindex $AnimatedIcons($w,icons) $index]
    set AnimatedIcons($w,index) \
            [expr ($index + 1) % $AnimatedIcons($w,numIcons)]
    set AnimatedIcons($w,afterId) \
            [after $AnimatedIcons($w,delay) "animation::DoFrame $w"]
    return
}

proc animation::stopAnimation {w} {
    variable AnimatedIcons
    catch {after cancel $AnimatedIcons($w,afterId)}
    unset AnimatedIcons($w,afterId)
}

proc animation::deleteAnimation {w} {
    variable AnimatedIcons
    animation::stopAnimation $w
    foreach name [array names AnimatedIcons $w,*] {
        unset AnimatedIcons($name)
    }
}

################
# Main program
#

namespace import animation::*

# Note: The following assumes you have three files called file1.gif,
#       file2.gif, and file3.gif.  Substitute filenames (or whatever) as
#       appropriate.

set animatedList {}
foreach image {file1.gif file2.gif file3.gif} {
    append animatedList [image create photo -file $image]
}

pack [label .l]
createAnimation .l $animatedList 100
after 5000
stopAnimation   .l
after 5000
startAnimation  .l
after 5000
deleteAnimation .l
