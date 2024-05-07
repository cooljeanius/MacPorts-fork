OBJS= 		libmachista.o hashmap.o machista_wrap.o
SHLIB_NAME= machista${SHLIB_SUFFIX}
INSTALLDIR=	${DESTDIR}${datadir}/macports/Tcl/machista1.0

SWIG         = @SWIG@
SWIG_FLAGS   = -tcl8 -pkgversion 1.0 -namespace
LDFLAGS_FOR_SWIG = -ltcl

SWIG_IFACE = machista.i
SWIG_SRCS  = ${SWIG_IFACE:%.i=%_wrap.c}
SWIG_OBJS  = ${SWIG_SRCS:%.c=%.o}

TESTS = ./tests/libmachista-test

include ../../Mk/macports.autoconf.mk.am
@ifGNUmake@include ../../Mk/macports.tea.mk

CFLAGS+= -fPIC -std=c99 -pedantic

${SWIG_SRCS}:: ${SWIG_IFACE}
@ifGNUmake@ifdef SWIG
@ifGNUmake@	${SWIG} ${SWIG_FLAGS} $<
@ifGNUmake@else
@ifGNUmake@	@echo "Building ${SWIG_SRCS} requires swig, which you apparently did not have installed when configuring MacPorts." >&2
@ifGNUmake@	@echo "Please install swig and re-run configure" >&2
@ifGNUmake@	@echo "I recommend installing SWIG 1.x in /opt/swig, because as of this writing SWIG 2.x-generated code does not compile warning-free" >&2
@ifGNUmake@	@echo "To use this SWIG, run configure as follows:" >&2
@ifGNUmake@	@echo "    SWIG=/opt/swig/bin/swig ./configure --your-usual-config-flags" >&2
@ifGNUmake@	@echo "If you checked out from svn you can also run svn revert in base/src/machista1.0 to get rid of this error" >&2
@ifGNUmake@	@exit 1
@ifGNUmake@endif

${SWIG_OBJS}:: ${SWIG_SRCS}

${PKG_INDEX}:: ${SWIG_SHLIB}
	$(SILENT) ../pkg_mkindex.sh $< || ( rm -rf $@ && exit 1 )

clean-local::
	rm -f ${SWIG_OBJS} ${PKG_INDEX}
	rm -f ${TESTS}
	rm -rf ${TESTS:%=%.dSYM}
distclean-local: clean-local

test:: ${TESTS}
	${TESTS}

tests/libmachista-test: tests/libmachista-test.c libmachista.h libmachista.o hashmap.o
	$(CC) $(CFLAGS) -D_POSIX_SOURCE -o $@ -I. $< libmachista.o hashmap.o

