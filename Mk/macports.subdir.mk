# $Id: macports.subdir.mk 30816 2007-11-07 19:52:25Z jmpp@macports.org $

.PHONY : all-local
.PHONY : clean distclean
.PHONY : install-data-and-exec-local

all-local::
	@for subdir in $(SUBDIR); do\
		echo ===\> making $@ in ${DIRPRFX}$$subdir; \
		( cd $$subdir && $(MAKE) DIRPRFX=${DIRPRFX}$$subdir/ $@) || exit 1; \
	done

clean-local distclean-local::
	@for subdir in $(SUBDIR); do\
	  if test -e $${subdir}/Makefile && test -r $${subdir}/Makefile; then \
		echo ===\> making $@ in ${DIRPRFX}$$subdir; \
		( cd $$subdir && $(MAKE) DIRPRFX=${DIRPRFX}$$subdir/ $@) || exit 1; \
	  else \
	    echo "skipping making $@ in $${subdir} due to missing or unreadable Makefile"; \
	  fi; \
	done

test::
	@for subdir in $(SUBDIR); do\
		echo ===\> making $@ in ${DIRPRFX}$$subdir; \
		( cd $$subdir && $(MAKE) DIRPRFX=${DIRPRFX}$$subdir/ $@) || exit 1; \
	done

install-data-and-exec-local::
	@for subdir in $(SUBDIR); do\
		echo ===\> making $@ in ${DIRPRFX}$$subdir; \
		( cd $$subdir && $(MAKE) DIRPRFX=${DIRPRFX}$$subdir/ $@) || exit 1; \
	done
