TCLPKG=		@OUR_INCLUDED_PACKAGES@ \
			cregistry \
			macports1.0 \
			port1.0 \
			package1.0 \
			pextlib1.0 \
			registry2.0 \
			darwintracelib1.0 \
			machista1.0
SUBDIR=		${TCLPKG} port programs
DISTCLEANFILES= *~

all-local::

clean-local:: Makefile
distclean-local::
	-rm -f config.h
	-rm -f Makefile
	-rm -f pkg_mkindex.sh

test::

include ../Mk/macports.subdir.mk
