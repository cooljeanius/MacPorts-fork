OBJS=		darwintrace.o
SHLIB_NAME=	darwintrace${SHLIB_SUFFIX}
INSTALLDIR=	${DESTDIR}${datadir}/macports/Tcl/darwintrace1.0

test::

include ../../Mk/macports.autoconf.mk
include ../../Mk/macports.tea.mk

CFLAGS+= -fPIC -Wno-deprecated-declarations
CFLAGS_PEDANTIC=

all-local:: ${SHLIB_NAME}

$(SHLIB_NAME):: ${OBJS}
	${SHLIB_LD} ${OBJS} -o ${SHLIB_NAME} ${SHLIB_LDFLAGS} ${LIBS}

clean-local::
	rm -f ${OBJS} ${SHLIB_NAME} so_locations

distclean-local:: clean-local

install-data-and-exec-local:: all-local
	$(INSTALL) -d -o ${DSTUSR} -g ${DSTGRP} -m ${DSTMODE} ${INSTALLDIR}
	$(INSTALL) -o ${DSTUSR} -g ${DSTGRP} -m 444 ${SHLIB_NAME} ${INSTALLDIR}
