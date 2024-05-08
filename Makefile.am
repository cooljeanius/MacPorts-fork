# $Id: Makefile.am 90002 2012-02-19 17:25:25Z jmr@macports.org $

ACLOCAL_AMFLAGS = -I m4 --install
AM_CFLAGS       = -Wall

PATH		= @PATH_CLEANED@
SUBDIR		= doc src tests
DISTDIR		= dist
DISTVER		=
@ifGNUmake@DISTTAG = release_${subst .,_,${DISTVER}}
@ifnGNUmake@DISTTAG = release_${DISTVER}
DISTNAME	= MacPorts-${DISTVER}
DISTARCTAG	= ${DISTTAG}-archive
DISTARCNAME	= ${DISTNAME}-archive
SVNURL		= https://svn.macports.org/repository/macports
TCLDOC		= @TCLDOC@


include Mk/macports.autoconf.mk.am


all_hardcoded:: Mk/macports.autoconf.mk

Mk/macports.autoconf.mk: Mk/macports.autoconf.mk.in src/config.h.in Makefile.in config.status
	./config.status
	${MAKE} clean

regen_config_dot_status: configure
	@if test -f ./config.status ; then	\
		set -x ;						\
		./config.status --recheck ;		\
	else								\
		set -x ;						\
		echo "Source tree not configured. Use ./configure" ; \
	fi
.PHONY: regen_config_dot_status

include Mk/macports.subdir.mk

install-data-and-exec-local::
	[ ! -f $(DESTDIR)${sysconfdir}/macports/mp_version ] || rm -vf $(DESTDIR)${sysconfdir}/macports/mp_version
	$(INSTALL) -o ${DSTUSR} -g ${DSTGRP} -m 444 setupenv.bash  $(DESTDIR)${datadir}/macports/
	$(INSTALL) -o ${DSTUSR} -g ${DSTGRP} -m 444 macports-pubkey.pem  $(DESTDIR)${datadir}/macports/
# Only run these scripts when not building in a destroot
@ifGNUmake@ifeq ($(DESTDIR),)
@ifGNUmake@# create run user if it does not exist
@ifGNUmake@	@if test -n "${DSCL}" -a -n "${DSEDITGROUP}" ; then \
@ifGNUmake@        if ! ${DSCL} -q . -read /Groups/${RUNUSR} > /dev/null 2>&1 ; then \
@ifGNUmake@            if test `id -u` -eq 0; then \
@ifGNUmake@                echo "Creating group \"${RUNUSR}\"" ; \
@ifGNUmake@                ${DSEDITGROUP} -q -o create ${RUNUSR} ; \
@ifGNUmake@            else \
@ifGNUmake@                echo "Not creating group \"${RUNUSR}\" (not root)" ; \
@ifGNUmake@            fi ; \
@ifGNUmake@        fi ; \
@ifGNUmake@        if ! ${DSCL} -q . -list /Users/${RUNUSR} > /dev/null 2>&1 ; then \
@ifGNUmake@            if test `id -u` -eq 0; then \
@ifGNUmake@                echo "Creating user \"${RUNUSR}\"" ; \
@ifGNUmake@                NEXTUID=501; \
@ifGNUmake@                while test -n "`${DSCL} -q /Search -search /Users UniqueID $$NEXTUID`"; do \
@ifGNUmake@                    let "NEXTUID=NEXTUID+1"; \
@ifGNUmake@                done; \
@ifGNUmake@                ${DSCL} -q . -create /Users/${RUNUSR} UniqueID $$NEXTUID ; \
@ifGNUmake@                \
@ifGNUmake@                ${DSCL} -q . -delete /Users/${RUNUSR} AuthenticationAuthority ; \
@ifGNUmake@                ${DSCL} -q . -delete /Users/${RUNUSR} PasswordPolicyOptions ; \
@ifGNUmake@                ${DSCL} -q . -delete /Users/${RUNUSR} dsAttrTypeNative:KerberosKeys ; \
@ifGNUmake@                ${DSCL} -q . -delete /Users/${RUNUSR} dsAttrTypeNative:ShadowHashData ; \
@ifGNUmake@                \
@ifGNUmake@                ${DSCL} -q . -create /Users/${RUNUSR} RealName MacPorts ; \
@ifGNUmake@                ${DSCL} -q . -create /Users/${RUNUSR} Password \* ; \
@ifGNUmake@                ${DSCL} -q . -create /Users/${RUNUSR} PrimaryGroupID $$(${DSCL} -q . -read /Groups/${RUNUSR} PrimaryGroupID | /usr/bin/awk '{print $$2}') ; \
@ifGNUmake@                ${DSCL} -q . -create /Users/${RUNUSR} NFSHomeDirectory ${localstatedir}/macports/home ; \
@ifGNUmake@                ${DSCL} -q . -create /Users/${RUNUSR} UserShell /usr/bin/false ; \
@ifGNUmake@            else \
@ifGNUmake@                echo "Not creating user \"${RUNUSR}\" (not root)" ; \
@ifGNUmake@            fi ; \
@ifGNUmake@        fi ; \
@ifGNUmake@        if test "$$(${DSCL} -q . -read /Users/${RUNUSR} NFSHomeDirectory)" = "NFSHomeDirectory: /var/empty" ; then \
@ifGNUmake@            if test `id -u` -eq 0; then \
@ifGNUmake@                echo "Updating home directory location for user \"${RUNUSR}\"" ; \
@ifGNUmake@                ${DSCL} -q . -create /Users/${RUNUSR} NFSHomeDirectory ${localstatedir}/macports/home ; \
@ifGNUmake@            else \
@ifGNUmake@                echo "Not updating home directory location for user \"${RUNUSR}\" (not root)" ; \
@ifGNUmake@            fi ; \
@ifGNUmake@        fi ; \
@ifGNUmake@        if test `sw_vers -productVersion | /usr/bin/awk -F . '{print $$2}'` -eq 4 -a `id -u` -eq 0; then \
@ifGNUmake@            GID=`${DSCL} -q . -read /Groups/${RUNUSR} PrimaryGroupID | /usr/bin/awk '{print $$2}'` ; \
@ifGNUmake@            if test "`${DSCL} -q . -read /Users/${RUNUSR} PrimaryGroupID 2>/dev/null | /usr/bin/awk '{print $$2}'`" != "$$GID"; then \
@ifGNUmake@                echo "Fixing PrimaryGroupID for user \"${RUNUSR}\"" ; \
@ifGNUmake@                ${DSCL} -q . -create /Users/${RUNUSR} PrimaryGroupID $$GID ; \
@ifGNUmake@                ${DSCL} -q . -create /Users/${RUNUSR} RealName MacPorts ; \
@ifGNUmake@            fi ; \
@ifGNUmake@        fi ; \
@ifGNUmake@    else \
@ifGNUmake@        echo "Cannot find ${DSCL} / ${DSEDITGROUP}, not creating user \"${RUNUSR}\"" ; \
@ifGNUmake@    fi
@ifGNUmake@# Add [default] tag to the central MacPorts repository, if it has not
@ifGNUmake@# already been added
@ifGNUmake@	$(TCLSH) src/upgrade_sources_conf_default.tcl "${prefix}"
@ifGNUmake@# Convert image directories (and direct mode installs) to image archives
@ifGNUmake@	$(TCLSH) src/images_to_archives.tcl "${macports_tcl_dir}"
@ifGNUmake@endif
@ifGNUmake@ifndef SELFUPDATING
@ifGNUmake@	@echo ""; echo "Congratulations, you have successfully installed the MacPorts system. To get the Portfiles and update the system, add ${prefix}/bin to your PATH and run:"; echo ""
@ifGNUmake@	@echo "sudo port -v selfupdate"; echo ""
@ifGNUmake@	@echo "Please read \"man port\", the MacPorts guide at http://guide.macports.org/ and Wiki at https://trac.macports.org/ for full documentation."; echo ""
@ifGNUmake@else
@ifGNUmake@	@echo ""; echo "Congratulations, you have successfully upgraded the MacPorts system."; echo ""
@ifGNUmake@endif

group::
	@echo "creating a macports group..." && sudo dseditgroup -o create -n . macports && echo "done! use './configure --with-install-group=macports --with-shared-directory' if you have not done so already"

rmgroup::
	@echo "deleting macports group..." && sudo dseditgroup -o delete -n . macports && echo "done! use 'make group' to re-create"


clean-local::

distclean-local::
	rm -f config.log config.status configure.lineno
	rm -rf autom4te.cache ${DISTDIR}
	rm -f Makefile Mk/macports.autoconf.mk portmgr/freebsd/Makefile
	rm -f Doxyfile
	rm -f setupenv.bash

_gettag:
	cd ${DISTDIR}; svn co ${SVNURL}/tags/${SVNTAG} ${PKGNAME}-svn

_pkgdist:
	[ ! -d ${DISTDIR}/${PKGNAME} ] || rm -rf ${DISTDIR}/${PKGNAME}
	cd ${DISTDIR}; svn export ${PKGNAME}-svn ${PKGNAME}
	cd ${DISTDIR}; COPY_EXTENDED_ATTRIBUTES_DISABLE=true tar -c ${PKGNAME} | gzip > ${PKGNAME}.tar.gz
	cd ${DISTDIR}; COPY_EXTENDED_ATTRIBUTES_DISABLE=true tar -c ${PKGNAME} | bzip2 > ${PKGNAME}.tar.bz2
	cd ${DISTDIR}; for tarball in ${PKGNAME}.tar.*; do { \
		for type in -md5 -sha1 -ripemd160 -sha256; do { \
			openssl dgst $$type $$tarball; \
		}; done >> ${DISTNAME}.chk.txt; \
	}; done

_dopkg: _gettag _pkgdist

# This target fetches a tagged distribution from svn, and generates
# tarballs and checksums for it
distfromsvn:
	@[ -n "${DISTVER}" ] || { echo Must specify DISTVER, like: make DISTVER=1.4.0 distfromsvn; exit 1; }
	[ -d ${DISTDIR} ] || mkdir ${DISTDIR}
	rm -f ${DISTDIR}/${DISTNAME}.chk.txt
	${MAKE} SVNTAG=${DISTTAG}/base/ PKGNAME=${DISTNAME} _dopkg
	test "$(ARC)" = "yes" && \
	${MAKE} SVNTAG=${DISTARCTAG} PKGNAME=${DISTARCNAME} _dopkg

tcldoc:
	@[ -e "${prefix}/bin/tcldoc" ] \
		|| { echo "Install tcldoc with MacPorts in ${prefix} first."; exit 1; }
	find src -name '*.tcl' | xargs ${TCLDOC} --verbose --title "MacPorts Documentation" --force tcldoc

tcldox:
	@[ -e "${prefix}/bin/doxygen" -a -e "${prefix}/bin/tcl-dox" -a -e "${prefix}/bin/dot" ] \
		|| { echo "Install doxygen, tcl-dox and graphviz with MacPorts in ${prefix} first."; exit 1; }
	${prefix}/bin/doxygen

test::

.PHONY: dist _gettag _pkgdist _dopkg tcldoc tcldox
