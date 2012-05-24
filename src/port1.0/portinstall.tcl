# et:ts=4
# portinstall.tcl
# $Id$
#
# Copyright (c) 2002 - 2004 Apple Inc.
# Copyright (c) 2004 Robert Shaw <rshaw@opendarwin.org>
# Copyright (c) 2005, 2007 - 2012 The MacPorts Project
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
# 3. Neither the name of Apple Inc. nor the names of its contributors
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

package provide portinstall 1.0
package require portutil 1.0
package require registry2 2.0

set org.macports.install [target_new org.macports.install portinstall::install_main]
target_provides ${org.macports.install} install
target_runtype ${org.macports.install} always
target_requires ${org.macports.install} main archivefetch fetch checksum extract patch configure build destroot
target_prerun ${org.macports.install} portinstall::install_start

namespace eval portinstall {
}

# define options
options install.asroot

# Set defaults
default install.asroot no

set_ui_prefix

proc portinstall::install_start {args} {
    global UI_PREFIX subport version revision portvariants
    global prefix registry_open registry.path
    ui_notice "$UI_PREFIX [format [msgcat::mc "Installing %s @%s_%s%s"] $subport $version $revision $portvariants]"
    
    # start gsoc08-privileges
    if {![file writable $prefix] || ([getuid] == 0 && [geteuid] != 0)} {
        # if install location is not writable, need root privileges to install
        # Also elevate if started as root, since 'file writable' doesn't seem
        # to take euid into account.
        elevateToRoot "install"
    }
    # end gsoc08-privileges
    
    if {![info exists registry_open]} {
        registry::open [file join ${registry.path} registry registry.db]
        set registry_open yes
    }

    # create any users and groups needed by the port
    handle_add_users
}

# fake some info for a list of files to match the format
# used for contents in the flat registry
# This list is a 6-tuple of the form:
# 0: file path
# 1: uid
# 2: gid
# 3: mode
# 4: size
# 5: md5 checksum information
proc portinstall::_fake_fileinfo_for_index {flist} {
    global 
	set rval [list]
	foreach file $flist {
		lappend rval [list $file [getuid] [getgid] 0644 0 "MD5 ($fname) NONE"]
	}
	return $rval
}

proc portinstall::putel { fd el data } {
    # Quote xml data
    set quoted [string map  { & &amp; < &lt; > &gt; } $data]
    # Write the element
    puts $fd "<${el}>${quoted}</${el}>"
}

proc portinstall::putlist { fd listel itemel list } {
    puts $fd "<$listel>"
    foreach item $list {
        putel $fd $itemel $item
    }
    puts $fd "</$listel>"
}

proc portinstall::create_archive {location archive.type} {
    global workpath destpath portpath subport version revision portvariants \
           epoch os.platform PortInfo installPlist \
           archive.env archive.cmd archive.pre_args archive.args \
           archive.post_args archive.dir \
           depends_fetch depends_extract depends_build depends_lib depends_run
    set archive.env {}
    set archive.cmd {}
    set archive.pre_args {}
    set archive.args {}
    set archive.post_args {}
    set archive.dir ${destpath}

    switch -regex -- ${archive.type} {
        cp(io|gz) {
            set pax "pax"
            if {[catch {set pax [findBinary $pax ${portutil::autoconf::pax_path}]} errmsg] == 0} {
                ui_debug "Using $pax"
                set archive.cmd "$pax"
                set archive.pre_args {-w -v -x cpio}
                if {[regexp {z$} ${archive.type}]} {
                    set gzip "gzip"
                    if {[catch {set gzip [findBinary $gzip ${portutil::autoconf::gzip_path}]} errmsg] == 0} {
                        ui_debug "Using $gzip"
                        set archive.args {.}
                        set archive.post_args "| $gzip -c9 > ${location}"
                    } else {
                        ui_debug $errmsg
                        return -code error "No '$gzip' was found on this system!"
                    }
                } else {
                    set archive.args "-f ${location} ."
                }
            } else {
                ui_debug $errmsg
                return -code error "No '$pax' was found on this system!"
            }
        }
        t(ar|bz|lz|xz|gz) {
            set tar "tar"
            if {[catch {set tar [findBinary $tar ${portutil::autoconf::tar_path}]} errmsg] == 0} {
                ui_debug "Using $tar"
                set archive.cmd "$tar"
                set archive.pre_args {-cvf}
                if {[regexp {z2?$} ${archive.type}]} {
                    if {[regexp {bz2?$} ${archive.type}]} {
                        set gzip "bzip2"
                        set level 9
                    } elseif {[regexp {lz$} ${archive.type}]} {
                        set gzip "lzma"
                        set level ""
                    } elseif {[regexp {xz$} ${archive.type}]} {
                        set gzip "xz"
                        set level 6
                    } else {
                        set gzip "gzip"
                        set level 9
                    }
                    if {[info exists portutil::autoconf::${gzip}_path]} {
                        set hint [set portutil::autoconf::${gzip}_path]
                    } else {
                        set hint ""
                    }
                    if {[catch {set gzip [findBinary $gzip $hint]} errmsg] == 0} {
                        ui_debug "Using $gzip"
                        set archive.args {- .}
                        set archive.post_args "| $gzip -c$level > ${location}"
                    } else {
                        ui_debug $errmsg
                        return -code error "No '$gzip' was found on this system!"
                    }
                } else {
                    set archive.args "${location} ."
                }
            } else {
                ui_debug $errmsg
                return -code error "No '$tar' was found on this system!"
            }
        }
        xar {
            set xar "xar"
            if {[catch {set xar [findBinary $xar ${portutil::autoconf::xar_path}]} errmsg] == 0} {
                ui_debug "Using $xar"
                set archive.cmd "$xar"
                set archive.pre_args {-cvf}
                set archive.args "${location} ."
            } else {
                ui_debug $errmsg
                return -code error "No '$xar' was found on this system!"
            }
        }
        xpkg {
            set xar "xar"
            set compression "bzip2"
            set archive.meta yes
            set archive.metaname "xpkg"
            set archive.metapath [file join $workpath "${archive.metaname}.xml"]
            if {[catch {set xar [findBinary $xar ${portutil::autoconf::xar_path}]} errmsg] == 0} {
                ui_debug "Using $xar"
                set archive.cmd "$xar"
                set archive.pre_args "-cv --exclude='\./\+.*' --compression=${compression} -n ${archive.metaname} -s ${archive.metapath} -f"
                set archive.args "${location} ."
            } else {
                ui_debug $errmsg
                return -code error "No '$xar' was found on this system!"
            }
        }
        zip {
            set zip "zip"
            if {[catch {set zip [findBinary $zip ${portutil::autoconf::zip_path}]} errmsg] == 0} {
                ui_debug "Using $zip"
                set archive.cmd "$zip"
                set archive.pre_args {-ry9}
                set archive.args "${location} ."
            } else {
                ui_debug $errmsg
                return -code error "No '$zip' was found on this system!"
            }
        }
    }

    set archive.fulldestpath [file dirname $location]
    # Create archive destination path (if needed)
    if {![file isdirectory ${archive.fulldestpath}]} {
        file mkdir ${archive.fulldestpath}
    }

    # Create (if no files) destroot for archiving
    if {![file isdirectory ${destpath}]} {
        return -code error "no destroot found at: ${destpath}"
    }

    # Copy state file into destroot for archiving
    # +STATE contains a copy of the MacPorts state information
    set statefile [file join $workpath .macports.${subport}.state]
    file copy -force $statefile [file join $destpath "+STATE"]

    # Copy Portfile into destroot for archiving
    # +PORTFILE contains a copy of the MacPorts Portfile
    set portfile [file join $portpath Portfile]
    file copy -force $portfile [file join $destpath "+PORTFILE"]

    # Create some informational files that we don't really use just yet,
    # but we may in the future in order to allow port installation from
    # archives without a full "ports" tree of Portfiles.
    #
    # Note: These have been modeled after FreeBSD type package files to
    # start. We can change them however we want for actual future use if
    # needed.
    #
    # +COMMENT contains the port description
    set fd [open [file join $destpath "+COMMENT"] w]
    if {[exists description]} {
        puts $fd "[option description]"
    }
    close $fd
    # +DESC contains the port long_description and homepage
    set fd [open [file join $destpath "+DESC"] w]
    if {[exists long_description]} {
        puts $fd "[option long_description]"
    }
    if {[exists homepage]} {
        puts $fd "\nWWW: [option homepage]"
    }
    close $fd
    # +CONTENTS contains the port version/name info and all installed
    # files and checksums
    set control [list]
    set fd [open [file join $destpath "+CONTENTS"] w]
    puts $fd "@name ${subport}-${version}_${revision}${portvariants}"
    puts $fd "@portname ${subport}"
    puts $fd "@portepoch ${epoch}"
    puts $fd "@portversion ${version}"
    puts $fd "@portrevision ${revision}"
    puts $fd "@archs [get_canonical_archs]"
    array set ourvariations $PortInfo(active_variants)
    set vlist [lsort -ascii [array names ourvariations]]
    foreach v $vlist {
        if {$ourvariations($v) == "+"} {
            puts $fd "@portvariant +${v}"
        }
    }

    foreach key "depends_lib depends_run" {
         if {[info exists $key]} {
             foreach depspec [set $key] {
                 set depname [lindex [split $depspec :] end]
                 set dep [mport_lookup $depname]
                 if {[llength $dep] < 2} {
                     ui_debug "Dependency $depname not found"
                 } else {
                     array set portinfo [lindex $dep 1]
                     set depver $portinfo(version)
                     set deprev $portinfo(revision)
                     puts $fd "@pkgdep $portinfo(name)-${depver}_${deprev}"
                 }
             }
         }
    }

    # also save the contents for our own use later
    set installPlist {}
    fs-traverse -depth fullpath $destpath {
        if {[file type $fullpath] == "directory"} {
            continue
        }
        set relpath [strsed $fullpath "s|^$destpath/||"]
        if {![regexp {^[+]} $relpath]} {
            puts $fd "$relpath"
            lappend installPlist [file join [file separator] $relpath]
            if {[file isfile $fullpath]} {
                ui_debug "checksum file: $fullpath"
                set checksum [md5 file $fullpath]
                puts $fd "@comment MD5:$checksum"
            }
        } else {
            lappend control $relpath
        }
    }
    foreach relpath $control {
        puts $fd "@ignore"
        puts $fd "$relpath"
    }
    close $fd

    # the XML package metadata, for XAR package
    # (doesn't contain any file list/checksums)
    if {[tbool archive.meta]} {
        set sd [open ${archive.metapath} w]
        puts $sd "<xpkg version='0.2'>"
        # TODO: split contents into <buildinfo> (new) and <package> (current)
        #       see existing <portpkg> for the matching source package layout

        putel $sd name ${subport}
        putel $sd epoch ${epoch}
        putel $sd version ${version}
        putel $sd revision ${revision}
        putel $sd major 0
        putel $sd minor 0

        putel $sd platform ${os.platform}
        if {[llength [get_canonical_archs]] > 1} {
            putlist $sd archs arch [get_canonical_archs]
        } else {
            putel $sd arch [get_canonical_archs]
        }
        putlist $sd variants variant $vlist

        if {[exists categories]} {
            set primary [lindex [split [option categories] " "] 0]
            putel $sd category $primary
        }
        if {[exists description]} {
            putel $sd comment "[option description]"
        }
        if {[exists long_description]} {
            putel $sd desc "[option long_description]"
        }
        if {[exists homepage]} {
            putel $sd homepage "[option homepage]"
        }

            # Emit dependencies provided by this package
            puts $sd "<provides>"
                puts $sd "<item>"
                putel $sd name $subport
                putel $sd major 0
                putel $sd minor 0
                puts $sd "</item>"
            puts $sd "</provides>"


            # Emit build, library, and runtime dependencies
            puts $sd "<requires>"
            foreach {key type} {
                depends_fetch "fetch"
                depends_extract "extract"
                depends_build "build"
                depends_lib "library"
                depends_run "runtime"
            } {
                if {[info exists $key]} {
                    set depname [lindex [split [set $key] :] end]
                    puts $sd "<item type=\"$type\">"
                    putel $sd name $depname
                    putel $sd major 0
                    putel $sd minor 0
                    puts $sd "</item>"
                }
            }
            puts $sd "</requires>"

        puts $sd "</xpkg>"
        close $sd
    }

    # Now create the archive
    ui_debug "Creating [file tail $location]"
    command_exec archive
    ui_debug "Archive [file tail $location] packaged"

    # Cleanup all control files when finished
    set control_files [glob -nocomplain -types f [file join $destpath +*]]
    foreach file $control_files {
        ui_debug "removing file: $file"
        file delete -force $file
    }
}

proc portinstall::extract_contents {location type} {
    set qflag ${portutil::autoconf::tar_q}
    switch -- $type {
        tbz -
        tbz2 {
            set raw_contents [exec [findBinary tar ${portutil::autoconf::tar_path}] -xOj${qflag}f $location ./+CONTENTS]
        }
        tgz {
            set raw_contents [exec [findBinary tar ${portutil::autoconf::tar_path}] -xOz${qflag}f $location ./+CONTENTS]
        }
        tar {
            set raw_contents [exec [findBinary tar ${portutil::autoconf::tar_path}] -xO${qflag}f $location ./+CONTENTS]
        }
        txz {
            set raw_contents [exec [findBinary tar ${portutil::autoconf::tar_path}] -xO${qflag}f $location --use-compress-program [findBinary xz ""] ./+CONTENTS]
        }
        tlz {
            set raw_contents [exec [findBinary tar ${portutil::autoconf::tar_path}] -xO${qflag}f $location --use-compress-program [findBinary lzma ""] ./+CONTENTS]
        }
        xar {
            system "cd ${workpath} && [findBinary xar ${portutil::autoconf::xar_path}] -xf $location +CONTENTS"
            set twostep 1
        }
        xpkg {
            system "cd ${workpath} && [findBinary xar ${portutil::autoconf::xar_path}] -xf $location --compression=bzip2 +CONTENTS"
            set twostep 1
        }
        zip {
            set raw_contents [exec [findBinary unzip ${portutil::autoconf::unzip_path}] -p $location +CONTENTS]
        }
        cpgz {
            system "cd ${workpath} && [findBinary pax ${portutil::autoconf::pax_path}] -rzf $location +CONTENTS"
            set twostep 1
        }
        cpio {
            system "cd ${workpath} && [findBinary pax ${portutil::autoconf::pax_path}] -rf $location +CONTENTS"
            set twostep 1
        }
    }
    if {[info exists twostep]} {
        set fd [open "${workpath}/+CONTENTS"]
        set raw_contents [read $fd]
        close $fd
    }
    set contents {}
    set ignore 0
    set sep [file separator]
    foreach line [split $raw_contents \n] {
        if {$ignore} {
            set ignore 0
            continue
        }
        if {[string index $line 0] != "@"} {
            lappend contents "${sep}${line}"
        } elseif {$line == "@ignore"} {
            set ignore 1
        }
    }
    return $contents
}

proc portinstall::install_main {args} {
    global subport version portpath categories description long_description \
    homepage depends_run package-install workdir workpath \
    worksrcdir UI_PREFIX destroot revision maintainers user_options \
    portvariants negated_variants targets depends_lib PortInfo epoch license \
    os.platform os.major portarchivetype installPlist

    set oldpwd [pwd]
    if {$oldpwd == ""} {
        set oldpwd $portpath
    }

    set location [get_portimage_path]
    set archive_path [find_portarchive_path]
    if {$archive_path != ""} {
        set install_dir [file dirname $location]
        file mkdir $install_dir
        file rename -force $archive_path $install_dir
        set location [file join $install_dir [file tail $archive_path]]
        set current_archive_type [string range [file extension $location] 1 end]
        set installPlist [extract_contents $location $current_archive_type]
    } else {
        # throws an error if an unsupported value has been configured
        archiveTypeIsSupported $portarchivetype
        # create archive from the destroot
        create_archive $location $portarchivetype
    }

    # can't do this inside the write transaction due to deadlock issues with _get_dep_port
    set dep_portnames [list]
    foreach deplist {depends_lib depends_run} {
        if {[info exists $deplist]} {
            foreach dep [set $deplist] {
                set dep_portname [_get_dep_port $dep]
                if {$dep_portname != ""} {
                    lappend dep_portnames $dep_portname
                }
            }
        }
    }

    registry::write {

        set regref [registry::entry create $subport $version $revision $portvariants $epoch]

        if {[info exists user_options(ports_requested)]} {
            $regref requested $user_options(ports_requested)
        } else {
            $regref requested 0
        }
        $regref os_platform ${os.platform}
        $regref os_major ${os.major}
        $regref archs [get_canonical_archs]
        # Trick to have a portable GMT-POSIX epoch-based time.
        $regref date [expr [clock scan now -gmt true] - [clock scan "1970-1-1 00:00:00" -gmt true]]
        if {[info exists negated_variants]} {
            $regref negated_variants $negated_variants
        }

        foreach dep_portname $dep_portnames {
            $regref depends $dep_portname
        }

        $regref installtype image
        $regref state imaged
        $regref location $location

        if {[info exists installPlist]} {
            # register files
            $regref map $installPlist
        }
        
        # store portfile
        set fd [open [file join ${portpath} Portfile]]
        $regref portfile [read $fd]
        close $fd
    }

    _cd $oldpwd
    return 0
}

# apparent usage of pkg_uninstall variable in the (flat) registry
# the Portfile needs to define a procedure
# proc pkg_uninstall {portname portver} {
#     body of proc
# }
# which gets stored above in the receipt's pkg_uninstall property
# this is then called by the portuninstall procedure
# note that the portuninstall procedure is not called within
# the context of the portfile so many usual port variables do not exist
# e.g. destroot/workpath/filespath
 
# this procedure encodes the pkg_uninstall body so that it can be stored in the
# the receipt file
proc portinstall::proc_disasm {pname} {
    set p "proc "
    append p $pname " {"
    set space ""
    foreach arg [info args $pname] {
        if {[info default $pname $arg value]} {
            append p "$space{" [list $arg $value] "}"
        } else {
            append p $space $arg
        }
        set space " "
    }
    append p "} {" [string map { \n \\n } [info body $pname] ] " }"
    return $p
}
