#!/bin/bash -norc
dnl#                                               -*- Autoconf -*-
dnl# This file is an input file used by the GNU "autoconf" program to
dnl# generate the file "configure", which is run during Tcl installation
dnl# to configure the system for the local environment.
#
# RCS: @(#) $Id: configure.in,v 1.20 2004/12/18 13:26:02 vasiljevic Exp $

#-----------------------------------------------------------------------
# Sample configure.in for Tcl Extensions.  The only places you should
# need to modify this file are marked by the string __CHANGE__
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# __CHANGE__
# Set your package name and version numbers here.
#
# This initializes the environment with PACKAGE_NAME and PACKAGE_VERSION
# set as provided.  These will also be added as -D defs in your Makefile
# so you can encode the package version directly into the source files.
#-----------------------------------------------------------------------

AC_PREREQ([2.69])
AC_INIT([thread],[2.6])
AC_SUBST([PACKAGE_VERSION])
AC_CONFIG_SRCDIR([generic/aolstub.cpp])
AC_CONFIG_HEADERS([config.h])
AC_CONFIG_MACRO_DIR([m4])
AC_CONFIG_AUX_DIR([tclconfig])
AC_CANONICAL_TARGET
AC_EXEEXT
AC_OBJEXT
AC_USE_SYSTEM_EXTENSIONS
AM_INIT_AUTOMAKE([foreign dejagnu no-installinfo -Wall])
AM_MISSING_PROG([AUTOMAKE],[automake])
AM_MISSING_PROG([AUTOMAKE_1_15],[automake-1.15])
AM_MAINTAINER_MODE
AC_SEARCH_LIBS([strerror],[cposix]) dnl# This used to be AC\_ISC\_POSIX
AX_CHECK_GNU_MAKE
AC_BAKEFILE_GNUMAKE

#--------------------------------------------------------------------
# Call TEA_INIT as the first TEA_ macro to set up initial vars.
# This will define a ${TEA_PLATFORM} variable == "unix" or "windows"
# as well as PKG_LIB_FILE and PKG_STUB_LIB_FILE.
#--------------------------------------------------------------------

TEA_INIT([3.1])

#--------------------------------------------------------------------
# Load Tcl via the tclConfig.sh file
#--------------------------------------------------------------------

AX_PROG_TCL([8.4])
TEA_PATH_TCLCONFIG
TEA_LOAD_TCLCONFIG

#-----------------------------------------------------------------------
# Handle the --prefix=... option by defaulting to what Tcl gave.
# Must be called after TEA_LOAD_TCLCONFIG and before TEA_SETUP_COMPILER.
#-----------------------------------------------------------------------

TEA_PREFIX

#-----------------------------------------------------------------------
# Standard compiler checks.
# This sets up CC by using the CC env var, or looks for gcc otherwise.
# This also calls AC_PROG_CC and a few others to create
# the basic setup necessary to compile executables.
#-----------------------------------------------------------------------

TEA_SETUP_COMPILER
AC_PROG_INSTALL
if test "x${CC}" = "x"; then
  AC_PROG_CC
  test -x compile
  AM_PROG_CC_C_O
else
  test ! -z "${CC}"
  AC_SUBST([CC])
fi
AC_BAKEFILE_METROWERKS_EXTO
AC_PROG_CXX
if test "x${CPP}" = "x"; then
  test -z "${CPP}"
  AC_PROG_CPP
else
  XORG_PROG_RAWCPP
fi
AM_PROG_AR
XORG_LD_WRAP
PKG_PROG_PKG_CONFIG

#--------------------------------------------------------------------
# Check if building with optional Gdbm package. This will define
# GDBM_CFLAGS and GDBM_LIBS variables.
#--------------------------------------------------------------------

TCLTHREAD_WITH_GDBM

#-----------------------------------------------------------------------
# __CHANGE__
# Specify the C source files to compile in TEA_ADD_SOURCES,
# public headers that need to be installed in TEA_ADD_HEADERS,
# stub library C source files to compile in TEA_ADD_STUB_SOURCES,
# and runtime Tcl library files in TEA_ADD_TCL_SOURCES.
# This defines PKG(_STUB)_SOURCES, PKG(_STUB)_OBJECTS, PKG_HEADERS
# and PKG_TCL_SOURCES.
#-----------------------------------------------------------------------

TEA_ADD_SOURCES([generic/threadCmd.c          \
                 generic/threadSvCmd.c        \
                 generic/threadSpCmd.c        \
                 generic/threadPoolCmd.c      \
                 generic/psGdbm.c             \
                 generic/threadSvListCmd.c    \
                 generic/threadSvKeylistCmd.c \
                 generic/tclXkeylist.c])
TEA_ADD_HEADERS([])
TEA_ADD_INCLUDES([])
TEA_ADD_LIBS([${GDBM_LIBS}])
TEA_ADD_CFLAGS([${GDBM_CFLAGS}])
TEA_ADD_STUB_SOURCES([])
TEA_ADD_TCL_SOURCES([lib/ttrace.tcl])dnl

#--------------------------------------------------------------------
# __CHANGE__
# A few miscellaneous platform-specific items:
#
# Define a special symbol for Windows (BUILD_sample in this case) so
# that we create the export library with the dll.
#
# Windows creates a few extra files that need to be cleaned up.
# You can add more files to clean if your extension creates any extra
# files.
#
# TEA_ADD_* any platform specific compiler/build info here.
#--------------------------------------------------------------------

if test "${TEA_PLATFORM}" = "windows" ; then
    AC_DEFINE([BUILD_sample],[1],[Defined to 1 if building sample])
    CLEANFILES="*.lib *.dll *.exp *.ilk *.pdb vc*.pch"
    TEA_ADD_SOURCES([win/threadWin.c])
    TEA_ADD_INCLUDES([-I\"$(${CYGPATH} ${srcdir}/win)\"])
else
    CLEANFILES=""
    TEA_ADD_SOURCES([unix/threadUnix.c])
fi
AC_SUBST([CLEANFILES])dnl

#--------------------------------------------------------------------
# __CHANGE__
# Choose which headers you need.  Extension authors should try very
# hard to only rely on the Tcl public header files.  Internal headers
# contain private data structures and are subject to change without
# notice.
# This MUST be called after TEA_LOAD_TCLCONFIG / TEA_LOAD_TKCONFIG
#--------------------------------------------------------------------

AC_CHECK_HEADERS([sys/time.h sys/timeb.h])
AC_HEADER_RESOLV
TEA_PUBLIC_TCL_HEADERS
TEA_BUGGY_STRTOD

# Checks for typedefs, structures, and compiler characteristics.
AC_TYPE_SIZE_T
AC_C_BIGENDIAN
AC_C_FLEXIBLE_ARRAY_MEMBER
AC_C_PROTOTYPES
AC_C_VARARRAYS
AC_CHECK_MEMBERS([Tcl_Interp.errorLine])
AC_CHECK_MEMBERS([struct Tcl_Interp.errorLine])
XORG_MEMORY_CHECK_FLAGS
XORG_CHECK_MALLOC_ZERO
XORG_CWARNFLAGS

# Checks for library functions.
AC_CHECK_FUNCS([ftime gettimeofday memset strchr strstr])dnl

dnl#
#--------------------------------------------------------------------
# Check Tcl blocking style
#--------------------------------------------------------------------

TEA_BLOCKING_STYLE

#--------------------------------------------------------------------
# Check whether --enable-threads or --disable-threads was given.
# This auto-enables if Tcl was compiled threaded.
#--------------------------------------------------------------------

AX_PTHREAD
TEA_ENABLE_THREADS
gl_THREADLIB

#--------------------------------------------------------------------
# The statement below defines a collection of symbols related to
# building as a shared library instead of a static library.
#--------------------------------------------------------------------

TEA_ENABLE_SHARED
LT_INIT([shared dlopen win32-dll])
LT_LANG([C])dnl

#--------------------------------------------------------------------
# This macro figures out what flags to use with the compiler/linker
# when building shared/static debug/optimized objects. This information
# can be taken from the tclConfig.sh file, but this figures it all out.
#--------------------------------------------------------------------

TEA_CONFIG_CFLAGS

#--------------------------------------------------------------------
# Set the default compiler switches based on the --enable-symbols option.
#--------------------------------------------------------------------

TEA_ENABLE_SYMBOLS

# Checks for libraries.
AC_CHECK_LIB([tcl],[Tcl_InitStubs])
AX_DLL_STRING

#--------------------------------------------------------------------
# Everyone should be linking against the Tcl stub library. If you
# cannot do so for some reason, remove this definition. If you are
# not using stubs, you also need to modify the SHLIB_LD_LIBS setting
# below to link against the non-stubbed Tcl library. Add Tk too if
# necessary.
#--------------------------------------------------------------------

AC_DEFINE([USE_TCL_STUBS],[1],[Defined to 1 if using Tcl stubs])dnl

#--------------------------------------------------------------------
# This macro generates a line to use when building a library. It
# depends on values set by the TEA_ENABLE_SHARED, TEA_ENABLE_SYMBOLS,
# and TEA_LOAD_TCLCONFIG macros above.
#--------------------------------------------------------------------

TEA_MAKE_LIB

#--------------------------------------------------------------------
# Find tclsh so that we can run pkg_mkIndex to generate the pkgIndex.tcl
# file during the install process. Do NOT run the TCLSH_PROG through
# ${CYGPATH} because it is being used directly by make.
# Require that we use a tclsh shell version 8.2 or later since earlier
# versions have bugs in the pkg_mkIndex routine.
# Add WISH as well if this is a Tk extension.
#--------------------------------------------------------------------

TEA_PROG_TCLSH

#--------------------------------------------------------------------
# Finally, substitute all of the various values into the Makefile.
# You may alternatively have a special pkgIndex.tcl.in or other files
# which require substituting th AC variables in.  Include these here.
#--------------------------------------------------------------------

AC_SUBST([OBJEXT])dnl
AC_SUBST([CYGPATH])dnl
AC_SUBST([INSTALLdir])dnl
AC_SUBST([PKGdir])dnl
AC_CONFIG_FILES([Makefile pkgIndex.tcl])
AC_OUTPUT
