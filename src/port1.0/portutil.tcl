# ex:ts=4
#
# Insert some license text here at some point soon.
#

package provide portutil 1.0
package require Pextlib 1.0

global targets

namespace eval portutil {
    variable uniqid 0
}

########### External High Level Procedures ###########

# options
# Exports options in an array as externally callable procedures
# Thus, "options myarray name date" would create procedures named "name"
# and "date" that set the array items keyed by "name" and "date"
# Arguments: <array for export> <options (keys in array) to export>
proc options {args} {
    foreach option $args {
    	eval proc $option {args} \{ global ${option} user_options\; \if \{!\[info exists user_options(${option})\]\} \{ set ${option} {$args} \} \}
    }
}

# default
# Checks if variable is set, if not, sets to supplied value
proc default {option args} {
    global $option
    if {![info exists $option]} {
	set $option $args
    }
}

########### Misc Utility Functions ###########

proc tbool {key} {
    upvar $key upkey
    if {[info exists upkey]} {
	if {$upkey == "yes"} {
	    return 1
	}
    }
    return 0
}

# makeuserproc
# This procedure re-writes the user-defined custom target to include
# all the globals in its scope.  This is undeniably ugly, but I haven't
# thought of any other way to do this.
proc makeuserproc {name body} {
    regsub -- "^\{(.*)" $body "\{ \n foreach g \[info globals\] \{ \n global \$g \n \} \n \\1 " body
    eval "proc $name {} $body"
}

########### External Dependancy Manipulation Procedures ###########
# register
# Creates a target in the global target list using the internal dependancy
#     functions
# Arguments: <identifier> <mode> <args ...>
# The following modes are supported:
#	<identifier> target <procedure to execute> <init procedure> [run type]
#	<identifier> provides <list of target names>
#	<identifier> requires <list of target names>
#	<identifier> uses <list of target names>
#	<identifier> preflight <target name>
#	<identifier> postflight <target name>
proc register {name mode args} {
    global targets
    dlist_add_item targets $name

    if {[string equal target $mode]} {
        set procedure [lindex $args 0]
        set init [lindex $args 1]
        if {[dlist_has_key targets $name procedure]} {
            ui_info "Warning: target '$name' re-registered (new procedure: '$procedure')"
        }
        dlist_set_key targets $name procedure $procedure
        dlist_set_key targets $name init $init

	# Set runtype {always,once} if available
	if {[llength $args] == 3} {
	    dlist_set_key targets $name runtype [lindex $args 2]
	}
    } elseif {[string equal requires $mode] || [string equal uses $mode] || [string equal provides $mode]} {
        if {[dlist_has_item targets $name]} {
            dlist_append_key targets $name $mode $args
        } else {
            ui_info "Warning: target '$name' not-registered in register $mode"
        }
        
        if {[string equal provides $mode]} {
            # If it's a provides, register the pre-/post- hooks for use in Portfile.
            # Portfile syntax: pre-fetch { puts "hello world" }
            # User-code exceptions are caught and returned as a result of the target.
            # Thus if the user code breaks, dependent targets will not execute.
            foreach target $args {
		if {[info commands $target] != ""} {
		    ui_error "$name attempted to register provide \'$target\' which is a pre-existing procedure. Ignoring register."
		    continue;
		}
                set id [incr portutil::uniqid]
                set ident [lindex [dlist_get_matches targets provides $args] 0]
                set origproc [dlist_get_key targets $ident procedure]
                eval "proc $target {args} \{ \n\
                    register $ident target proc-$target$id \n\
                    proc proc-$target$id \{name\} \{ \n\
                        return \[catch userproc-$target$id\] \n\
                    \} \n\
                    eval \"proc do-$target \{\} \{ $origproc $target\}\" \n\
                    makeuserproc userproc-$target$id \$args \}"
                eval "proc pre-$target {args} \{ \n\
                    register pre-$target$id target proc-pre-$target$id \n\
                    register pre-$target$id preflight $target \n\
                    proc proc-pre-$target$id \{name\} \{ \n\
                        return \[catch userproc-pre-$target$id\] \n\
                    \} \n\
                    makeuserproc userproc-pre-$target$id \$args \}"
                eval "proc post-$target {args} \{ \n\
                    register post-$target$id target proc-post-$target$id \n\
                    register post-$target$id postflight $target \n\
                    proc proc-post-$target$id \{name\} \{ \n\
                        return \[catch userproc-post-$target$id\] \n\
                    \} \n\
                    makeuserproc userproc-pre-$target$id \$args \}"
            }
        }
	
    } elseif {[string equal preflight $mode]} {
	# preflight vulcan mind meld:
	# "your requirements to my requirements; my provides to your requirements"
	
	dlist_append_key targets $name provides $name-pre-$args
	# XXX: this only returns the first match, is this what we want?
	set ident [lindex [dlist_get_matches targets provides $args] 0]
	
	dlist_append_key targets $name requires \
	    [dlist_get_key targets $ident requires]
	dlist_append_key targets $ident requires \
	    [dlist_get_key targets $name provides]
	
    } elseif {[string equal postflight $mode]} {
	# postflight procedure:
	
	dlist_append_key targets $name provides $name-post-$args
		
	set ident [lindex [dlist_get_matches targets provides $args] 0]

	# your provides to my requires
	dlist_append_key targets $name requires \
	    [dlist_get_key targets $ident provides]
	
	# my provides to the requires of your children
	foreach token [join [dlist_get_key targets $ident provides]] {
	    set matches [dlist_get_matches targets requires $token]
	    foreach match $matches {
		# don't want to require ourself
		if {![string equal $match $name]} {
		    dlist_append_key targets $match requires $name-post-$args
		}
	    }
	}
    }
}

# unregister
# Unregisters a target in the global target list
# Arguments: target <target name>
proc unregister {mode target} {
}

########### Internal Dependancy Manipulation Procedures ###########

# Dependency List (dlist)
# The dependency list is really just one big array.  (I would have
# liked to make this nested arrays, but that's not feasible in Tcl,
# thus we'll use the $fieldname,$groupname syntax to mimic structures.
#
# Dependency lists may contain private data, via the 
# dlist_*_key APIs.  However, it must be recognized that the
# following keys are reserved for use by the evaluation engine.
# (Don't fret, you want these keys anyway, honest.)  These keys also
# have predefined accessor APIs to remind you of their significance.
#
# Reserved keys: 
# name		- The unique identifier of the item.  No Commas!
# provides	- The list of tokens this item provides
# requires	- The list of hard-dependency tokens
# uses		- The list of soft-dependency tokens
# runtype	- The runtype of the item {always,once}

# Sets the key/value to an item in the dependency list
proc dlist_set_key {dlist name key args} {
    upvar $dlist uplist
    # might be keen to validate $name here.
    eval "set uplist($key,$name) $args"
}

# Appends the value to the list stored at the key of the item
proc dlist_append_key {dlist name key args} {
    upvar $dlist uplist
    if {![dlist_has_key uplist $name $key]} { set uplist($key,$name) [list] }
    eval "lappend uplist($key,$name) [join $args]"
}

# Return true if the key exists for the item, false otherwise
proc dlist_has_key {dlist name key} {
    upvar $dlist uplist
    return [info exists uplist($key,$name)]
}

# Retrieves the value of the key of an item in the dependency list
proc dlist_get_key {dlist name key} {
    upvar $dlist uplist
    if {[info exists uplist($key,$name)]} {
	return $uplist($key,$name)
    } else {
	return ""
    }
}

# Adds a colorless odorless item to the dependency list
proc dlist_add_item {dlist name} {
    upvar $dlist uplist
    set uplist(name,$name) $name
}

# Deletes all keys of the specified item
proc dlist_remove_item {dlist name} {
    upvar $dlist uplist
    array unset uplist *,$name
}

# Tests if the item is present in the dependency list
proc dlist_has_item {dlist name} {
    upvar $dlist uplist
    return [info exists uplist(name,$name)]
}

# Return a list of names of items that provide the given name
proc dlist_get_matches {dlist key value} {
    upvar $dlist uplist
    set result [list]
    foreach ident [array names uplist name,*] {
	set name $uplist($ident)
	foreach val [dlist_get_key uplist $name $key] {
	    if {[string equal $val $value] && 
		![info exists ${result}($name)]} {
		lappend result $name
	    }
	}
    }
    return $result
}

# Count the unmet dependencies in the dlist based on the statusdict
proc dlist_count_unmet {names statusdict} {
    upvar $statusdict upstatusdict
    set unmet 0
    foreach name $names {
	if {![info exists upstatusdict($name)] ||
	    ![string equal $upstatusdict($name) success]} {
	    incr unmet
	}
    }
    return $unmet
}

# Returns true if any of the dependencies are pending in the dlist
proc dlist_has_pending {dlist uses} {
    foreach name $uses {
	if {[info exists ${dlist}(name,$name)]} { 
	    return 1
	}
    }
    return 0
}

# Get the name of the next eligible item from the dependency list
proc dlist_get_next {dlist statusdict} {
    set nextitem ""
    # arbitrary large number ~ INT_MAX
    set minfailed 2000000000
    upvar $dlist uplist
    upvar $statusdict upstatusdict
    
    foreach n [array names uplist name,*] {
	set name $uplist($n)
	
	# skip if unsatisfied hard dependencies
	if {[dlist_count_unmet [dlist_get_key uplist $name requires] upstatusdict]} { continue }
	
	# favor item with fewest unment soft dependencies
	set unmet [dlist_count_unmet [dlist_get_key uplist $name uses] upstatusdict]
	
	# delay items with unmet soft dependencies that can be filled
	if {$unmet > 0 && [dlist_has_pending dlist [dlist_get_key uplist $name uses]]} { continue }
	
	if {$unmet >= $minfailed} {
	    # not better than our last pick
	    continue
	} else {
	    # better than our last pick
	    set minfailed $unmet
	    set nextitem $name
	}
    }
    return $nextitem
}


# Evaluate the dlist, invoking action on each name in the dlist as it
# becomes eligible.
proc dlist_evaluate {dlist downstatusdict action fd} {
    # dlist - nodes waiting to be executed
    upvar $dlist uplist
    upvar $downstatusdict statusdict
    
    # status - keys will be node names, values will be success or failure.
    array set statusdict [list]
    
    # loop for as long as there are nodes in the dlist.
    while (1) {
	set name [dlist_get_next uplist statusdict]
	if {[string length $name] == 0} { 
	    break
	} else {
	    set result [eval $action uplist $name]
	    foreach token $uplist(provides,$name) {
		array set statusdict [list $token $result]
	    }
	    dlist_remove_item uplist $name
	}
    }
    
    set names [array names uplist name,*]
    if { [llength $names] > 0} {
	# somebody broke!
	ui_info "Warning: the following items did not execute: "
	foreach name $names {
	    ui_info "$uplist($name) " -nonewline
	}
	ui_info ""
    }
}

proc exec_target {fd dlist name} {
# XXX: Don't depend on entire dlist, this should really receive just one node.
    upvar $dlist uplist
    if {[dlist_has_key uplist $name procedure] && [dlist_has_key uplist $name init]} {
	set procedure [dlist_get_key uplist $name procedure]
	set init [dlist_get_key uplist $name init]
	if {[$init != ""]} {
	    $init $name
	}
	if {[check_statefile $name $fd]} {
	    set result 0
	    ui_debug "Skipping completed $name"
	} else {
	    ui_debug "Executing $name"
	    set result [$procedure $name]
	}
	if {$result == 0} {
	    set result success
	    if {[dlist_get_key uplist $name runtype] != "always"} {
		write_statefile $name $fd
	    }
	} else {
	    ui_error "Target error: $name returned $result"
	    set result failure
	}
    } else {
	ui_info "Warning: $name does not have a registered procedure"
	set result failure
    }
    return $result
}

proc eval_targets {dlist target} {
    upvar $dlist uplist
	
    # Select the subset of targets under $target
    if {[string length $target] > 0} {
        set matches [dlist_get_matches uplist provides $target]
        if {[llength $matches] > 0} {
            array set dependents [list]
            dlist_append_dependents dependents uplist [lindex $matches 0]
            array unset uplist
            array set uplist [array get dependents]
            # Special-case 'all'
        } elseif {![string equal $target all]} {
            ui_info "Warning: unknown target: $target"
            return
        }
    }
    
    array set statusdict [list]
    
    # Restore the state from a previous run.
    set fd [open_statefile]
    
    dlist_evaluate uplist statusdict [list exec_target $fd] $fd
    
    close $fd
}

# select dependents of <name> from the <itemlist>
# adding them to <dependents>
proc dlist_append_dependents {dependents dlist name} {
    upvar $dependents updependents
    upvar $dlist uplist

    # Append item to the list, avoiding duplicates
    if {![info exists updependents(name,$name)]} {
	set names [array names uplist *,$name]
        foreach n $names {
            set updependents($n) $uplist($n)
        }
    }
    
    # Recursively append any hard dependencies
    if {[info exists uplist(requires,$name)]} {
        foreach dep $uplist(requires,$name) {
            foreach provide [dlist_get_matches uplist provides $dep] {
                dlist_append_dependents updependents uplist $provide
            }
        }
    }
    
    # XXX: add soft-dependencies?
}

# open_statefile
# open file to store name of completed targets
proc open_statefile {args} {
    global portpath workdir

    if ![file isdirectory $portpath/$workdir] {
	file mkdir $portpath/$workdir
    }
    set fd [open "$portpath/$workdir/.darwinports.state" a+]
    return $fd
}

# check_statefile
# Check completed state of target $name
proc check_statefile {name fd} {
    global portpath workdir

    seek $fd 0
    while {[gets $fd line] >= 0} {
	if {[string equal $line $name]} {
	    return 1
	}
    }
    return 0
}

# write_statefile
# Set target $name completed in the state file
proc write_statefile {name fd} {
    if {[check_statefile $name $fd]} {
	return 0
    }
    seek $fd 0 end
    puts $fd $name
    flush $fd
}
