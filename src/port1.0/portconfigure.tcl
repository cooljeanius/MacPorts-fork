# et:ts=4
# portconfigure.tcl
# $Id$
#
# Copyright (c) 2002 - 2003 Apple Computer, Inc.
# Copyright (c) 2007 Markus W. Weissmann <mww@macports.org>
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

package provide portconfigure 1.0
package require portutil 1.0

set org.macports.configure [target_new org.macports.configure configure_main]
target_provides ${org.macports.configure} configure
target_requires ${org.macports.configure} main fetch extract checksum patch
target_prerun ${org.macports.configure} configure_start

# define options
commands configure automake autoconf xmkmf libtool
# defaults
default configure.env ""
default configure.pre_args {--prefix=${prefix}}
default configure.cmd ./configure
default configure.dir {${worksrcpath}}
default autoconf.dir {${worksrcpath}}
default automake.dir {${worksrcpath}}
default xmkmf.cmd xmkmf
default xmkmf.dir {${worksrcpath}}
default use_configure yes

# Configure special environment variables.
options configure.cflags configure.cppflags configure.cxxflags configure.ldflags
# We could have default debug/optimization flags at some point.
default configure.cflags	{-O2}
default configure.cppflags	{"-I${prefix}/include"}
default configure.cxxflags	{-O2}
default configure.ldflags	{"-L${prefix}/lib"}

# Universal options & default values.
options configure.universal_args		configure.universal_cflags configure.universal_cppflags configure.universal_cxxflags configure.universal_ldflags configure.universal_env
default configure.universal_args		--disable-dependency-tracking
default configure.universal_cflags		{"-isysroot /Developer/SDKs/MacOSX10.4u.sdk -arch i386 -arch ppc"}
default configure.universal_cppflags	{}
default configure.universal_cxxflags	{"-isysroot /Developer/SDKs/MacOSX10.4u.sdk -arch i386 -arch ppc"}
default configure.universal_ldflags		{"-arch i386 -arch ppc"}

# Select a distinct compiler (C, C preprocessor, C++)
options configure.cc configure.cxx configure.cpp configure.f77 configure.f90 configure.fc configure.compiler
default configure.cc			{}
default configure.cxx			{}
default configure.cpp			{}
default configure.f77			{}
default configure.f90			{}
default configure.fc			{}
default configure.compiler		{}

set_ui_prefix

proc configure_start {args} {
    global UI_PREFIX
    
    ui_msg "$UI_PREFIX [format [msgcat::mc "Configuring %s"] [option portname]]"
}

# internal function for setting compiler variables; use like "_set_compiler string var val var val .."
# this function will NOT override explicitely set variables from the portfile
proc select_compiler {info args} {
    global configure.cc configure.cxx configure.cpp configure.f77 configure.f90 configure.fc
    ui_debug "Using compiler '$info'"
    set i 0
    foreach value $args {
        if {0==$i} {
            set comp $value
            set i 1
        } else {
            switch -exact $comp {
                cc  { if {""==${configure.cc}}  { set configure.cc $value } }
                cxx { if {""==${configure.cxx}} { set configure.cxx $value } }
                cpp { if {""==${configure.cpp}} { set configure.cpp $value } }
                fc  { if {""==${configure.fc}}  { set configure.fc $value } }
                f77 { if {""==${configure.f77}} { set configure.f77 $value } }
                f90 { if {""==${configure.f90}} { set configure.f90 $value } }
            }
            set i 0
        }
    }
}

proc configure_main {args} {
    global [info globals]
    global worksrcpath use_configure use_autoconf use_automake use_xmkmf
    global configure.env configure.cflags configure.cppflags configure.cxxflags configure.ldflags
    global configure.cc configure.cxx configure.cpp configure.f77 configure.f90 configure.fc configure.compiler prefix
    global os.platform os.major
    
    if {[tbool use_automake]} {
	# XXX depend on automake
	if {[catch {command_exec automake} result]} {
	    return -code error "[format [msgcat::mc "%s failure: %s"] automake $result]"
	}
    }
    
    if {[tbool use_autoconf]} {
	# XXX depend on autoconf
	if {[catch {command_exec autoconf} result]} {
	    return -code error "[format [msgcat::mc "%s failure: %s"] autoconf $result]"
	}
    }

    # 1st chose a reasonable default compiler suite for each platform if none was chosen
    if {""==${configure.compiler}} {
        switch -exact "${os.platform} ${os.major}" {
            "darwin 7" { set configure.compiler gcc-3.3 }
            "darwin 8" { set configure.compiler gcc-4.0 }
            "darwin 9" { set configure.compiler gcc-4.0 }
        }
    }

    # select a compiler collection
    switch -exact ${configure.compiler} {
        gcc-3.3 {
            select_compiler "Mac OS X gcc 3.3" \
                cc  /usr/bin/gcc-3.3 \
                cxx /usr/bin/g++-3.3 \
                cpp /usr/bin/cpp-3.3 }
        gcc-4.0 {
            select_compiler "Mac OS X gcc 4.0" \
                cc  /usr/bin/gcc-4.0 \
                cxx /usr/bin/g++-4.0 \
                cpp /usr/bin/cpp-4.0 }
        apple-gcc-3.3 {
            select_compiler "MacPorts Apple gcc 3.3" \
                cc  ${prefix}/bin/gcc-apple-3.3 \
                cpp ${prefix}/bin/cpp-apple-3.3 }
        apple-gcc-4.0 {
            select_compiler "MacPorts Apple gcc 4.0" \
                cc  ${prefix}/bin/gcc-apple-4.0 \
                cpp ${prefix}/bin/cpp-apple-4.0 }
        macports-gcc-3.3 {
            select_compiler "MacPorts gcc 3.3" \
                cc  ${prefix}/bin/gcc-mp-3.3 \
                cxx ${prefix}/bin/g++-mp-3.3 \
                cpp ${prefix}/bin/cpp-mp-3.3 }
        macports-gcc-3.4 {
            select_compiler "MacPorts gcc 3.4" \
                cc  ${prefix}/bin/gcc-mp-3.4 \
                cxx ${prefix}/bin/g++-mp-3.4 \
                cpp ${prefix}/bin/cpp-mp-3.4 }
        macports-gcc-4.0 {
            select_compiler "MacPorts gcc 4.0" \
                cc  ${prefix}/bin/gcc-mp-4.0 \
                cxx ${prefix}/bin/g++-mp-4.0 \
                cpp ${prefix}/bin/cpp-mp-4.0 \
                fc  ${prefix}/bin/gfortran-mp-4.0 \
                f77 ${prefix}/bin/gfortran-mp-4.0 \
                f90 ${prefix}/bin/gfortran-mp-4.0 }
        macports-gcc-4.1 {
            select_compiler "MacPorts gcc 4.1" \
                cc  ${prefix}/bin/gcc-mp-4.1 \
                cxx ${prefix}/bin/g++-mp-4.1 \
                cpp ${prefix}/bin/cpp-mp-4.1 \
                fc  ${prefix}/bin/gfortran-mp-4.1 \
                f77 ${prefix}/bin/gfortran-mp-4.1 \
                f90 ${prefix}/bin/gfortran-mp-4.1 }
        macports-gcc-4.2 {
            select_compiler "MacPorts gcc 4.2" \
                cc  ${prefix}/bin/gcc-mp-4.2 \
                cxx ${prefix}/bin/g++-mp-4.2 \
                cpp ${prefix}/bin/cpp-mp-4.2 \
                fc  ${prefix}/bin/gfortran-mp-4.2 \
                f77 ${prefix}/bin/gfortran-mp-4.2 \
                f90 ${prefix}/bin/gfortran-mp-4.2 }
        macports-gcc-4.3 {
            select_compiler "MacPorts gcc 4.3" \
                cc  ${prefix}/bin/gcc-mp-4.3 \
                cxx ${prefix}/bin/g++-mp-4.3 \
                cpp ${prefix}/bin/cpp-mp-4.3 \
                fc  ${prefix}/bin/gfortran-mp-4.3 \
                f77 ${prefix}/bin/gfortran-mp-4.3 \
                f90 ${prefix}/bin/gfortran-mp-4.3 }
        default {
            ui_debug "No compiler collection selected explicitly" }
    }
    
    if {[tbool use_xmkmf]} {
		# XXX depend on xmkmf
		if {[catch {command_exec xmkmf} result]} {
		    return -code error "[format [msgcat::mc "%s failure: %s"] xmkmf $result]"
		} else {
		    # XXX should probably use make command abstraction but we know that
		    # X11 will already set things up so that "make Makefiles" always works.
		    system "cd ${worksrcpath} && make Makefiles"
		}
	} elseif {[tbool use_configure]} {
    	# Merge (ld|c|cpp|cxx)flags into the environment variable.
    	parse_environment configure

    	# Append configure flags.
		append_list_to_environment_value configure "CC" ${configure.cc}
		append_list_to_environment_value configure "CPP" ${configure.cpp}
		append_list_to_environment_value configure "CXX" ${configure.cxx}
		append_list_to_environment_value configure "FC" ${configure.fc}
		append_list_to_environment_value configure "F77" ${configure.f77}
		append_list_to_environment_value configure "F90" ${configure.f90}
		append_list_to_environment_value configure "CFLAGS" ${configure.cflags}
		append_list_to_environment_value configure "CPPFLAGS" ${configure.cppflags}
		append_list_to_environment_value configure "CXXFLAGS" ${configure.cxxflags}
		append_list_to_environment_value configure "LDFLAGS" ${configure.ldflags}

		# Execute the command (with the new environment).
		if {[catch {command_exec configure} result]} {
			return -code error "[format [msgcat::mc "%s failure: %s"] configure $result]"
		}
    }
    return 0
}
