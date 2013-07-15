#
# Tcl package index file, version 1.1
#
if {[package vsatisfies [package provide Tcl] 8.4]} {
    package ifneeded Thread 2.6 [subst -nocommands {
        load [file join $dir libthread2.6g.dylib] Thread
        if {[file readable [file join $dir .. lib ttrace.tcl]]} { 
            source [file join $dir .. lib ttrace.tcl]
        } else {
            source [file join $dir ttrace.tcl]
        }
    }]
}

