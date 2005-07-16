# darwinports.tcl
#
# Copyright (c) 2002 Apple Computer, Inc.
# Copyright (c) 2004 - 2005 Paul Guyot, Darwinports Team.
# Copyright (c) 2004 Ole Guldberg Jensen <olegb@opendarwin.org>.
# Copyright (c) 2004 - 2005 Robert Shaw <rshaw@opendarwin.org>
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
package provide darwinports 1.0
package require darwinports_dlist 1.0
package require darwinports_index 1.0
package require portutil 1.0

namespace eval darwinports {
    namespace export bootstrap_options portinterp_options open_dports
    variable bootstrap_options "portdbpath libpath binpath auto_path sources_conf prefix portdbformat portinstalltype portarchivemode portarchivepath portarchivetype portautoclean destroot_umask variants_conf rsync_server rsync_options rsync_dir xcodeversion xcodebuildcmd"
    variable portinterp_options "portdbpath portpath portbuildpath auto_path prefix portsharepath registry.path registry.format registry.installtype portarchivemode portarchivepath portarchivetype portautoclean destroot_umask rsync_server rsync_options rsync_dir xcodeversion xcodebuildcmd"
	
    variable open_dports {}
}

# Provided UI instantiations
# For standard messages, the following priorities are defined
#     debug, info, msg, warn, error
# Clients of the library are expected to provide ui_puts with the following prototype.
#     proc ui_puts {message}
# message is a tcl list of array element pairs, defined as such:
#     version   - ui protocol version
#     priority  - message priority
#     data      - message data
# ui_puts should handle the above defined priorities

foreach priority "debug info msg error warn" {
    eval "proc ui_$priority {str} \{ \n\
	set message(priority) $priority \n\
	set message(data) \$str \n\
	ui_puts \[array get message\] \n\
    \}"
}

proc darwinports::ui_event {context message} {
    array set postmessage $message
    set postmessage(context) $context
    ui_puts [array get postmessage]
}

# Replace puts to catch errors (typically broken pipes when being piped to head)
rename puts tcl::puts
proc puts {args} {
	catch "tcl::puts $args"
}

proc dportinit {args} {
    global auto_path env darwinports::portdbpath darwinports::bootstrap_options darwinports::portinterp_options darwinports::portconf darwinports::sources darwinports::sources_conf darwinports::portsharepath darwinports::registry.path darwinports::autoconf::dports_conf_path darwinports::registry.format darwinports::registry.installtype darwinports::upgrade darwinports::destroot_umask darwinports::variants_conf darwinports::selfupdate darwinports::rsync_server darwinports::rsync_dir darwinports::rsync_options darwinports::xcodeversion
	global options variations

    # first look at PORTSRC for testing/debugging
    if {[llength [array names env PORTSRC]] > 0} {
	set PORTSRC [lindex [array get env PORTSRC] 1]
	if {[file isfile ${PORTSRC}]} {
	    set portconf ${PORTSRC}
	    lappend conf_files ${portconf}
	}
    }

    # then look in ~/.portsrc
    if {![info exists portconf]} {
	if {[llength [array names env HOME]] > 0} {
	    set HOME [lindex [array get env HOME] 1]
	    if {[file isfile [file join ${HOME} .portsrc]]} {
		set portconf [file join ${HOME} .portsrc]
		lappend conf_files ${portconf}
	    }
	}
    }

    # finally /etc/ports/ports.conf, or whatever path was configured
    if {![info exists portconf]} {
	if {[file isfile $dports_conf_path/ports.conf]} {
	    set portconf $dports_conf_path/ports.conf
	    lappend conf_files $dports_conf_path/ports.conf
	}
    }
    if {[info exists conf_files]} {
	foreach file $conf_files {
	    set fd [open $file r]
	    while {[gets $fd line] >= 0} {
		foreach option $bootstrap_options {
		    if {[regexp "^$option\[ \t\]+(\[A-Za-z0-9_:,\./-\]+$)" $line match val] == 1} {
			set darwinports::$option $val
			global darwinports::$option
		    }
		}
	    }
        }
    }

    if {![info exists sources_conf]} {
        return -code error "sources_conf must be set in $dports_conf_path/ports.conf or in your ~/.portsrc"
    }
    if {[catch {set fd [open $sources_conf r]} result]} {
        return -code error "$result"
    }
    while {[gets $fd line] >= 0} {
        set line [string trimright $line]
        if {![regexp {[\ \t]*#.*|^$} $line]} {
            lappend sources $line
	}
    }
    if {![info exists sources]} {
	if {[file isdirectory dports]} {
	    set sources "file://[pwd]/dports"
	} else {
	    return -code error "No sources defined in $sources_conf"
	}
    }

	if {[info exists variants_conf]} {
		if {[file exist $variants_conf]} {
			if {[catch {set fd [open $variants_conf r]} result]} {
				return -code error "$result"
			}
			while {[gets $fd line] >= 0} {
				set line [string trimright $line]
				if {![regexp {^[\ \t]*#.*$|^$} $line]} {
					foreach arg [split $line " \t"] {
						if {[regexp {^([-+])([-A-Za-z0-9_+\.]+)$} $arg match sign opt] == 1} {
							if {![info exists variations($opt)]} {
								set variations($opt) $sign
							}
						} else {
							ui_warn "$variants_conf specifies invalid variant syntax '$arg', ignored."
						}
					}
				}
			}
		} else {
			ui_debug "$variants_conf does not exist, variants_conf setting ignored."
		}
	}

    if {![info exists portdbpath]} {
	return -code error "portdbpath must be set in $dports_conf_path/ports.conf or in your ~/.portsrc"
    }
    if {![file isdirectory $portdbpath]} {
	if {![file exists $portdbpath]} {
	    if {[catch {file mkdir $portdbpath} result]} {
		return -code error "portdbpath $portdbpath does not exist and could not be created: $result"
	    }
	}
    }
    if {![file isdirectory $portdbpath]} {
	return -code error "$portdbpath is not a directory. Please create the directory $portdbpath and try again"
    }

    set registry.path $portdbpath
    if {![file isdirectory ${registry.path}]} {
	if {![file exists ${registry.path}]} {
	    if {[catch {file mkdir ${registry.path}} result]} {
		return -code error "portdbpath ${registry.path} does not exist and could not be created: $result"
	    }
	}
    }
    if {![file isdirectory ${darwinports::registry.path}]} {
	return -code error "${darwinports::registry.path} is not a directory. Please create the directory $portdbpath and try again"
    }

	# Format for receipts, can currently be either "flat" or "sqlite"
	if {[info exists portdbformat]} {
		if { $portdbformat == "sqlite" } {
			return -code error "SQLite is not yet supported for registry storage."
		} 
		set registry.format receipt_${portdbformat}
	} else {
		set registry.format receipt_flat
	}

	# Installation type, whether to use port "images" or install "direct"
	if {[info exists portinstalltype]} {
		set registry.installtype $portinstalltype
	} else {
		set registry.installtype image
	}
    
	# Autoclean mode, whether to automatically call clean after "install"
	if {![info exists portautoclean]} {
		set darwinports::portautoclean "yes"
		global darwinports::portautoclean
	}
	# Check command line override for autoclean
	if {[info exists options(ports_autoclean)]} {
		if {![string equal $options(ports_autoclean) $portautoclean]} {
			set darwinports::portautoclean $options(ports_autoclean)
		}
	}

	# Archive mode, whether to create/use binary archive packages
	if {![info exists portarchivemode]} {
		set darwinports::portarchivemode "yes"
		global darwinports::portarchivemode
	}

	# Archive path, where to store/retrieve binary archive packages
	if {![info exists portarchivepath]} {
		set darwinports::portarchivepath [file join $portdbpath packages]
		global darwinports::portarchivepath
	}
	if {$portarchivemode == "yes"} {
		if {![file isdirectory $portarchivepath]} {
			if {![file exists $portarchivepath]} {
				if {[catch {file mkdir $portarchivepath} result]} {
					return -code error "portarchivepath $portarchivepath does not exist and could not be created: $result"
				}
			}
		}
		if {![file isdirectory $portarchivepath]} {
			return -code error "$portarchivepath is not a directory. Please create the directory $portarchivepath and try again"
		}
	}

	# Archive type, what type of binary archive to use (CPIO, gzipped
	# CPIO, XAR, etc.)
	if {![info exists portarchivetype]} {
		set darwinports::portarchivetype "cpgz"
		global darwinports::portarchivetype
	}
	# Convert archive type to a list for multi-archive support, colon or
	# comma separators indicates to use multiple archive formats
	# (reading and writing)
	set darwinports::portarchivetype [split $portarchivetype {:,}]

	# Set rync options
	if {![info exists rsync_server]} {
		set darwinports::rsync_server rsync.opendarwin.org
		global darwinports::rsync_server
	}
	if {![info exists rsync_dir]} {
		set darwinports::rsync_dir dpupdate1/base/
		global darwinports::rsync_dir
	}
	if {![info exists rsync_options]} {
		set rsync_options "-rtzv --delete --delete-after"
		global darwinports::rsync_options
	}

    set portsharepath ${prefix}/share/darwinports
    if {![file isdirectory $portsharepath]} {
	return -code error "Data files directory '$portsharepath' must exist"
    }
    
    if {![info exists libpath]} {
	set libpath "${prefix}/share/darwinports/Tcl"
    }

    if {![info exists binpath]} {
	set env(PATH) "${prefix}/bin:${prefix}/sbin:/bin:/sbin:/usr/bin:/usr/sbin:/usr/X11R6/bin"
    } else {
	set env(PATH) "$binpath"
    }

	if {![info exists xcodeversion] || ![info exists xcodebuildcmd]} {
		if {[catch {set xcodebuild [binaryInPath "xcodebuild"]}] == 0} {
			if {![info exists xcodeversion]} {
				# Determine xcode version (<= 2.0 or 2.1)
				if {[catch {set xcodebuildversion [exec xcodebuild -version]}] == 0} {
					if {[regexp "DevToolsCore-(.*); DevToolsSupport-(.*)" $xcodebuildversion devtoolscore_v devtoolssupport_v] == 1} {
						if {$devtoolscore_v >= 620.0 && $devtoolssupport_v >= 610.0} {
							# for now, we don't need to distinguish 2.1 from 2.1 or higher.
							set darwinports::xcodeversion "2.1"
						} else {
							set darwinports::xcodeversion "2.0orlower"
						}
					} else {
						set darwinports::xcodeversion "2.0orlower"
					}
				} else {
					set darwinports::xcodeversion "2.0orlower"
				}
			}
			
			if {![info exists xcodebuildcmd]} {
				set darwinports::xcodebuildcmd "xcodebuild"
			}
		} elseif {[catch {set pbxbuild [binaryInPath "pbxbuild"]}] == 0} {
			if {![info exists xcodeversion]} {
				set darwinports::xcodeversion "pb"
			}
			if {![info exists xcodebuildcmd]} {
				set darwinports::xcodebuildcmd "pbxbuild"
			}
		} else {
			if {![info exists xcodeversion]} {
				set darwinports::xcodeversion "none"
			}
			if {![info exists xcodebuildcmd]} {
				set darwinports::xcodebuildcmd "none"
			}
		}

		global darwinports::xcodeversion
		global darwinports::xcodebuildcmd
	}

    # Set the default umask
    if {![info exists destroot_umask]} {
        set destroot_umask 022
    }

    if {[info exists master_site_local] && ![info exists env(MASTER_SITE_LOCAL)]} {
	set env(MASTER_SITE_LOCAL) "$master_site_local"
    }

	# Prebinding. useful with MacOS X's ld, harmless elsewhere.
	# With both variables, prebiding will always succeed but we might need
	# to redo it.
    if {![info exists env(LD_PREBIND)] && ![info exists env(LD_PREBIND_ALLOW_OVERLAP)]} {
	set env(LD_PREBIND) "1"
	set env(LD_PREBIND_ALLOW_OVERLAP) "1"
    }

    if {[file isdirectory $libpath]} {
		lappend auto_path $libpath
		set darwinports::auto_path $auto_path

		# XXX: not sure if this the best place, but it needs to happen
		# early, and after auto_path has been set.  Or maybe Pextlib
		# should ship with darwinports1.0 API?
		package require Pextlib 1.0
		package require registry 1.0
    } else {
		return -code error "Library directory '$libpath' must exist"
    }
}

proc darwinports::worker_init {workername portpath portbuildpath options variations} {
    global darwinports::portinterp_options auto_path registry.installtype

	# Tell the sub interpreter about all the Tcl packages we already
	# know about so it won't glob for packages.
	foreach pkgName [package names] {
		foreach pkgVers [package versions $pkgName] {
			set pkgLoadScript [package ifneeded $pkgName $pkgVers]
			$workername eval "package ifneeded $pkgName $pkgVers {$pkgLoadScript}"
		}
	}

    # Create package require abstraction procedure
    $workername eval "proc PortSystem \{version\} \{ \n\
			package require port \$version \}"

    foreach proc {dportexec dportopen dportclose dportsearch} {
        $workername alias $proc $proc
    }

    # instantiate the UI call-back
    $workername alias ui_event darwinports::ui_event $workername

	# New Registry/Receipts stuff
	$workername alias registry_new registry::new_entry
	$workername alias registry_open registry::open_entry
	$workername alias registry_write registry::write_entry
	$workername alias registry_prop_store registry::property_store
	$workername alias registry_prop_retr registry::property_retrieve
	$workername alias registry_delete registry::delete_entry
	$workername alias registry_exists registry::entry_exists
	$workername alias registry_activate portimage::activate
	$workername alias registry_deactivate portimage::deactivate
	$workername alias registry_register_deps registry::register_dependencies
	$workername alias registry_fileinfo_for_index registry::fileinfo_for_index
	$workername alias registry_bulk_register_files registry::register_bulk_files
	$workername alias registry_installed registry::installed

    foreach opt $portinterp_options {
	if {![info exists $opt]} {
	    global darwinports::$opt
	}
        if {[info exists $opt]} {
            $workername eval set system_options($opt) \"[set $opt]\"
            $workername eval set $opt \"[set $opt]\"
        } #"
    }

    foreach {opt val} $options {
        $workername eval set user_options($opt) $val
        $workername eval set $opt $val
    }

    foreach {var val} $variations {
        $workername eval set variations($var) $val
    }

    if { [info exists registry.installtype] } {
	    $workername eval set installtype ${registry.installtype}
    }
}

proc darwinports::fetch_port {url} {
    global darwinports::portdbpath tcl_platform
    set fetchdir [file join $portdbpath portdirs]
    set fetchfile [file tail $url]
    if {[catch {file mkdir $fetchdir} result]} {
        return -code error $result
    }
    if {![file writable $fetchdir]} {
    	return -code error "Port remote fetch failed: You do not have permission to write to $fetchdir"
    }
    if {[catch {exec curl -L -s -S -o [file join $fetchdir $fetchfile] $url} result]} {
        return -code error "Port remote fetch failed: $result"
    }
    if {[catch {cd $fetchdir} result]} {
	return -code error $result
    }
    if {[catch {exec tar -zxf $fetchfile} result]} {
	return -code error "Port extract failed: $result"
    }
    if {[regexp {(.+).tgz} $fetchfile match portdir] != 1} {
        return -code error "Can't decipher portdir from $fetchfile"
    }
    return [file join $fetchdir $portdir]
}

proc darwinports::getprotocol {url} {
    if {[regexp {(?x)([^:]+)://.+} $url match protocol] == 1} {
        return ${protocol}
    } else {
        return -code error "Can't parse url $url"
    }
}

# XXX: this really needs to be rethought in light of the remote index
# I've added the destdir parameter.  This is the location a remotely
# fetched port will be downloaded to (currently only applies to
# dports:// sources).
proc darwinports::getportdir {url {destdir "."}} {
	if {[regexp {(?x)([^:]+)://(.+)} $url match protocol string] == 1} {
		switch -regexp -- ${protocol} {
			{^file$} {
				return $string
			}
			{^dports$} {
				return [darwinports::index::fetch_port $url $destdir]
			}
			{^https?$|^ftp$} {
				return [darwinports::fetch_port $url]
			}
			default {
				return -code error "Unsupported protocol $protocol"
			}
		}
	} else {
		return -code error "Can't parse url $url"
	}
}

# dportopen
# Opens a DarwinPorts portfile specified by a URL.  The portfile is
# opened with the given list of options and variations.  The result
# of this function should be treated as an opaque handle to a
# DarwinPorts Portfile.

proc dportopen {porturl {options ""} {variations ""} {nocache ""}} {
    global darwinports::portinterp_options darwinports::portdbpath darwinports::portconf darwinports::open_dports auto_path

	# Look for an already-open DPort with the same URL.
	# XXX: should compare options and variations here too.
	# if found, return the existing reference and bump the refcount.
	if {$nocache != ""} {
		set dport {}
	} else {
		set dport [dlist_search $darwinports::open_dports porturl $porturl]
	}
	if {$dport != {}} {
		set refcnt [ditem_key $dport refcnt]
		incr refcnt
		ditem_key $dport refcnt $refcnt
		return $dport
	}

	array set options_array $options
	if {[info exists options_array(portdir)]} {
		set portdir $options_array(portdir)
	} else {
		set portdir ""
	}

	set portdir [darwinports::getportdir $porturl $portdir]
	ui_debug "Changing to port directory: $portdir"
	cd $portdir
	set portpath [pwd]
	set workername [interp create]

	set dport [ditem_create]
	lappend darwinports::open_dports $dport
	ditem_key $dport porturl $porturl
	ditem_key $dport portpath $portpath
	ditem_key $dport workername $workername
	ditem_key $dport options $options
	ditem_key $dport variations $variations
	ditem_key $dport refcnt 1

    darwinports::worker_init $workername $portpath [darwinports::getportbuildpath $porturl] $options $variations
    if {![file isfile Portfile]} {
        return -code error "Could not find Portfile in $portdir"
    }

    $workername eval source Portfile
	
    ditem_key $dport provides [$workername eval return \$portname]

    return $dport
}

# Traverse a directory with ports, calling a function on the path of ports
# (at the second depth).
# I.e. the structure of dir shall be:
# category/port/
# with a Portfile file in category/port/
#
# func:		function to call on every port directory (it is passed
#			category/port/ as its parameter)
# root:		the directory with all the categories directories.
proc dporttraverse {func {root .}} {
	# Save the current directory
	set pwd [pwd]
	
	# Join the root.
	set pathToRoot [file join $pwd $root]

	# Go to root because some callers expects us to be there.
	cd $pathToRoot

    foreach category [lsort -increasing -unique [readdir $root]] {
    	set pathToCategory [file join $root $category]
        if {[file isdirectory $pathToCategory]} {
        	# Iterate on port directories.
			foreach port [lsort -increasing -unique [readdir $pathToCategory]] {
				set pathToPort [file join $pathToCategory $port]
				if {[file isdirectory $pathToPort] &&
					[file exists [file join $pathToPort "Portfile"]]} {
					# Call the function.
					$func [file join $category $port]
					
					# Restore the current directory because some
					# functions changes it.
					cd $pathToRoot
				}
			}
        }
	}
	
	# Restore the current directory.
	cd $pwd
}

### _dportsearchpath is private; subject to change without notice

# depregex -> regex on the filename to find.
# search_path -> directories to search
# executable -> whether we want to check that the file is executable by current
#				user or not.
proc _dportsearchpath {depregex search_path {executable 0}} {
    set found 0
    foreach path $search_path {
	if {![file isdirectory $path]} {
	    continue
	}

	if {[catch {set filelist [readdir $path]} result]} {
		return -code error "$result ($path)"
		set filelist ""
	}

	foreach filename $filelist {
	    if {[regexp $depregex $filename] &&
	    	(($executable == 0) || [file executable [file join $path $filename]])} {
		ui_debug "Found Dependency: path: $path filename: $filename regex: $depregex"
		set found 1
		break
	    }
	}
    }
    return $found
}

### _libtest is private; subject to change without notice
# XXX - Architecture specific
# XXX - Rely on information from internal defines in cctools/dyld:
# define DEFAULT_FALLBACK_FRAMEWORK_PATH
# /Library/Frameworks:/Library/Frameworks:/Network/Library/Frameworks:/System/Library/Frameworks
# define DEFAULT_FALLBACK_LIBRARY_PATH /lib:/usr/local/lib:/lib:/usr/lib
#   -- Since /usr/local is bad, using /lib:/usr/lib only.
# Environment variables DYLD_FRAMEWORK_PATH, DYLD_LIBRARY_PATH,
# DYLD_FALLBACK_FRAMEWORK_PATH, and DYLD_FALLBACK_LIBRARY_PATH take precedence

proc _libtest {dport depspec} {
    global env tcl_platform
	set depline [lindex [split $depspec :] 1]
	set prefix [_dportkey $dport prefix]
	
	if {[info exists env(DYLD_FRAMEWORK_PATH)]} {
	    lappend search_path $env(DYLD_FRAMEWORK_PATH)
	} else {
	    lappend search_path /Library/Frameworks /Network/Library/Frameworks /System/Library/Frameworks
	}
	if {[info exists env(DYLD_FALLBACK_FRAMEWORK_PATH)]} {
	    lappend search_path $env(DYLD_FALLBACK_FRAMEWORK_PATH)
	}
	if {[info exists env(DYLD_LIBRARY_PATH)]} {
	    lappend search_path $env(DYLD_LIBRARY_PATH)
	}
	lappend search_path /lib /usr/lib /usr/X11R6/lib ${prefix}/lib
	if {[info exists env(DYLD_FALLBACK_LIBRARY_PATH)]} {
	    lappend search_path $env(DYLD_LIBRARY_PATH)
	}

	set i [string first . $depline]
	if {$i < 0} {set i [string length $depline]}
	set depname [string range $depline 0 [expr $i - 1]]
	set depversion [string range $depline $i end]
	regsub {\.} $depversion {\.} depversion
	if {$tcl_platform(os) == "Darwin"} {
		set depregex \^${depname}${depversion}\\.dylib\$
	} else {
		set depregex \^${depname}\\.so${depversion}\$
	}

	return [_dportsearchpath $depregex $search_path]
}

### _bintest is private; subject to change without notice

proc _bintest {dport depspec} {
    global env
	set depregex [lindex [split $depspec :] 1]
	set prefix [_dportkey $dport prefix] 
	
	set search_path [split $env(PATH) :]
	
	set depregex \^$depregex\$
	
	return [_dportsearchpath $depregex $search_path 1]
}

### _pathtest is private; subject to change without notice

proc _pathtest {dport depspec} {
    global env
	set depregex [lindex [split $depspec :] 1]
	set prefix [_dportkey $dport prefix] 
    
	# separate directory from regex
	set fullname $depregex

	regexp {^(.*)/(.*?)$} "$fullname" match search_path depregex

	if {[string index $search_path 0] != "/"} {
		# Prepend prefix if not an absolute path
		set search_path "${prefix}/${search_path}"
	}

	set depregex \^$depregex\$

	return [_dportsearchpath $depregex $search_path]
}

### _porttest is private; subject to change without notice

proc _porttest {dport depspec} {
	# We don't actually look for the port, but just return false
	# in order to let the dportdepends handle the dependency
	return 0
}

### _dportinstalled is private; may change without notice

# Determine if a port is already *installed*, as in "in the registry".
proc _dportinstalled {dport} {
	# Check for the presense of the port in the registry
	set workername [ditem_key $dport workername]
	set res [$workername eval registry_exists \${portname} \${portversion}]
	if {$res != 0} {
		ui_debug "[ditem_key $dport provides] is installed"
		return 1
	} else {
		return 0
	}
}

### _dportispresent is private; may change without notice

# Determine if some depspec is satisfied or if the given port is installed.
# We actually start with the registry (faster?)
#
# dport		the port to test (to figure out if it's present)
# depspec	the dependency test specification (path, bin, lib, etc.)
proc _dportispresent {dport depspec} {
	# Check for the presense of the port in the registry
	set workername [ditem_key $dport workername]
	ui_debug "Searching for dependency: [ditem_key $dport provides]"
	if {[catch {set reslist [$workername eval registry_installed \${portname}]} res]} {
		set res 0
	} else {
		set res [llength $reslist]
	}
	if {$res != 0} {
		ui_debug "Found Dependency: receipt exists for [ditem_key $dport provides]"
		return 1
	} else {
		# The receipt test failed, use one of the depspec regex mechanisms
		ui_debug "Didn't find receipt, going to depspec regex for: [ditem_key $dport provides]"
		set type [lindex [split $depspec :] 0]
		switch $type {
			lib { return [_libtest $dport $depspec] }
			bin { return [_bintest $dport $depspec] }
			path { return [_pathtest $dport $depspec] }
			port { return [_porttest $dport $depspec] }
			default {return -code error "unknown depspec type: $type"}
		}
		return 0
	}
}

### _dportexec is private; may change without notice

proc _dportexec {target dport} {
	# xxx: set the work path?
	set workername [ditem_key $dport workername]
	if {![catch {$workername eval eval_variants variations $target} result] && $result == 0 &&
		![catch {$workername eval eval_targets $target} result] && $result == 0} {
		# If auto-clean mode, clean-up after dependency install
		if {[string equal ${darwinports::portautoclean} "yes"]} {
			# Make sure we are back in the port path before clean
			# otherwise if the current directory had been changed to
			# inside the port,  the next port may fail when trying to
			# install because [pwd] will return a "no file or directory"
			# error since the directory it was in is now gone.
			set portpath [ditem_key $dport portpath]
			catch {cd $portpath}
			$workername eval eval_targets clean
		}
		return 0
	} else {
		# An error occurred.
		return 1
	}
}

# dportexec
# Execute the specified target of the given dport.

proc dportexec {dport target} {
    global darwinports::portinterp_options darwinports::registry.installtype

	set workername [ditem_key $dport workername]

	# XXX: move this into dportopen?
	if {[$workername eval eval_variants variations $target] != 0} {
		return 1
	}
	
	# Before we build the port, we must build its dependencies.
	# XXX: need a more general way of comparing against targets
	set dlist {}
	if {$target == "package"} {
		ui_warn "package target replaced by pkg target, please use the pkg target in the future."
		set target "pkg"
	}
	if {$target == "configure" || $target == "build"
		|| $target == "destroot" || $target == "install"
		|| $target == "archive"
		|| $target == "pkg" || $target == "mpkg"
		|| $target == "rpmpackage" || $target == "dpkg" } {

		if {[dportdepends $dport 1 1] != 0} {
			return 1
		}
		
		# Select out the dependents along the critical path,
		# but exclude this dport, we might not be installing it.
		set dlist [dlist_append_dependents $darwinports::open_dports $dport {}]
		
		dlist_delete dlist $dport

		# install them
		# xxx: as with below, this is ugly.  and deps need to be fixed to
		# understand Port Images before this can get prettier
		if { [string equal ${darwinports::registry.installtype} "image"] } {
			set result [dlist_eval $dlist _dportinstalled [list _dportexec "activate"]]
		} else {
			set result [dlist_eval $dlist _dportinstalled [list _dportexec "install"]]
		}
		
		if {$result != {}} {
			set errstring "The following dependencies failed to build:"
			foreach ditem $result {
				append errstring " [ditem_key $ditem provides]"
			}
			ui_error $errstring
			return 1
		}
		
		# Close the dependencies, we're done installing them.
		foreach ditem $dlist {
			dportclose $ditem
		}
	}

	# If we're doing an install, check if we should clean after
	set clean 0
	if {[string equal ${darwinports::portautoclean} "yes"] && [string equal $target "install"] } {
		set clean 1
	}

	# If we're doing image installs, then we should activate after install
	# xxx: This isn't pretty
	if { [string equal ${darwinports::registry.installtype} "image"] && [string equal $target "install"] } {
		set target activate
	}
	
	# Build this port with the specified target
	set result [$workername eval eval_targets $target]

	# If auto-clean mode and successful install, clean-up after install
	if {$result == 0 && $clean == 1} {
		# Make sure we are back in the port path, just in case
		set portpath [ditem_key $dport portpath]
		catch {cd $portpath}
		$workername eval eval_targets clean
	}

	return $result
}

proc darwinports::getsourcepath {url} {
	global darwinports::portdbpath
	regsub {://} $url {.} source_path
	regsub -all {/} $source_path {_} source_path
	return [file join $portdbpath sources $source_path]
}

proc darwinports::getportbuildpath {porturl} {
	global darwinports::portdbpath
	regsub {://} $porturl {.} port_path
	regsub -all {/} $port_path {_} port_path
	return [file join $portdbpath build $port_path]
}

proc darwinports::getindex {source} {
	# Special case file:// sources
	if {[darwinports::getprotocol $source] == "file"} {
		return [file join [darwinports::getportdir $source] PortIndex]
	}

	return [file join [darwinports::getsourcepath $source] PortIndex]
}

proc dportsync {args} {
	global darwinports::sources darwinports::portdbpath tcl_platform

	foreach source $sources {
		ui_info "Synchronizing from $source"
		switch -regexp -- [darwinports::getprotocol $source] {
			{^file$} {
				continue
			}
			{^dports$} {
				darwinports::index::sync $darwinports::portdbpath $source
			}
			{^rsync$} {
				# Where to, boss?
				set destdir [file dirname [darwinports::getindex $source]]

				if {[catch {file mkdir $destdir} result]} {
					return -code error $result
				}

				# Keep rsync happy with a trailing slash
				if {[string index $source end] != "/"} {
					set source "${source}/"
				}

				# Do rsync fetch
				if {[catch {system "rsync -rtzv --delete-after --delete \"$source\" \"$destdir\""}]} {
					return -code error "sync failed doing rsync"
				}
			}
			{^https?$|^ftp$} {
				set indexfile [darwinports::getindex $source]
				if {[catch {file mkdir [file dirname $indexfile]} result]} {
					return -code error $result
				}
				exec curl -L -s -S -o $indexfile $source/PortIndex
			}
		}
	}
}

proc dportsearch {regexp {case_sensitive "yes"}} {
	global darwinports::portdbpath darwinports::sources
	set matches [list]

	set found 0
	foreach source $sources {
		if {[darwinports::getprotocol $source] == "dports"} {
			array set attrs [list name $regexp]
			set res [darwinports::index::search $darwinports::portdbpath $source [array get attrs]]
			eval lappend matches $res
		} else {
			if {[catch {set fd [open [darwinports::getindex $source] r]} result]} {
				ui_warn "Can't open index file for source: $source"
			} else {
				incr found 1
				while {[gets $fd line] >= 0} {
					set name [lindex $line 0]
					if {$case_sensitive == "yes"} {
						set rxres [regexp -- $regexp $name]
					} else {
						set rxres [regexp -nocase -- $regexp $name]
					}
					if {$rxres == 1} {
						gets $fd line
						array set portinfo $line
						switch -regexp -- [darwinports::getprotocol ${source}] {
							{^rsync$} {
								# Rsync files are local
								set source_url "file://[darwinports::getsourcepath $source]"
							}
							default {
								set source_url $source
							}
						}
						if {[info exists portinfo(portarchive)]} {
							set porturl ${source_url}/$portinfo(portarchive)
						} elseif {[info exists portinfo(portdir)]} {
							set porturl ${source_url}/$portinfo(portdir)
						}
						if {[info exists porturl]} {
							lappend line porturl $porturl
							ui_debug "Found port in $porturl"
						} else {
							ui_debug "Found port info: $line"
						}
						lappend matches $name
						lappend matches $line
					} else {
						set len [lindex $line 1]
						catch {seek $fd $len current}
					}
				}
				close $fd
			}
		}
	}
	if {!$found} {
		return -code error "No index(es) found! Have you synced your source indexes?"
	}

	return $matches
}

proc dportinfo {dport} {
	set workername [ditem_key $dport workername]
    return [$workername eval array get PortInfo]
}

proc dportclose {dport} {
	global darwinports::open_dports
	set refcnt [ditem_key $dport refcnt]
	incr refcnt -1
	ditem_key $dport refcnt $refcnt
	if {$refcnt == 0} {
		dlist_delete darwinports::open_dports $dport
		set workername [ditem_key $dport workername]
		interp delete $workername
	}
}

##### Private Depspec API #####
# This API should be considered work in progress and subject to change without notice.
##### "

# _dportkey
# - returns a variable from the port's interpreter

proc _dportkey {dport key} {
	set workername [ditem_key $dport workername]
	return [$workername eval "return \$${key}"]
}

# dportdepends builds the list of dports which the given port depends on.
# This list is added to $dport.
# - optionally includes the build dependencies in the list.
# - optionally recurses through the dependencies, looking for dependencies
#	of dependencies.

proc dportdepends {dport includeBuildDeps recurseDeps {accDeps {}}} {
	array set portinfo [dportinfo $dport]
	set depends {}
	if {[info exists portinfo(depends_run)]} { eval "lappend depends $portinfo(depends_run)" }
	if {[info exists portinfo(depends_lib)]} { eval "lappend depends $portinfo(depends_lib)" }
	if {$includeBuildDeps != "" && [info exists portinfo(depends_build)]} {
		eval "lappend depends $portinfo(depends_build)"
	}

	set subPorts {}
	
	foreach depspec $depends {
		# grab the portname portion of the depspec
		set portname [lindex [split $depspec :] end]
		
		# Find the porturl
		if {[catch {set res [dportsearch "^$portname\$"]} error]} {
			ui_error "Internal error: port search failed: $error"
			return 1
		}
		foreach {name array} $res {
			array set portinfo $array
			if {[info exists portinfo(porturl)]} {
				set porturl $portinfo(porturl)
				break
			}
		}

		if {![info exists porturl]} {
			ui_error "Dependency '$portname' not found."
			return 1
		}

		set options [ditem_key $dport options]
		set variations [ditem_key $dport variations]

		# Figure out the subport.	
		set subport [dportopen $porturl $options $variations]

		# Is that dependency satisfied or this port installed?
		# If not, add it to the list. Otherwise, don't.
		if {![_dportispresent $subport $depspec]} {
			# Append the sub-port's provides to the port's requirements list.
			ditem_append_unique $dport requires "[ditem_key $subport provides]"
	
			if {$recurseDeps != ""} {
				# Skip the port if it's already in the accumulated list.
				if {[lsearch $accDeps $portname] == -1} {
					# Add it to the list
					lappend accDeps $portname
				
					# We'll recursively iterate on it.
					lappend subPorts $subport
				}
			}
		}
	}

	# Loop on the subports.
	if {$recurseDeps != ""} {
		foreach subport $subPorts {
			set res [dportdepends $subport $includeBuildDeps $recurseDeps $accDeps]
			if {$res != 0} {
				return $res
			}
		}
	}
	
	return 0
}

# selfupdate procedure
proc darwinports::selfupdate {args} {
	global darwinports::prefix darwinports::rsync_server darwinports::rsync_dir darwinports::rsync_options options

	if { [info exists options(ports_force)] && $options(ports_force) == "yes" } {
		set use_the_force_luke yes
		ui_debug "Forcing a rebuild of the darwinports base system."
	} else {
		set use_the_force_luke no
		ui_debug "Rebuilding the darwinports base system if needed."
	}
	# syncing ports tree. We expect the user have rsync:// in teh sources.conf
	if {[catch {dportsync} result]} {
		return -code error "Couldnt sync dports tree: $result"
	}

	set dp_base_path [file join $prefix var/db/dports/sources/rsync.${rsync_server}_${rsync_dir}/]
	if {![file exists $dp_base_path]} {
		file mkdir $dp_base_path
	}
	ui_debug "DarwinPorts base dir: $dp_base_path"

	# get user of the darwinports system
	set user [file attributes [file join $prefix var/db/dports/sources/] -owner]
	ui_debug "Setting user: $user"

	# get darwinports version 
	set dp_version_path [file join ${prefix}/etc/ports/ dp_version]
	if { [file exists $dp_version_path]} {
		set fd [open $dp_version_path r]
		gets $fd dp_version_old
	} else {
		set dp_version_old 0
	}
	ui_msg "DarwinPorts base version $dp_version_old installed"

	ui_debug "Updating using rsync"
	if { [catch { system "/usr/bin/rsync $rsync_options rsync://${rsync_server}/${rsync_dir} $dp_base_path" } ] } {
		return -code error "Error: rsync failed in selfupdate"
	}

	# get new darwinports version and write the old version back
	set fd [open [file join $dp_base_path dp_version] r]
	gets $fd dp_version_new
	close $fd
	ui_msg "New DarwinPorts base version $dp_version_new"

	# check if we we need to rebuild base
	if {$dp_version_new > $dp_version_old || $use_the_force_luke == "yes"} {
		ui_msg "Configuring, Building and Installing new DarwinPorts base"
		# check if $prefix/bin/port is writable, if so we go !
		# get installation user / group 
		set owner root
		set group admin
		if {[file exists [file join $prefix bin/port] ]} {
			# set owner
			set owner [file attributes [file join $prefix bin/port] -owner]
			# set group
			set group [file attributes [file join $prefix bin/port] -group]
		}
		set p_user [exec /usr/bin/whoami]
		if {[file writable ${prefix}/bin/port] || [string equal $p_user $owner] } {
			ui_debug "permissions OK"
		} else {
			return -code error "Error: $p_user cannot write to ${prefix}/bin - try using sudo"
		}
		ui_debug "Setting owner: $owner group: $group"

		set dp_tclpackage_path [file join $prefix var/db/dports/ .tclpackage]
		if { [file exists $dp_tclpackage_path]} {
			set fd [open $dp_tclpackage_path r]
				gets $fd tclpackage
		} else {
			set tclpackage [file join ${prefix} share/darwinports/Tcl]
		}
		# do the actual installation of new base
		ui_debug "Install in: $prefix as $owner : $group - TCL-PACKAGE in $tclpackage"
		if { [catch { system "cd $dp_base_path && ./configure --prefix=$prefix --with-install-user=$owner --with-install-group=$group --with-tclpackage=$tclpackage && make && make install" } result] } {
			return -code error "Error installing new DarwinPorts base: $result"
		}
	}

	# set the darwinports system to the right owner 
	ui_debug "Setting ownership to $user"
	if { [catch { exec chown -R $user [file join $prefix var/db/dports/sources/] } result] } {
		return -code error "Couldn't change permissions: $result"
	}

	# set the right version
	ui_msg "selfupdate done!"

	return 0
}

proc darwinports::version {} {
	global darwinports::prefix darwinports::rsync_server darwinports::rsync_dir
	
	set dp_version_path [file join $prefix etc/ports/ dp_version]

	if [file exists $dp_version_path] {
		set fd [open $dp_version_path r]
		gets $fd retval
		return $retval
	} else {
		return -1
	}
}

# upgrade procedure
proc darwinports::upgrade {pname dspec} {
	# globals
	global options variations

	# set to no-zero is epoch overrides version
	set epoch_override 0

	# check if pname contains \, if so remove it. 
	if { [regexp {\\} $pname] } {
		set portname [join $pname {\\}]
		ui_debug "removing stray ecape-character for $portname"
	} else {
		set portname $pname
	}

	# check if the port is in tree
	if {[catch {dportsearch ^$pname$} result]} {
		ui_error "port search failed: $result"
		return 1
	}
	# argh! port doesnt exist!
	if {$result == ""} {
		ui_error "No port $portname found."
		return 1
	}
	# fill array with information
	array set portinfo [lindex $result 1]

	# set version_in_tree
	if {![info exists portinfo(version)]} {
		ui_error "Invalid port entry for $portname, missing version"
		return 1
	}
	set version_in_tree "$portinfo(version)_$portinfo(revision)"
	set epoch_in_tree "$portinfo(epoch)"

	# the depflag tells us if we should follow deps (this is for stuff installed outside DP)
	# if this is set (not 0) we dont follow the deps
	set depflag 0

	# set version_installed
	set ilist {}
	if { [catch {set ilist [registry::installed $portname ""]} result] } {
		if {$result == "Registry error: $portname not registered as installed." } {
			ui_debug "$portname is *not* installed by DarwinPorts"
			# open porthandle    
			set porturl $portinfo(porturl)
		    if {![info exists porturl]} {
		        set porturl file://./    
			}    
			if {[catch {set workername [dportopen $porturl [array get options] ]} result]} {
			        ui_error "Unable to open port: $result"        
					return 1
		    }

			if {![_dportispresent $workername $dspec ] } {
				# port in not installed - install it!
				if {[catch {set result [dportexec $workername install]} result]} {
					ui_error "Unable to exec port: $result"
					return 1
				}
			} else {
				# port installed outside DP
				ui_debug "$portname installed outside the DarwinPorts system"
				set depflag 1
			}

		} else {
			ui_error "Checking installed version failed: $result"
			exit 1
		}
	}
	set anyactive 0
	set version_installed 0
	set epoch_installed 0
	if {$ilist == ""} {
		# XXX  this sets $version_installed to $version_in_tree even if not installed!!
		set version_installed $version_in_tree
	} else {
		# a port could be installed but not activated
		# so, deactivate all and save newest for activation later
		set num 0
		set variant ""
		foreach i $ilist {
			set variant [lindex $i 3]
			set version "[lindex $i 1]_[lindex $i 2]"
			if { [rpm-vercomp $version $version_installed] > 0} {
				set version_installed $version
				set epoch_installed [registry::property_retrieve [registry::open_entry $portname [lindex $i 1] [lindex $i 2] $variant] epoch]
				set num $i
			}

			set isactive [lindex $i 4]
			if {$isactive == 1 && [rpm-vercomp $version_installed $version] < 0 } {
				# deactivate version
    			if {[catch {portimage::deactivate $portname $version} result]} {
    	    		ui_error "Deactivating $portname $version_installed failed: $result"
    	    		return 1
    			}
			}
		}
		if { [lindex $num 4] == 0} {
			# activate the latest installed version
			if {[catch {portimage::activate $portname $version_installed$variant} result]} {
    			ui_error "Activating $portname $version_installed failed: $result"
				return 1
			}
		}
	}

	# output version numbers
	ui_debug "epoch: in tree: $epoch_in_tree installed: $epoch_installed"
	ui_debug "$portname $version_in_tree exists in the ports tree"
	ui_debug "$portname $version_installed is installed"

	# set the nodeps option  
	if {![info exists options(ports_nodeps)]} {
		set nodeps no
	} else {	
		set nodeps yes
	}

	if {$nodeps == "yes" || $depflag == 1} {
		ui_debug "Not following dependencies"
		set depflag 0
	} else {
		# build depends is upgraded
		if {[info exists portinfo(depends_build)]} {
			foreach i $portinfo(depends_build) {
				set d [lindex [split $i :] end]
				upgrade $d $i
			}
		}
		# library depends is upgraded
		if {[info exists portinfo(depends_lib)]} {
			foreach i $portinfo(depends_lib) {
				set d [lindex [split $i :] end]
				upgrade $d $i
			}
		}
		# runtime depends is upgraded
		if {[info exists portinfo(depends_run)]} {
			foreach i $portinfo(depends_run) {
				set d [lindex [split $i :] end]
				upgrade $d $i
			}
		}
	}

	# check installed version against version in ports
	if { [rpm-vercomp $version_installed $version_in_tree] >= 0 } {
		ui_debug "No need to upgrade! $portname $version_installed >= $portname $version_in_tree"
		if { $epoch_installed >= $epoch_in_tree } {
			return 0
		} else {
			ui_debug "epoch override ... upgrading!"
			set epoch_override 1
		}
	}

	# open porthandle
	set porturl $portinfo(porturl)
	if {![info exists porturl]} {
		set porturl file://./
	}

	# check if the variants is present in $version_in_tree
	set oldvariant $variant
	set variant [split $variant +]
	ui_debug "variants to install $variant"
	if {[info exists portinfo(variants)]} {
		set avariants $portinfo(variants)
	} else {
		set avariants {}
	}
	ui_debug "available variants are : $avariants"
	foreach v $variant {
		if {[lsearch $avariants $v] == -1} {
		} else {
			ui_debug "variant $v is present in $portname $version_in_tree"
			set variations($v) "+"
		}
	}
	ui_debug "new portvariants: [array get variations]"
	
	if {[catch {set workername [dportopen $porturl [array get options] [array get variations]]} result]} {
		ui_error "Unable to open port: $result"
		return 1
	}

	# install version_in_tree
	if {[catch {set result [dportexec $workername destroot]} result] || $result != 0} {
		ui_error "Unable to upgrade port: $result"
		return 1
	}

	# uninstall old ports
	if {[info exists options(port_uninstall_old)] || $epoch_override == 1} {
		# uninstalll old
		ui_debug "Uninstalling $portname $version_installed$oldvariant"
		if {[catch {portuninstall::uninstall $portname $version_installed$oldvariant} result]} {
     		ui_error "Uninstall $portname $version_installed$oldvariant failed: $result"
       		return 1
    	}
	} else {
		# XXX deactivate version_installed
		if {[catch {portimage::deactivate $portname $version_installed$oldvariant} result]} {
			ui_error "Deactivating $portname $version_installed failed: $result"
			return 1
		}
	}

	if {[catch {set result [dportexec $workername install]} result]} {
		ui_error "Couldn't activate $portname $version_in_tree$oldvariant: $result"
		return 1
	}
	
	# close the port handle
	dportclose $workername
}
