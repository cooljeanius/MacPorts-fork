builtin(include,tcl.m4)

dnl This macro checks if the user specified a dports tree
dnl explicitly. If not, search for it

# OD_PATH_DPORTSDIR(DEFAULT_DPORTSDIR)
#---------------------------------------
 AC_DEFUN([OD_PATH_DPORTSDIR],[
 	dnl For ease of reading, run after gcc has been found/configured
 	AC_REQUIRE([AC_PROG_CC])

 	AC_ARG_WITH(dports-dir, [AC_HELP_STRING([--with-dports-dir=DIR], [Specify alternate dports directory])], [ dportsdir="$withval" ] )


 	AC_MSG_CHECKING([for dports tree])
 	if test "x$dportsdir" != "x" ; then
 	  if test -d "$dportsdir" -a -e "$dportsdir/PortIndex" ; then
 		:
 	  else
 		AC_MSG_ERROR([$dportsdir not a valid dports tree])
 	  fi
 	else
 		dnl If the user didn't give a path, look for default
 		if test "x$1" != "x" ; then
 		  if test -d "$1" -a -e "$1/PortIndex" ; then
 			dportsdir=$1
 		  fi
 		fi
 	fi

 	if test "x$dportsdir" != "x" ; then
 		AC_MSG_RESULT($dportsdir)
 		DPORTSDIR="$dportsdir"
 		AC_SUBST(DPORTSDIR)
 	else
 		AC_MSG_WARN([No dports tree found])
 	fi

         ])


# OD_PATH_PORTCONFIGDIR
#---------------------------------------
AC_DEFUN([OD_PATH_PORTCONFIGDIR],[
	dnl if the user actually specified --prefix, shift
	dnl portconfigdir to $prefix/etc/ports
	dnl 	AC_REQUIRE([OD_PATH_DPORTSDIR])
	
        AC_MSG_CHECKING([for ports config directory])

	portconfigdir='${sysconfdir}/ports'

	AC_MSG_RESULT([$portconfigdir])
	PORTCONFIGDIR="$portconfigdir"
        AC_SUBST(PORTCONFIGDIR)

	])

# OD_CHECK_INSTALLUSER
#-------------------------------------------------
AC_DEFUN([OD_CHECK_INSTALLUSER],[
	dnl if with user specifies --with-install-user,
	dnl use it. otherwise default to platform defaults
        AC_REQUIRE([OD_PATH_PORTCONFIGDIR])

	AC_ARG_WITH(install-user, [AC_HELP_STRING([--with-install-user=USER], [Specify user ownership of installed files])], [ DSTUSR=$withval ] )
	
	AC_MSG_CHECKING([for install user])
	if test "x$DSTUSR" = "x" ; then
	   DSTUSR=root
	fi

	AC_MSG_RESULT([$DSTUSR])
	AC_SUBST(DSTUSR)
])

# OD_CHECK_INSTALLGROUP
#-------------------------------------------------
AC_DEFUN([OD_CHECK_INSTALLGROUP],[
	dnl if with user specifies --with-install-group,
	dnl use it. otherwise default to platform defaults
        AC_REQUIRE([OD_CHECK_INSTALLUSER])

	AC_ARG_WITH(install-group, [AC_HELP_STRING([--with-install-group=GROUP], [Specify group ownership of installed files])], [ DSTGRP=$withval ] )

	AC_MSG_CHECKING([for install group])
	if test "x$DSTGRP" = "x" ; then
	   
	   case $host_os in
	   darwin*)
		DSTGRP="admin"
		;;
	   *)
		DSTGRP="wheel"
		;;
	   esac
	fi

	AC_MSG_RESULT([$DSTGRP])
	AC_SUBST(DSTGRP)
])

# OD_DIRECTORY_MODE
#-------------------------------------------------
AC_DEFUN([OD_DIRECTORY_MODE],[
	dnl if with user specifies --with-directory-mode,
	dnl use the specified permissions for ${prefix} directories
	dnl otherwise use 0775
        AC_REQUIRE([OD_PATH_PORTCONFIGDIR])

	AC_ARG_WITH(directory-mode, [AC_HELP_STRING([--with-directory-mode=MODE], [Specify directory mode of installed directories])], [ DSTMODE=$withval ] )
	
	AC_MSG_CHECKING([what permissions to use for installation directories])
	if test "x$DSTMODE" = "x" ; then
	   DSTMODE=0775
	fi

	AC_MSG_RESULT([$DSTMODE])
	AC_SUBST(DSTMODE)
])

# OD_LIB_MD5
#---------------------------------------
# Check for an md5 implementation
AC_DEFUN([OD_LIB_MD5],[

	# Check for libmd, which is prefered
	AC_CHECK_LIB([md], [MD5Update],[
		AC_CHECK_HEADERS([md5.h], ,[
			case $host_os in
				darwin*)	
					AC_MSG_NOTICE([Please install the BSD SDK package from the Xcode Developer Tools CD.])
					;;
				*)	
					AC_MSG_NOTICE([Please install the libmd developer headers for your platform.])
					;;
			esac
			AC_MSG_ERROR([libmd was found, but md5.h is missing.])
		])
		AC_DEFINE([HAVE_LIBMD], ,[Define if you have the `md' library (-lmd).])
		MD5_LIBS="-lmd"]
	)
	if test "x$MD5_LIBS" = "x" ; then
		# If libmd is not found, check for libcrypto from OpenSSL
		AC_CHECK_LIB([crypto], [MD5_Update],[
			AC_CHECK_HEADERS([openssl/md5.h],,[
				case $host_os in
					darwin*)	
					AC_MSG_NOTICE([Please install the BSD SDK package from the Xcode Developer Tools CD.])
						;;
					*)	
					AC_MSG_NOTICE([Please install the libmd developer headers for your platform.])
						;;
				esac
				AC_MSG_ERROR([libcrypt was found, but header file openssl/md5.h is missing.])
			])
			AC_DEFINE([HAVE_LIBCRYPTO],,[Define if you have the `crypto' library (-lcrypto).])
			MD5_LIBS="-lcrypto"
		], [
			AC_MSG_ERROR([Neither OpenSSL or libmd were found. A working md5 implementation is required.])
		])
	fi
	if test "x$MD5_LIBS" = "x"; then
		AC_MSG_ERROR([Neither OpenSSL or libmd were found. A working md5 implementation is required.])
	fi
	AC_SUBST([MD5_LIBS])
])

dnl This macro checks for X11 presence. If the libraries are
dnl present, so must the headers be. If nothing is present,
dnl print a warning

# OD_CHECK_X11
# ---------------------
AC_DEFUN([OD_CHECK_X11], [

	AC_PATH_XTRA

	# Check for libX11
	AC_CHECK_LIB([X11], [XOpenDisplay],[
		has_x_runtime=yes
		], [ has_x_runtime=no ], [-L/usr/X11R6/lib $X_LIBS])

# 	echo "------done---------"
# 	echo "x_includes=${x_includes}"
# 	echo "x_libraries=${x_libraries}"
# 	echo "no_x=${no_x}"
# 	echo "X_CFLAGS=${X_CFLAGS}"
# 	echo "X_LIBS=${X_LIBS}"
# 	echo "X_DISPLAY_MISSING=${X_DISPLAY_MISSING}"
# 	echo "has_x_runtime=${has_x_runtime}"
# 	echo "host_os=${host_os}"
# 	echo "------done---------"

	state=

	case "__${has_x_runtime}__${no_x}__" in
		"__no__yes__")
		# either the user said --without-x, or it was not found
		# at all (runtime or headers)
			AC_MSG_WARN([X11 not available. You will not be able to use dports that use X11])
			state=0
			;;
		"__yes__yes__")
			state=1
			;;
		"__yes____")
			state=2
			;;
		*)
			state=3
			;;
	esac

	case $host_os in
		darwin*)	
			case $state in
				1)
					cat <<EOF;
Please install the X11 SDK packages from the
Xcode Developer Tools CD
EOF
					AC_MSG_ERROR([Broken X11 install. No X11 headers])

					;;
				3)
					cat <<EOF;
Unknown configuration problem. Please install the X11 runtime
and/or X11 SDK  packages from the Xcode Developer Tools CD
EOF
					AC_MSG_ERROR([Broken X11 install])
					;;
			esac
			;;
		*)	
			case $state in
				1)
					cat <<EOF;
Please install the X11 developer headers for your platform
EOF
					AC_MSG_ERROR([Broken X11 install. No X11 headers])

					;;
				3)
					cat <<EOF;
Unknown configuration problem. Please install the X11
implementation for your platform
EOF
					AC_MSG_ERROR([Broken X11 install])
					;;
			esac
			;;
	esac

])

# OD_PROG_MTREE
#---------------------------------------
AC_DEFUN([OD_PROG_MTREE],[

	AC_PATH_PROG([MTREE], [mtree], ,  [/usr/bin:/usr/sbin:/bin:/sbin])

	if test "x$MTREE" = "x" ; then
		AC_CONFIG_SUBDIRS([src/programs/mtree])
		MTREE='$(TOPSRCDIR)/src/programs/mtree/mtree'
#		MTREE='${prefix}/bin/mtree'
		REPLACEMENT_PROGS="$REPLACEMENT_PROGS mtree"
	fi

	AC_SUBST(MTREE)
])

#------------------------------------------------------------------------
# OD_TCL_PACKAGE_DIR --
#
#	Locate the correct directory for Tcl package installation
#
# Arguments:
#	None.
#
# Requires:
#	TCLVERSION must be set
#	CYGPATH must be set
#	TCLSH must be set
#
# Results:
#
#	Adds a --with-tclpackage switch to configure.
#	Result is cached.
#
#	Substs the following vars:
#		TCL_PACKAGE_DIR
#------------------------------------------------------------------------

AC_DEFUN(OD_TCL_PACKAGE_DIR, [
    AC_MSG_CHECKING(for Tcl package directory)

    AC_ARG_WITH(tclpackage, [  --with-tclpackage       Tcl package installation directory.], with_tclpackagedir=${withval})

    if test x"${with_tclpackagedir}" != x ; then
	ac_cv_c_tclpkgd=${with_tclpackagedir}
    else
	AC_CACHE_VAL(ac_cv_c_tclpkgd, [
	    # Use the value from --with-tclpackagedir, if it was given

	    if test x"${with_tclpackagedir}" != x ; then
		ac_cv_c_tclpkgd=${with_tclpackagedir}
	    else
		# On darwin we can do some intelligent guessing
		case $host_os in
		    darwin*)
		    	tcl_autopath=`echo 'puts \$auto_path' | $TCLSH`
			for path in $tcl_autopath; do
			    if test "$path" = "/Library/Tcl"; then
				ac_cv_c_tclpkgd="$path"
				break
			    fi
			    if test "$path" = "/System/Library/Tcl"; then
				if test -d "$path"; then
				    ac_cv_c_tclpkgd="$path"
				    break
			        fi
			    fi
			done
		    ;;
		esac
    		if test x"${ac_cv_c_tclpkgd}" = x ; then
		    # Fudge a path from the first entry in the auto_path
		    tcl_pkgpath=`echo 'puts [[lindex \$auto_path 0]]' | $TCLSH`
		    if test -d "$tcl_pkgpath"; then
			ac_cv_c_tclpkgd="$tcl_pkgpath"
		    fi
		    # If the first entry does not exist, do nothing
		fi
	    fi
	])
    fi

    if test x"${ac_cv_c_tclpkgd}" = x ; then
	AC_MSG_ERROR(Tcl package directory not found.  Please specify its location with --with-tclpackagedir)
    else
	AC_MSG_RESULT(${ac_cv_c_tclpkgd})
    fi

    # Convert to a native path and substitute into the output files.

    PACKAGE_DIR_NATIVE=`${CYGPATH} ${ac_cv_c_tclpkgd}`

    TCL_PACKAGE_DIR=${PACKAGE_DIR_NATIVE}

    AC_SUBST(TCL_PACKAGE_DIR)
])

# OD_PROG_TCLSH
#---------------------------------------
AC_DEFUN([OD_PROG_TCLSH],[


	case $host_os in
		freebsd*)
			# FreeBSD installs a dummy tclsh (annoying)
			# Look for a real versioned tclsh first
			AC_PATH_PROG([TCLSH], [tclsh${TCL_VERSION} tclsh])
			;;
		*)
			# Otherwise, look for a non-versioned tclsh
			AC_PATH_PROG([TCLSH], [tclsh tclsh${TCL_VERSION}])
			;;
	esac
	if test "x$TCLSH" = "x" ; then
		AC_MSG_ERROR([Could not find tclsh])
	fi

	AC_SUBST(TCLSH)
])

# OD_TCL_THREAD_SUPPORT
#	Determine if thread support is available in tclsh and if thread package is
#   installed.
#
# Arguments:
#	None.
#
# Requires:
#	TCLSH must be set
#
# Results:
#
#   Fail if thread support isn't available.
#
#	Set the following vars:
#		with_tclthread
#---------------------------------------
AC_DEFUN([OD_TCL_THREAD_SUPPORT],[
    AC_ARG_WITH(
    		tclthread,
    		[  --with-tclthread        install included thread package.],
    		[with_tclthread="yes"],
			[with_tclthread="no"])

	AC_MSG_CHECKING([whether tclsh was compiled with threads])
	tcl_threadenabled=`echo 'puts [[info exists tcl_platform\(threaded\)]]' | $TCLSH`
	if test "$tcl_threadenabled" = "1" ; then
		AC_MSG_RESULT([yes])
	else
		AC_MSG_RESULT([no])
		AC_MSG_ERROR([tcl wasn't compiled with threads enabled])
	fi
	
	if test "x$with_tclthread" = "xno" ; then
		AC_MSG_CHECKING([for Tcl thread package])
		tcl_present=`echo 'if {[[catch {package require Thread}]]} {puts 0} else {puts 1}' | $TCLSH`
		if test "$tcl_present" = "1" ; then
			AC_MSG_RESULT([yes])
			with_tclthread=no
		else
			AC_MSG_RESULT([no])
			with_tclthread=yes
		fi
	fi
])

dnl This macro tests if the compiler supports GCC's
dnl __attribute__ syntax for unused variables/parameters
AC_DEFUN([OD_COMPILER_ATTRIBUTE_UNUSED], [
	AC_MSG_CHECKING([how to mark unused variables])
	AC_COMPILE_IFELSE(
		[AC_LANG_SOURCE([[int a __attribute__ ((unused));]])],
		[AC_DEFINE(UNUSED, [__attribute__((unused))], [Attribute to mark unused variables])],
		[AC_DEFINE(UNUSED, [])])

	AC_MSG_RESULT([])
	
])

dnl This macro ensures DP installation prefix bin/sbin paths are NOT in PATH
dnl for configure to prevent potential problems when base/ code is updated
dnl and ports are installed that would match needed items.
AC_DEFUN([OD_PATH_SCAN],[
	oldprefix=$prefix
	if test "x$prefix" = "xNONE" ; then
		prefix=$ac_default_prefix
	fi
	oldPATH=$PATH
	newPATH=
	as_save_IFS=$IFS; IFS=$PATH_SEPARATOR
	for as_dir in $oldPATH
	do
		IFS=$as_save_IFS
		if test "x$as_dir" != "x$prefix/bin" &&
			test "x$as_dir" != "x$prefix/sbin"; then
			if test -z "$newPATH"; then
				newPATH=$as_dir
			else
				newPATH=$newPATH$PATH_SEPARATOR$as_dir
			fi
		fi
	done
	PATH=$newPATH; export PATH
	prefix=$oldprefix
])

dnl This macro tests for tar support of --no-same-owner
AC_DEFUN([OD_TAR_NO_SAME_OWNER],[
	AC_PATH_PROG(TAR, [tar])
	AC_PATH_PROG(GNUTAR, [gnutar])
	
	AC_MSG_CHECKING([for which tar variant to use])
	AS_IF([test -n "$GNUTAR"], [TAR_CMD=$GNUTAR], [TAR_CMD=$TAR])
	AC_MSG_RESULT([$TAR_CMD])
	AC_SUBST(TAR_CMD)

	AC_MSG_CHECKING([for $TAR_CMD --no-same-owner support])
	[no_same_owner_support=`$TAR_CMD --help 2>&1 | grep no-same-owner`]
	if test -z "$no_same_owner_support" ; then
		AC_MSG_RESULT([no])
	else
		AC_MSG_RESULT([yes])
		TAR_CMD="$TAR_CMD --no-same-owner"
	fi
])

