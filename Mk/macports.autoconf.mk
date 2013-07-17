# $Id: macports.autoconf.mk.in 81642 2011-08-03 09:09:55Z jmr@macports.org $

SHELL			= /bin/sh


srcdir			= .


CC			= gcc -std=gnu99
CFLAGS			= -g -O2 $(CFLAGS_QUICHEEATERS) $(CFLAGS_PEDANTIC) $(CFLAGS_WERROR)
OBJCFLAGS		= -g -O2 $(CFLAGS_QUICHEEATERS) $(CFLAGS_PEDANTIC) $(CFLAGS_WERROR)
CPPFLAGS		=  -DHAVE_CONFIG_H -I.. -I.  -I"/System/Library/Frameworks/Tcl.framework/Versions/8.5/Headers"
TCL_DEFS		= -DPACKAGE_NAME=\"tcl\" -DPACKAGE_TARNAME=\"tcl\" -DPACKAGE_VERSION=\"8.5\" -DPACKAGE_STRING=\"tcl\ 8.5\" -DPACKAGE_BUGREPORT=\"\" -DSTDC_HEADERS=1 -DHAVE_SYS_TYPES_H=1 -DHAVE_SYS_STAT_H=1 -DHAVE_STDLIB_H=1 -DHAVE_STRING_H=1 -DHAVE_MEMORY_H=1 -DHAVE_STRINGS_H=1 -DHAVE_INTTYPES_H=1 -DHAVE_STDINT_H=1 -DHAVE_UNISTD_H=1 -DNO_VALUES_H=1 -DHAVE_LIMITS_H=1 -DHAVE_SYS_PARAM_H=1 -DUSE_THREAD_ALLOC=1 -D_REENTRANT=1 -D_THREAD_SAFE=1 -DHAVE_PTHREAD_ATTR_SETSTACKSIZE=1 -DHAVE_PTHREAD_GET_STACKSIZE_NP=1 -DTCL_THREADS=1 -DTCL_CFGVAL_ENCODING=\"iso8859-1\" -DMODULE_SCOPE=extern\ __attribute__\(\(__visibility__\(\"hidden\"\)\)\) -DMAC_OSX_TCL=1 -DHAVE_COREFOUNDATION=1 -DTCL_SHLIB_EXT=\".dylib\" -DTCL_CFG_OPTIMIZED=1 -DTCL_CFG_DEBUG=1 -DTCL_TOMMATH=1 -DMP_PREC=4 -DTCL_WIDE_INT_IS_LONG=1 -DHAVE_GETCWD=1 -DHAVE_OPENDIR=1 -DHAVE_STRTOL=1 -DHAVE_WAITPID=1 -DHAVE_GETADDRINFO=1 -DHAVE_GETPWUID_R_5=1 -DHAVE_GETPWUID_R=1 -DHAVE_GETPWNAM_R_5=1 -DHAVE_GETPWNAM_R=1 -DHAVE_GETGRGID_R_5=1 -DHAVE_GETGRGID_R=1 -DHAVE_GETGRNAM_R_5=1 -DHAVE_GETGRNAM_R=1 -DHAVE_MTSAFE_GETHOSTBYNAME=1 -DHAVE_MTSAFE_GETHOSTBYADDR=1 -DHAVE_SYS_TIME_H=1 -DTIME_WITH_SYS_TIME=1 -DHAVE_STRUCT_TM_TM_ZONE=1 -DHAVE_TM_ZONE=1 -DHAVE_GMTIME_R=1 -DHAVE_LOCALTIME_R=1 -DHAVE_MKTIME=1 -DHAVE_TM_GMTOFF=1 -DHAVE_TIMEZONE_VAR=1 -DHAVE_STRUCT_STAT_ST_BLKSIZE=1 -DHAVE_ST_BLKSIZE=1 -DHAVE_INTPTR_T=1 -DHAVE_UINTPTR_T=1 -DHAVE_SIGNED_CHAR=1 -DHAVE_LANGINFO=1 -DHAVE_CHFLAGS=1 -DHAVE_GETATTRLIST=1 -DHAVE_COPYFILE_H=1 -DHAVE_COPYFILE=1 -DHAVE_LIBKERN_OSATOMIC_H=1 -DHAVE_OSSPINLOCKLOCK=1 -DHAVE_PTHREAD_ATFORK=1 -DUSE_VFORK=1 -DTCL_DEFAULT_ENCODING=\"utf-8\" -DTCL_LOAD_FROM_MEMORY=1 -DTCL_WIDE_CLICKS=1 -DHAVE_AVAILABILITYMACROS_H=1 -DHAVE_WEAK_IMPORT=1 -D_DARWIN_C_SOURCE=1 -DHAVE_FTS=1 -DHAVE_SYS_IOCTL_H=1 -DHAVE_SYS_FILIO_H=1 -DTCL_UNLOAD_DLLS=1 -DUSE_DTRACE=1 -DTCL_FRAMEWORK=1 
SHLIB_CFLAGS		= -fno-common
CFLAGS_QUICHEEATERS	= -Wextra -Wall
CFLAGS_PEDANTIC		= -pedantic
CFLAGS_WERROR		= 

READLINE_CFLAGS		=
MD5_CFLAGS		=
SQLITE3_CFLAGS		= -I/opt/local/include
CURL_CFLAGS		= -I/opt/local/include

OBJC_RUNTIME		= APPLE_RUNTIME
OBJC_RUNTIME_FLAGS	= -fnext-runtime
OBJC_LIBS		= -lobjc

OBJC_FOUNDATION		= Apple
OBJC_FOUNDATION_CPPFLAGS	= 
OBJC_FOUNDATION_LDFLAGS		= 
OBJC_FOUNDATION_LIBS		= -framework Foundation

TCL_CC			= gcc
SHLIB_LD		= ${CC} -dynamiclib ${CFLAGS} ${LDFLAGS} -Wl,-single_module
STLIB_LD		= ${AR} cr
LDFLAGS			= -prebind
SHLIB_LDFLAGS		=  ${LDFLAGS}
SHLIB_SUFFIX		= .dylib
TCL_STUB_LIB_SPEC	= -L/System/Library/Frameworks/Tcl.framework/Versions/8.5 -ltclstub8.5

LIBS			= -ltcl  -lreadline -framework CoreFoundation
READLINE_LIBS		= -lreadline
MD5_LIBS		= 
SQLITE3_LIBS		= -L/opt/local/lib -lsqlite3
CURL_LIBS		= -L/opt/local/lib -lcurl -lcares -lidn -lssh2 -lssh2 -lssl -lcrypto -lssl -lcrypto -llber -lldap -lz
INSTALL			= /opt/local/bin/ginstall -c
MTREE			= /usr/sbin/mtree
LN_S			= ln -s
XCODEBUILD		= /usr/bin/xcodebuild
BZIP2			= /opt/local/bin/bzip2

TCLSH			= /opt/local/bin/tclsh
TCL_PACKAGE_DIR		= /opt/local/lib/tcl8.6
macports_tcl_dir	= /opt/local/share/macports/Tcl

DSCL			= /usr/bin/dscl
DSEDITGROUP		= /usr/sbin/dseditgroup
DSTUSR			= root
DSTGRP			= admin
DSTMODE			= 0755
RUNUSR			= macports

prefix			= /opt/local
sysconfdir		= ${prefix}/etc
exec_prefix		= ${prefix}
bindir			= ${exec_prefix}/bin
datarootdir		= ${prefix}/share
datadir			= ${datarootdir}
libdir			= ${exec_prefix}/lib
localstatedir		= ${prefix}/var
infodir			= ${datarootdir}/info

mpconfigdir		= ${sysconfdir}/macports
portsdir		= 

SILENT			= @
