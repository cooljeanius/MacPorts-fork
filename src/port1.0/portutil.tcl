# et:ts=4
# portutil.tcl
#
# Copyright (c) 2002 Apple Computer, Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. Neither the name of Apple Computer, Inc. nor the names of its contributors
#    may be used to endorse or promote products derived from this software
#    without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#

package provide portutil 1.0
package require Pextlib 1.0
package require darwinports_dlist 1.0
package require msgcat

global targets target_uniqid all_variants

set targets [list]
set target_uniqid 0

set all_variants [list]

########### External High Level Procedures ###########


# UI Instantiations
foreach priority "debug info msg error warn" {
    eval "proc ui_$priority {str} \{ \n\
	set message(priority) $priority \n\
	set message(data) \$str \n\
	ui_event \[array get message\] \n\
    \}"
}


namespace eval options {
}

# option
# This is an accessor for Portfile options.  Targets may use
# this in the same style as the standard Tcl "set" procedure.
#	name  - the name of the option to read or write
#	value - an optional value to assign to the option

proc option {name args} {
	# XXX: right now we just transparently use globals
	# eventually this will need to bridge the options between
	# the Portfile's interpreter and the target's interpreters.
	global $name
	if {[llength $args] > 0} {
		ui_debug "setting option $name to $args"
		set $name [lindex $args 0]
	}
	return [set $name]
}

# exists
# This is an accessor for Portfile options.  Targets may use
# this procedure to test for the existence of a Portfile option.
#	name - the name of the option to test for existence

proc exists {name} {
	# XXX: right now we just transparently use globals
	# eventually this will need to bridge the options between
	# the Portfile's interpreter and the target's interpreters.
	global $name
	return [info exists $name]
}

# options
# Exports options in an array as externally callable procedures
# Thus, "options name date" would create procedures named "name"
# and "date" that set global variables "name" and "date", respectively
# When an option is modified in any way, options::$option is called,
# if it exists
# Arguments: <list of options>
proc options {args} {
    foreach option $args {
	eval "proc $option {args} \{ \n\
	    global ${option} user_options option_procs \n\
		\if \{!\[info exists user_options(${option})\]\} \{ \n\
		     set ${option} \$args \n\
			 if \{\[info exists option_procs($option)\]\} \{ \n\
				foreach p \$option_procs($option) \{ \n\
					eval \"\$p $option set \$args\" \n\
				\} \n\
			 \} \n\
		\} \n\
	\}"
	
	eval "proc ${option}-delete {args} \{ \n\
	    global ${option} user_options option_procs \n\
		\if \{!\[info exists user_options(${option})\]\} \{ \n\
		    foreach val \$args \{ \n\
			ldelete ${option} \$val \n\
		    \} \n\
		    if \{\[string length \$\{${option}\}\] == 0\} \{ \n\
			unset ${option} \n\
		    \} \n\
			if \{\[info exists option_procs($option)\]\} \{ \n\
			    foreach p \$option_procs($option) \{ \n\
				eval \"\$p $option delete \$args\" \n\
			\} \n\
		    \} \n\
		\} \n\
	\}"
	eval "proc ${option}-append {args} \{ \n\
	    global ${option} user_options option_procs \n\
		\if \{!\[info exists user_options(${option})\]\} \{ \n\
		    if \{\[info exists ${option}\]\} \{ \n\
			set ${option} \[concat \$\{$option\} \$args\] \n\
		    \} else \{ \n\
			set ${option} \$args \n\
		    \} \n\
		    if \{\[info exists option_procs($option)\]\} \{ \n\
			foreach p \$option_procs($option) \{ \n\
			    eval \"\$p $option append \$args\" \n\
			\} \n\
		    \} \n\
		\} \n\
	\}"
    }
}

proc options_export {args} {
    foreach option $args {
        eval "proc options::${option} \{args\} \{ \n\
	    global ${option} PortInfo \n\
	    if \{\[info exists ${option}\]\} \{ \n\
		set PortInfo(${option}) \$${option} \n\
	    \} else \{ \n\
		unset PortInfo(${option}) \n\
	    \} \n\
        \}"
	option_proc ${option} options::${option}
    }
}

# option_deprecate
# Causes a warning to be printed when an option is set or accessed
proc option_deprecate {option {newoption ""} } {
    # If a new option is specified, default the option to {${newoption}}
    # Display a warning
    if {$newoption != ""} {
    	eval "proc warn_deprecated_$option \{option action args\} \{ \n\
	    global portname $option $newoption \n\
	    if \{\$action != \"read\"\} \{ \n\
	    	$newoption \$$option \n\
	    \} else \{ \n\
	        ui_warn \"Port \$portname using deprecated option \\\"$option\\\".\" \n\
		$option \[set $newoption\] \n\
	    \} \n\
	\}"
    } else {
    	eval "proc warn_deprecated_$option \{option action args\} \{ \n\
	    global portname $option $newoption \n\
	    ui_warn \"Port \$portname using deprecated option \\\"$option\\\".\" \n\
	\}"
    }
    option_proc $option warn_deprecated_$option
}

proc option_proc {option args} {
    global option_procs $option
    eval "lappend option_procs($option) $args"
    # Add a read trace to the variable, as the option procedures have no access to reads
    trace variable $option r option_proc_trace
}

# option_proc_trace
# trace handler for option reads. Calls option procedures with correct arguments.
proc option_proc_trace {optionName index op} {
    global option_procs
    foreach p $option_procs($optionName) {
	eval "$p $optionName read"
    }
}

# commands
# Accepts a list of arguments, of which several options are created
# and used to form a standard set of command options.
proc commands {args} {
    foreach option $args {
	options use_${option} ${option}.dir ${option}.pre_args ${option}.args ${option}.post_args ${option}.env ${option}.type ${option}.cmd
    }
}

# command
# Given a command name, command assembled a string
# composed of the command options.
proc command {command} {
    global ${command}.dir ${command}.pre_args ${command}.args ${command}.post_args ${command}.env ${command}.type ${command}.cmd
    
    set cmdstring ""
    if {[info exists ${command}.dir]} {
	set cmdstring "cd \"[set ${command}.dir]\" &&"
    }
    
    if {[info exists ${command}.env]} {
	foreach string [set ${command}.env] {
	    set cmdstring "$cmdstring $string"
	}
    }
    
    if {[info exists ${command}.cmd]} {
	foreach string [set ${command}.cmd] {
	    set cmdstring "$cmdstring $string"
	}
    } else {
	set cmdstring "$cmdstring ${command}"
    }
    foreach var "${command}.pre_args ${command}.args ${command}.post_args" {
	if {[info exists $var]} {
	    foreach string [set ${var}] {
		set cmdstring "$cmdstring $string"
	    }
	}
    }
    ui_debug "Assembled command: '$cmdstring'"
    return $cmdstring
}

# default
# Sets a variable to the supplied default if it does not exist,
# and adds a variable trace. The variable traces allows for delayed
# variable and command expansion in the variable's default value.
proc default {option val} {
    global $option option_defaults
    if {[info exists option_defaults($option)]} {
	ui_debug "Re-registering default for $option"
    } else {
	# If option is already set and we did not set it
	# do not reset the value
	if {[info exists $option]} {
	    return
	}
    }
    set option_defaults($option) $val
    set $option $val
    trace variable $option rwu default_check
}

# default_check
# trace handler to provide delayed variable & command expansion
# for default variable values
proc default_check {optionName index op} {
    global option_defaults $optionName
    switch $op {
	w {
	    unset option_defaults($optionName)
	    trace vdelete $optionName rwu default_check
	    return
	}
	r {
	    upvar $optionName option
	    uplevel #0 set $optionName $option_defaults($optionName)
	    return
	}
	u {
	    unset option_defaults($optionName)
	    trace vdelete $optionName rwu default_check
	    return
	}
    }
}

# variant <provides> [<provides> ...] [requires <requires> [<requires>]]
# Portfile level procedure to provide support for declaring variants
proc variant {args} {
    global all_variants PortInfo
    upvar $args upargs
    
    set len [llength $args]
    set code [lindex $args end]
    set args [lrange $args 0 [expr $len - 2]]
    
    set ditem [variant_new "temp-variant"]
    
    # mode indicates what the arg is interpreted as.
	# possible mode keywords are: requires, conflicts, provides
	# The default mode is provides.  Arguments are added to the
	# most recently specified mode (left to right).
    set mode "provides"
    foreach arg $args {
		switch -exact $arg {
			provides { set mode "provides" }
			requires { set mode "requires" }
			conflicts { set mode "conflicts" }
			default { ditem_append $ditem $mode $arg }		
        }
    }
    ditem_key $ditem name "[join [ditem_key $ditem provides] -]"

    # make a user procedure named variant-blah-blah
    # we will call this procedure during variant-run
    makeuserproc "variant-[ditem_key $ditem name]" \{$code\}
    lappend all_variants $ditem
    
    # Export provided variant to PortInfo
    lappend PortInfo(variants) [ditem_key $ditem provides]
}

# variant_isset name
# Returns 1 if variant name selected, otherwise 0
proc variant_isset {name} {
    global variations
    
    if {[info exists variations($name)] && $variations($name) == "+"} {
	return 1
    }
    return 0
}

# variant_set name
# Sets variant to run for current portfile
proc variant_set {name} {
    global variations
    
    set variations($name) +
}

# variant_unset name
# Clear variant for current portfile
proc variant_unset {name} {
    global variations

    set variations($name) -
}

########### Misc Utility Functions ###########

# tbool (testbool)
# If the variable exists in the calling procedure's namespace
# and is set to "yes", return 1. Otherwise, return 0
proc tbool {key} {
    upvar $key $key
    if {[info exists $key]} {
	if {[string equal -nocase [set $key] "yes"]} {
	    return 1
	}
    }
    return 0
}

# ldelete
# Deletes a value from the supplied list
proc ldelete {list value} {
    upvar $list uplist
    set ix [lsearch -exact $uplist $value]
    if {$ix >= 0} {
	set uplist [lreplace $uplist $ix $ix]
    }
}

# reinplace
# Provides "sed in place" functionality
proc reinplace {pattern args}  {
    if {$args == ""} {
    	ui_error "reinplace: no value given for parameter \"file\""
	return -code error "no value given for parameter \"file\" to \"reinplace\"" 
    }

    foreach file $args {
	if {[catch {set tmpfile [mktemp "/tmp/[file tail $file].sed.XXXXXXXX"]} error]} {
	    ui_error "reinplace: $error"
	    return -code error "reinplace failed"
	}

	if {[catch {exec sed $pattern < $file > $tmpfile} error]} {
	    ui_error "reinplace: $error"
	    file delete "$tmpfile"
	    return -code error "reinplace failed"
	}

	if {[catch {exec cp $tmpfile $file} error]} {
	    ui_error "reinplace: $error"
	    file delete "$tmpfile"
	    return -code error "reinplace failed"
	}
	file delete "$tmpfile"
    }
    return
}

# filefindbypath
# Provides searching of the standard path for included files
proc filefindbypath {fname} {
    global distpath filedir workdir worksrcdir portpath

    if {[file readable $portpath/$fname]} {
	return $portpath/$fname
    } elseif {[file readable $portpath/$filedir/$fname]} {
	return $portpath/$filedir/$fname
    } elseif {[file readable $distpath/$fname]} {
	return $distpath/$fname
    }
    return ""
}

# include
# Source a file, looking for it along a standard search path.
proc include {fname} {
    set tgt [filefindbypath $fname]
    if {[string length $tgt]} {
	uplevel "source $tgt"
    } else {
	return -code error "Unable to find include file $fname"
    }
}

# makeuserproc
# This procedure re-writes the user-defined custom target to include
# all the globals in its scope.  This is undeniably ugly, but I haven't
# thought of any other way to do this.
proc makeuserproc {name body} {
    regsub -- "^\{(.*?)" $body "\{ \n foreach g \[info globals\] \{ \n global \$g \n \} \n \\1" body
    eval "proc $name {} $body"
}

########### Internal Dependancy Manipulation Procedures ###########

proc target_run {ditem} {
    global target_state_fd portname
    set result 0
    set procedure [ditem_key $ditem procedure]
    if {$procedure != ""} {
	set name [ditem_key $ditem name]
	
	if {[ditem_contains $ditem init]} {
	    set result [catch {[ditem_key $ditem init] $name} errstr]
	}
	
	if {[check_statefile target $name $target_state_fd] && $result == 0} {
	    set result 0
	    ui_debug "Skipping completed $name ($portname)"
	} elseif {$result == 0} {
	    # Execute pre-run procedure
	    if {[ditem_contains $ditem prerun]} {
		set result [catch {[ditem_key $ditem prerun] $name} errstr]
	    }
	    
	    if {$result == 0} {
		foreach pre [ditem_key $ditem pre] {
		    ui_debug "Executing $pre"
		    set result [catch {$pre $name} errstr]
		    if {$result != 0} { break }
		}
	    }
	    
	    if {$result == 0} {
		ui_debug "Executing $name ($portname)"
		set result [catch {$procedure $name} errstr]
	    }
	    
	    if {$result == 0} {
		foreach post [ditem_key $ditem post] {
		    ui_debug "Executing $post"
		    set result [catch {$post $name} errstr]
		    if {$result != 0} { break }
		}
	    }
	    # Execute post-run procedure
	    if {[ditem_contains $ditem postrun] && $result == 0} {
		set postrun [ditem_key $ditem postrun]
		ui_debug "Executing $postrun"
		set result [catch {$postrun $name} errstr]
	    }
	}
	if {$result == 0} {
	    if {[ditem_key $ditem runtype] != "always"} {
		write_statefile target $name $target_state_fd
	    }
	} else {
	    ui_error "Target $name returned: $errstr"
	    set result 1
	}
	
    } else {
	ui_info "Warning: $name does not have a registered procedure"
	set result 1
    }
    
    return $result
}

proc eval_targets {target} {
    global targets target_state_fd portname
    set dlist $targets
	    
	# Select the subset of targets under $target
    if {$target != ""} {
        set matches [dlist_search $dlist provides $target]

        if {[llength $matches] > 0} {
			set dlist [dlist_append_dependents $dlist [lindex $matches 0] [list]]
			# Special-case 'all'
		} elseif {$target != "all"} {
			ui_info "unknown target: $target"
            return 1
        }
    }
	
    # Restore the state from a previous run.
    set target_state_fd [open_statefile]
    
    set dlist [dlist_eval $dlist "" target_run]

    if {[llength $dlist] > 0} {
		# somebody broke!
		set errstring "Warning: the following items did not execute (for $portname):"
		foreach ditem $dlist {
			append errstring " [ditem_key $ditem name]"
		}
		ui_info $errstring
		set result 1
    } else {
		set result 0
    }
	
    close $target_state_fd
    return $result
}

# open_statefile
# open file to store name of completed targets
proc open_statefile {args} {
    global workpath portname portpath ports_ignore_older
    
    if {![file isdirectory $workpath]} {
	file mkdir $workpath
    }
    # flock Portfile
    set statefile [file join $workpath .darwinports.${portname}.state]
    if {[file exists $statefile]} {
		if {![file writable $statefile]} {
			return -code error "$statefile is not writable - check permission on port directory"
		}
		if {!([info exists ports_ignore_older] && $ports_ignore_older == "yes") && [file mtime $statefile] < [file mtime ${portpath}/Portfile]} {
			ui_msg "Portfile changed since last build; discarding previous state."
			#file delete $statefile
			exec rm -rf [file join $workpath]
			exec mkdir [file join $workpath]
		}
	}
	
    set fd [open $statefile a+]
    if {[catch {flock $fd -exclusive -noblock} result]} {
        if {"$result" == "EAGAIN"} {
            ui_msg "Waiting for lock on $statefile"
	} elseif {"$result" == "EOPNOTSUPP"} {
	    # Locking not supported, just return
	    return $fd
        } else {
            return -code error "$result obtaining lock on $statefile"
        }
    }
    flock $fd -exclusive
    return $fd
}

# check_statefile
# Check completed/selected state of target/variant $name
proc check_statefile {class name fd} {
    global portpath workdir
    	
    seek $fd 0
    while {[gets $fd line] >= 0} {
		if {$line == "$class: $name"} {
			return 1
		}
    }
    return 0
}

# write_statefile
# Set target $name completed in the state file
proc write_statefile {class name fd} {
    if {[check_statefile $class $name $fd]} {
		return 0
    }
    seek $fd 0 end
    puts $fd "$class: $name"
    flush $fd
}

# check_statefile_variants
# Check that recorded selection of variants match the current selection
proc check_statefile_variants {variations fd} {
	upvar $variations upvariations
	
    seek $fd 0
    while {[gets $fd line] >= 0} {
		if {[regexp "variant: (.*)" $line match name]} {
			set oldvariations([string range $name 1 end]) [string range $name 0 0]
		}
    }

	set mismatch 0
	if {[array size oldvariations] > 0} {
		if {[array size oldvariations] != [array size upvariations]} {
			set mismatch 1
		} else {
			foreach key [array names upvariations *] {
				if {$upvariations($key) != $oldvariations($key)} {
					set mismatch 1
					break
				}
			}
		}
	}

	return $mismatch
}

# Traverse the ports collection hierarchy and call procedure func for
# each directory containing a Portfile
proc port_traverse {func {dir .}} {
    set pwd [pwd]
    if {[catch {cd $dir} err]} {
	ui_error $err
	return
    }
    foreach name [readdir .] {
	if {[string match $name .] || [string match $name ..]} {
	    continue
	}
	if {[file isdirectory $name]} {
	    port_traverse $func $name
	} else {
	    if {[string match $name Portfile]} {
		catch {eval $func {[file join $pwd $dir]}}
	    }
	}
    }
    cd $pwd
}


########### Port Variants ###########

# Each variant which provides a subset of the requested variations
# will be chosen.  Returns a list of the selected variants.
proc choose_variants {dlist variations} {
    upvar $variations upvariations
    
    set selected [list]
    
    foreach ditem $dlist {
	# Enumerate through the provides, tallying the pros and cons.
	set pros 0
	set cons 0
	set ignored 0
	foreach flavor [ditem_key $ditem provides] {
	    if {[info exists upvariations($flavor)]} {
		if {$upvariations($flavor) == "+"} {
		    incr pros
		} elseif {$upvariations($flavor) == "-"} {
		    incr cons
		}
	    } else {
		incr ignored
	    }
	}
	
	if {$cons > 0} { continue }
	
	if {$pros > 0 && $ignored == 0} {
	    lappend selected $ditem
	}
    }
    return $selected
}

proc variant_run {ditem} {
    set name [ditem_key $ditem name]
    ui_debug "Executing $name provides [ditem_key $ditem provides]"

	# test for conflicting variants
	foreach v [ditem_key $ditem conflicts] {
		if {[variant_isset $v]} {
			ui_error "Variant $name conflicts with $v"
			return 1
		}
	}

    # execute proc with same name as variant.
    if {[catch "variant-${name}" result]} {
	ui_error "Error executing $name: $result"
	return 1
    }
    return 0
}

proc eval_variants {variations target} {
    global all_variants ports_force
    set dlist $all_variants
	set result 0
    upvar $variations upvariations
    set chosen [choose_variants $dlist upvariations]
    
    # now that we've selected variants, change all provides [a b c] to [a-b-c]
    # this will eliminate ambiguity between item a, b, and a-b while fulfilling requirments.
    #foreach obj $dlist {
    #    $obj set provides [list [join [$obj get provides] -]]
    #}
    
    set newlist [list]
    foreach variant $chosen {
        set newlist [dlist_append_dependents $dlist $variant $newlist]
    }
    
    dlist_eval $newlist "" variant_run
	
	# Make sure the variations match those stored in the statefile.
	# If they don't match, print an error indicating a 'port clean' 
	# should be performed.  
	# - Skip this test if the statefile is empty.
	# - Skip this test if performing a clean.
	# - Skip this test if ports_force was specified.

	if {$target != "clean" && 
		!([info exists ports_force] && $ports_force == "yes")} {
		set state_fd [open_statefile]
	
		if {[check_statefile_variants upvariations $state_fd]} {
			ui_error "Requested variants do not match original selection.\nPlease perform 'port clean' or specify the force option."
			set result 1
		} else {
			# Write variations out to the statefile
			foreach key [array names upvariations *] {
				write_statefile variant $upvariations($key)$key $state_fd
			}
		}
		
		close $state_fd
	}
	
	return $result
}

# Target class definition.

# constructor for target object
proc target_new {name procedure} {
    global targets
    set ditem [ditem_create]
	
	ditem_key $ditem name $name
	ditem_key $ditem procedure $procedure
    
    lappend targets $ditem
    
    return $ditem
}

proc target_provides {ditem args} {
    global targets
    # Register the pre-/post- hooks for use in Portfile.
    # Portfile syntax: pre-fetch { puts "hello world" }
    # User-code exceptions are caught and returned as a result of the target.
    # Thus if the user code breaks, dependent targets will not execute.
    foreach target $args {
	set origproc [ditem_key $ditem procedure]
	set ident [ditem_key $ditem name]
	if {[info commands $target] != ""} {
	    ui_debug "$ident registered provides \'$target\', a pre-existing procedure. Target override will not be provided"
	} else {
		eval "proc $target {args} \{ \n\
			ditem_key $ditem procedure proc-${ident}-${target}
			eval \"proc proc-${ident}-${target} \{name\} \{ \n\
				if \{\\\[catch userproc-${ident}-${target} result\\\]\} \{ \n\
					return -code error \\\$result \n\
				\} else \{ \n\
					return 0 \n\
				\} \n\
			\}\" \n\
			eval \"proc do-$target \{\} \{ $origproc $target\}\" \n\
			makeuserproc userproc-${ident}-${target} \$args \n\
		\}"
	}
	eval "proc pre-$target {args} \{ \n\
			ditem_append $ditem pre proc-pre-${ident}-${target}
			eval \"proc proc-pre-${ident}-${target} \{name\} \{ \n\
				if \{\\\[catch userproc-pre-${ident}-${target} result\\\]\} \{ \n\
					return -code error \\\$result \n\
				\} else \{ \n\
					return 0 \n\
				\} \n\
			\}\" \n\
			makeuserproc userproc-pre-${ident}-${target} \$args \n\
		\}"
	eval "proc post-$target {args} \{ \n\
			ditem_append $ditem post proc-post-${ident}-${target}
			eval \"proc proc-post-${ident}-${target} \{name\} \{ \n\
				if \{\\\[catch userproc-post-${ident}-${target} result\\\]\} \{ \n\
					return -code error \\\$result \n\
				\} else \{ \n\
					return 0 \n\
				\} \n\
			\}\" \n\
			makeuserproc userproc-post-${ident}-${target} \$args \n\
		\}"
    }
    eval "ditem_append $ditem provides $args"
}

proc target_requires {ditem args} {
    eval "ditem_append $ditem requires $args"
}

proc target_uses {ditem args} {
    eval "ditem_append $ditem uses $args"
}

proc target_deplist {ditem args} {
    eval "ditem_append $ditem deplist $args"
}

proc target_prerun {ditem args} {
    eval "ditem_append $ditem prerun $args"
}

proc target_postrun {ditem args} {
    eval "ditem_append $ditem postrun $args"
}

proc target_runtype {ditem args} {
	eval "ditem_append $ditem runtype $args"
}

proc target_init {ditem args} {
    eval "ditem_append $ditem init $args"
}

##### variant class #####

# constructor for variant objects
proc variant_new {name} {
    set ditem [ditem_create]
    ditem_key $ditem name $name
    return $ditem
}

proc handle_default_variants {option action args} {
    global variations
    switch -regex $action {
	set|append {
	    foreach v $args {
		if {[regexp {([-+])([-A-Za-z0-9_]+)} $v whole val variant]} {
		    if {![info exists variations($variant)]} {
			set variations($variant) $val
		    }
		}
	    }
	}
	delete {
	    # xxx
	}
    }
}


# builds the specified port (looked up in the index) to the specified target
# doesn't yet support options or variants...
# newworkpath defines the port's workpath - useful for when one port relies
# on the source, etc, of another
proc portexec_int {portname target {newworkpath ""}} {
    ui_debug "Executing $target ($portname)"
    set variations [list]
    if {$newworkpath == ""} {
        array set options [list]
    } else {
        set options(workpath) ${newworkpath}
    }
	# Escape regex special characters
	regsub -all "(\\(){1}|(\\)){1}|(\\{1}){1}|(\\+){1}|(\\{1}){1}|(\\{){1}|(\\}){1}|(\\^){1}|(\\$){1}|(\\.){1}|(\\\\){1}" $portname "\\\\&" search_string 

    set res [dportsearch ^$search_string\$]
    if {[llength $res] < 2} {
        ui_error "Dependency $portname not found"
        return -1
    }

    array set portinfo [lindex $res 1]
    set porturl $portinfo(porturl)
    if {[catch {set worker [dportopen $porturl [array get options] $variations]} result]} {
        ui_error "Opening $portname $target failed: $result"
        return -1
    }
    if {[catch {dportexec $worker $target} result] || $result != 0} {
        ui_error "Execution $portname $target failed: $result"
        dportclose $worker
        return -1
    }
    dportclose $worker
    
    return 0
}

# portfile primitive that calls portexec_int with newworkpath == ${workpath}
proc portexec {portname target} {
    global workpath
    return [portexec_int $portname $target $workpath]
}

proc adduser {name args} {
    global os.platform
    set passwd {\*}
    set uid [nextuid]
    set gid [existsgroup nogroup]
    set realname ${name}
    set home /dev/null
    set shell /dev/null

    foreach arg $args {
	if {[regexp {([a-z]*)=(.*)} $arg match key val]} {
	    regsub -all " " ${val} "\\ " val
	    set $key $val
	}
    }

    if {[existsuser ${name}] != 0 || [existsuser ${uid}] != 0} {
	return
    }

    if {${os.platform} == "darwin"} {
	system "niutil -create . /users/${name}"
	system "niutil -createprop . /users/${name} name ${name}"
	system "niutil -createprop . /users/${name} passwd ${passwd}"
	system "niutil -createprop . /users/${name} uid ${uid}"
	system "niutil -createprop . /users/${name} gid ${gid}"
	system "niutil -createprop . /users/${name} realname ${realname}"
	system "niutil -createprop . /users/${name} home ${home}"
	system "niutil -createprop . /users/${name} shell ${shell}"
    } else {
	# XXX adduser is only available for darwin, add more support here
	ui_warn "WARNING: adduser is not implemented on ${os.platform}."
	ui_warn "The requested user was not created."
    }
}

proc addgroup {name args} {
    global os.platform
    set gid [nextgid]
    set passwd {\*}
    set users ""

    foreach arg $args {
	if {[regexp {([a-z]*)=(.*)} $arg match key val]} {
	    regsub -all " " ${val} "\\ " val
	    set $key $val
	}
    }

    if {[existsgroup ${name}] != 0 || [existsgroup ${gid}] != 0} {
	return
    }

    if {${os.platform} == "darwin"} {
	system "niutil -create . /groups/${name}"
	system "niutil -createprop . /groups/${name} name ${name}"
	system "niutil -createprop . /groups/${name} gid ${gid}"
	system "niutil -createprop . /groups/${name} passwd ${passwd}"
	system "niutil -createprop . /groups/${name} users ${users}"
    } else {
	# XXX addgroup is only available for darwin, add more support here
	ui_warn "WARNING: addgroup is not implemented on ${os.platform}."
	ui_warn "The requested group was not created."
    }
}
