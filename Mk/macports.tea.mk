# $Id: macports.tea.mk 66305 2010-04-09 00:13:29Z raimue@macports.org $

SUFFIXES = .m .c .o
.SUFFIXES: .m .c .o

.m.o:
	${CC} -c -DUSE_TCL_STUBS -DTCL_NO_DEPRECATED ${OBJCFLAGS} ${CPPFLAGS} ${SHLIB_CFLAGS} $< -o $@

.c.o:
	${CC} -c -DUSE_TCL_STUBS -DTCL_NO_DEPRECATED ${CFLAGS} ${CPPFLAGS} ${SHLIB_CFLAGS} $< -o $@

all-local:: ${SHLIB_NAME} pkgIndex.tcl

$(SHLIB_NAME):: ${OBJS}
	${SHLIB_LD} ${OBJS} -o ${SHLIB_NAME} ${TCL_STUB_LIB_SPEC} ${SHLIB_LDFLAGS} ${LIBS}

pkgIndex.tcl: $(SHLIB_NAME)
	$(SILENT) ../pkg_mkindex.sh . || ( rm -rf $@ && exit 1 )

clean-local::
	rm -f ${OBJS} ${SHLIB_NAME} so_locations pkgIndex.tcl

distclean-local:: clean-local

install-data-and-exec-local:: all-local
	$(INSTALL) -d -o ${DSTUSR} -g ${DSTGRP} -m ${DSTMODE} ${INSTALLDIR}
	$(INSTALL) -o ${DSTUSR} -g ${DSTGRP} -m 444 ${SHLIB_NAME} ${INSTALLDIR}
	$(INSTALL) -o ${DSTUSR} -g ${DSTGRP} -m 444 pkgIndex.tcl ${INSTALLDIR}
