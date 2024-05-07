dnl#                                               -*- Autoconf -*-
dnl# Process this file with autoconf to produce a configure script.
dnl# $Id: configure.ac 91520 2012-04-04 00:40:40Z jmr@macports.org $

AC_PREREQ([2.69])
AC_DEFUN([MACPORTS_VERSION_MACRO],[esyscmd(<config/macports_version tr -d '\n')])
dnl# Square brackets cannot be put around the middle arg to AC_INIT here.
dnl# That would be how it is normally done, and it is what autoupdate 
dnl# wants to do, but this cannot be done because of the following error:
dnl# configure.ac:7: error: m4_divert_push: cannot change diversion to `GROW' inside m4_expand
dnl# configure.ac:7: the top level
AC_INIT([MacPorts],MACPORTS_VERSION_MACRO,[macports-dev@lists.macosforge.org],[macports])
AC_CONFIG_SRCDIR([src/pextlib1.0/Pextlib.c])
AC_CONFIG_HEADERS([src/config.h])
AC_CONFIG_MACRO_DIR([m4])

AC_CANONICAL_TARGET
AC_USE_SYSTEM_EXTENSIONS
AM_INIT_AUTOMAKE([1.11 foreign dejagnu dist-bzip2 dist-lzip dist-xz dist-zip no-installinfo tar-pax -Wall])
AM_MAINTAINER_MODE
AC_SEARCH_LIBS([strerror],[cposix]) dnl# This used to be AC\_ISC\_POSIX
AC_OBJEXT
AC_EXEEXT
AC_LANG([C])
if test "x${prefix}" != "x"; then
  PREFIX=${prefix}
  AC_SUBST([PREFIX])
fi

# Read in the MacPorts version from the base/config/macports_version file
AC_MSG_CHECKING([MacPorts version])
MACPORTS_VERSION=MACPORTS_VERSION_MACRO
AC_MSG_RESULT([${MACPORTS_VERSION}])
AC_SUBST([MACPORTS_VERSION])dnl

# Check user PATH for MP paths, and remove as necessary.
dnl# I would like to remove this macro, but removing it breaks the build...
MP_PATH_SCAN
dnl# ...so instead I will just do this:
if test -d /opt/local/bin; then
  echo "adding MacPorts prefix back in to path..."
  PATH=${PATH}:/opt/local/bin
  PATH=$(echo "${PATH}" | tr \: \\n | uniq | tr \\n \: | uniq | sed "s|::|:|g")
  if test "x${PREFIX}" != "x"; then
    if test "x${PREFIX}" != "x/opt/local"; then
      PATH=${PATH}:${PREFIX}/bin
      PATH=$(echo "${PATH}" | tr \: \\n | uniq | tr \\n \: | uniq | sed "s|::|:|g")
      AC_MSG_CHECKING([path])
      AC_MSG_RESULT([${PATH}])
    else
      echo "prefix is default, not adding it again"
    fi
  else
    echo "prefix is not defined, only using default"
  fi
fi

AC_PATH_PROG([SW_VERS],[sw_vers])
AC_PATH_PROG([DEFAULTS],[defaults])
AC_PATH_PROG([XCODE_SELECT],[xcode-select])dnl

if test "x${SW_VERS}" != "x"; then
  AC_MSG_CHECKING([Mac OS X version])
  MACOSX_VERSION=`${SW_VERS} -productVersion`
  AC_MSG_RESULT([$MACOSX_VERSION])
fi

case "${MACOSX_VERSION}" in
  10.0*|10.1*|10.2*|10.3*)
    AC_MSG_ERROR([This version of Mac OS X is not supported any more.
                  Please upgrade at http://store.apple.com/])
    ;;
  10.4.[[0-9]]|10.4.10|10.5.[[0-7]]|10.6.[[0-7]]|10.7.[[0-4]]|10.8.[[0-3]])
    AC_MSG_WARN([This version of Mac OS X is out of date.])
    AC_MSG_WARN([Please run Software Update to update it.])
    ;;
  10.4*|10.5*|10.6*|10.7*|10.8*|10.9*)
    dnl# Supported version
    ;;
  *)
    ;;
esac

# locate currently selected Xcode path
AC_MSG_CHECKING([Xcode location])
if test "x${XCODE_SELECT}" != "x"; then
  DEVELOPER_DIR=`${XCODE_SELECT} -print-path`
fi
if test -z "${DEVELOPER_DIR}" -o ! -d "${DEVELOPER_DIR}" ; then
    if test -d /Applications/Xcode.app/Contents/Developer ; then
        DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
    else
        DEVELOPER_DIR=/Developer
    fi
fi
AC_MSG_RESULT([${DEVELOPER_DIR}])
AC_SUBST([DEVELOPER_DIR])dnl

case "${DEVELOPER_DIR}" in
  *Xcode.app/Contents/Developer)
    XCODEPLIST_BASE=`dirname ${DEVELOPER_DIR}`/version
    ;;
  *)
    XCODEPLIST_BASE=${DEVELOPER_DIR}/Applications/Xcode.app/Contents/version
    ;;
esac
XCODEPLIST=${XCODEPLIST_BASE}.plist
if test -r "${XCODEPLIST}"; then
  AC_MSG_CHECKING([Xcode version])
  if test "x${DEFAULTS}" != "x"; then
    XCODE_VERSION=`${DEFAULTS} read ${XCODEPLIST_BASE} CFBundleShortVersionString`
  else
    XCODE_VERSION=`tr -d '\r\n' < ${XCODEPLIST} | sed -e 's/.*<key>CFBundleShortVersionString<\/key>.<string>\([[0-9.]]*\)<\/string>.*/\1/'`
  fi
  AC_MSG_RESULT([${XCODE_VERSION}])
fi

case "${XCODE_VERSION}" in
  1.*|2.[[0-1]]*)
    AC_MSG_WARN([This version of Xcode Tools is not supported])
    AC_MSG_WARN([Please upgrade at http://connect.apple.com/])
    ;;
  2.[[2-3]]*|3.[[0]]*)
    AC_MSG_WARN([This version of Xcode Tools is out of date])
    AC_MSG_WARN([Please consider upgrading as some ports fail compiling])
    ;;
  2.*|3.*|4.*|5.*)
    dnl# Supported version
    ;;
  *)
    ;;
esac

# Checks for programs.
AM_PROG_AS
AM_PROG_AR
if test "x${AR}" = "x"; then
  test -z "${AR}" || unset AR
  AC_CHECK_TOOLS([AR],[ar gar])dnl
  ## might want to switch around these checks...
  if test "x${ac_cv_prog_AR}" = "x"; then
    test -z "${ac_cv_prog_AR}" || unset ac_cv_prog_AR
    AC_PROG_AR
  fi
else
  test -n "${AR}" && export AR
fi
if test "x${CC}" = "x"; then
  AC_PROG_CC
  test -x compile
  AM_PROG_CC_C_O
else
  # The "test" is just a dummy to make sure that this "else" condition
  # is not empty, as sometimes `autoconf` removes the AC_SUBSTs...
  # (I do this elsewhere, too)
  test ! -z "${CC}"
  AC_SUBST([CC])
fi
AC_PROG_CXX
AM_WITH_DMALLOC
AC_PROG_INSTALL
AC_PROG_LEX([yywrap])
AM_PROG_LEX
AC_PROG_LN_S
AC_PROG_OBJC
AM_PATH_PYTHON
AC_PROG_YACC
LT_INIT([dlopen])
LT_LANG([C])
if test "x${RANLIB}" = "x"; then
  AC_PROG_RANLIB
else
  test ! -z "${RANLIB}"
  AC_SUBST([RANLIB])
fi
PKG_PROG_PKG_CONFIG

dnl# AX_* macros are from the autoconf-archive package
AX_PTHREAD
AX_PROG_PERL_VERSION([5.12])
AX_PROG_TCL([8.4])
AX_CHECK_GNU_MAKE
AX_PKG_SWIG([2.0.9])
AX_SWIG_MULTI_MODULE_SUPPORT
AX_C___ATTRIBUTE__
AX_LIB_READLINE

dnl# XORG_* macros are from the xorg-util-macros package
if test "x${CPP}" = "x"; then
  test -z "${CPP}"
  AC_PROG_CPP
else
  XORG_PROG_RAWCPP
fi
XORG_MEMORY_CHECK_FLAGS
XORG_CHECK_MALLOC_ZERO
XORG_CWARNFLAGS
XORG_WITH_DOXYGEN
if test "x${PERL}" = "x"; then
  XORG_WITH_PERL
else
  test ! -z "${PERL}" && export PERL
  AC_SUBST([PERL])
fi
XORG_ENABLE_UNIT_TESTS
XORG_ENABLE_INTEGRATION_TESTS
XORG_LD_WRAP

dnl# AC_BAKEFILE_* macros are from the bakefile package
AC_BAKEFILE_PROG_MWCC
AC_BAKEFILE_PROG_MWCXX
if test "x`whoami`" = "xroot"; then
  test -d ~/.ccache && test -w ~/.ccache && AC_BAKEFILE_METROWERKS_EXTO
fi
AC_BAKEFILE_GNUMAKE

dnl# checks for programs without specifically-crafted AC_* macros
AC_PATH_PROGS([BSDMAKE],[bsdmake pmake],[])
AC_PATH_PROG([BZIP2],[bzip2],[])
AC_PATH_PROG([BZR],[bzr],[])
AC_PATH_PROG([CHOWN],[chown],[],[${PATH}:/usr/sbin])
AC_PATH_PROG([CHGRP],[chgrp],[],[${PATH}:/usr/sbin])
AC_PATH_PROG([CHMOD],[chmod],[],[${PATH}:/usr/sbin])
AC_PATH_PROG([CODESIGN],[codesign],[])
AC_PATH_PROG([CP],[cp],[])
AC_PATH_PROG([CPIO],[cpio],[])
AC_PATH_PROG([CVS],[cvs],[])
AC_PATH_PROG([DIFF],[diff],[])
if test "x${DOXYGEN}" = "x"; then
  AC_PATH_PROG([DOXYGEN],[doxygen],[])
else
  test ! -z "${DOXYGEN}"
  AC_SUBST([DOXYGEN])
fi
AC_PATH_PROG([DSCL],[dscl],[])
AC_PATH_PROG([DSEDITGROUP],[dseditgroup],[])
AC_PATH_PROG([DYLIBBUNDLER],[dylibbundler],[])
AC_PATH_PROG([ED],[ed])
AC_PATH_PROG([FILE],[file],[])
AC_PATH_PROG([GIT],[git],[])
AC_PATH_PROGS([GNUMAKE],[gnumake gmake],[],[${PATH}:/usr/local/bin])
AC_PATH_PROGS([GNUPATCH],[gnupatch],[],[${PATH}:/usr/local/bin])
AC_PATH_PROGS([GNUTAR],[gnutar gtar],[],[${PATH}:/usr/local/bin])
AC_PATH_PROG([GZIP],[gzip],[])
AC_PATH_PROG([HDIUTIL],[hdiutil],[])
AC_PATH_PROG([HG],[hg],[])
AC_PATH_PROG([LAUNCHCTL],[launchctl],[])
AC_PATH_PROG([LIPO],[lipo],[])
AC_PATH_PROG([LSBOM],[lsbom],[])
AC_PATH_PROG([LZMA],[lzma],[])
AC_PATH_PROG([MAKE],[make])
AC_PATH_PROG([MDFIND],[mdfind],[])
AC_PATH_PROG([MDLS],[mdls],[])
AC_PATH_PROG([MKBOM],[mkbom],[])
AC_PATH_PROG([MTREE],[mtree],[],[${PATH}:/usr/sbin])
AC_PATH_PROG([OPEN],[open],[])
AC_PATH_PROG([OPENSSL],[openssl],[])
AC_PATH_PROG([PAX],[pax],[])
AC_PATH_PROG([PERL5],[perl],[])
AC_PATH_PROG([RLWRAP],[rlwrap],[])
AC_PATH_PROG([RMDIR],[rmdir],[])
AC_PATH_PROG([RSYNC],[rsync],[])
AC_PATH_PROG([SANDBOX_EXEC],[sandbox-exec],[],[/usr/bin])
if test "x${SED}" = "x"; then
  AC_PATH_PROG([SED],[sed],[])
  AC_ARG_VAR([SED],[path to sed command])
else
  test ! -z "${SED}" && export SED
  AC_SUBST([SED])
fi
AC_PATH_PROG([SVN],[svn],[])
AC_PATH_PROG([TCLDOC],[tcldoc],[])
AC_SUBST([TCLDOC])
export TCLDOC
AC_PATH_PROG([UNZIP],[unzip])
AC_PATH_PROG([XATTR],[xattr],[])
AC_PATH_PROG([XAR],[xar],[])
AC_PATH_PROG([XARGS],[xargs],[])
AC_PATH_PROG([XCODEBUILD],[xcodebuild],[])
AC_PATH_PROG([XCRUN],[xcrun],[])
AC_PATH_PROG([XZ],[xz],[])
AC_PATH_PROG([ZIP],[zip])dnl

AC_CHECK_PROG([HAVE_LAUNCHD],[launchd],[yes],[])dnl

# Define some precious variables allowing user to override PATH for
# some programs
AC_ARG_VAR([BSDMAKE],[path to bsdmake/pmake command])
AC_ARG_VAR([BZIP2],[path to bzip2 command])
AC_ARG_VAR([CVS],[path to cvs command])
AC_ARG_VAR([GNUMAKE],[path to gnumake command])
AC_ARG_VAR([GNUTAR],[path to gnutar command])
AC_ARG_VAR([LZMA],[path to lzma command])
AC_ARG_VAR([MAKE],[path to make command])
AC_ARG_VAR([MTREE],[path to mtree command])
AC_ARG_VAR([OPEN],[path to open command])
AC_ARG_VAR([OPENSSL],[path to openssl command])
AC_ARG_VAR([RSYNC],[path to rsync command])
AC_ARG_VAR([SVN],[path to svn command])
AC_ARG_VAR([SWIG],[path to swig command])
AC_ARG_VAR([TCLSH],[path to tclsh command])
AC_ARG_VAR([TAR],[path to tar command])
AC_ARG_VAR([XAR],[path to xar command])
AC_ARG_VAR([XZ],[path to xz command])dnl

if test "x${MTREE}" = "x"; then
    AC_MSG_ERROR([mtree not found; you can get a copy from http://opensource.apple.com/source/file_cmds/file_cmds-220.7/])
fi

MP_SED_EXTENDED_REGEXP
MP_TAR_FAST_READ
MP_TAR_NO_SAME_OWNER
MP_PATCH_GNU_VERSION

# Quiche eaters options.
if test x${GCC} = xyes; then
	CFLAGS_QUICHEEATERS='-Wextra -Wall'
	CFLAGS_PEDANTIC='-pedantic'
fi
AC_SUBST([CFLAGS_QUICHEEATERS])dnl
AC_SUBST([CFLAGS_PEDANTIC])dnl
MP_WERROR

MP_COMPILER_ATTRIBUTE_UNUSED
MP_COMPILER_ATTRIBUTE_LF_PRIVATE

# Foundation checks
dnl# ACX\_PTHREAD has been moved to AX_PTHREAD above
dnl# (i.e. it has been put with the rest of the autoconf-archive macros)
MP_OBJC_RUNTIME
AC_MSG_CHECKING([for GNUStep system root])
AC_ARG_VAR([GNUSTEP_SYSTEM_ROOT],[path to GNUStep installation])
if test "x${GNUSTEP_SYSTEM_ROOT}" = "x"; then
  # TODO: move prefix-checking code above this step so that configured
  # prefix can be used instead of hardwiring /opt/local
  if test -d /opt/local/GNUStep/System; then
    export GNUSTEP_SYSTEM_ROOT=/opt/local/GNUSTEP/System
    AC_MSG_RESULT([using MacPorts GNUStep system root: ${GNUSTEP_SYSTEM_ROOT}])
    AC_SUBST([GNUSTEP_SYSTEM_ROOT])
  else
    # This had previously been in the other "else" condition, but I think
    # that was the wrong order...
    AC_MSG_RESULT([not found])
  fi
else
  AC_MSG_RESULT([using user-set GNUStep system root: ${GNUSTEP_SYSTEM_ROOT}])
  AC_SUBST([GNUSTEP_SYSTEM_ROOT])
fi
MP_OBJC_FOUNDATION

MP_PROG_DAEMONDO

AC_SUBST([EXTRA_PROGS])dnl

# set default ports-directory
PORTS_DIR_DEFAULT=`pwd | sed -e "s/base/ports/"`

# Check for paths
AC_PREFIX_DEFAULT([/opt/local])
AC_ARG_WITH([unsupported-prefix],
	    [AS_HELP_STRING([--with-unsupported-prefix],
	                    [Acknowledge that you accept the consequences of using an unsupported prefix.])],
	    [with_unsupported_prefix=${withval}],
	    [with_unsupported_prefix=no])
if test x${prefix} = x/usr/local -o x${prefix} = x/usr && test x${with_unsupported_prefix} != xyes; then
    AC_MSG_ERROR([Installing MacPorts into ${prefix} is not supported. If \
you understand this and wish to do so anyway, pass \
--with-unsupported-prefix to configure.])
fi
MP_PATH_PORTSDIR([${PORTS_DIR_DEFAULT}])
MP_PATH_MPCONFIGDIR

# Check whether to install without root privileges
MP_CHECK_NOROOTPRIVILEGES

# Check for install ownership
MP_CHECK_INSTALLUSER
MP_CHECK_INSTALLGROUP
MP_CHECK_RUNUSER
MP_DIRECTORY_MODE
MP_SHARED_DIRECTORY

# Check for default directories
MP_PATH_APPLICATIONS
MP_PATH_FRAMEWORKS

# Check for universal options
MP_UNIVERSAL_OPTIONS

# Checks for libraries.
AC_CHECK_LIB([tcl],[Tcl_InitStubs])dnl

# Check for standard header files.
dnl# AC_HEADER_STDC is no longer needed by itself, as it automatically gets
dnl# pulled in by other macros
AC_HEADER_DIRENT
AC_HEADER_STDBOOL dnl# calls "AC_CHECK_HEADER_STDBOOL"
AC_HEADER_SYS_WAIT
AC_HEADER_TIME
dnl# sys/ioctl.h sys/param.h sys/time.h and limits.h get to stay in
dnl# because autoscan will still warn about them when removed
dnl# (even though they are checked elsewhere)
AC_CHECK_HEADERS([crt_externs.h ctype.h err.h fcntl.h libkern/OSAtomic.h \
                  limits.h mach/mach.h netdb.h paths.h pwd.h spawn.h \
                  stddef.h stdio.h sys/cdefs.h sys/event.h sys/fcntl.h \
                  sys/file.h sys/ioctl.h sys/mount.h sys/param.h \
                  sys/paths.h sys/socket.h sys/sysctl.h sys/time.h \
                  time.h utime.h])
dnl# other stuff that autoscan will warn about:
if test "x${ac_cv_header_inttypes_h}" = "x"; then
  test -z "${ac_cv_header_inttypes_h}" || unset ac_cv_header_inttypes_h
  AC_CHECK_HEADERS([inttypes.h])
fi
if test "x${ac_cv_header_stdint_h}" = "x"; then
  test -z "${ac_cv_header_stdint_h}" || unset ac_cv_header_stdint_h
  AC_CHECK_HEADERS([stdint.h])
fi
if test "x${ac_cv_header_strings_h}" = "x"; then
  test -z "${ac_cv_header_strings_h}" || unset ac_cv_header_strings_h
  AC_CHECK_HEADERS([strings.h])
fi
if test "x${ac_cv_header_unistd_h}" = "x"; then
  test -z "${ac_cv_header_unistd_h}" || unset ac_cv_header_unistd_h
  AC_CHECK_HEADERS([unistd.h])
fi
dnl# readline/history.h and readline/readline.h are checked for by 
dnl# the AX_LIB_READLINE macro above

AM_CPPFLAGS="-I.. -I. ${AM_CPPFLAGS}"
dnl# This should be permanently converted eventually,
dnl# but as it is, the build fails without it.
if test "x${INCLUDES}" = "x"; then
  test -z "${INCLUDES}" && test -n "${AM_CPPFLAGS}" && export INCLUDES=${AM_CPPFLAGS}
fi

# Checks for typedefs, structures, and compiler characteristics.
AC_TYPE_UID_T
AC_C_BIGENDIAN
AC_C_INLINE
AC_TYPE_INTMAX_T
AC_TYPE_INTPTR_T
AC_TYPE_LONG_DOUBLE_WIDER
AC_TYPE_MODE_T
AC_TYPE_OFF_T
AC_TYPE_PID_T
AC_C_PROTOTYPES
AC_C_RESTRICT
AC_TYPE_SIZE_T
AC_TYPE_SSIZE_T
AC_TYPE_UINT8_T
AC_TYPE_UINT32_T
AC_TYPE_UINTMAX_T
AC_TYPE_UINTPTR_T
AC_C_FLEXIBLE_ARRAY_MEMBER
AC_C_VARARRAYS
AC_CHECK_MEMBERS([Tcl_Interp.errorLine])
AC_CHECK_MEMBERS([struct Tcl_Interp.errorLine])
AC_CHECK_SIZEOF([long])
AC_CHECK_ALIGNOF([long])
AC_CHECK_SIZEOF([uint8_t])
AC_CHECK_ALIGNOF([uint8_t])
AC_CHECK_SIZEOF([uint32_t])
AC_CHECK_ALIGNOF([uint32_t])dnl

# Checks for library functions.
AC_FUNC_CHOWN
AC_FUNC_FORK
AC_FUNC_LSTAT dnl# calls "AC_FUNC_LSTAT_FOLLOWS_SLASHED_SYMLINK"
AC_FUNC_MALLOC
AC_FUNC_MMAP
AC_FUNC_REALLOC
# the localtime_r function is checked for elsewhere
AC_CHECK_FUNCS([OSAtomicCompareAndSwap32 OSAtomicCompareAndSwap64 \
                OSAtomicCompareAndSwapPtr bzero clearenv copyfile dup2 \
                fgetln flock getcwd kqueue lchown lockf memmove memset \
                mkdir munmap posix_spawn printf realpath regcomp rmdir \
                select setenv setmode socket strcasecmp strchr strdup \
                strerror strlcat strlcpy strncasecmp strrchr strstr \
                strtol strtoul sysctlbyname system utime])
AC_SUBST([ac_cv_func_strlcat])dnl

MP_CHECK_READLINK_IS_P1003_1A

# Check for md5 implementation
AC_CHECK_HEADER([CommonCrypto/CommonDigest.h],
                [AC_DEFINE([HAVE_COMMONCRYPTO_COMMONDIGEST_H],[1],
                           [Define if CommonCrypto is available.])],
                [MP_LIB_MD5])dnl

# Check for readline
AC_ARG_ENABLE([readline],
              [AS_HELP_STRING([--enable-readline],
                              [Enable addition of readline support, if readline present.])],
[
	AC_CHECK_LIB([readline],[readline],[
				 READLINE_LIBS=-lreadline
				 AC_DEFINE([HAVE_LIBREADLINE],[1],[Define to 1 if you have the 'readline' library (-lreadline).])
				 ])
	AC_CHECK_DECLS([rl_username_completion_function,rl_filename_completion_function,rl_completion_matches,username_completion_function,filename_completion_function,completion_matches],[],[],
	[
	#include <stdio.h>
	#if HAVE_READLINE_READLINE_H
	# include <readline/readline.h>
	#else
	# if defined(__GNUC__) && !defined(__STRICT_ANSI__)
	#  waring "This conftest expects <readline/readline.h> to be included."
	# endif /* __GNUC__ && !__STRICT_ANSI__ */
	#endif /* HAVE_READLINE_READLINE_H */
	])
])
AC_SUBST([READLINE_LIBS])dnl

# Lowest non-system-reserved uid and gid (Apple claims <500)
AC_DEFINE([MIN_USABLE_UID],[500],[Lowest non-system-reserved UID.])dnl
AC_DEFINE([MIN_USABLE_GID],[500],[Lowest non-system-reserved GID.])dnl

# Load tclConfig.sh
SC_PATH_TCLCONFIG
SC_LOAD_TCLCONFIG

# Check for Tcl public headers (and other Tcl-relevant headers)
dnl# XXX: hardwire CYGPATH (CYGPATH must be set for SC_PUBLIC_TCL_HEADERS)
CYGPATH=echo
SC_PUBLIC_TCL_HEADERS
SC_TIME_HANDLER
SC_MISSING_POSIX_HEADERS

# Check for tclsh binary
MP_PROG_TCLSH

# Check for Tcl package path
MP_TCL_PACKAGE_DIR

# Check if thread is enabled.
MP_TCL_THREAD_SUPPORT

## libcurl
MP_LIBCURL_FLAGS
LIBCURL_CHECK_CONFIG
AX_LIB_CURL
AC_CHECK_HEADERS([curl/curl.h curl/curlrules.h])dnl

## sqlite3
MP_SQLITE3_FLAGS

MP_CHECK_SQLITE_VERSION([3003011])
if test "x${mp_sqlite_version_ge_3003011}" = "xno"; then
  AC_DEFINE([sqlite3_prepare_v2],[sqlite3_prepare],
            [define sqlite3_prepare to sqlite_prepare_v2 if the latter is not available])
fi

# Determine if we need to install some bundled packages
OUR_INCLUDED_PACKAGES=""

## Thread package.
AC_ARG_WITH([included-tclthread],
            [AS_HELP_STRING([--with-included-tclthread],
                            [install included Thread package.])],
            [with_included_tclthread=${withval}],
            [with_included_tclthread="unspecified"])

# Check if thread package is already installed.
if test "x${with_included_tclthread}" = "xunspecified" ; then
	MP_TCL_PACKAGE([Thread],
		[AC_MSG_RESULT([yes]); with_included_tclthread=no],
		[AC_MSG_RESULT([no]); with_included_tclthread=yes])
fi

# If thread package is not installed, configure and install thread package.
if test "${with_included_tclthread}" = "yes"; then
	OUR_INCLUDED_PACKAGES="${OUR_INCLUDED_PACKAGES} thread2.6"
	AC_CONFIG_SUBDIRS([src/thread2.6])
	# Extract thread package
	# (only if it has not already been extracted)
	if test ! -d src/thread2.6 ; then
		(cd src/; gzip -d < thread2.6.tar.gz | tar xf -)
		# If extracting a fresh copy, we have to patch the thread
		# package directory
		# (so that thread2.6 is the vanilla distribution directory)
		patch -p0 < src/thread2.6.diff
	fi
fi

AH_TEMPLATE([TRACE_SDK],[SDK for SDK redirect in tracelib])
AC_ARG_WITH([trace-sdk],
	[AS_HELP_STRING([--with-trace-sdk=SDK],
		[SDK for redirection in trace lib (for example MacOSX10.4u.sdk)])],
	[test -d ${DEVELOPER_DIR}/SDKs/${withval} && AC_DEFINE_UNQUOTED([TRACE_SDK],["${withval}"])],[])dnl

# Allows building of shared libraries
SC_ENABLE_SHARED

# Allows debugging
SC_ENABLE_SYMBOLS

# Allows use of nl_langinfo check
SC_ENABLE_LANGINFO

# Allows serial ports to be used
# (yes, serial ports are still used)
# (afaik, xnu can still only be debugged over a serial port)
SC_SERIAL_PORT

# Check blocking style
SC_BLOCKING_STYLE

# Pull compiler / linker values from tclConfig.sh
SC_CONFIG_CFLAGS
SC_BUGGY_STRTOD
SC_TCL_LINK_LIBS
SC_TCL_EARLY_FLAGS
SC_TCL_64BIT_FLAGS
LDFLAGS_DEBUG=${TCL_LDFLAGS_DEBUG}
LDFLAGS_OPTIMIZE=${TCL_LDFLAGS_OPTIMIZE}
SHLIB_LD=${TCL_SHLIB_LD}
STLIB_LD=${TCL_STLIB_LD}
SHLIB_CFLAGS=${TCL_SHLIB_CFLAGS}
SHLIB_SUFFIX=${TCL_SHLIB_SUFFIX}

AC_SUBST([AM_CPPFLAGS])dnl
AC_SUBST([PATHCONF])dnl
AC_SUBST([STLIB_LD])dnl
AC_SUBST([SHLIB_LD])dnl
AC_SUBST([SHLIB_CFLAGS])dnl
AC_SUBST([SHLIB_LDFLAGS])dnl
AC_SUBST([SHLIB_SUFFIX])dnl
AC_SUBST([TCL_DEFS])dnl
AC_SUBST([TCL_STUB_LIB_SPEC])dnl
AC_SUBST([TCL_CC])dnl
AC_SUBST([OUR_INCLUDED_PACKAGES])dnl

# misc variables that need to be expanded for substitution into tcl

oldprefix=${prefix}
if test "x${prefix}" = "xNONE" ; then
   prefix=${ac_default_prefix}
fi

# Check if there is an existing DP/MP install too old to upgrade
MP_CHECK_OLDLAYOUT

eval "prefix_expanded=${prefix}"
AC_SUBST([prefix_expanded])
# do this twice, since there is a nested variable of
# ${prefix} inside of ${sysconfdir}
eval "MPCONFIGDIR_EXPANDED=${MPCONFIGDIR}"
eval "MPCONFIGDIR_EXPANDED=${MPCONFIGDIR_EXPANDED}"
AC_SUBST([MPCONFIGDIR_EXPANDED])
eval "localstatedir_expanded=${localstatedir}"
AC_SUBST([localstatedir_expanded])
eval "macports_tcl_dir=${datadir}/macports/Tcl"
eval "macports_tcl_dir=${macports_tcl_dir}"
AC_SUBST([macports_tcl_dir])dnl

prefix=${oldprefix}

dnl# man page settings (compressed, links, etc)
dnl#
SC_CONFIG_MANPAGES

# Output
AC_CONFIG_FILES([Doxyfile
		 Makefile
		 Makefile_orig
		 Mk/macports.autoconf.mk
		 doc/base.mtree
		 doc/prefix.mtree
		 doc/macosx.mtree
		 doc/macports.conf
		 doc/pubkeys.conf
		 src/Makefile
		 src/Makefile_orig
		 src/cregistry/Makefile
		 src/machista1.0/Makefile
		 src/machista1.0/Makefile_orig
	 	 src/macports1.0/macports_autoconf.tcl
	 	 src/port1.0/port_autoconf.tcl
		 src/registry2.0/registry_autoconf.tcl
		 src/programs/Makefile
		 src/macports1.0/macports_fastload.tcl
		 setupenv.bash])dnl

dnl# Things removed from output files:
dnl# portmgr/freebsd/Makefile (not a regular "makefile")

AC_CONFIG_FILES([src/pkg_mkindex.sh],[chmod +x src/pkg_mkindex.sh])dnl

AC_OUTPUT
