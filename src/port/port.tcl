#!/bin/sh
#\
exec @TCLSH@ "$0" "$@"
# port.tcl
# $Id: port.tcl,v 1.158 2006/03/28 06:50:37 jberry Exp $
#
# Copyright (c) 2002-2006 DarwinPorts organization
# Copyright (c) 2004 Robert Shaw <rshaw@opendarwin.org>
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
#	TODO:
#

catch {source \
	[file join "@TCL_PACKAGE_DIR@" darwinports1.0 darwinports_fastload.tcl]}
package require darwinports


# UI Instantiations
# ui_options(ports_debug) - If set, output debugging messages.
# ui_options(ports_verbose) - If set, output info messages (ui_info)
# ui_options(ports_quiet) - If set, don't output "standard messages"

# ui_options accessor
proc ui_isset {val} {
	global ui_options
	if {[info exists ui_options($val)]} {
		if {$ui_options($val) == "yes"} {
			return 1
		}
	}
	return 0
}

# global_options accessor
proc global_option_isset {val} {
	global global_options
	if {[info exists global_options($val)]} {
		if {$global_options($val) == "yes"} {
			return 1
		}
	}
	return 0
}

# UI Callback
proc ui_prefix {priority} {
    switch $priority {
        debug {
        	return "DEBUG: "
        }
        error {
        	return "Error: "
        }
        warn {
        	return "Warning: "
        }
        default {
        	return ""
        }
    }
}

proc ui_channels {priority} {
    global logfd
    switch $priority {
        debug {
            if {[ui_isset ports_debug]} {
            	return {stderr}
            } else {
            	return {}
            }
        }
        info {
            if {[ui_isset ports_verbose]} {
                return {stdout}
            } else {
                return {}
			}
		}
        msg {
            if {[ui_isset ports_quiet]} {
                return {}
			} else {
				return {stdout}
			}
		}
        error {
        	return {stderr}
        }
        default {
        	return {stdout}
        }
    }
}


# Standard procedures
proc print_usage {args} {
	global cmdname
	set syntax { [-bcdfFiknopqRstuxv] [-D portdir] [-F cmdfile] action [privopts] [actionflags]
[[portname|pseudo-portname|port-url] [@version] [+-variant]... [option=value]...]...
}
		
	puts "Usage: $cmdname$syntax"
	puts "\"$cmdname help\" or \"man 1 port\" for more information."
}


proc print_help {args} {
	global cmdname
	global action_array
	
	set syntax { [-bcdfFiknopqRstuxv] [-D portdir] [-F cmdfile] action [privopts] [actionflags]
[[portname|pseudo-portname|port-url] [@version] [+-variant]... [option=value]...]...
}

	# Generate and format the command list from the action_array
	set cmds ""
	set lineLen 0
	foreach cmd [lsort [array names action_array]] {
		if {$lineLen > 65} {
			set cmds "$cmds,\n"
			set lineLen 0
		}
		if {$lineLen == 0} {
			set new "$cmd"
		} else {
			set new ", $cmd"
		}
		incr lineLen [string length $new]
		set cmds "$cmds$new"
	}
	
	set cmdText "
Supported commands
------------------
$cmds
"

	set text {
Pseudo-portnames
----------------
Pseudo-portnames are words that may be used in place of a portname, and
which expand to some set of ports. The common pseudo-portnames are:
all, current, active, inactive, installed, uninstalled, and outdated.
These pseudo-portnames expand to the set of ports named.

Additional pseudo-portnames start with...
variants:, variant:, description:, portdir:, homepage:, epoch:,
platforms:, platform:, name:, long_description:, maintainers:,
maintainer:, categories:, category:, version:, and revision:.
These each select a set of ports based on a regex search of metadata
about the ports. In all such cases, a standard regex pattern following
the colon will be used to select the set of ports to which the
pseudo-portname expands.

Portnames that contain standard glob characters will be expanded to the
set of ports matching the glob pattern.
	
Port expressions
----------------
Portnames, port glob patterns, and pseudo-portnames may be logically
combined using expressions consisting of and, or, not, !, (, and ).
	
For more information
--------------------
See man pages: port(1), ports.conf(5), portfile(7), portgroup(7),
porthier(7), portstyle(7). Also, see http://www.darwinports.org.
}

	
	puts "$cmdname$syntax $cmdText $text"
}



# Produce error message and exit
proc fatal s {
	global argv0
	ui_error "$argv0: $s"
	exit 1
}


# Produce an error message, and exit, unless
# we're handling errors in a soft fashion, in which
# case we continue
proc fatal_softcontinue s {
	if {[global_option_isset ports_force]} {
		ui_error $s
		return -code continue
	} else {
		fatal $s
	}
}


# Produce an error message, and break, unless
# we're handling errors in a soft fashion, in which
# case we continue
proc break_softcontinue { msg status name_status } {
	upvar $name_status status_var 
	ui_error $msg
	if {[ui_isset ports_processall]} {
		set status_var 0
		return -code continue
	} else {
		set status_var $status
		return -code break
	}
}


# Form a composite version as is sometimes used for registry functions
proc composite_version {version variations {emptyVersionOkay 0}} {
	# Form a composite version out of the version and variations
	
	# Select the variations into positive and negative
	set pos {}
	set neg {}
	foreach { key val } $variations {
		if {$val == "+"} {
			lappend pos $key
		} elseif {$val == "-"} {
			lappend neg $key
		}
	}
	
	# If there is no version, we have nothing to do
	set composite_version ""
	if {$version != "" || $emptyVersionOkay} {
		set pos_str ""
		set neg_str ""
		
		if {[llength $pos]} {
			set pos_str "+[join [lsort -ascii $pos] "+"]"
		}
		if {[llength $neg]} {
			set neg_str "-[join [lsort -ascii $neg] "-"]"
		}
		
		set composite_version "$version$pos_str$neg_str"
	}
	
	return $composite_version
}


proc split_variants {variants} {
	set result {}
	set l [regexp -all -inline -- {([-+])([[:alpha:]_]+[\w\.]*)} $variants]
	foreach { match sign variant } $l {
		lappend result $variant $sign
	}
	return $result
}


proc registry_installed {portname {portversion ""}} {
	set ilist [registry::installed $portname $portversion]
	if { [llength $ilist] > 1 } {
		puts "The following versions of $portname are currently installed:"
		foreach i $ilist { 
			set iname [lindex $i 0]
			set iversion [lindex $i 1]
			set irevision [lindex $i 2]
			set ivariants [lindex $i 3]
			set iactive [lindex $i 4]
			if { $iactive == 0 } {
				puts "	$iname ${iversion}_${irevision}${ivariants}"
			} elseif { $iactive == 1 } {
				puts "	$iname ${iversion}_${irevision}${ivariants} (active)"
			}
		}
		return -code error "Registry error: Please specify the full version as recorded in the port registry."
	} else {
		return [lindex $ilist 0]
	}
}


proc add_to_portlist {listname portentry} {
	upvar $listname portlist
	global global_options global_variations
	
	# The portlist currently has the following elements in it:
	#	url				if any
	#	name
	#	version			(version_revision)
	#	variants array	(variant=>+-)
	#	options array	(key=>value)
	#	fullname		(name/version_revision+-variants)
	
	array set port $portentry
	if {![info exists port(url)]}		{ set port(url) "" }
	if {![info exists port(name)]}		{ set port(name) "" }
	if {![info exists port(version)]}	{ set port(version) "" }
	if {![info exists port(variants)]}	{ set port(variants) "" }
	if {![info exists port(options)]}	{ set port(options) [array get global_options] }
	
	# If neither portname nor url is specified, then default to the current port
	if { $port(url) == "" && $port(name) == "" } {
		set url file://.
		set portname [url_to_portname $url]
		set port(url) $url
		set port(name) $portname
		if {$portname == ""} {
			ui_error "A default port name could not be supplied."
		}
	}
	
		
	# Form the fully descriminated portname: portname/version_revison+-variants
	set port(fullname) "$port(name)/[composite_version $port(version) $port(variants)]"
	
	# Add it to our portlist
	lappend portlist [array get port]
}


proc add_ports_to_portlist {listname ports {overridelist ""}} {
	upvar $listname portlist
	
	array set overrides $overridelist
	
	# Add each entry to the named portlist, overriding any values
	# specified as overrides
	foreach portentry $ports {
		array set port $portentry
		if ([info exists overrides(version)])	{ set port(version) $overrides(version)	}
		if ([info exists overrides(variants)])	{ set port(variants) $overrides(variants)	}
		if ([info exists overrides(options)])	{ set port(options) $overrides(options)	}
		add_to_portlist portlist [array get port]
	}
}


proc url_to_portname { url {quiet 0} } {
	# Save directory and restore the directory, since dportopen changes it
	set savedir [pwd]
	set portname ""
	if {[catch {set ctx [dportopen $url]} result]} {
		if {!$quiet} {
			puts stderr "Can't map the URL '$url' to a port description file (${result}). Please verify that the directory and portfile syntax are correct."
		}
	} else {
		array set portinfo [dportinfo $ctx]
		set portname $portinfo(name)
		dportclose $ctx
	}
	cd $savedir
	return $portname
}


# Supply a default porturl/portname if the portlist is empty
proc require_portlist { nameportlist } {
	upvar $nameportlist portlist
	
	if {[llength $portlist] == 0} {
		set portlist [get_current_port]
	}
}


# Execute the enclosed block once for every element in the portlist
# When the block is entered, the variables portname, portversion, options, and variations
# will have been set
proc foreachport {portlist block} {
	# Restore cwd after each port, since dportopen changes it, and relative
	# urls will break on subsequent passes
	set savedir [pwd]
	foreach portspec $portlist {
		uplevel 1 "array set portspec { $portspec }"
		uplevel 1 {
			set porturl $portspec(url)
			set portname $portspec(name)
			set portversion $portspec(version)
			array unset variations
			array set variations $portspec(variants)
			array unset options
			array set options $portspec(options)
		}
		uplevel 1 $block
		cd $savedir
	}
}


proc portlist_compare { a b } {
	array set a_ $a
	array set b_ $b
	return [string compare $a_(name) $b_(name)]
}


proc portlist_sort { list } {
	return [lsort -command portlist_compare $list]
}


proc regex_pat_sanitize { s } {
	set sanitized [regsub -all {[\\(){}+$.^]} $s {\\&}]
	return $sanitized
}


##########################################
# Port selection
##########################################
proc get_matching_ports {pattern {casesensitive no} {matchstyle glob} {field name}} {
	if {[catch {set res [dportsearch $pattern $casesensitive $matchstyle $field]} result]} {
		global errorInfo
		ui_debug "$errorInfo"
		fatal "search for portname $pattern failed: $result"
	}

	set results {}
	foreach {name info} $res {
		array set portinfo $info
		
		#set variants {}
		#if {[info exists portinfo(variants)]} {
		#	foreach variant $portinfo(variants) {
		#		lappend variants $variant "+"
		#	}
		#}
		# For now, don't include version or variants with all ports list
		#"$portinfo(version)_$portinfo(revision)"
		#$variants
		add_to_portlist results [list url $portinfo(porturl) name $name]
	}
	
	# Return the list of all ports, sorted
	return [portlist_sort $results]
}


proc get_all_ports {} {
	global all_ports_cache
	
	if {![info exists all_ports_cache]} {
		set all_ports_cache [get_matching_ports "*"]
	}
	return $all_ports_cache
}


proc get_current_ports {} {
	# This is just a synonym for get_current_port that
	# works with the regex in element
	return [get_current_port]
}


proc get_current_port {} {
	set url file://.
	set portname [url_to_portname $url]
	if {$portname == ""} {
		ui_error "To use the current port, you must be in a port's directory"
	}
	
	set results {}
	add_to_portlist results [list url $url name $portname]
	return $results
}


proc get_installed_ports { {ignore_active yes} {active yes} } {
	set ilist {}
	if { [catch {set ilist [registry::installed]} result] } {
		if {$result != "Registry error: No ports registered as installed."} {
			global errorInfo
			ui_debug "$errorInfo"
			fatal "port installed failed: $result"
		}
	}
	
	set results {}
	foreach i $ilist {
		set iname [lindex $i 0]
		set iversion [lindex $i 1]
		set irevision [lindex $i 2]
		set ivariants [split_variants [lindex $i 3]]
		set iactive [lindex $i 4]
		
		if { ${ignore_active} == "yes" || (${active} == "yes") == (${iactive} != 0) } {
			add_to_portlist results [list name $iname version "${iversion}_${irevision}" variants $ivariants]
		}
	}
	
	# Return the list of ports, sorted
	return [portlist_sort $results]
}


proc get_uninstalled_ports {} {
	# Return all - installed
	set all [get_all_ports]
	set installed [get_installed_ports]
	return [opComplement $all $installed]
}


proc get_active_ports {} {
	return [get_installed_ports no yes]
}


proc get_inactive_ports {} {
	return [get_installed_ports no no]
}


proc get_outdated_ports {} {
	global darwinports::registry.installtype
	set is_image_mode [expr 0 == [string compare "image" ${darwinports::registry.installtype}]]
	
	# Get the list of installed ports
	set ilist {}
	if { [catch {set ilist [registry::installed]} result] } {
		if {$result != "Registry error: No ports registered as installed."} {
			global errorInfo
			ui_debug "$errorInfo"
			fatal "port installed failed: $result"
		}
	}

	# Now process the list, keeping only those ports that are outdated
	set results {}
	if { [llength $ilist] > 0 } {
		foreach i $ilist {
		
			# Get information about the installed port
			set portname			[lindex $i 0]
			set installed_version	[lindex $i 1]
			set installed_revision	[lindex $i 2]
			set installed_compound	"${installed_version}_${installed_revision}"
			set installed_variants	[lindex $i 3]

			set is_active			[lindex $i 4]
			if { $is_active == 0 && $is_image_mode } continue

			set installed_epoch		[lindex $i 5]

			# Get info about the port from the index
			if {[catch {set res [dportsearch $portname no exact]} result]} {
				global errorInfo
				ui_debug "$errorInfo"
				fatal "search for portname $portname failed: $result"
			}
			if {[llength $res] < 2} {
				if {[ui_isset ports_debug]} {
					puts "$portname ($installed_compound is installed; the port was not found in the port index)"
				}
				continue
			}
			array set portinfo [lindex $res 1]
			
			# Get information about latest available version and revision
			set latest_version $portinfo(version)
			set latest_revision		0
			if {[info exists portinfo(revision)] && $portinfo(revision) > 0} { 
				set latest_revision	$portinfo(revision)
			}
			set latest_compound		"${latest_version}_${latest_revision}"
			set latest_epoch		0
			if {[info exists portinfo(epoch)]} { 
				set latest_epoch	$portinfo(epoch)
			}
			
			# Compare versions, first checking epoch, then the compound version string
			set comp_result [expr $installed_epoch - $latest_epoch]
			if { $comp_result == 0 } {
				set comp_result [rpm-vercomp $installed_compound $latest_compound]
			}
			
			# Add outdated ports to our results list
			if { $comp_result < 0 } {
				add_to_portlist results [list name $portname version $installed_compound variants [split_variants $installed_variants]]
			}
		}
	}

	return $results
}



##########################################
# Port expressions
##########################################
proc portExpr { resname } {
	upvar $resname reslist
	set result [seqExpr reslist]
	return $result
}


proc seqExpr { resname } {
	upvar $resname reslist
	
	# Evaluate a sequence of expressions a b c...
	# These act the same as a or b or c

	set result 1
	while {$result} {
		switch -- [lookahead] {
			;		-
			)		-
			_EOF_	{ break }
		}
		
		set blist {}
		set result [orExpr blist]
		if {$result} {
			# Calculate the union of result and b
			set reslist [opUnion $reslist $blist]
		}
	}
	
	return $result
}


proc orExpr { resname } {
	upvar $resname reslist
	
	set a [andExpr reslist]
	while ($a) {
		switch -- [lookahead] {
			or {
					advance
					set blist {}
					if {![andExpr blist]} {
						return 0
					}
						
					# Calculate a union b
					set reslist [opUnion $reslist $blist]
				}
			default {
					return $a
				}
		}
	}
	
	return $a
}


proc andExpr { resname } {
	upvar $resname reslist
	
	set a [unaryExpr reslist]
	while {$a} {
		switch -- [lookahead] {
			and {
					advance
					
					set blist {}
					set b [unaryExpr blist]
					if {!$b} {
						return 0
					}
					
					# Calculate a intersect b
					set reslist [opIntersection $reslist $blist]
				}
			default {
					return $a
				}
		}
	}
	
	return $a
}


proc unaryExpr { resname } {
	upvar $resname reslist
	set result 0

	switch -- [lookahead] {
		!	-
		not	{
				advance
				set blist {}
				set result [unaryExpr blist]
				if {$result} {
					set all [get_all_ports]
					set reslist [opComplement $all $blist]
				}
			}
		default {
				set result [element reslist]
			}
	}
	
	return $result
}


proc element { resname } {
	upvar $resname reslist
	set el 0
	
	set url ""
	set name ""
	set version ""
	array unset variants
	array unset options
	
	set token [lookahead]
	switch -regex -- $token {
		^\\)$			-
		^\;				-
		^_EOF_$			{	# End of expression/cmd/file
						}
						
		^\\($			{	# Parenthesized Expression
							advance
							set el [portExpr reslist]
							if {!$el || ![match ")"]} {
								set el 0
							}
						}
			
		^all(@.*)?$ 			-
		^installed(@.*)?$		-
		^uninstalled(@.*)?$		-
		^active(@.*)?$			-
		^inactive(@.*)?$		-
		^outdated(@.*)?$		-
		^current(@.*)?$	{
							# A simple pseudo-port name
							advance
							
							# Break off the version component, if there is one
							regexp {^(\w+)(@.*)?} $token matchvar name remainder
							
							add_multiple_ports reslist [get_${name}_ports] $remainder
							
							set el 1
						}
		
		^variants:		-
		^variant:		-
		^description:	-
		^portdir:		-
		^homepage:		-
		^epoch:			-
		^platforms:		-
		^platform:		-
		^name:			-
		^long_description:	-
		^maintainers:	-
		^maintainer:	-
		^categories:	-
		^category:		-
		^version:		-
		^revision:		{	# Handle special port selectors
							advance
							
							# Break up the token, because older Tcl switch doesn't support -matchvar
							regexp {^(\w+):(.*)} $token matchvar field pat
							
							# Remap friendly names to actual names
							switch -- $field {
								variant		-
								platform	-
								maintainer	{ set field "${field}s" }
								category	{ set field "categories" }
							}							
							add_multiple_ports reslist [get_matching_ports $pat no regexp $field]
							set el 1
						}
						
		[][?*]			{	# Handle portname glob patterns
							advance; add_multiple_ports reslist [get_matching_ports $token no glob]
							set el 1
						}
						
		^\\w+:.+		{	# Handle a url by trying to open it as a port and mapping the name
							advance
							set name [url_to_portname $token]
							if {$name != ""} {
								parsePortSpec version variants options
								add_to_portlist reslist [list url $token \
															name $name \
															version $version \
															variants [array get variants] \
															options [array get options]]
							} else {
								ui_error "Can't open URL '$token' as a port"
								set el 0
							}
							set el 1
						}
						
		default			{	# Treat anything else as a portspec (portname, version, variants, options
							# or some combination thereof).
							parseFullPortSpec url name version variants options
							add_to_portlist reslist [list 	url $url \
															name $name \
															version $version \
															variants [array get variants] \
															options [array get options]]
							set el 1
						}
	}
	
	return $el
}


proc add_multiple_ports { resname ports {remainder ""} } {
	upvar $resname reslist
	
	set version ""
	array unset variants
	array unset options
	parsePortSpec version variants options $remainder
	
	array unset overrides
	if {$version != ""}			{ set overrides(version) $version }
	if {[array size variants]}	{ set overrides(variants) [array get variants] }
	if {[array size options]}	{ set overrides(options) [array get options] }

	add_ports_to_portlist reslist $ports [array get overrides]
}


proc opUnion { a b } {
	set result {}
	
	array unset onetime
	
	# Walk through each array, adding to result only those items that haven't
	# been added before
	foreach item $a {
		array set port $item
		if {[info exists onetime($port(fullname))]} continue
		lappend result $item
	}

	foreach item $b {
		array set port $item
		if {[info exists onetime($port(fullname))]} continue
		lappend result $item
	}
	
	return $result
}


proc opIntersection { a b } {
	set result {}
	
	# Rules we follow in performing the intersection of two port lists:
	#
	#	a/, a/			==> a/
	#	a/, b/			==>
	#	a/, a/1.0		==> a/1.0
	#	a/1.0, a/		==> a/1.0
	#	a/1.0, a/2.0	==>
	#
	#	If there's an exact match, we take it.
	#	If there's a match between simple and descriminated, we take the later.
	
	# First create a list of the fully descriminated names in b
	array unset bfull
	set i 0
	foreach bitem $b {
		array set port $bitem
		set bfull($port(fullname)) $i
		incr i
	}
	
	# Walk through each item in a, matching against b
	#
	# Note: -regexp may not be present in all versions of Tcl we need to work
	# 		against, in which case we may have to fall back to a slower alternative
	#		for those cases. I'm not worrying about that for now, however. -jdb
	foreach aitem $a {
		array set port $aitem
		
		# Quote the fullname and portname to avoid special characters messing up the regexp
		set safefullname [regex_pat_sanitize $port(fullname)]
		
		set simpleform [expr { "$port(name)/" == $port(fullname) }]
		if {$simpleform} {
			set pat "^${safefullname}"
		} else {
			set safename [regex_pat_sanitize $port(name)]
			set pat "^${safefullname}$|^${safename}/$"
		}
		
		set matches [array names bfull -regexp $pat]
		foreach match $matches {
			if {$simpleform} {
				set i $bfull($match)
				lappend result [lindex $b $i]
			} else {
				lappend result $aitem
			}
		}
	}
	
	return $result
}


proc opComplement { a b } {
	set result {}
	
	# Return all elements of a not matching elements in b
	
	# First create a list of the fully descriminated names in b
	array unset bfull
	set i 0
	foreach bitem $b {
		array set port $bitem
		set bfull($port(fullname)) $i
		incr i
	}
	
	# Walk through each item in a, taking all those items that don't match b
	#
	# Note: -regexp may not be present in all versions of Tcl we need to work
	# 		against, in which case we may have to fall back to a slower alternative
	#		for those cases. I'm not worrying about that for now, however. -jdb
	foreach aitem $a {
		array set port $aitem
		
		# Quote the fullname and portname to avoid special characters messing up the regexp
		set safefullname [regex_pat_sanitize $port(fullname)]
		
		set simpleform [expr { "$port(name)/" == $port(fullname) }]
		if {$simpleform} {
			set pat "^${safefullname}"
		} else {
			set safename [regex_pat_sanitize $port(name)]
			set pat "^${safefullname}$|^${safename}/$"
		}
		
		set matches [array names bfull -regexp $pat]

		# We copy this element to result only if it didn't match against b
		if {![llength $matches]} {
			lappend result $aitem
		}
	}
	
	return $result
}


proc parseFullPortSpec { urlname namename vername varname optname } {
	upvar $urlname porturl
	upvar $namename portname
	upvar $vername portversion
	upvar $varname portvariants
	upvar $optname portoptions
	
	set portname ""
	set portversion ""
	array unset portvariants
	array unset portoptions
	
	if { [moreargs] } {
		# Look first for a potential portname
		#
		# We need to allow a wide variaty of tokens here, because of actions like "provides"
		# so we take a rather lenient view of what a "portname" is. We allow
		# anything that doesn't look like either a version, a variant, or an option
		set token [lookahead]

		set remainder ""
		if {![regexp {^(@|[-+]([[:alpha:]_]+[\w\.]*)|[[:alpha:]_]+[\w\.]*=)} $token match]} {
			advance
			regexp {^([^@]+)(@.*)?} $token match portname remainder
			
			# If the portname contains a /, then try to use it as a URL
			if {[string match "*/*" $portname]} {
				set url "file://$portname"
				set name [url_to_portname $url 1]
				if { $name != "" } {
					# We mapped the url to valid port
					set porturl $url
					set portname $name
					# Continue to parse rest of portspec....
				} else {
					# We didn't map the url to a port; treat it
					# as a raw string for something like port contents
					# or cd
					set porturl ""
					# Since this isn't a port, we don't try to parse
					# any remaining portspec....
					return
				}
			}
		}
		
		# Now parse the rest of the spec
		parsePortSpec portversion portvariants portoptions $remainder
	}
}

	
proc parsePortSpec { vername varname optname {remainder ""} } {
	upvar $vername portversion
	upvar $varname portvariants
	upvar $optname portoptions
	
	global global_options
	
	set portversion	""
	array unset portoptions
	array set portoptions [array get global_options]
	array unset portvariants
	
	# Parse port version/variants/options
	set opt $remainder
	set adv 0
	set consumed 0
	for {set firstTime 1} {$opt != "" || [moreargs]} {set firstTime 0} {
	
		# Refresh opt as needed
		if {$opt == ""} {
			if {$adv} advance
			set opt [lookahead]
			set adv 1
			set consumed 0
		}
		
		# Version must be first, if it's there at all
		if {$firstTime && [string match {@*} $opt]} {
			# Parse the version
			
			# Strip the @
			set opt [string range $opt 1 end]
			
			# Handle the version
			set sepPos [string first "/" $opt]
			if {$sepPos >= 0} {
				# Version terminated by "/" to disambiguate -variant from part of version
				set portversion [string range $opt 0 [expr $sepPos-1]]
				set opt [string range $opt [expr $sepPos+1] end]
			} else {
				# Version terminated by "+", or else is complete
				set sepPos [string first "+" $opt]
				if {$sepPos >= 0} {
					# Version terminated by "+"
					set portversion [string range $opt 0 [expr $sepPos-1]]
					set opt [string range $opt $sepPos end]
				} else {
					# Unterminated version
					set portversion $opt
					set opt ""
				}
			}
			set consumed 1
		} else {
			# Parse all other options
			
			# Look first for a variable setting: VARNAME=VALUE
			if {[regexp {^([[:alpha:]_]+[\w\.]*)=(.*)} $opt match key val] == 1} {
				# It's a variable setting
				set portoptions($key) "\"$val\""
				set opt ""
				set consumed 1
			} elseif {[regexp {^([-+])([[:alpha:]_]+[\w\.]*)} $opt match sign variant] == 1} {
				# It's a variant
				set portvariants($variant) $sign
				set opt [string range $opt [expr [string length $variant]+1] end]
				set consumed 1
			} else {
				# Not an option we recognize, so break from port option processing
				if { $consumed && $adv } advance
				break
			}
		}
	}
}


##########################################
# Action Handlers
##########################################

proc action_usage { action portlist opts } {
	print_usage
	return 0
}


proc action_help { action portlist opts } {
	print_help
	return 0
}


proc action_info { action portlist opts } {
	set status 0
	require_portlist portlist
	foreachport $portlist {	
		# Get information about the named port
		if {[catch {dportsearch $portname no exact} result]} {
			global errorInfo
			ui_debug "$errorInfo"
			break_softcontinue "search for portname $portname failed: $result" 1 status
		}
	
		if {$result == ""} {
			puts "No port $portname found."
		} else {
			set found [expr [llength $result] / 2]
			if {$found > 1} {
				ui_warn "Found $found port $portname definitions, displaying first one."
			}
			array set portinfo [lindex $result 1]
			
			
			# Map from friendly to less-friendly but real names
			array set name_map "
					category		categories
					maintainer		maintainers
					platform		platforms
					variant			variants
					"
					
			# Understand which info items are actually lists
			# (this could be overloaded to provide a generic formatting code to
			# allow us to, say, split off the prefix on libs)
			array set list_map "
					categories		1
					depends_build	1
					depends_lib		1
					maintainers		1
					platforms		1
					variants		1
					"
					
			# Set up our field separators
			set show_label 1
			set field_sep "\n"
			set subfield_sep ", "
			
			# Tune for sort(1)
			if {[info exists options(ports_info_line)]} {
				array unset options ports_info_line
				set show_label 0
				set field_sep "\t"
				set subfield_sep ","
			}

			# Figure out whether to show field name
			set quiet [ui_isset ports_quiet]
			if {$quiet} {
				set show_label 0
			}
			
			# Spin through action options, emitting information for any found
			set fields {}
			foreach { option } [array names options ports_info_*] {
				set opt [string range $option 11 end]
				
				# Map from friendly name
				set ropt $opt
				if {[info exists name_map($opt)]} {
					set ropt $name_map($opt)
				}
				
				# If there's no such info, move on
				if {![info exists portinfo($ropt)]} {
					if {!$quiet} {
						puts "no info for '$opt'"
					}
					continue
				}
				
				# Calculate field label
				set label ""
				if {$show_label} {
					set label "$opt: "
				}
				
				# Format the data
				set inf $portinfo($ropt)
				if [info exists list_map($ropt)] {
					set field [join $inf $subfield_sep]
				} else {
					set field $inf
				}
				
				lappend fields "$label$field"
			}
			
			if {[llength $fields]} {
				# Show specific fields
				puts [join $fields $field_sep]
			} else {
			
				# If we weren't asked to show any specific fields, then show general information
				puts -nonewline "$portinfo(name) $portinfo(version)"
				if {[info exists portinfo(revision)] && $portinfo(revision) > 0} { 
					puts -nonewline ", Revision $portinfo(revision)" 
				}
				puts -nonewline ", $portinfo(portdir)" 
				if {[info exists portinfo(variants)]} {
					puts -nonewline " (Variants: "
					for {set i 0} {$i < [llength $portinfo(variants)]} {incr i} {
						if {$i > 0} { puts -nonewline ", " }
						puts -nonewline "[lindex $portinfo(variants) $i]"
					}
					puts -nonewline ")"
				}
				puts ""
				if {[info exists portinfo(homepage)]} { 
					puts "$portinfo(homepage)"
				}
		
				if {[info exists portinfo(long_description)]} {
					puts "\n$portinfo(long_description)\n"
				}
	
				# find build dependencies
				if {[info exists portinfo(depends_build)]} {
					puts -nonewline "Build Dependencies: "
					for {set i 0} {$i < [llength $portinfo(depends_build)]} {incr i} {
						if {$i > 0} { puts -nonewline ", " }
						puts -nonewline "[lindex [split [lindex $portinfo(depends_build) $i] :] end]"
					}
					set nodeps false
					puts ""
				}
		
				# find library dependencies
				if {[info exists portinfo(depends_lib)]} {
					puts -nonewline "Library Dependencies: "
					for {set i 0} {$i < [llength $portinfo(depends_lib)]} {incr i} {
						if {$i > 0} { puts -nonewline ", " }
						puts -nonewline "[lindex [split [lindex $portinfo(depends_lib) $i] :] end]"
					}
					set nodeps false
					puts ""
				}
		
				# find runtime dependencies
				if {[info exists portinfo(depends_run)]} {
					puts -nonewline "Runtime Dependencies: "
					for {set i 0} {$i < [llength $portinfo(depends_run)]} {incr i} {
						if {$i > 0} { puts -nonewline ", " }
						puts -nonewline "[lindex [split [lindex $portinfo(depends_run) $i] :] end]"
					}
					set nodeps false
					puts ""
				}
				if {[info exists portinfo(platforms)]} { puts "Platforms: $portinfo(platforms)"}
				if {[info exists portinfo(maintainers)]} { puts "Maintainers: $portinfo(maintainers)"}
			}
		}
	}
	
	return $status
}


proc action_location { action portlist opts } {
	set status 0
	require_portlist portlist
	foreachport $portlist {
		if { [catch {set ilist [registry_installed $portname [composite_version $portversion [array get variations]]]} result] } {
			global errorInfo
			ui_debug "$errorInfo"
			break_softcontinue "port location failed: $result" 1 status
		} else {
			set version [lindex $ilist 1]
			set revision [lindex $ilist 2]
			set	variants [lindex $ilist 3]
		}

		set ref [registry::open_entry $portname $version $revision $variants]
		if { [string equal [registry::property_retrieve $ref installtype] "image"] } {
			set imagedir [registry::property_retrieve $ref imagedir]
			puts "Port $portname ${version}_${revision}${variants} is installed as an image in:"
			puts $imagedir
		} else {
			break_softcontinue "Port $portname is not installed as an image." 1 status
		}
	}
	
	return $status
}


proc action_provides { action portlist opts } {
	# In this case, portname is going to be used for the filename... since
	# that is the first argument we expect... perhaps there is a better way
	# to do this?
	if { ![llength $portlist] } {
		ui_error "Please specify a filename to check which port provides that file."
		return 1
	}
	foreachport $portlist {
		set file [compat filenormalize $portname]
		if {[file exists $file]} {
			if {![file isdirectory $file]} {
				set port [registry::file_registered $file] 
				if { $port != 0 } {
					puts "$file is provided by: $port"
				} else {
					puts "$file is not provided by a DarwinPorts port."
				}
			} else {
				puts "$file is a directory."
			}
		} else {
			puts "$file does not exist."
		}
	}
	
	return 0
}


proc action_activate { action portlist opts } {
	set status 0
	require_portlist portlist
	foreachport $portlist {
		if { [catch {portimage::activate $portname [composite_version $portversion [array get variations]] [array get options]} result] } {
			global errorInfo
			ui_debug "$errorInfo"
			break_softcontinue "port activate failed: $result" 1 status
		}
	}
	
	return $status
}


proc action_deactivate { action portlist opts } {
	set status 0
	require_portlist portlist
	foreachport $portlist {
		if { [catch {portimage::deactivate $portname [composite_version $portversion [array get variations]] [array get options]} result] } {
			global errorInfo
			ui_debug "$errorInfo"
			break_softcontinue "port deactivate failed: $result" 1 status
		}
	}
	
	return $status
}


proc action_selfupdate { action portlist opts } {
	if { [catch {darwinports::selfupdate [array get global_options]} result ] } {
		global errorInfo
		ui_debug "$errorInfo"
		fatal "selfupdate failed: $result"
	}
	
	return 0
}


proc action_upgrade { action portlist opts } {
	require_portlist portlist
	foreachport $portlist {
		# Merge global variations into the variations specified for this port
		foreach { variation value } [array get global_variations] {
			if { ![info exists variations($variation)] } {
				set variations($variation) $value
			}
		}
		
		darwinports::upgrade $portname "port:$portname" [array get variations] [array get options]
	}
	
	return 0
}


proc action_version { action portlist opts } {
	puts "Version: [darwinports::version]"
	return 0
}


proc action_compact { action portlist opts } {
	set status 0
	require_portlist portlist
	foreachport $portlist {
		if { [catch {portimage::compact $portname [composite_version $portversion [array get variations]]} result] } {
			global errorInfo
			ui_debug "$errorInfo"
			break_softcontinue "port compact failed: $result" 1 status
		}
	}

	return $status
}


proc action_uncompact { action portlist opts } {
	set status 0
	require_portlist portlist
	foreachport $portlist {
		if { [catch {portimage::uncompact $portname [composite_version $portversion [array get variations]]} result] } {
			global errorInfo
			ui_debug "$errorInfo"
			break_softcontinue "port uncompact failed: $result" 1 status
		}
	}
	
	return $status
}



proc action_dependents { action portlist opts } {
	require_portlist portlist
	foreachport $portlist {
		registry::open_dep_map
		set deplist [registry::list_dependents $portname]
 
		if { [llength $deplist] > 0 } {
			set dl [list]
			# Check the deps first
			foreach dep $deplist {
				set depport [lindex $dep 2]
				ui_msg "$depport depends on $portname"
			}
		} else {
			ui_msg "$portname has no dependents!"
		}
	}
	return 0
}


proc action_uninstall { action portlist opts } {
	set status 0
	if {[info exists global_options(port_uninstall_old)]} {
		# if -u then uninstall all inactive ports
		# (union these to any other ports user has in the port list)
		set portlist [opUnion $portlist [get_inactive_ports]]
	} else {
		# Otherwise the user had better have supplied a portlist, or we'll default to the existing directory
		require_portlist portlist
	}

	foreachport $portlist {
		if { [catch {portuninstall::uninstall $portname [composite_version $portversion [array get variations]] [array get options]} result] } {
			global errorInfo
			ui_debug "$errorInfo"
			break_softcontinue "port uninstall failed: $result" 1 status
		}
	}
	
	return 0
}


proc action_installed { action portlist opts } {
	set status 0
	set ilist {}
	if { [llength $portlist] } {
		foreachport $portlist {
			set composite_version [composite_version $portversion [array get variations]]
			if { [catch {set ilist [concat $ilist [registry::installed $portname $composite_version]]} result] } {
				if {[string match "* not registered as installed." $result]} {
					puts "Port $portname is not installed."
				} else {
					global errorInfo
					ui_debug "$errorInfo"
					break_softcontinue "port installed failed: $result" 1 status
				}
			}
		}
	} else {
		if { [catch {set ilist [registry::installed]} result] } {
			if {$result != "Registry error: No ports registered as installed."} {
				global errorInfo
				ui_debug "$errorInfo"
				ui_error "port installed failed: $result"
				set status 1
			}
		}
	}
	if { [llength $ilist] > 0 } {
		puts "The following ports are currently installed:"
		foreach i $ilist {
			set iname [lindex $i 0]
			set iversion [lindex $i 1]
			set irevision [lindex $i 2]
			set ivariants [lindex $i 3]
			set iactive [lindex $i 4]
			if { $iactive == 0 } {
				puts "  $iname @${iversion}_${irevision}${ivariants}"
			} elseif { $iactive == 1 } {
				puts "  $iname @${iversion}_${irevision}${ivariants} (active)"
			}
		}
	} else {
		puts "No ports are installed."
	}
	
	return $status
}


proc action_outdated { action portlist opts } {
	global darwinports::registry.installtype
	set is_image_mode [expr 0 == [string compare "image" ${darwinports::registry.installtype}]]

	set status 0

	# If port names were supplied, limit ourselves to those port, else check all installed ports
	set ilist {}
	if { [llength $portlist] } {
		foreach portspec $portlist {
			array set port $portspec
			set portname $port(name)
			set composite_version [composite_version $port(version) $port(variants)]
			if { [catch {set ilist [concat $ilist [registry::installed $portname $composite_version]]} result] } {
				if {![string match "* not registered as installed." $result]} {
					global errorInfo
					ui_debug "$errorInfo"
					break_softcontinue "port outdated failed: $result" 1 status
				}
			}
		}
	} else {
		if { [catch {set ilist [registry::installed]} result] } {
			if {$result != "Registry error: No ports registered as installed."} {
				global errorInfo
				ui_debug "$errorInfo"
				ui_error "port installed failed: $result"
				set status 1
			}
		}
	}

	if { [llength $ilist] > 0 } {
		puts "The following installed ports are outdated:"
	
		foreach i $ilist { 
		
			# Get information about the installed port
			set portname			[lindex $i 0]
			set installed_version	[lindex $i 1]
			set installed_revision	[lindex $i 2]
			set installed_compound	"${installed_version}_${installed_revision}"

			set is_active			[lindex $i 4]
            if { $is_active == 0 && $is_image_mode } {
				continue
			}
			set installed_epoch		[lindex $i 5]

			# Get info about the port from the index
			if {[catch {set res [dportsearch $portname no exact]} result]} {
				global errorInfo
				ui_debug "$errorInfo"
				break_softcontinue "search for portname $portname failed: $result" 1 status
			}
			if {[llength $res] < 2} {
				if {[ui_isset ports_debug]} {
					puts "$portname ($installed_compound is installed; the port was not found in the port index)"
				}
				continue
			}
			array set portinfo [lindex $res 1]
			
			# Get information about latest available version and revision
			set latest_version $portinfo(version)
			set latest_revision		0
			if {[info exists portinfo(revision)] && $portinfo(revision) > 0} { 
				set latest_revision	$portinfo(revision)
			}
			set latest_compound		"${latest_version}_${latest_revision}"
			set latest_epoch		0
			if {[info exists portinfo(epoch)]} { 
				set latest_epoch	$portinfo(epoch)
			}
			
			# Compare versions, first checking epoch, then the compound version string
			set comp_result [expr $installed_epoch - $latest_epoch]
			if { $comp_result == 0 } {
				set comp_result [rpm-vercomp $installed_compound $latest_compound]
			}
			
			# Report outdated (or, for verbose, predated) versions
			if { $comp_result != 0 } {
							
				# Form a relation between the versions
				set flag ""
				if { $comp_result > 0 } {
					set relation ">"
					set flag "!"
				} else {
					set relation "<"
				}
				
				# Emit information
				if {$comp_result < 0 || [ui_isset ports_verbose]} {
					puts [format "%-30s %-24s %1s" $portname "$installed_compound $relation $latest_compound" $flag]
				}
				
			}
		}
	} else {
		puts "No installed ports are outdated."
	}
	
	return $status
}


proc action_contents { action portlist opts } {
	set status 0
	require_portlist portlist
	foreachport $portlist {
		set files [registry::port_registered $portname]
		if { $files != 0 } {
			if { [llength $files] > 0 } {
				puts "Port $portname contains:"
				foreach file $files {
					puts "  $file"
				}
			} else {
				puts "Port $portname does not contain any file or is not active."
			}
		} else {
			puts "Port $portname is not installed."
		}
	}
	
	return $status
}


proc action_deps { action portlist opts } {
	set status 0
	require_portlist portlist
	foreachport $portlist {
		# Get info about the port
		if {[catch {dportsearch $portname no exact} result]} {
			global errorInfo
			ui_debug "$errorInfo"
			break_softcontinue "search for portname $portname failed: $result" 1 status
		}

		if {$result == ""} {
			break_softcontinue "No port $portname found." 1 status
		}

		array set portinfo [lindex $result 1]

		set depstypes {depends_build depends_lib depends_run}
		set depstypes_descr {"build" "library" "runtime"}

		set nodeps true
		foreach depstype $depstypes depsdecr $depstypes_descr {
			if {[info exists portinfo($depstype)] &&
				$portinfo($depstype) != ""} {
				puts "$portname has $depsdecr dependencies on:"
				foreach i $portinfo($depstype) {
					puts "\t[lindex [split [lindex $i 0] :] end]"
				}
				set nodeps false
			}
		}
		
		# no dependencies found
		if {$nodeps == "true"} {
			puts "$portname has no dependencies"
		}
	}
	
	return $status
}


proc action_variants { action portlist opts } {
	set status 0
	require_portlist portlist
	foreachport $portlist {
		# search for port
		if {[catch {dportsearch $portname no exact} result]} {
			global errorInfo
			ui_debug "$errorInfo"
			break_softcontinue "search for portname $portname failed: $result" 1 status
		}
	
		if {$result == ""} {
			puts "No port $portname found."
		}
	
		array set portinfo [lindex $result 1]
	
		# if this fails the port doesn't have any variants
		if {![info exists portinfo(variants)]} {
			puts "$portname has no variants"
		} else {
			# print out all the variants
			puts "$portname has the variants:"
			for {set i 0} {$i < [llength $portinfo(variants)]} {incr i} {
				puts "\t[lindex $portinfo(variants) $i]"
			}
		}
	}
	
	return $status
}


proc action_search { action portlist opts } {
	set status 0
	if {![llength portlist]} {
		ui_error "You must specify a search pattern"
		return 1
	}
	
	foreachport $portlist {
		set portfound 0
		if {[catch {set res [dportsearch $portname no]} result]} {
			global errorInfo
			ui_debug "$errorInfo"
			break_softcontinue "search for portname $portname failed: $result" 1 status
		}
		foreach {name array} $res {
			array set portinfo $array

			# XXX is this the right place to verify an entry?
			if {![info exists portinfo(name)]} {
				puts "Invalid port entry, missing portname"
				continue
			}
			if {![info exists portinfo(description)]} {
				puts "Invalid port entry for $portinfo(name), missing description"
				continue
			}
			if {![info exists portinfo(version)]} {
				puts "Invalid port entry for $portinfo(name), missing version"
				continue
			}
			if {![info exists portinfo(portdir)]} {
				set output [format "%-30s %-12s %s" $portinfo(name) $portinfo(version) $portinfo(description)]
			} else {
				set output [format "%-30s %-14s %-12s %s" $portinfo(name) $portinfo(portdir) $portinfo(version) $portinfo(description)]
			}
			set portfound 1
			puts $output
			unset portinfo
		}
		if { !$portfound } {
			ui_msg "No match for $portname found"
		}
	}
	
	return $status
}


proc action_list { action portlist opts } {
	set status 0

	# Default to list all ports if no portnames are supplied
	if {![llength $portlist]} {
		add_to_portlist portlist [list name "-all-"]
	}
	
	foreachport $portlist {
		if {$portname == "-all-"} {
			set search_string ".+"
		} else {
			set search_string [regex_pat_sanitize $portname]
		}
		
		if {[catch {set res [dportsearch ^$search_string\$ no]} result]} {
			global errorInfo
			ui_debug "$errorInfo"
			break_softcontinue "search for portname $search_string failed: $result" 1 status
		}

		foreach {name array} $res {
			array set portinfo $array
			set outdir ""
			if {[info exists portinfo(portdir)]} {
				set outdir $portinfo(portdir)
			}
			puts [format "%-30s @%-14s %s" $portinfo(name) $portinfo(version) $outdir]
		}
	}
	
	return $status
}


proc action_echo { action portlist opts } {
	# Simply echo back the port specs given to this command
	foreachport $portlist {
		set opts {}
		foreach { key value } [array get options] {
			lappend opts "$key=$value"
		}
		
		set composite_version [composite_version $portversion [array get variations] 1]
		if { $composite_version != "" } {
			set ver_field "@$composite_version"
		} else {
			set ver_field ""
		}
		puts [format "%-30s %s %s" $portname $ver_field  [join $opts " "]]
	}
	
	return 0
}


proc action_portcmds { action portlist opts } {
	# Operations on the port's directory and Portfile
	global env, boot_env
	global current_portdir
	
	set status 0
	require_portlist portlist
	foreachport $portlist {
		# If we have a url, use that, since it's most specific
		# otherwise try to map the portname to a url
		if {$porturl == ""} {
			# Verify the portname, getting portinfo to map to a porturl
			if {[catch {set res [dportsearch $portname no exact]} result]} {
				global errorInfo
				ui_debug "$errorInfo"
				break_softcontinue "search for portname $portname failed: $result" 1 status
			}
			if {[llength $res] < 2} {
				break_softcontinue "Port $portname not found" 1 status
			}
			array set portinfo [lindex $res 1]
			set porturl $portinfo(porturl)
		}
		
		set portdir [file normalize [darwinports::getportdir $porturl]]
		set porturl "file://${portdir}";	# Rebuild url so it's fully qualified
		set portfile "${portdir}/Portfile"
		
		if {[file readable $portfile]} {
			switch -- $action {
				cat	{
					# Copy the portfile to standard output
					set f [open $portfile RDONLY]
					while { ![eof $f] } {
						puts [read $f 4096]
					}
					close $f
				}
				
				ed - edit {
					# Edit the port's portfile with the user's editor
					
					# Restore our entire environment from start time.
					# We need it to evaluate the editor, and the editor
					# may want stuff from it as well, like TERM.
					array unset env_save; array set env_save [array get env]
					array unset env *; array set env [array get boot_env]
					
					# Find an editor to edit the portfile
					set editor ""
					foreach ed { VISUAL EDITOR } {
						if {[info exists env($ed)]} {
							set editor $env($ed)
							break
						}
					}
					
					# Invoke the editor
					if { $editor == "" } {
						break_softcontinue "No EDITOR is specified in your environment" 1 status
					} else {
						if {[catch {eval exec >/dev/stdout </dev/stdin $editor $portfile} result]} {
							global errorInfo
							ui_debug "$errorInfo"
							break_softcontinue "unable to invoke editor $editor: $result" 1 status
						}
					}
					
					# Restore internal dp environment
					array unset env *; array set env [array get env_save]
				}
				
				dir {
					# output the path to the port's directory
					puts $portdir
				}
				
				cd {
					# Change to the port's directory, making it the default
					# port for any future commands
					set current_portdir $portdir
				}

				url {
					# output the url of the port's directory, suitable to feed back in later as a port descriptor
					puts $porturl
				}

				file {
					# output the path to the port's portfile
					puts $portfile
				}
			}
		} else {
			break_softcontinue "Could not read $portfile" 1 status
		}
	}
	
	return $status
}


proc action_sync { action portlist opts } {
	set status 0
	if {[catch {dportsync} result]} {
		global errorInfo
		ui_debug "$errorInfo"
		ui_msg "port sync failed: $result"
		set status 1
	}
	
	return $status
}


proc action_target { action portlist opts } {
	set status 0
	require_portlist portlist
	foreachport $portlist {
		set target $action

		# If we have a url, use that, since it's most specific
		# otherwise try to map the portname to a url
		if {$porturl == ""} {
			# Verify the portname, getting portinfo to map to a porturl
			if {[catch {set res [dportsearch $portname no exact]} result]} {
				global errorInfo
				ui_debug "$errorInfo"
				break_softcontinue "search for portname $portname failed: $result" 1 status
			}
			if {[llength $res] < 2} {
				break_softcontinue "Port $portname not found" 1 status
			}
			array set portinfo [lindex $res 1]
			set porturl $portinfo(porturl)
		}
		
		# If this is the install target, add any global_variations to the variations
		# specified for the port
		if { $target == "install" } {
			foreach { variation value } [array get global_variations] {
				if { ![info exists variations($variation)] } {
					set variations($variation) $value
				}
			}
		}

		# If version was specified, save it as a version glob for use
		# in port actions (e.g. clean).
		if {[string length $portversion]} {
			set options(ports_version_glob) $portversion
		}
		if {[catch {set workername [dportopen $porturl [array get options] [array get variations]]} result]} {
			global errorInfo
			ui_debug "$errorInfo"
			break_softcontinue "Unable to open port: $result" 1 status
		}
		if {[catch {set result [dportexec $workername $target]} result]} {
			global errorInfo
			dportclose $workername
			ui_debug "$errorInfo"
			break_softcontinue "Unable to execute port: $result" 1 status
		}

		dportclose $workername
		
		# Process any error that wasn't thrown and handled already
		if {$result} {
			break_softcontinue "Status $result encountered during processing." 1 status
		}
	}
	
	return $status
}


proc action_exit { action portlist opts } {
	# Return a semaphore telling the main loop to quit
	return -999
}


##########################################
# Command Parsing
##########################################
proc moreargs {} {
	global cmd_argn cmd_argc
	return [expr {$cmd_argn < $cmd_argc}]
}


proc lookahead {} {
	global cmd_argn cmd_argc cmd_argv
	if {$cmd_argn < $cmd_argc} {
		return [lindex $cmd_argv $cmd_argn]
	} else {
		return _EOF_
	}
}


proc advance {} {
	global cmd_argn
	incr cmd_argn
}


proc match s {
	if {[lookahead] == $s} {
		advance
		return 1
	}
	return 0
}


global action_array
array set action_array {
	usage		action_usage
	help		action_help

	echo		action_echo
	
	info		action_info
	location	action_location
	provides	action_provides
	
	activate	action_activate
	deactivate	action_deactivate
	
	sync		action_sync
	selfupdate	action_selfupdate
	
	upgrade		action_upgrade
	
	version		action_version
	compact		action_compact
	uncompact	action_uncompact
	
	uninstall	action_uninstall
	
	installed	action_installed
	outdated	action_outdated
	contents	action_contents
	dependents	action_dependents
	deps		action_deps
	variants	action_variants
	
	search		action_search
	list		action_list
	
	ed			action_portcmds
	edit		action_portcmds
	cat			action_portcmds
	dir			action_portcmds
	cd			action_portcmds
	url			action_portcmds
	file		action_portcmds
	
	depends		action_target
	fetch		action_target
	checksum	action_target
	extract		action_target
	patch		action_target
	configure	action_target
	build		action_target
	destroot	action_target
	install		action_target
	clean		action_target
	test		action_target
	submit		action_target
	trace		action_target
	livecheck	action_target

	archive		action_target
	unarchive	action_target
	dmg			action_target
	dpkg		action_target
	mpkg		action_target
	pkg			action_target
	rpmpackage	action_target

	quit		action_exit
	exit		action_exit
}


proc find_action_proc { action } {
	global action_array
	
	set action_proc ""
	if { [info exists action_array($action)] } {
		set action_proc $action_array($action)
	}
	
	return $action_proc
}


# Parse global options
#
# Note that this is called several times:
#	(1) Initially, to parse options that will be constant across all commands
#		(options that come prior to any command, frozen into global_options_base)
#	(2) Following each command (to parse options that will be unique to that command
#		(the global_options array is reset to global_options_base prior to each command)
#
proc parse_options { action ui_options_name global_options_name } {
	upvar $ui_options_name ui_options
	upvar $global_options_name global_options
	global cmdname
	
	while {[moreargs]} {
		set arg [lookahead]
		
		if {[string index $arg 0] != "-"} {
			break
		} elseif {[string index $arg 1] == "-"} {
			# Process long arguments
			switch -- $arg {
				--			{ # This is the options terminator; do no further option processing
							  advance; break
							}
				default		{
							  set key [string range $arg 2 end]
							  set global_options(ports_${action}_${key}) yes
							}
			}
		} else {
			# Process short arg(s)
			set opts [string range $arg 1 end]
			foreach c [split $opts {}] {
				switch -- $c {
					v {	set ui_options(ports_verbose) yes			}
					d { set ui_options(ports_debug) yes
						# debug implies verbose
						set ui_options(ports_verbose) yes
					  }
					q { set ui_options(ports_quiet) yes
						set ui_options(ports_verbose) no
						set ui_options(ports_debug) no
					  }
					i { # Always go to interactive mode
						lappend ui_options(ports_commandfiles) -	}
					p { # Ignore errors while processing within a command
						set ui_options(ports_processall) yes		}
					x { # Exit with error from any command while in batch/interactive mode
						set ui_options(ports_exit) yes				}
					
					f { set global_options(ports_force) yes			}
					o { set global_options(ports_ignore_older) yes	}
					n { set global_options(ports_nodeps) yes		}
					u { set global_options(port_uninstall_old) yes	}
					R { set global_options(ports_do_dependents) yes	}
					s { set global_options(ports_source_only) yes	}
					b { set global_options(ports_binary_only) yes	}
					c { set global_options(ports_autoclean) yes		}
					k { set global_options(ports_autoclean) no		}
					t { set global_options(ports_trace) yes			}
					F { # Name a command file to process
						advance
						if {[moreargs]} {
							lappend ui_options(ports_commandfiles) [lookahead]
						}
					  }
					D { advance
						if {[moreargs]} {
							cd [lookahead]
						}
						break
					  }
					default {
						print_usage; exit 1
					  }
				}
			}
		}
		
		advance
	}
}


proc process_cmd { argv } {
	global cmd_argc cmd_argv cmd_argn
	global global_options global_options_base
	global current_portdir
	set cmd_argv $argv
	set cmd_argc [llength $argv]
	set cmd_argn 0

	set action_status 0

	# Process an action if there is one
	while {$action_status == 0 && [moreargs]} {
		set action [lookahead]
		advance
		
		# Handle command separator
		if { $action == ";" } {
			continue
		}
		
		# Handle a comment
		if { [string index $action 0] == "#" } {
			while { [moreargs] } { advance }
			break
		}
		
		# Always start out processing an action in current_portdir
		cd $current_portdir
		
		# Reset global_options from base before each action, as we munge it just below...
		array set global_options $global_options_base
		
		# Parse options that will be unique to this action
		# (to avoid abiguity with -variants and a default port, either -- must be
		# used to terminate option processing, or the pseudo-port current must be specified).
		parse_options $action ui_options global_options
		
		# Parse port specifications into portlist
		set portlist {}
		if {![portExpr portlist]} {
			ui_error "Improper expression syntax while processing parameters"
			set action_status 1
			break
		}

		# Find an action to execute
		set action_proc [find_action_proc $action]
		if { $action_proc != "" } {
			set action_status [$action_proc $action $portlist [array get global_options]]
		} else {
			puts "Unrecognized action \"$action\""
			set action_status 1
		}
		
		# semaphore to exit
		if {$action_status == -999} break

		# If we're not in exit mode then ignore the status from the command
		if { ![ui_isset ports_exit] } {
			set action_status 0
		}
	}
	
	return $action_status
}


proc complete_portname { text state } {	
	global action_array
	global complete_choices complete_position
	
	if {$state == 0} {
		set complete_position 0
		set complete_choices {}

		# Build a list of ports with text as their prefix
		if {[catch {set res [dportsearch "${text}*" false glob]} result]} {
			global errorInfo
			ui_debug "$errorInfo"
			fatal "search for portname $pattern failed: $result"
		}
		foreach {name info} $res {
			lappend complete_choices $name
		}
	}
	
	set word [lindex $complete_choices $complete_position]
	incr complete_position
	
	return $word
}


proc complete_action { text state } {	
	global action_array
	global complete_choices complete_position
	
	if {$state == 0} {
		set complete_position 0
		set complete_choices [array names action_array "[string tolower $text]*"]
	}
	
	set word [lindex $complete_choices $complete_position]
	incr complete_position
	
	return $word
}


proc attempt_completion { text word start end } {
	# If the word starts with '~', or contains '.' or '/', then use the build-in
	# completion to complete the word
	if { [regexp {^~|[/.]} $word] } {
		return ""
	}

	# Decide how to do completion based on where we are in the string
	set prefix [string range $text 0 [expr $start - 1]]
	
	# If only whitespace characters preceed us, or if the
	# previous non-whitespace character was a ;, then we're
	# an action (the first word of a command)
	if { [regexp {(^\s*$)|(;\s*$)} $prefix] } {
		return complete_action
	}
	
	# Otherwise, do completion on portname
	return complete_portname
}


proc get_next_cmdline { in out use_readline prompt linename } {
	upvar $linename line
	
	set line ""
	while { $line == "" } {
	
		if {$use_readline} {
			set len [readline read -attempted_completion attempt_completion line $prompt]
		} else {
			puts -nonewline $out $prompt
			set len [gets $in line]
		}
		
		if { $len < 0 } {
			return -1
		}
		
		set line [string trim $line]
		
		if { $use_readline && $line != "" } {
			rl_history add $line
		}
	}
	
	return [llength $line]
}


proc process_command_file { in } {
	global current_portdir

	# Initialize readline
	set isstdin [string match $in "stdin"]
	set name "port"
	set use_readline [expr $isstdin && [readline init $name]]
	set history_file [file normalize "~/.${name}_history"]
	
	# Read readline history
	if {$use_readline} {
		rl_history read $history_file
		rl_history stifle 100
	}
	
	# Be noisy, if appropriate
	set noisy [expr $isstdin && ![ui_isset ports_quiet]]
	if { $noisy } {
		puts "DarwinPorts [darwinports::version]"
		puts "Entering interactive mode... (\"help\" for help, \"quit\" to quit)"
	}
	
	# Main command loop
	set exit_status 0
	while { $exit_status == 0 } {
	
		# Calculate our prompt
		if { $noisy } {
			set shortdir [eval file join [lrange [file split $current_portdir] end-1 end]]
			set prompt "\[$shortdir\] > "
		} else {
			set prompt ""
		}
		
		# Get a command line
		if { [get_next_cmdline $in stdout $use_readline $prompt line] <= 0  } {
			puts ""
			break
		}
		
		# Process the command
		set exit_status [process_cmd $line]
		
		# Check for semaphore to exit
		if {$exit_status == -999} break
		
		# Ignore status unless we're in error-exit mode
		if { ![ui_isset ports_exit] } {
			set exit_status 0
		}
	}
	
	# Save readine history
	if {$use_readline} {
		rl_history write $history_file
	}
	
	# Say goodbye
	if { $noisy } {
		puts "Goodbye"
	}
	
	return $exit_status
}


proc process_command_files { filelist } {
	set exit_status 0
	
	# For each file in the command list, process commands
	# in the file
	foreach file $filelist {
		if {$file == "-"} {
			set in stdin
		} else {
			
			if {[catch {set in [open $file]} result]} {
				fatal "Failed to open command file; $result"
			}
			
		}
		
		set exit_status [process_command_file $in]
		
		if {$in != "stdin"} {
			close $in
		}

		# Check for semaphore to exit
		if {$exit_status == -999} {
			set exit_status 0
			break
		}
		
		# Ignore status unless we're in error-exit mode
		if { ![ui_isset ports_exit] } {
			set exit_status 0
		}
	}
	
	return $exit_status
}


##########################################
# Main
##########################################

# globals
array set ui_options 		{}
array set global_options	{}
array set global_variations	{}

# Save off a copy of the environment before dportinit monkeys with it
global env boot_env
array set boot_env [array get env]

global argv0
global cmdname
set cmdname [file tail $argv0]

# Setp cmd_argv to match argv
global argc argv
global cmd_argc cmd_argv cmd_argn
set cmd_argv $argv
set cmd_argc $argc
set cmd_argn 0

# If we've been invoked as portf, then the first argument is assumed
# to be the name of a command file (i.e., there is an implicit -F
# before any arguments).
if {[moreargs] && $cmdname == "portf"} {
	lappend ui_options(ports_commandfiles) [lookahead]
	advance
}

# Parse global options that will affect all subsequent commands
parse_options "global" ui_options global_options

# Get arguments remaining after option processing
set remaining_args [lrange $cmd_argv $cmd_argn end]

# Initialize dport
# This must be done following parse of global options, as some options are
# evaluated by dportinit.
if {[catch {dportinit ui_options global_options global_variations} result]} {
	global errorInfo
	puts "$errorInfo"
	fatal "Failed to initialize ports system, $result"
}

# If we have no arguments remaining after option processing then force
# interactive mode
if { [llength $remaining_args] == 0 && ![info exists ui_options(ports_commandfiles)] } {
	lappend ui_options(ports_commandfiles) -
}

# Set up some global state for our code
global current_portdir
set current_portdir [pwd]

# Freeze global_options into global_options_base; global_options
# will be reset to global_options_base prior to processing each command.
global global_options_base
set global_options_base [array get global_options]

# First process any remaining args as action(s)
set exit_status 0
if { [llength $remaining_args] > 0 } {

	# If there are remaining arguments, process those as a command
	
	# Exit immediately, by default, unless we're going to be processing command files
	if {![info exists ui_options(ports_commandfiles)]} {
		set ui_options(ports_exit) yes
	}
	set exit_status [process_cmd $remaining_args]
}

# Process any prescribed command files, including standard input
if { $exit_status == 0 && [info exists ui_options(ports_commandfiles)] } {
	set exit_status [process_command_files $ui_options(ports_commandfiles)]
}

# Return with exit_status
exit $exit_status
