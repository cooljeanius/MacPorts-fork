# -*- coding: utf-8; mode: tcl; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- vim:fenc=utf-8:filetype=tcl:et:sw=4:ts=4:sts=4
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

set org.macports.configure [target_new org.macports.configure portconfigure::configure_main]
target_provides ${org.macports.configure} configure
target_requires ${org.macports.configure} main fetch extract checksum patch
target_prerun ${org.macports.configure} portconfigure::configure_start

namespace eval portconfigure {
}

# define options
commands configure autoreconf automake autoconf xmkmf
# defaults
default configure.env       ""
default configure.pre_args  {[portconfigure::configure_get_pre_args]}
default configure.cmd       ./configure
default configure.dir       {${worksrcpath}}
default autoreconf.dir      {${worksrcpath}}
default autoreconf.pre_args {--install}
default autoconf.dir        {${worksrcpath}}
default automake.dir        {${worksrcpath}}
default xmkmf.cmd           xmkmf
default xmkmf.dir           {${worksrcpath}}
default use_configure       yes

option_proc use_autoreconf  portconfigure::set_configure_type
option_proc use_automake    portconfigure::set_configure_type
option_proc use_autoconf    portconfigure::set_configure_type
option_proc use_xmkmf       portconfigure::set_configure_type

proc portconfigure::set_configure_type {option action args} {
    if {[string equal ${action} "set"] && [tbool args]} {
        switch $option {
            use_xmkmf {
                depends_build-append port:imake
            }
            default {
                depends_build-append port:autoconf port:automake port:libtool
            }
        }
    }
}

options configure.asroot
default configure.asroot no

# Configure special environment variables.
# We could have m32/m64/march/mtune be global configurable at some point.
options configure.m32 configure.m64 configure.march configure.mtune
default configure.march     {}
default configure.mtune     {}
# We could have debug/optimizations be global configurable at some point.
options configure.optflags configure.cflags configure.cppflags configure.cxxflags configure.objcflags configure.ldflags configure.libs configure.fflags configure.f90flags configure.fcflags configure.classpath
default configure.optflags  {-O2}
# compiler flags section
default configure.cflags    {[portconfigure::configure_get_cflags]}
default configure.cppflags  {[portconfigure::configure_get_cppflags]}
default configure.cxxflags  {[portconfigure::configure_get_cflags]}
default configure.objcflags {[portconfigure::configure_get_cflags]}
default configure.ldflags   {[portconfigure::configure_get_ldflags]}
default configure.libs      {}
default configure.fflags    {[portconfigure::configure_get_cflags]}
default configure.f90flags  {[portconfigure::configure_get_cflags]}
default configure.fcflags   {[portconfigure::configure_get_cflags]}
default configure.classpath {}

# internal function to return the system value for CFLAGS/CXXFLAGS/etc
proc portconfigure::configure_get_cflags {args} {
    global configure.optflags configure.archflags
    global configure.march configure.mtune
    global configure.universal_cflags
    
    set flags "${configure.optflags}"
    if {[variant_exists universal] && [variant_isset universal]} {
        if {${configure.universal_cflags} != ""} {
            append flags " ${configure.universal_cflags}"
        }
        # stop here since the rest doesn't make much sense for universal
        return $flags
    }
    
    if {${configure.archflags} != ""} {
        append flags " ${configure.archflags}"
    }
    if {[info exists configure.march] && ${configure.march} != {}} {
        append flags " -march=${configure.march}"
    }
    if {[info exists configure.mtune] && ${configure.mtune} != {}} {
        append flags " -mtune=${configure.mtune}"
    }
    return $flags
}

proc portconfigure::configure_get_cppflags {args} {
    global prefix configure.universal_cppflags
    set flags "-I${prefix}/include"
    if {[variant_exists universal] && [variant_isset universal] && ${configure.universal_cppflags} != ""} {
        append flags " ${configure.universal_cppflags}"
    }
    return $flags
}

proc portconfigure::configure_get_ldflags {args} {
    global prefix configure.universal_ldflags configure.archflags
    set flags "-L${prefix}/lib"
    if {[variant_exists universal] && [variant_isset universal] && ${configure.universal_ldflags} != ""} {
        append flags " ${configure.universal_ldflags}"
    } elseif {${configure.archflags} != ""} {
        append flags " ${configure.archflags}"
    }
    return $flags
}

# tools section
options configure.perl configure.python configure.ruby configure.install configure.awk configure.bison configure.pkg_config configure.pkg_config_path
default configure.perl              {}
default configure.python            {}
default configure.ruby              {}
default configure.install           {${portutil::autoconf::install_command}}
default configure.awk               {}
default configure.bison             {}
default configure.pkg_config        {}
default configure.pkg_config_path   {}

options configure.build_arch configure.archflags
default configure.build_arch {${build_arch}}
default configure.archflags  {[portconfigure::configure_get_archflags]}

options configure.universal_archs configure.universal_args configure.universal_cflags configure.universal_cppflags configure.universal_cxxflags configure.universal_ldflags
default configure.universal_archs       {${universal_archs}}
default configure.universal_args        {--disable-dependency-tracking}
default configure.universal_cflags      {[portconfigure::configure_get_universal_cflags]}
default configure.universal_cppflags    {[portconfigure::configure_get_universal_cppflags]}
default configure.universal_cxxflags    {[portconfigure::configure_get_universal_cflags]}
default configure.universal_ldflags     {[portconfigure::configure_get_universal_ldflags]}

# Select a distinct compiler (C, C preprocessor, C++)
options configure.ccache configure.distcc configure.pipe configure.cc configure.cxx configure.cpp configure.objc configure.f77 configure.f90 configure.fc configure.javac configure.compiler
default configure.ccache        {${configureccache}}
default configure.distcc        {${configuredistcc}}
default configure.pipe          {${configurepipe}}
default configure.cc            {[portconfigure::configure_get_compiler cc]}
default configure.cxx           {[portconfigure::configure_get_compiler cxx]}
default configure.cpp           {[portconfigure::configure_get_compiler cpp]}
default configure.objc          {[portconfigure::configure_get_compiler objc]}
default configure.f77           {[portconfigure::configure_get_compiler f77]}
default configure.f90           {[portconfigure::configure_get_compiler f90]}
default configure.fc            {[portconfigure::configure_get_compiler fc]}
default configure.javac         {[portconfigure::configure_get_compiler javac]}
default configure.compiler      {[portconfigure::configure_get_default_compiler]}

set_ui_prefix

proc portconfigure::configure_start {args} {
    global UI_PREFIX
    global configure.compiler
    
    ui_msg "$UI_PREFIX [format [msgcat::mc "Configuring %s"] [option name]]"

    set name ""
    switch -exact ${configure.compiler} {
        gcc { set name "System gcc" }
        gcc-3.3 { set name "Mac OS X gcc 3.3" }
        gcc-4.0 { set name "Mac OS X gcc 4.0" }
        gcc-4.2 { set name "Mac OS X gcc 4.2" }
        llvm-gcc-4.2 { set name "Mac OS X llvm-gcc 4.2" }
        clang { set name "Mac OS X clang" }
        apple-gcc-3.3 { set name "MacPorts Apple gcc 3.3" }
        apple-gcc-4.0 { set name "MacPorts Apple gcc 4.0" }
        apple-gcc-4.2 { set name "MacPorts Apple gcc 4.2" }
        macports-gcc-3.3 { set name "MacPorts gcc 3.3" }
        macports-gcc-3.4 { set name "MacPorts gcc 3.4" }
        macports-gcc-4.0 { set name "MacPorts gcc 4.0" }
        macports-gcc-4.1 { set name "MacPorts gcc 4.1" }
        macports-gcc-4.2 { set name "MacPorts gcc 4.2" }
        macports-gcc-4.3 { set name "MacPorts gcc 4.3" }
        macports-gcc-4.4 { set name "MacPorts gcc 4.4" }
        default { return -code error "Invalid value for configure.compiler" }
    }
    ui_debug "Using compiler '$name'"
}

proc portconfigure::configure_get_pre_args {args} {
    global prefix configure.universal_args
    set result "--prefix=${prefix}"
    if {[variant_exists universal] && [variant_isset universal] && ${configure.universal_args} != ""} {
        append result " ${configure.universal_args}"
    }
    return $result
}

# internal function to determine the compiler flags to select an arch
proc portconfigure::configure_get_archflags {args} {
    global configure.build_arch configure.m32 configure.m64 configure.compiler
    set flags ""
    if {[tbool configure.m64]} {
        set flags "-m64"
    } elseif {[tbool configure.m32]} {
        set flags "-m32"
    } elseif {${configure.build_arch} != ""} {
        if {[arch_flag_supported]} {
            set flags "-arch ${configure.build_arch}"
        } elseif {${configure.build_arch} == "x86_64" || ${configure.build_arch} == "ppc64"} {
            set flags "-m64"
        } elseif {${configure.compiler} != "gcc-3.3"} {
            set flags "-m32"
        }
    }
    return $flags
}

# internal function to determine the "-arch xy" flags for the compiler
proc portconfigure::configure_get_universal_archflags {args} {
    global configure.universal_archs
    set flags ""
    foreach arch ${configure.universal_archs} {
        if {$flags == ""} {
            set flags "-arch $arch"
        } else {
            append flags " -arch $arch"
        }
    }
    return $flags
}

# internal function to determine the CPPFLAGS for the compiler
proc portconfigure::configure_get_universal_cppflags {args} {
    global os.arch os.major developer_dir
    set flags ""
    # include sysroot in CPPFLAGS too (twice), for the benefit of autoconf
    if {${os.arch} == "powerpc" && ${os.major} == "8"} {
        set flags "-isysroot ${developer_dir}/SDKs/MacOSX10.4u.sdk"
    }
    return $flags
}

# internal function to determine the CFLAGS for the compiler
proc portconfigure::configure_get_universal_cflags {args} {
    global os.arch os.major developer_dir
    set flags [configure_get_universal_archflags]
    # these flags should be valid for C/C++ and similar compiler frontends
    if {${os.arch} == "powerpc" && ${os.major} == "8"} {
        set flags "-isysroot ${developer_dir}/SDKs/MacOSX10.4u.sdk ${flags}"
    }
    return $flags
}

# internal function to determine the LDFLAGS for the compiler
proc portconfigure::configure_get_universal_ldflags {args} {
    global os.arch os.major developer_dir
    set flags [configure_get_universal_archflags]
    # works around linking without using the CFLAGS, outside of automake
    if {${os.arch} == "powerpc" && ${os.major} == "8"} {
        set flags "-Wl,-syslibroot,${developer_dir}/SDKs/MacOSX10.4u.sdk ${flags}"
    }
    return $flags
}

# internal proc to determine if the compiler supports -arch
proc portconfigure::arch_flag_supported {args} {
    global configure.compiler
    switch -exact ${configure.compiler} {
        gcc-4.0 -
        gcc-4.2 -
        llvm-gcc-4.2 -
        clang -
        apple-gcc-4.0 -
        apple-gcc-4.2 {
            return yes
        }
        default {
            return no
        }
    }
}

# internal function to determine the default compiler
proc portconfigure::configure_get_default_compiler {args} {
    global os.platform os.major
    set compiler ""
    switch -exact "${os.platform} ${os.major}" {
        "darwin 7" { set compiler gcc-3.3 }
        "darwin 8" { set compiler gcc-4.0 }
        "darwin 9" { set compiler gcc-4.0 }
        "darwin 10" { set compiler gcc-4.2 }
        default { set compiler gcc }
    }
    return $compiler
}

# internal function to find correct compilers
proc portconfigure::configure_get_compiler {type} {
    global configure.compiler prefix developer_dir
    set ret ""
    switch -exact ${configure.compiler} {
        gcc {
            switch -exact ${type} {
                cc   { set ret /usr/bin/gcc }
                objc { set ret /usr/bin/gcc }
                cxx  { set ret /usr/bin/g++ }
                cpp  { set ret /usr/bin/cpp }
            }
        }
        gcc-3.3 {
            switch -exact ${type} {
                cc   { set ret /usr/bin/gcc-3.3 }
                objc { set ret /usr/bin/gcc-3.3 }
                cxx  { set ret /usr/bin/g++-3.3 }
                cpp  { set ret /usr/bin/cpp-3.3 }
            }
        }
        gcc-4.0 {
            switch -exact ${type} {
                cc   { set ret /usr/bin/gcc-4.0 }
                objc { set ret /usr/bin/gcc-4.0 }
                cxx  { set ret /usr/bin/g++-4.0 }
                cpp  { set ret /usr/bin/cpp-4.0 }
            }
        }
        gcc-4.2 {
            switch -exact ${type} {
                cc   { set ret /usr/bin/gcc-4.2 }
                objc { set ret /usr/bin/gcc-4.2 }
                cxx  { set ret /usr/bin/g++-4.2 }
            }
        }
        llvm-gcc-4.2 {
            switch -exact ${type} {
                cc   { set ret ${developer_dir}/usr/llvm-gcc-4.2/bin/llvm-gcc-4.2 }
                objc { set ret ${developer_dir}/usr/llvm-gcc-4.2/bin/llvm-gcc-4.2 }
                cxx  { set ret ${developer_dir}/usr/llvm-gcc-4.2/bin/llvm-g++-4.2 }
            }
        }
        clang {
            switch -exact ${type} {
                cc   { set ret ${developer_dir}/usr/bin/clang }
                objc { set ret ${developer_dir}/usr/bin/clang }
            }
        }
        apple-gcc-3.3 {
            switch -exact ${type} {
                cc  { set ret ${prefix}/bin/gcc-apple-3.3 }
                cpp { set ret ${prefix}/bin/cpp-apple-3.3 }
            }
        }
        apple-gcc-4.0 {
            switch -exact ${type} {
                cc   { set ret ${prefix}/bin/gcc-apple-4.0 }
                objc { set ret ${prefix}/bin/gcc-apple-4.0 }
                cpp  { set ret ${prefix}/bin/cpp-apple-4.0 }
            }
        }
        apple-gcc-4.2 {
            switch -exact ${type} {
                cc   { set ret ${prefix}/bin/gcc-apple-4.2 }
                objc { set ret ${prefix}/bin/gcc-apple-4.2 }
                cpp  { set ret ${prefix}/bin/cpp-apple-4.2 }
            }
        }
        macports-gcc-3.3 {
            switch -exact ${type} {
                cc  { set ret ${prefix}/bin/gcc-mp-3.3 }
                cxx { set ret ${prefix}/bin/g++-mp-3.3 }
                cpp { set ret ${prefix}/bin/cpp-mp-3.3 }
            }
        }
        macports-gcc-3.4 {
            switch -exact ${type} {
                cc  { set ret ${prefix}/bin/gcc-mp-3.4 }
                cxx { set ret ${prefix}/bin/g++-mp-3.4 }
                cpp { set ret ${prefix}/bin/cpp-mp-3.4 }
            }
        }
        macports-gcc-4.0 {
            switch -exact ${type} {
                cc   { set ret ${prefix}/bin/gcc-mp-4.0 }
                objc { set ret ${prefix}/bin/gcc-mp-4.0 }
                cxx  { set ret ${prefix}/bin/g++-mp-4.0 }
                cpp  { set ret ${prefix}/bin/cpp-mp-4.0 }
                fc   { set ret ${prefix}/bin/gfortran-mp-4.0 }
                f77  { set ret ${prefix}/bin/gfortran-mp-4.0 }
                f90  { set ret ${prefix}/bin/gfortran-mp-4.0 }
            }
        }
        macports-gcc-4.1 {
            switch -exact ${type} {
                cc   { set ret ${prefix}/bin/gcc-mp-4.1 }
                objc { set ret ${prefix}/bin/gcc-mp-4.1 }
                cxx  { set ret ${prefix}/bin/g++-mp-4.1 }
                cpp  { set ret ${prefix}/bin/cpp-mp-4.1 }
                fc   { set ret ${prefix}/bin/gfortran-mp-4.1 }
                f77  { set ret ${prefix}/bin/gfortran-mp-4.1 }
                f90  { set ret ${prefix}/bin/gfortran-mp-4.1 }
            }
        }
        macports-gcc-4.2 {
            switch -exact ${type} {
                cc   { set ret ${prefix}/bin/gcc-mp-4.2 }
                objc { set ret ${prefix}/bin/gcc-mp-4.2 }
                cxx  { set ret ${prefix}/bin/g++-mp-4.2 }
                cpp  { set ret ${prefix}/bin/cpp-mp-4.2 }
                fc   { set ret ${prefix}/bin/gfortran-mp-4.2 }
                f77  { set ret ${prefix}/bin/gfortran-mp-4.2 }
                f90  { set ret ${prefix}/bin/gfortran-mp-4.2 }
            }
        }
        macports-gcc-4.3 {
            switch -exact ${type} {
                cc   { set ret ${prefix}/bin/gcc-mp-4.3 }
                objc { set ret ${prefix}/bin/gcc-mp-4.3 }
                cxx  { set ret ${prefix}/bin/g++-mp-4.3 }
                cpp  { set ret ${prefix}/bin/cpp-mp-4.3 }
                fc   { set ret ${prefix}/bin/gfortran-mp-4.3 }
                f77  { set ret ${prefix}/bin/gfortran-mp-4.3 }
                f90  { set ret ${prefix}/bin/gfortran-mp-4.3 }
            }
        }
        macports-gcc-4.4 {
            switch -exact ${type} {
                cc   { set ret ${prefix}/bin/gcc-mp-4.4 }
                objc { set ret ${prefix}/bin/gcc-mp-4.4 }
                cxx  { set ret ${prefix}/bin/g++-mp-4.4 }
                cpp  { set ret ${prefix}/bin/cpp-mp-4.4 }
                fc   { set ret ${prefix}/bin/gfortran-mp-4.4 }
                f77  { set ret ${prefix}/bin/gfortran-mp-4.4 }
                f90  { set ret ${prefix}/bin/gfortran-mp-4.4 }
            }
        }
    }
    return $ret
}

proc portconfigure::configure_main {args} {
    global [info globals]
    global worksrcpath use_configure use_autoreconf use_autoconf use_automake use_xmkmf
    global configure.env configure.pipe configure.cflags configure.cppflags configure.cxxflags configure.objcflags configure.ldflags configure.libs configure.fflags configure.f90flags configure.fcflags configure.classpath
    global configure.perl configure.python configure.ruby configure.install configure.awk configure.bison configure.pkg_config configure.pkg_config_path
    global configure.ccache configure.distcc configure.cc configure.cxx configure.cpp configure.objc configure.f77 configure.f90 configure.fc configure.javac
    
    if {[tbool use_autoreconf]} {
        if {[catch {command_exec autoreconf} result]} {
            return -code error "[format [msgcat::mc "%s failure: %s"] autoreconf $result]"
        }
    }
    
    if {[tbool use_automake]} {
        if {[catch {command_exec automake} result]} {
            return -code error "[format [msgcat::mc "%s failure: %s"] automake $result]"
        }
    }
    
    if {[tbool use_autoconf]} {
        if {[catch {command_exec autoconf} result]} {
            return -code error "[format [msgcat::mc "%s failure: %s"] autoconf $result]"
        }
    }

    if {[tbool use_xmkmf]} {
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

        # Set pre-compiler filter to use (ccache/distcc), if any.
        if {[tbool configure.ccache] && [tbool configure.distcc]} {
            set filter "ccache "
            append_list_to_environment_value configure "CCACHE_PREFIX" "distcc"
        } elseif {[tbool configure.ccache]} {
            set filter "ccache "
        } elseif {[tbool configure.distcc]} {
            set filter "distcc "
        } else {
            set filter ""
        }
        
        # Set flags controlling the kind of compiler output.
        if {[tbool configure.pipe]} {
            set output "-pipe "
        } else {
            set output ""
        }

        # Append configure flags.
        append_list_to_environment_value configure "CC" ${filter}${configure.cc}
        append_list_to_environment_value configure "CPP" ${filter}${configure.cpp}
        append_list_to_environment_value configure "CXX" ${filter}${configure.cxx}
        append_list_to_environment_value configure "OBJC" ${filter}${configure.objc}
        append_list_to_environment_value configure "FC" ${configure.fc}
        append_list_to_environment_value configure "F77" ${configure.f77}
        append_list_to_environment_value configure "F90" ${configure.f90}
        append_list_to_environment_value configure "JAVAC" ${configure.javac}
        append_list_to_environment_value configure "CFLAGS" ${output}${configure.cflags}
        append_list_to_environment_value configure "CPPFLAGS" ${configure.cppflags}
        append_list_to_environment_value configure "CXXFLAGS" ${output}${configure.cxxflags}
        append_list_to_environment_value configure "OBJCFLAGS" ${output}${configure.objcflags}
        append_list_to_environment_value configure "LDFLAGS" ${configure.ldflags}
        append_list_to_environment_value configure "LIBS" ${configure.libs}
        append_list_to_environment_value configure "FFLAGS" ${output}${configure.fflags}
        append_list_to_environment_value configure "F90FLAGS" ${output}${configure.f90flags}
        append_list_to_environment_value configure "FCFLAGS" ${output}${configure.fcflags}
        append_list_to_environment_value configure "CLASSPATH" ${configure.classpath}
        append_list_to_environment_value configure "PERL" ${configure.perl}
        append_list_to_environment_value configure "PYTHON" ${configure.python}
        append_list_to_environment_value configure "RUBY" ${configure.ruby}
        append_list_to_environment_value configure "INSTALL" ${configure.install}
        append_list_to_environment_value configure "AWK" ${configure.awk}
        append_list_to_environment_value configure "BISON" ${configure.bison}
        append_list_to_environment_value configure "PKG_CONFIG" ${configure.pkg_config}
        append_list_to_environment_value configure "PKG_CONFIG_PATH" ${configure.pkg_config_path}

        # Execute the command (with the new environment).
        if {[catch {command_exec configure} result]} {
            return -code error "[format [msgcat::mc "%s failure: %s"] configure $result]"
        }
    }
    return 0
}
