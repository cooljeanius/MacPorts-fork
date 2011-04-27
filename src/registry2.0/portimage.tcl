# -*- coding: utf-8; mode: tcl; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- vim:fenc=utf-8:ft=tcl:et:sw=4:ts=4:sts=4
# portimage.tcl
# $Id$
#
# Copyright (c) 2004 Will Barton <wbb4@opendarwin.org>
# Copyright (c) 2002 Apple Inc.
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

package provide portimage 2.0

package require registry 1.0
package require registry2 2.0
package require registry_util 2.0
package require macports 1.0
package require Pextlib 1.0

set UI_PREFIX "--> "

# Port Images are installations of the destroot of a port into a compressed
# tarball in ${macports::registry.path}/software/${name}.
# They allow the user to install multiple versions of the same port, treating
# each revision and each different combination of variants as a "version".
#
# From there, the user can "activate" a port image.  This extracts the port's
# files from the image into the ${prefix}.  Directories are created.
# Activation checks the registry's file_map for any files which conflict with
# other "active" ports, and will not overwrite the links to the those files.
# The conflicting port must be deactivated first.
#
# The user can also "deactivate" an active port.  This will remove all the
# port's files from ${prefix}, and if any directories are empty, remove them
# as well. It will also remove all of the references of the files from the 
# registry's file_map.


namespace eval portimage {

variable force 0
variable use_reg2 0
variable noexec 0

# Activate a "Port Image"
proc activate {name v optionslist} {
    global macports::prefix macports::registry.format macports::registry.path registry_open UI_PREFIX
    array set options $optionslist
    variable force
    variable use_reg2
    variable noexec

    if {[info exists options(ports_force)] && [string is true -strict $options(ports_force)] } {
        set force 1
    }
    if {[info exists options(ports_activate_no-exec)]} {
        set noexec $options(ports_activate_no-exec)
    }
    if {[string equal ${macports::registry.format} "receipt_sqlite"]} {
        set use_reg2 1
        if {![info exists registry_open]} {
            registry::open [file join ${macports::registry.path} registry registry.db]
            set registry_open yes
        }
    }
    set todeactivate [list]

    if {$use_reg2} {
        registry::read {

            set requested [_check_registry $name $v]
            # set name again since the one we were passed may not have had the correct case
            set name [$requested name]
            set version [$requested version]
            set revision [$requested revision]
            set variants [$requested variants]
            set specifier "${version}_${revision}${variants}"
            set location [$requested location]

            # if another version of this port is active, deactivate it first
            set current [registry::entry installed $name]
            foreach i $current {
                if { ![string equal $specifier "[$i version]_[$i revision][$i variants]"] } {
                    lappend todeactivate $i
                }
            }

            # this shouldn't be possible
            if { ![string equal [$requested installtype] "image"] } {
                return -code error "Image error: ${name} @${version}_${revision}${variants} not installed as an image."
            }
            if {![file isfile $location]} {
                return -code error "Image error: Can't find image file $location"
            }
            if { [string equal [$requested state] "installed"] } {
                return -code error "Image error: ${name} @${version}_${revision}${variants} is already active."
            }
        }
        foreach a $todeactivate {
            if {$noexec || ![registry::run_target $a deactivate [list ports_nodepcheck 1]]} {
                deactivate $name "[$a version]_[$a revision][$a variants]" [list ports_nodepcheck 1]
            }
        }
    } else {
        # registry1.0
        set ilist [_check_registry $name $v]
        # set name again since the one we were passed may not have had the correct case
        set name [lindex $ilist 0]
        set version [lindex $ilist 1]
        set revision [lindex $ilist 2]
        set variants [lindex $ilist 3]

        # if another version of this port is active, deactivate it first
        set ilist [registry::installed $name]
        if { [llength $ilist] > 1 } {
            foreach i $ilist {
                set iversion [lindex $i 1]
                set irevision [lindex $i 2]
                set ivariants [lindex $i 3]
                set iactive [lindex $i 4]
                if { ![string equal "${iversion}_${irevision}${ivariants}" "${version}_${revision}${variants}"] && $iactive == 1 } {
                    lappend todeactivate "${iversion}_${irevision}${ivariants}"
                }
            }
        }

        set ref [registry::open_entry $name $version $revision $variants]

        if { ![string equal [registry::property_retrieve $ref installtype] "image"] } {
            return -code error "Image error: ${name} @${version}_${revision}${variants} not installed as an image."
        }
        set location [registry::property_retrieve $ref location]
        if {![file isfile $location]} {
            return -code error "Image error: Can't find image file $location"
        }
        if { [registry::property_retrieve $ref active] != 0 } {
            return -code error "Image error: ${name} @${version}_${revision}${variants} is already active."
        }

        foreach a $todeactivate {
            deactivate $name $a [list ports_nodepcheck 1]
        }
    }

    if {$v != ""} {
        ui_msg "$UI_PREFIX [format [msgcat::mc "Activating %s @%s"] $name $v]"
    } else {
        ui_msg "$UI_PREFIX [format [msgcat::mc "Activating %s"] $name]"
    }

    if {$use_reg2} {
        _activate_contents $requested
        $requested state installed
    } else {
        set contents [registry::property_retrieve $ref contents]

        set imagefiles {}
        foreach content_element $contents {
            lappend imagefiles [lindex $content_element 0]
        }

        registry::open_file_map
        _activate_contents $name $imagefiles $location

        registry::property_store $ref active 1

        registry::write_entry $ref

        foreach file $imagefiles {
            registry::register_file $file $name
        }
        registry::write_file_map
        registry::close_file_map
    }
}

proc deactivate {name v optionslist} {
    global UI_PREFIX macports::registry.format macports::registry.path registry_open
    array set options $optionslist
    variable use_reg2

    if {[info exists options(ports_force)] && [string is true -strict $options(ports_force)] } {
        # this not using the namespace variable is correct, since activate
        # needs to be able to force deactivate independently of whether
        # the activation is being forced
        set force 1
    } else {
        set force 0
    }
    if {[string equal ${macports::registry.format} "receipt_sqlite"]} {
        set use_reg2 1
        if {![info exists registry_open]} {
            registry::open [file join ${macports::registry.path} registry registry.db]
            set registry_open yes
        }
    }

    if {$use_reg2} {
        if { [string equal $name ""] } {
            throw registry::image-error "Registry error: Please specify the name of the port."
        }
        set ilist [registry::entry installed $name]
        if { [llength $ilist] == 1 } {
            set requested [lindex $ilist 0]
        } else {
            throw registry::image-error "Image error: port ${name} is not active."
        }
        # set name again since the one we were passed may not have had the correct case
        set name [$requested name]
        set version [$requested version]
        set revision [$requested revision]
        set variants [$requested variants]
        set specifier "${version}_${revision}${variants}"
    } else {
        set ilist [registry::active $name]
        if { [llength $ilist] > 1 } {
            return -code error "Registry error: Please specify the name of the port."
        } else {
            set ilist [lindex $ilist 0]
        }
        # set name again since the one we were passed may not have had the correct case
        set name [lindex $ilist 0]
        set version [lindex $ilist 1]
        set revision [lindex $ilist 2]
        set variants [lindex $ilist 3]
        set specifier "${version}_${revision}${variants}"
    }

    if { $v != "" && ![string equal $specifier $v] } {
        return -code error "Active version of $name is not $v but ${specifier}."
    }

    if {$v != ""} {
        ui_msg "$UI_PREFIX [format [msgcat::mc "Deactivating %s @%s"] $name $v]"
    } else {
        ui_msg "$UI_PREFIX [format [msgcat::mc "Deactivating %s"] $name]"
    }

    if {$use_reg2} {
        if { ![string equal [$requested installtype] "image"] } {
            return -code error "Image error: ${name} @${specifier} not installed as an image."
        }
        # this shouldn't be possible
        if { [$requested state] != "installed" } {
            return -code error "Image error: ${name} @${specifier} is not active."
        }

        if {![info exists options(ports_nodepcheck)] || ![string is true -strict $options(ports_nodepcheck)]} {
            registry::check_dependents $requested $force "deactivate"
        }

        _deactivate_contents $requested [$requested files] $force
        $requested state imaged
    } else {
        set ref [registry::open_entry $name $version $revision $variants]

        if { ![string equal [registry::property_retrieve $ref installtype] "image"] } {
            return -code error "Image error: ${name} @${specifier} not installed as an image."
        }
        if { [registry::property_retrieve $ref active] != 1 } {
            return -code error "Image error: ${name} @${specifier} is not active."
        }

        registry::open_file_map
        set imagefiles [registry::port_registered $name]

        _deactivate_contents $name $imagefiles

        foreach file $imagefiles {
            registry::unregister_file $file
        }
        registry::write_file_map
        registry::close_file_map

        registry::property_store $ref active 0

        registry::write_entry $ref
    }
}

proc _check_registry {name v} {
    global UI_PREFIX
    variable use_reg2

    if {$use_reg2} {
        if { [registry::decode_spec $v version revision variants] } {
            set ilist [registry::entry imaged $name $version $revision $variants]
            set valid 1
        } else {
            set valid [string equal $v {}]
            set ilist [registry::entry imaged $name]
        }

        if { [llength $ilist] > 1 || (!$valid && [llength $ilist] == 1) } {
            ui_msg "$UI_PREFIX [msgcat::mc "The following versions of $name are currently installed:"]"
            foreach i $ilist {
                set iname [$i name]
                set iversion [$i version]
                set irevision [$i revision]
                set ivariants [$i variants]
                if { [$i state] == "installed" } {
                    ui_msg "$UI_PREFIX [format [msgcat::mc "    %s @%s_%s%s (active)"] $iname $iversion $irevision $ivariants]"
                } else {
                    ui_msg "$UI_PREFIX [format [msgcat::mc "    %s @%s_%s%s"] $iname $iversion $irevision $ivariants]"
                }
            }
            if { $valid } {
                throw registry::invalid "Registry error: Please specify the full version as recorded in the port registry."
            } else {
                throw registry::invalid "Registry error: Invalid version specified. Please specify a version as recorded in the port registry."
            }
        } elseif { [llength $ilist] == 1 } {
            return [lindex $ilist 0]
        }
        throw registry::invalid "Registry error: No port of $name installed."
    } else {
        # registry1.0
        set ilist [registry::installed $name $v]
        if { [string equal $v ""] && [llength $ilist] > 1 } {
            # set name again since the one we were passed may not have had the correct case
            set name [lindex [lindex $ilist 0] 0]
            ui_msg "$UI_PREFIX [msgcat::mc "The following versions of $name are currently installed:"]"
            foreach i $ilist { 
                set iname [lindex $i 0]
                set iversion [lindex $i 1]
                set irevision [lindex $i 2]
                set ivariants [lindex $i 3]
                set iactive [lindex $i 4]
                if { $iactive == 0 } {
                    ui_msg "$UI_PREFIX [format [msgcat::mc "    %s @%s_%s%s"] $iname $iversion $irevision $ivariants]"
                } elseif { $iactive == 1 } {
                    ui_msg "$UI_PREFIX [format [msgcat::mc "    %s @%s_%s%s (active)"] $iname $iversion $irevision $ivariants]"
                }
            }
            return -code error "Registry error: Please specify the full version as recorded in the port registry."
        } elseif {[llength $ilist] == 1} {
            return [lindex $ilist 0]
        }
        return -code error "Registry error: No port of $name installed."
    }
}

## Activates a file from an image into the filesystem. Deals with symlinks,
## directories and files.
##
## @param [in] srcfile path to file in image
## @param [in] dstfile path to activate file to
## @return 1 if file needs to be explicitly deleted if we have to roll back, 0 otherwise
proc _activate_file {srcfile dstfile} {
    switch [file type $srcfile] {
        directory {
            # Don't recursively copy directories
            ui_debug "activating directory: $dstfile"
            # Don't do anything if the directory already exists.
            if { ![file isdirectory $dstfile] } {
                file mkdir $dstfile
                # fix attributes on the directory.
                if {[getuid] == 0} {
                    eval file attributes {$dstfile} [file attributes $srcfile]
                } else {
                    # not root, so can't set owner/group
                    eval file attributes {$dstfile} -permissions [file attributes -permissions $srcfile]
                }
                # set mtime on installed element
                file mtime $dstfile [file mtime $srcfile]
            }
            return 0
        }
        default {
            ui_debug "activating file: $dstfile"
            file rename $srcfile $dstfile
            return 1
        }
    }
}

# extract an archive to a temporary location
# returns: path to the extracted directory
proc extract_archive_to_tmpdir {location} {
    set extractdir [mkdtemp [file join [macports::gettmpdir] mpextractXXXXXXXX]]

    try {
        set startpwd [pwd]
        if {[catch {cd $extractdir} err]} {
            throw MACPORTS $err
        }
    
        # clagged straight from unarchive... this really needs to be factored
        # out, but it's a little tricky as the places where it's used run in
        # different interpreter contexts with access to different packages.
        set unarchive.cmd {}
        set unarchive.pre_args {}
        set unarchive.args {}
        set unarchive.pipe_cmd ""
        set unarchive.type [file tail $location]
        switch -regex ${unarchive.type} {
            cp(io|gz) {
                set pax "pax"
                if {[catch {set pax [macports::findBinary $pax ${macports::autoconf::pax_path}]} errmsg] == 0} {
                    ui_debug "Using $pax"
                    set unarchive.cmd "$pax"
                    if {[geteuid] == 0} {
                        set unarchive.pre_args {-r -v -p e}
                    } else {
                        set unarchive.pre_args {-r -v -p p}
                    }
                    if {[regexp {z$} ${unarchive.type}]} {
                        set unarchive.args {.}
                        set gzip "gzip"
                        if {[catch {set gzip [macports::findBinary $gzip ${macports::autoconf::gzip_path}]} errmsg] == 0} {
                            ui_debug "Using $gzip"
                            set unarchive.pipe_cmd "$gzip -d -c ${location} |"
                        } else {
                            ui_debug $errmsg
                            throw MACPORTS "No '$gzip' was found on this system!"
                        }
                    } else {
                        set unarchive.args "-f ${location} ."
                    }
                } else {
                    ui_debug $errmsg
                    throw MACPORTS "No '$pax' was found on this system!"
                }
            }
            t(ar|bz|lz|xz|gz) {
                set tar "tar"
                if {[catch {set tar [macports::findBinary $tar ${macports::autoconf::tar_path}]} errmsg] == 0} {
                    ui_debug "Using $tar"
                    set unarchive.cmd "$tar"
                    set unarchive.pre_args {-xvpf}
                    if {[regexp {z2?$} ${unarchive.type}]} {
                        set unarchive.args {-}
                        if {[regexp {bz2?$} ${unarchive.type}]} {
                            set gzip "bzip2"
                        } elseif {[regexp {lz$} ${unarchive.type}]} {
                            set gzip "lzma"
                        } elseif {[regexp {xz$} ${unarchive.type}]} {
                            set gzip "xz"
                        } else {
                            set gzip "gzip"
                        }
                        if {[info exists macports::autoconf::${gzip}_path]} {
                            set hint [set macports::autoconf::${gzip}_path]
                        } else {
                            set hint ""
                        }
                        if {[catch {set gzip [macports::findBinary $gzip $hint]} errmsg] == 0} {
                            ui_debug "Using $gzip"
                            set unarchive.pipe_cmd "$gzip -d -c ${location} |"
                        } else {
                            ui_debug $errmsg
                            throw MACPORTS "No '$gzip' was found on this system!"
                        }
                    } else {
                        set unarchive.args "${location}"
                    }
                } else {
                    ui_debug $errmsg
                    throw MACPORTS "No '$tar' was found on this system!"
                }
            }
            xar|xpkg {
                set xar "xar"
                if {[catch {set xar [macports::findBinary $xar ${macports::autoconf::xar_path}]} errmsg] == 0} {
                    ui_debug "Using $xar"
                    set unarchive.cmd "$xar"
                    set unarchive.pre_args {-xvpf}
                    set unarchive.args "${location}"
                } else {
                    ui_debug $errmsg
                    throw MACPORTS "No '$xar' was found on this system!"
                }
            }
            zip {
                set unzip "unzip"
                if {[catch {set unzip [macports::findBinary $unzip ${macports::autoconf::unzip_path}]} errmsg] == 0} {
                    ui_debug "Using $unzip"
                    set unarchive.cmd "$unzip"
                    if {[geteuid] == 0} {
                        set unarchive.pre_args {-oX}
                    } else {
                        set unarchive.pre_args {-o}
                    }
                    set unarchive.args "${location} -d ."
                } else {
                    ui_debug $errmsg
                    throw MACPORTS "No '$unzip' was found on this system!"
                }
            }
            default {
                throw MACPORTS "Unsupported port archive type '${unarchive.type}'!"
            }
        }
        
        # and finally, reinvent command_exec
        if {${unarchive.pipe_cmd} == ""} {
            set cmdstring "${unarchive.cmd} ${unarchive.pre_args} ${unarchive.args}"
        } else {
            set cmdstring "${unarchive.pipe_cmd} ( ${unarchive.cmd} ${unarchive.pre_args} ${unarchive.args} )"
        }
        system $cmdstring
    } catch {*} {
        file delete -force $extractdir
        throw
    } finally {
        cd $startpwd
    }

    return $extractdir
}

## Activates the contents of a port
proc _activate_contents {port {imagefiles {}} {location {}}} {
    variable force
    variable use_reg2
    variable noexec
    global macports::prefix

    set files [list]
    set baksuffix .mp_[clock seconds]
    if {$use_reg2} {
        set location [$port location]
        set imagefiles [$port imagefiles]
    } else {
        set name $port
    }
    set extracted_dir [extract_archive_to_tmpdir $location]

    set backups [list]
    # This is big and hairy and probably could be done better.
    # First, we need to check the source file, make sure it exists
    # Then we remove the $location from the path of the file in the contents
    #  list  and check to see if that file exists
    # Last, if the file exists, and belongs to another port, and force is set
    #  we remove the file from the file_map, take ownership of it, and
    #  clobber it
    if {$use_reg2} {
        array set todeactivate {}
        try {
            registry::write {
                foreach file $imagefiles {
                    set srcfile "${extracted_dir}${file}"

                    # To be able to install links, we test if we can lstat the file to
                    # figure out if the source file exists (file exists will return
                    # false for symlinks on files that do not exist)
                    if { [catch {file lstat $srcfile dummystatvar}] } {
                        throw registry::image-error "Image error: Source file $srcfile does not appear to exist (cannot lstat it).  Unable to activate port [$port name]."
                    }

                    set owner [registry::entry owner $file]

                    if {$owner != {} && $owner != $port} {
                        # deactivate conflicting port if it is replaced_by this one
                        set result [mportlookup [$owner name]]
                        array unset portinfo
                        array set portinfo [lindex $result 1]
                        if {[info exists portinfo(replaced_by)] && [lsearch -regexp $portinfo(replaced_by) "(?i)^[$port name]\$"] != -1} {
                            # we'll deactivate the owner later, but before activating our files
                            set todeactivate($owner) yes
                            set owner "replaced"
                        }
                    }

                    if {$owner != "replaced"} {
                        if { [string is true -strict $force] } {
                            # if we're forcing the activation, then we move any existing
                            # files to a backup file, both in the filesystem and in the
                            # registry
                            if { [file exists $file] } {
                                set bakfile "${file}${baksuffix}"
                                ui_warn "File $file already exists.  Moving to: $bakfile."
                                file rename -force -- $file $bakfile
                                lappend backups $file
                            }
                            if { $owner != {} } {
                                $owner deactivate [list $file]
                                $owner activate [list $file] [list "${file}${baksuffix}"]
                            }
                        } else {
                            # if we're not forcing the activation, then we bail out if
                            # we find any files that already exist, or have entries in
                            # the registry
                            if { $owner != {} && $owner != $port } {
                                throw registry::image-error "Image error: $file is being used by the active [$owner name] port.  Please deactivate this port first, or use 'port -f activate [$port name]' to force the activation."
                            } elseif { $owner == {} && ![catch {file type $file}] } {
                                throw registry::image-error "Image error: $file already exists and does not belong to a registered port.  Unable to activate port [$port name]. Use 'port -f activate [$port name]' to force the activation."
                            }
                        }
                    }

                    # Split out the filename's subpaths and add them to the
                    # imagefile list.
                    # We need directories first to make sure they will be there
                    # before links. However, because file mkdir creates all parent
                    # directories, we don't need to have them sorted from root to
                    # subpaths. We do need, nevertheless, all sub paths to make sure
                    # we'll set the directory attributes properly for all
                    # directories.
                    set directory [file dirname $file]
                    while { [lsearch -exact $files $directory] == -1 } {
                        lappend files $directory
                        set directory [file dirname $directory]
                    }

                    # Also add the filename to the imagefile list.
                    lappend files $file
                }
            }

            # deactivate ports replaced_by this one
            foreach owner [array names todeactivate] {
                if {$noexec || ![registry::run_target $owner deactivate [list ports_nodepcheck 1]]} {
                    deactivate [$owner name] "" [list ports_nodepcheck 1]
                }
            }

            # Sort the list in forward order, removing duplicates.
            # Since the list is sorted in forward order, we're sure that
            # directories are before their elements.
            # We don't have to do this as mentioned above, but it makes the
            # debug output of activate make more sense.
            set files [lsort -increasing -unique $files]
            set rollback_filelist {}

            registry::write {
                # Activate it, and catch errors so we can roll-back
                try {
                    $port activate $imagefiles
                    foreach file $files {
                        if {[_activate_file "${extracted_dir}${file}" $file] == 1} {
                            lappend rollback_filelist $file
                        }
                    }
                } catch {*} {
                    ui_debug "Activation failed, rolling back."
                    # can't do it here since we're already inside a transaction
                    set deactivate_this yes
                    throw
                }
            }
        } catch {*} {
            # roll back activation of this port
            if {[info exists deactivate_this]} {
                _deactivate_contents $port $rollback_filelist yes yes
            }
            # if any errors occurred, move backed-up files back to their original
            # locations, then rethrow the error. Transaction rollback will take care
            # of this in the registry.
            foreach file $backups {
                file rename -force -- "${file}${baksuffix}" $file
            }
            # reactivate deactivated ports
            foreach entry [array names todeactivate] {
                if {[$entry state] == "imaged" && ($noexec || ![registry::run_target $entry activate ""])} {
                    set pvers "[$entry version]_[$entry revision][$entry variants]"
                    activate [$entry name] $pvers [list ports_activate_no-exec $noexec]
                }
            }
            # remove temp image dir
            file delete -force $extracted_dir
            throw
        }
    } else {
        # registry1.0
        set deactivated [list]
        foreach file $imagefiles {
            set srcfile "${extracted_dir}${file}"

            # To be able to install links, we test if we can lstat the file to
            # figure out if the source file exists (file exists will return
            # false for symlinks on files that do not exist)
            if { [catch {file lstat $srcfile dummystatvar}] } {
                file delete -force $extracted_dir
                return -code error "Image error: Source file $srcfile does not appear to exist (cannot lstat it).  Unable to activate port $name."
            }

            set port [registry::file_registered $file]
            
            if {$port != 0  && $port != $name} {
                # deactivate conflicting port if it is replaced_by this one
                if {[catch {mportlookup $port} result]} {
                    global errorInfo
                    ui_debug "$errorInfo"
                    file delete -force $extracted_dir
                    return -code error "port lookup failed: $result"
                }
                array unset portinfo
                array set portinfo [lindex $result 1]
                if {[info exists portinfo(replaced_by)] && [lsearch -regexp $portinfo(replaced_by) "(?i)^${name}\$"] != -1} {
                    lappend deactivated [lindex [registry::active $port] 0]
                    deactivate $port "" ""
                    set port 0
                }
            }
    
            if { $port != 0  && $force != 1 && $port != $name } {
                file delete -force $extracted_dir
                return -code error "Image error: $file is being used by the active $port port.  Please deactivate this port first, or use 'port -f activate $name' to force the activation."
            } elseif { [file exists $file] && $force != 1 } {
                file delete -force $extracted_dir
                return -code error "Image error: $file already exists and does not belong to a registered port.  Unable to activate port $name. Use 'port -f activate $name' to force the activation."
            } elseif { $force == 1 && [file exists $file] || $port != 0 } {
                set bakfile "${file}${baksuffix}"

                if {[file exists $file]} {
                    ui_warn "File $file already exists.  Moving to: $bakfile."
                    file rename -force -- $file $bakfile
                    lappend backups $file
                }

                if { $port != 0 } {
                    set bakport [registry::file_registered $file]
                    registry::unregister_file $file
                    if {[file exists $bakfile]} {
                        registry::register_file $bakfile $bakport
                    }
                }
            }

            # Split out the filename's subpaths and add them to the imagefile list.
            # We need directories first to make sure they will be there before
            # links. However, because file mkdir creates all parent directories,
            # we don't need to have them sorted from root to subpaths. We do need,
            # nevertheless, all sub paths to make sure we'll set the directory
            # attributes properly for all directories.
            set directory [file dirname $file]
            while { [lsearch -exact $files $directory] == -1 } { 
                lappend files $directory
                set directory [file dirname $directory]
            }

            # Also add the filename to the imagefile list.
            lappend files $file
        }
        registry::write_file_map

        # Sort the list in forward order, removing duplicates.
        # Since the list is sorted in forward order, we're sure that directories
        # are before their elements.
        # We don't have to do this as mentioned above, but it makes the
        # debug output of activate make more sense.
        set files [lsort -increasing -unique $files]
        set rollback_filelist {}

        # Activate it, and catch errors so we can roll-back
        if { [catch { foreach file $files {
                        if {[_activate_file "${extracted_dir}${file}" $file] == 1} {
                            lappend rollback_filelist $file
                        }
                    }} result]} {
            ui_debug "Activation failed, rolling back."
            _deactivate_contents $name $rollback_filelist yes yes
            # return backed up files to their old locations
            foreach f $backups {
                set bakfile "${f}${baksuffix}"
                set bakport [registry::file_registered $bakfile]
                if {$bakport != 0} {
                    registry::unregister_file $bakfile
                    registry::register_file $f $bakport
                }
                file rename -force -- $bakfile $file
            }
            # reactivate deactivated ports
            foreach entry $deactivated {
                set pname [lindex $entry 0]
                set pvers "[lindex $entry 1]_[lindex $entry 2][lindex $entry 3]"
                activate $pname $pvers ""
            }
            registry::write_file_map

            file delete -force $extracted_dir
            return -code error $result
        }
    }
    file delete -force $extracted_dir
}

proc _deactivate_file {dstfile} {
    if { [file type $dstfile] == "link" } {
        ui_debug "deactivating link: $dstfile"
        file delete -- $dstfile
    } elseif { [file isdirectory $dstfile] } {
        # 0 item means empty.
        if { [llength [readdir $dstfile]] == 0 } {
            ui_debug "deactivating directory: $dstfile"
            file delete -- $dstfile
        } else {
            ui_debug "$dstfile is not empty"
        }
    } else {
        ui_debug "deactivating file: $dstfile"
        file delete -- $dstfile
    }
}

proc _deactivate_contents {port imagefiles {force 0} {rollback 0}} {
    variable use_reg2
    set files [list]

    foreach file $imagefiles {
        if { [file exists $file] || (![catch {file type $file}] && [file type $file] == "link") } {
            # Normalize the file path to avoid removing the intermediate
            # symlinks (remove the empty directories instead)
            # Remark: paths in the registry may be not normalized.
            # This is not really a problem and it is in fact preferable.
            # Indeed, if I change the activate code to include normalized paths
            # instead of the paths we currently have, users' registry won't
            # match and activate will say that some file exists but doesn't
            # belong to any port.
            # The custom realpath proc is necessary because file normalize
            # does not resolve symlinks on OS X < 10.6
            set directory [realpath [file dirname $file]]
            lappend files [file join $directory [file tail $file]]

            # Split out the filename's subpaths and add them to the image list
            # as well.
            while { [lsearch -exact $files $directory] == -1 } {
                lappend files $directory
                set directory [file dirname $directory]
            }
        } else {
            ui_debug "$file does not exist."
        }
    }

    # Sort the list in reverse order, removing duplicates.
    # Since the list is sorted in reverse order, we're sure that directories
    # are after their elements.
    set files [lsort -decreasing -unique $files]

    # Remove all elements.
    if {$use_reg2 && !$rollback} {
        registry::write {
            $port deactivate $imagefiles
            foreach file $files {
                _deactivate_file $file
            }
        }
    } else {
        foreach file $files {
            _deactivate_file $file
        }
    }
}

# End of portimage namespace
}
