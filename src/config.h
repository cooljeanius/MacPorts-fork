/* src/config.h.  Generated from config.h.in by configure.  */
/* src/config.h.in.  Generated from configure.ac by autoheader.  */

/* Define if using the Apple Foundation framework */
#define APPLE_FOUNDATION 1

/* Define if using the Apple Objective-C runtime and compiler. */
#define APPLE_RUNTIME 1

/* Define to nothing if C supports flexible array members, and to 1 if it does
   not. That way, with a declaration like `struct s { int n; double
   d[FLEXIBLE_ARRAY_MEMBER]; };', the struct hack can be used with pre-C99
   compilers. When computing the size of such an object, don't use 'sizeof
   (struct s)' as it overestimates the size. Use 'offsetof (struct s, d)'
   instead. Don't use 'offsetof (struct s, d[0])', as this doesn't work with
   MSVC and with C++ compilers. */
#define FLEXIBLE_ARRAY_MEMBER /**/

/* Define if using the GNUstep Foundation library */
/* #undef GNUSTEP_FOUNDATION */

/* Define if using the GNU Objective-C runtime and compiler. */
/* #undef GNU_RUNTIME */

/* Define to 1 if you have the `bzero' function. */
#define HAVE_BZERO 1

/* Define to 1 if your system has a working `chown' function. */
#define HAVE_CHOWN 1

/* Define to 1 if you have the `clearenv' function. */
/* #undef HAVE_CLEARENV */

/* Define if CommonCrypto is available. */
#define HAVE_COMMONCRYPTO_COMMONDIGEST_H 1

/* Define to 1 if you have the `copyfile' function. */
#define HAVE_COPYFILE 1

/* Define to 1 if you have the <crt_externs.h> header file. */
#define HAVE_CRT_EXTERNS_H 1

/* Define to 1 if you have the <curl/curlrules.h> header file. */
/* #undef HAVE_CURL_CURLRULES_H */

/* Define to 1 if you have the <curl/curl.h> header file. */
#define HAVE_CURL_CURL_H 1

/* Define to 1 if C supports variable-length arrays. */
#define HAVE_C_VARARRAYS 1

/* Define to 1 if you have the declaration of `completion_matches', and to 0
   if you don't. */
#define HAVE_DECL_COMPLETION_MATCHES 0

/* Define to 1 if you have the declaration of `filename_completion_function',
   and to 0 if you don't. */
#define HAVE_DECL_FILENAME_COMPLETION_FUNCTION 0

/* Define to 1 if you have the declaration of `rl_completion_matches', and to
   0 if you don't. */
#define HAVE_DECL_RL_COMPLETION_MATCHES 1

/* Define to 1 if you have the declaration of
   `rl_filename_completion_function', and to 0 if you don't. */
#define HAVE_DECL_RL_FILENAME_COMPLETION_FUNCTION 1

/* Define to 1 if you have the declaration of
   `rl_username_completion_function', and to 0 if you don't. */
#define HAVE_DECL_RL_USERNAME_COMPLETION_FUNCTION 1

/* Define to 1 if you have the declaration of `tzname', and to 0 if you don't.
   */
/* #undef HAVE_DECL_TZNAME */

/* Define to 1 if you have the declaration of `username_completion_function',
   and to 0 if you don't. */
#define HAVE_DECL_USERNAME_COMPLETION_FUNCTION 0

/* Define to 1 if you have the <dirent.h> header file, and it defines `DIR'.
   */
#define HAVE_DIRENT_H 1

/* Define to 1 if you have the <dlfcn.h> header file. */
#define HAVE_DLFCN_H 1

/* Define to 1 if you have the `dup2' function. */
#define HAVE_DUP2 1

/* Define to 1 if you have the <err.h> header file. */
#define HAVE_ERR_H 1

/* Define to 1 if you have the <fcntl.h> header file. */
#define HAVE_FCNTL_H 1

/* Define to 1 if you have the `fgetln' function. */
#define HAVE_FGETLN 1

/* Define to 1 if you have the `flock' function. */
#define HAVE_FLOCK 1

/* Define to 1 if you have the `fork' function. */
#define HAVE_FORK 1

/* Define to 1 if CoreFoundation framework is available */
#define HAVE_FRAMEWORK_COREFOUNDATION 1

/* Defined to 1 if IOKit framework is available */
#define HAVE_FRAMEWORK_IOKIT 1

/* Defined to 1 if SystemConfiguration framework is available */
#define HAVE_FRAMEWORK_SYSTEMCONFIGURATION 1

/* Defined to 1 if function CFNotificationCenterGetDarwinNotifyCenter in
   CoreFoundation framework */
#define HAVE_FUNCTION_CFNOTIFICATIONCENTERGETDARWINNOTIFYCENTER 1

/* Define to 1 if you have the `getcwd' function. */
#define HAVE_GETCWD 1

/* Define to 1 if you have the `getpagesize' function. */
#define HAVE_GETPAGESIZE 1

/* Define to 1 if you have the `gmtime_r' function. */
#define HAVE_GMTIME_R 1

/* Define to 1 if you have the <history.h> header file. */
/* #undef HAVE_HISTORY_H */

/* Define to 1 if the system has the type `intmax_t'. */
#define HAVE_INTMAX_T 1

/* Define to 1 if the system has the type `intptr_t'. */
#define HAVE_INTPTR_T 1

/* Define to 1 if you have the <inttypes.h> header file. */
#define HAVE_INTTYPES_H 1

/* Defined to 1 if we have langinfo */
#define HAVE_LANGINFO 1

/* Define to 1 if you have the `lchown' function. */
#define HAVE_LCHOWN 1

/* Defined to 1 if you have the `crypto' library (-lcrypto). */
/* #undef HAVE_LIBCRYPTO */

/* Define to 1 if you have a functional curl library. */
#define HAVE_LIBCURL 1

/* Defined to 1 if you have the `md' library (-lmd). */
/* #undef HAVE_LIBMD */

/* Define to 1 if you have the 'readline' library (-lreadline). */
#define HAVE_LIBREADLINE 1

/* Define to 1 if you have the `tcl' library (-ltcl). */
#define HAVE_LIBTCL 1

/* Define to 1 if you have the <limits.h> header file. */
#define HAVE_LIMITS_H 1

/* Define to 1 if you have the `localtime_r' function. */
#define HAVE_LOCALTIME_R 1

/* Define to 1 if you have the `lockf' function. */
#define HAVE_LOCKF 1

/* Define to 1 if the system has the type `long double'. */
#define HAVE_LONG_DOUBLE 1

/* Define to 1 if the type `long double' works and has more range or precision
   than `double'. */
#define HAVE_LONG_DOUBLE_WIDER 1

/* Define to 1 if the system has the type `long long int'. */
#define HAVE_LONG_LONG_INT 1

/* Define to 1 if you have the <mach/mach.h> header file. */
#define HAVE_MACH_MACH_H 1

/* Define to 1 if your system has a GNU libc compatible `malloc' function, and
   to 0 otherwise. */
#define HAVE_MALLOC 1

/* Define to 1 if you have the <md5.h> header file. */
/* #undef HAVE_MD5_H */

/* Define to 1 if you have the `memmove' function. */
#define HAVE_MEMMOVE 1

/* Define to 1 if you have the <memory.h> header file. */
#define HAVE_MEMORY_H 1

/* Define to 1 if you have the `memset' function. */
#define HAVE_MEMSET 1

/* Define to 1 if you have the `mkdir' function. */
#define HAVE_MKDIR 1

/* Define to 1 if you have a working `mmap' system call. */
#define HAVE_MMAP 1

/* Define to 1 if you have the `munmap' function. */
#define HAVE_MUNMAP 1

/* Define to 1 if you have the <ndir.h> header file, and it defines `DIR'. */
/* #undef HAVE_NDIR_H */

/* Defined to 1 if we have net/errno.h */
/* #undef HAVE_NET_ERRNO_H */

/* Define to 1 if you have the <objc/objc.h> header file. */
#define HAVE_OBJC_OBJC_H 1

/* Define to 1 if you have the <openssl/md5.h> header file. */
/* #undef HAVE_OPENSSL_MD5_H */

/* Define to 1 if you have the <openssl/ripemd.h> header file. */
/* #undef HAVE_OPENSSL_RIPEMD_H */

/* Define to 1 if you have the <openssl/sha.h> header file. */
/* #undef HAVE_OPENSSL_SHA_H */

/* Define to 1 if you have the <paths.h> header file. */
#define HAVE_PATHS_H 1

/* Define if you have POSIX threads libraries and header files. */
#define HAVE_PTHREAD 1

/* Have PTHREAD_PRIO_INHERIT. */
#define HAVE_PTHREAD_PRIO_INHERIT 1

/* Define to 1 if you have the <pwd.h> header file. */
#define HAVE_PWD_H 1

/* Define to 1 if you have the <readline.h> header file. */
/* #undef HAVE_READLINE_H */

/* Define if your readline library has \`add_history' */
#define HAVE_READLINE_HISTORY 1

/* Define to 1 if you have the <readline/history.h> header file. */
#define HAVE_READLINE_HISTORY_H 1

/* Define to 1 if you have the <readline/readline.h> header file. */
#define HAVE_READLINE_READLINE_H 1

/* Define to 1 if your system has a GNU libc compatible `realloc' function,
   and to 0 otherwise. */
#define HAVE_REALLOC 1

/* Define to 1 if you have the `realpath' function. */
#define HAVE_REALPATH 1

/* Define to 1 if you have the `regcomp' function. */
#define HAVE_REGCOMP 1

/* Define to 1 if you have the <ripemd.h> header file. */
/* #undef HAVE_RIPEMD_H */

/* Define to 1 if you have the `rmdir' function. */
#define HAVE_RMDIR 1

/* Define to 1 if you have the `select' function. */
#define HAVE_SELECT 1

/* Define to 1 if you have the `setenv' function. */
#define HAVE_SETENV 1

/* Define to 1 if you have the `setmode' function. */
#define HAVE_SETMODE 1

/* Define to 1 if you have the `SHA1_File' function. */
/* #undef HAVE_SHA1_FILE */

/* Define to 1 if you have the <sha256.h> header file. */
/* #undef HAVE_SHA256_H */

/* Define to 1 if you have the `SHA256_Update' function. */
/* #undef HAVE_SHA256_UPDATE */

/* Define to 1 if you have the <sha.h> header file. */
/* #undef HAVE_SHA_H */

/* Define to 1 if you have the `socket' function. */
#define HAVE_SOCKET 1

/* Define to 1 if you have the <sqlite3ext.h> header file. */
#define HAVE_SQLITE3EXT_H 1

/* Define to 1 if you have the <stdint.h> header file. */
#define HAVE_STDINT_H 1

/* Define to 1 if you have the <stdio.h> header file. */
#define HAVE_STDIO_H 1

/* Define to 1 if you have the <stdlib.h> header file. */
#define HAVE_STDLIB_H 1

/* Define to 1 if you have the `strcasecmp' function. */
#define HAVE_STRCASECMP 1

/* Define to 1 if you have the `strchr' function. */
#define HAVE_STRCHR 1

/* Define to 1 if you have the `strdup' function. */
#define HAVE_STRDUP 1

/* Define to 1 if you have the `strerror' function. */
#define HAVE_STRERROR 1

/* Define to 1 if you have the <strings.h> header file. */
#define HAVE_STRINGS_H 1

/* Define to 1 if you have the <string.h> header file. */
#define HAVE_STRING_H 1

/* Define to 1 if you have the `strlcpy' function. */
#define HAVE_STRLCPY 1

/* Define to 1 if you have the `strncasecmp' function. */
#define HAVE_STRNCASECMP 1

/* Define to 1 if you have the `strrchr' function. */
#define HAVE_STRRCHR 1

/* Define to 1 if you have the `strstr' function. */
#define HAVE_STRSTR 1

/* Define to 1 if you have the `strtol' function. */
#define HAVE_STRTOL 1

/* Define to 1 if you have the `strtoul' function. */
#define HAVE_STRTOUL 1

/* Defined to 1 if we have the dirent64 struct */
/* #undef HAVE_STRUCT_DIRENT64 */

/* Defined to 1 if we have the stat64 struct */
/* #undef HAVE_STRUCT_STAT64 */

/* Define to 1 if `tm_zone' is a member of `struct tm'. */
#define HAVE_STRUCT_TM_TM_ZONE 1

/* Define to 1 if you have the `sysctlbyname' function. */
#define HAVE_SYSCTLBYNAME 1

/* Define to 1 if you have the <sys/cdefs.h> header file. */
#define HAVE_SYS_CDEFS_H 1

/* Define to 1 if you have the <sys/dir.h> header file, and it defines `DIR'.
   */
/* #undef HAVE_SYS_DIR_H */

/* Define to 1 if you have the <sys/fcntl.h> header file. */
#define HAVE_SYS_FCNTL_H 1

/* Define to 1 if you have the <sys/file.h> header file. */
#define HAVE_SYS_FILE_H 1

/* Define to 1 if you have the <sys/filio.h> header file. */
#define HAVE_SYS_FILIO_H 1

/* Define to 1 if you have the <sys/ioctl.h> header file. */
#define HAVE_SYS_IOCTL_H 1

/* Define to 1 if you have the <sys/modem.h> header file. */
/* #undef HAVE_SYS_MODEM_H */

/* Define to 1 if you have the <sys/mount.h> header file. */
#define HAVE_SYS_MOUNT_H 1

/* Define to 1 if you have the <sys/ndir.h> header file, and it defines `DIR'.
   */
/* #undef HAVE_SYS_NDIR_H */

/* Define to 1 if you have the <sys/param.h> header file. */
#define HAVE_SYS_PARAM_H 1

/* Define to 1 if you have the <sys/paths.h> header file. */
#define HAVE_SYS_PATHS_H 1

/* Define to 1 if you have the <sys/socket.h> header file. */
#define HAVE_SYS_SOCKET_H 1

/* Define to 1 if you have the <sys/stat.h> header file. */
#define HAVE_SYS_STAT_H 1

/* Define to 1 if you have the <sys/sysctl.h> header file. */
#define HAVE_SYS_SYSCTL_H 1

/* Define to 1 if you have the <sys/time.h> header file. */
#define HAVE_SYS_TIME_H 1

/* Define to 1 if you have the <sys/types.h> header file. */
#define HAVE_SYS_TYPES_H 1

/* Define to 1 if you have <sys/wait.h> that is POSIX.1 compatible. */
#define HAVE_SYS_WAIT_H 1

/* Define to 1 if `errorLine' is a member of `Tcl_Interp'. */
/* #undef HAVE_TCL_INTERP_ERRORLINE */

/* Defined to time_t if we have time_t timezone variable */
#define HAVE_TIMEZONE_VAR long

/* Defined to 1 if we have tm_gmtoff in struct tm */
#define HAVE_TM_GMTOFF 1

/* Defined to 1 if we have tm_tzadj in struct tm */
/* #undef HAVE_TM_TZADJ */

/* Define to 1 if your `struct tm' has `tm_zone'. Deprecated, use
   `HAVE_STRUCT_TM_TM_ZONE' instead. */
#define HAVE_TM_ZONE 1

/* Defined to 1 if we have the off64_T type */
/* #undef HAVE_TYPE_OFF64_T */

/* Define to 1 if you don't have `tm_zone' but do have the external array
   `tzname'. */
/* #undef HAVE_TZNAME */

/* Define to 1 if the system has the type `uintmax_t'. */
#define HAVE_UINTMAX_T 1

/* Define to 1 if the system has the type `uintptr_t'. */
#define HAVE_UINTPTR_T 1

/* Define to 1 if you have the <unistd.h> header file. */
#define HAVE_UNISTD_H 1

/* Define to 1 if the system has the type `unsigned long long int'. */
#define HAVE_UNSIGNED_LONG_LONG_INT 1

/* Define to 1 if you have the `utime' function. */
#define HAVE_UTIME 1

/* Define to 1 if you have the <utime.h> header file. */
#define HAVE_UTIME_H 1

/* Define to 1 if you have the `vfork' function. */
#define HAVE_VFORK 1

/* Define to 1 if you have the <vfork.h> header file. */
/* #undef HAVE_VFORK_H */

/* Define to 1 if `fork' works. */
#define HAVE_WORKING_FORK 1

/* Define to 1 if `vfork' works. */
#define HAVE_WORKING_VFORK 1

/* Define to 1 if the system has the type `_Bool'. */
#define HAVE__BOOL 1

/* define if your compiler has __attribute__ */
#define HAVE___ATTRIBUTE__ 1

/* Defined if libcurl supports AsynchDNS */
#define LIBCURL_FEATURE_ASYNCHDNS 1

/* Defined if libcurl supports IDN */
#define LIBCURL_FEATURE_IDN 1

/* Defined if libcurl supports IPv6 */
#define LIBCURL_FEATURE_IPV6 1

/* Defined if libcurl supports KRB4 */
/* #undef LIBCURL_FEATURE_KRB4 */

/* Defined if libcurl supports libz */
#define LIBCURL_FEATURE_LIBZ 1

/* Defined if libcurl supports NTLM */
#define LIBCURL_FEATURE_NTLM 1

/* Defined if libcurl supports SSL */
#define LIBCURL_FEATURE_SSL 1

/* Defined if libcurl supports SSPI */
/* #undef LIBCURL_FEATURE_SSPI */

/* Defined if libcurl supports DICT */
#define LIBCURL_PROTOCOL_DICT 1

/* Defined if libcurl supports FILE */
#define LIBCURL_PROTOCOL_FILE 1

/* Defined if libcurl supports FTP */
#define LIBCURL_PROTOCOL_FTP 1

/* Defined if libcurl supports FTPS */
#define LIBCURL_PROTOCOL_FTPS 1

/* Defined if libcurl supports HTTP */
#define LIBCURL_PROTOCOL_HTTP 1

/* Defined if libcurl supports HTTPS */
#define LIBCURL_PROTOCOL_HTTPS 1

/* Defined if libcurl supports IMAP */
#define LIBCURL_PROTOCOL_IMAP 1

/* Defined if libcurl supports LDAP */
#define LIBCURL_PROTOCOL_LDAP 1

/* Defined if libcurl supports POP3 */
#define LIBCURL_PROTOCOL_POP3 1

/* Defined if libcurl supports RTSP */
#define LIBCURL_PROTOCOL_RTSP 1

/* Defined if libcurl supports SMTP */
#define LIBCURL_PROTOCOL_SMTP 1

/* Defined if libcurl supports TELNET */
#define LIBCURL_PROTOCOL_TELNET 1

/* Defined if libcurl supports TFTP */
#define LIBCURL_PROTOCOL_TFTP 1

/* Define to 1 if `lstat' dereferences a symlink specified with a trailing
   slash. */
/* #undef LSTAT_FOLLOWS_SLASHED_SYMLINK */

/* Define to the sub-directory in which libtool stores uninstalled libraries.
   */
#define LT_OBJDIR ".libs/"

/* Lowest non-system-reserved GID. */
#define MIN_USABLE_GID 500

/* Lowest non-system-reserved UID. */
#define MIN_USABLE_UID 500

/* Mark private symbols */
#define MP_PRIVATE __attribute__((visibility("hidden")))

/* Defined to 1 if there is no dirent.h */
/* #undef NO_DIRENT_H */

/* Defined to 1 if there is no dlfcn.h */
/* #undef NO_DLFCN_H */

/* Defined to 1 if there is no errno.h */
/* #undef NO_ERRNO_H */

/* Defined to 1 if there is no float.h */
/* #undef NO_FLOAT_H */

/* Defined to 1 if there is no limits.h */
/* #undef NO_LIMITS_H */

/* Defined to 1 if there is no stdlib.h */
/* #undef NO_STDLIB_H */

/* Defined to 1 if there is no string.h */
/* #undef NO_STRING_H */

/* Defined to 1 if there is no sys/wait.h */
/* #undef NO_SYS_WAIT_H */

/* Defined to 1 if there is no values.h */
#define NO_VALUES_H 1

/* Name of package */
#define PACKAGE "macports"

/* Define to the address where bug reports for this package should be sent. */
#define PACKAGE_BUGREPORT "macports-dev@lists.macosforge.org"

/* Define to the full name of this package. */
#define PACKAGE_NAME "MacPorts"

/* Define to the full name and version of this package. */
#define PACKAGE_STRING "MacPorts 2.1.3"

/* Define to the one symbol short name of this package. */
#define PACKAGE_TARNAME "macports"

/* Define to the home page for this package. */
#define PACKAGE_URL ""

/* Define to the version of this package. */
#define PACKAGE_VERSION "2.1.3"

/* Define to 1 if XIM peeking works under XFree86. */
/* #undef PEEK_XCLOSEIM */

/* Define to necessary symbol if this constant uses a non-standard name on
   your system. */
/* #undef PTHREAD_CREATE_JOINABLE */

/* Define to 1 if readlink does not conform with POSIX 1003.1a (where third
   argument is a size_t and return value is a ssize_t) */
/* #undef READLINK_IS_NOT_P1003_1A */

/* The size of `long', as computed by sizeof. */
#define SIZEOF_LONG 8

/* Define to 1 if static build is requested */
/* #undef STATIC_BUILD */

/* Define to 1 if you have the ANSI C header files. */
#define STDC_HEADERS 1

/* Defined to 1 if compiling for debugging */
/* #undef TCL_COMPILE_DEBUG */

/* Defined to 1 if compiling with stats */
/* #undef TCL_COMPILE_STATS */

/* Defined to 1 if using the Tcl memdebug feature */
/* #undef TCL_MEM_DEBUG */

/* Defined to 1 if using long */
#define TCL_WIDE_INT_IS_LONG 1

/* Tcl wide int type */
/* #undef TCL_WIDE_INT_TYPE */

/* Define to 1 if you can safely include both <sys/time.h> and <time.h>. */
#define TIME_WITH_SYS_TIME 1

/* Define to 1 if your <sys/time.h> declares `struct tm'. */
/* #undef TM_IN_SYS_TIME */

/* SDK for SDK redirect in tracelib */
/* #undef TRACE_SDK */

/* Attribute to mark unused variables */
#define UNUSED __attribute__((unused))

/* Defined to 1 if using a.out.h */
/* #undef USE_A_OUT_H */

/* Defined to 1 if using delta for tz */
/* #undef USE_DELTA_FOR_TZ */

/* Defined to 1 if using FIONBIO */
/* #undef USE_FIONBIO */

/* Defined to 1 if using sgtty */
/* #undef USE_SGTTY */

/* Enable extensions on AIX 3, Interix.  */
#ifndef _ALL_SOURCE
# define _ALL_SOURCE 1
#endif
/* Enable GNU extensions on systems that have them.  */
#ifndef _GNU_SOURCE
# define _GNU_SOURCE 1
#endif
/* Enable threading extensions on Solaris.  */
#ifndef _POSIX_PTHREAD_SEMANTICS
# define _POSIX_PTHREAD_SEMANTICS 1
#endif
/* Enable extensions on HP NonStop.  */
#ifndef _TANDEM_SOURCE
# define _TANDEM_SOURCE 1
#endif
/* Enable general extensions on Solaris.  */
#ifndef __EXTENSIONS__
# define __EXTENSIONS__ 1
#endif


/* Defined to 1 if using sys/exec_aout.h */
/* #undef USE_SYS_EXEC_AOUT_H */

/* Defined to 1 if using sys/exec.h */
/* #undef USE_SYS_EXEC_H */

/* Defined to 1 if using termio */
/* #undef USE_TERMIO */

/* Defined to 1 if using termios */
/* #undef USE_TERMIOS */

/* Version number of package */
#define VERSION "2.1.3"

/* Define if using the dmalloc debugging malloc package */
/* #undef WITH_DMALLOC */

/* Define to 1 if `lex' declares `yytext' as a `char *' by default, not a
   `char[]'. */
#define YYTEXT_POINTER 1

/* Defined to 1 for _ISOC99_SOURCE */
/* #undef _ISOC99_SOURCE */

/* Defined to 1 for _LARGEFILE64_SOURCE */
/* #undef _LARGEFILE64_SOURCE */

/* Define to 1 if on MINIX. */
/* #undef _MINIX */

/* This define is needed in sys/socket.h */
/* #undef _OE_SOCKETS */

/* Define to 2 if the system does not provide POSIX.1 features except with
   this defined. */
/* #undef _POSIX_1_SOURCE */

/* Defined to 1 if using POSIX pthread semantics */
#define _POSIX_PTHREAD_SEMANTICS 1

/* Define to 1 if you need to in order for `stat' and other things to work. */
/* #undef _POSIX_SOURCE */

/* If this is not defined, then Solaris will not define thread-safe library
   routines. */
/* #undef _REENTRANT */

/* Define for Solaris 2.5.1 so the uint32_t typedef from <sys/synch.h>,
   <pthread.h>, or <semaphore.h> is not used. If the typedef were allowed, the
   #define below would cause a syntax error. */
/* #undef _UINT32_T */

/* Define for Solaris 2.5.1 so the uint8_t typedef from <sys/synch.h>,
   <pthread.h>, or <semaphore.h> is not used. If the typedef were allowed, the
   #define below would cause a syntax error. */
/* #undef _UINT8_T */

/* Define to 1 to use the XOPEN network library */
/* #undef _XOPEN_SOURCE */

/* Define to 1 to use the XOPEN network library */
/* #undef _XOPEN_SOURCE_EXTENDED */

/* Define curl_free() as free() if our version of curl lacks curl_free. */
/* #undef curl_free */

/* Define to `int' if <sys/types.h> doesn't define. */
/* #undef gid_t */

/* Define to `__inline__' or `__inline' if that's what the C compiler
   calls it, or to nothing if 'inline' is not supported under any name.  */
#ifndef __cplusplus
/* #undef inline */
#endif

/* Define to the widest signed integer type if <stdint.h> and <inttypes.h> do
   not define. */
/* #undef intmax_t */

/* Define to the type of a signed integer type wide enough to hold a pointer,
   if such a type exists, and if the system does not define it. */
/* #undef intptr_t */

/* Define to rpl_malloc if the replacement function should be used. */
/* #undef malloc */

/* Define to `int' if <sys/types.h> does not define. */
/* #undef mode_t */

/* Define to `long int' if <sys/types.h> does not define. */
/* #undef off_t */

/* Define to `int' if <sys/types.h> does not define. */
/* #undef pid_t */

/* Define to rpl_realloc if the replacement function should be used. */
/* #undef realloc */

/* Define to `unsigned int' if <sys/types.h> does not define. */
/* #undef size_t */

/* define sqlite3_prepare to sqlite_prepare_v2 if the latter is not available
   */
/* #undef sqlite3_prepare_v2 */

/* Define to `int' if <sys/types.h> does not define. */
/* #undef ssize_t */

/* Defined to fixstrtod if the original strtod was broken */
/* #undef strtod */

/* Define to `int' if <sys/types.h> doesn't define. */
/* #undef uid_t */

/* Define to the type of an unsigned integer type of width exactly 32 bits if
   such a type exists and the standard includes do not define it. */
/* #undef uint32_t */

/* Define to the type of an unsigned integer type of width exactly 8 bits if
   such a type exists and the standard includes do not define it. */
/* #undef uint8_t */

/* Define to the widest unsigned integer type if <stdint.h> and <inttypes.h>
   do not define. */
/* #undef uintmax_t */

/* Define to the type of an unsigned integer type wide enough to hold a
   pointer, if such a type exists, and if the system does not define it. */
/* #undef uintptr_t */

/* Define as `fork' if `vfork' does not work. */
/* #undef vfork */
