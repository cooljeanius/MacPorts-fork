# $Id: Makefile.in 90002 2012-02-19 17:25:25Z jmr@macports.org $

PATH		= /Users/ericgallager/.plenv/shims:/Users/ericgallager/GNUstep/Tools:/opt/local/GNUstep/sbin:/Users/ericgallager/gcc-root:/sw/opt/kde4/x11/bin:/sw/lib/freetype219/bin:/sw/lib/fontconfig2/bin:/sw/lib/qt4-x11/bin:/sw/opt/qca2/x11/bin:/sw2/lib/perl5/ExtUtils:/sw2/bin:/sw2/sbin:/sw2/bootstrap/bin:/sw2/bootstrap/sbin:/Users/ericgallager/.opam/system/bin:/Users/ericgallager/.rvm/gems/ruby-1.9.3-p327/bin:/Users/ericgallager/.rvm/gems/ruby-1.9.3-p327@global/bin:/Users/ericgallager/.rvm/rubies/ruby-1.9.3-p327/bin:/Users/ericgallager/.rvm/bin:/Users/ericgallager/perl5/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/opt/X11/bin:/usr/texbin:/usr/X11/bin:/Developer/usr/bin:/sw/bin:/opt/local/share/java/android-sdk-macosx/tools:/opt/local/share/java/android-sdk-macosx/platform-tools:/opt/local/go/bin:/opt/local/GNUstep/System/Tools:/sw/sbin:/usr/local/sbin:/Developer/Tools:/usr/local/tigcc/bin:/usr/local/php5/bin:/usr/local/mysql/bin:/Developer/usr/sbin:/Developer/usr/local/bin:/usr/local/heroku/bin:/usr/local/git/bin:/usr/local/foreman/bin:/usr/local/clamXav/bin:/opt/nova/bin:/usr/local/PDK/bin:/opt/local/GNUstep/bin:/usr/X11/lib/X11/xinit:/Developer/GPU Computing/CUDALibraries/bin/darwin/release:/opt/local/share/java/android-sdk-mac_x86/platform-tools:/usr/local/sdcc/bin:/usr/X11R6/bin:/Users/localadmin/.local/bin:/Users/ericgallager/go/bin:/Users/ericgallager/.gem/ruby/1.8/bin:/usr/local/osxbook/efi/gcc-4.1.0-glibc-2.3.6/i686-osxbook-linux-gnu/bin:/Users/ericgallager/.cabal/bin:/Users/ericgallager/bbbbin:/usr/local/src/smlnj/bin:/usr/local/cuda/bin:/Users/ericgallager/node_modules/.bin:/usr/osxws/bin:/usr/local/share/npm/bin:/Users/ericgallager/bin/FDK/Tools/osx:/Users/ericgallager/bin:/Library/Frameworks/Python.framework/Versions/2.7/bin:/Users/ericgallager/geant4.9/bin/Darwin-g++:/sw/bin:/sw/sbin:/bin:/sbin:/usr/bin:/usr/sbin:/opt/local/GNUstep/System/Tools:/sw/bin:/sw/sbin:/usr/local/sbin:/Developer/Tools:/usr/local/tigcc/bin:/usr/local/texlive/2010basic/bin/universal-darwin:/usr/local/php5/bin:/usr/local/mysql/bin:/Developer/usr/bin:/Developer/usr/sbin:/Developer/usr/local/bin:/usr/local/heroku/bin:/usr/local/git/bin:/usr/local/foreman/bin:/usr/local/flexnetserver:/usr/local/clamXav/bin:/opt/nova/bin:/usr/local/ActivePerl-5.14/bin:/usr/local/PDK/bin:/opt/local/GNUstep/bin:/usr/local/bin:/usr/X11/bin:/usr/X11/lib/X11/xinit:/opt/X11/bin:/System/Library/Java/JavaVirtualMachines/1.6.0.jdk/Contents/Home/bin:/opt/local/src/go/go-57.1/bin:/opt/local/share/java/android-sdk-mac_x86/platform-tools:/usr/local/sdcc/bin:/usr/X11R6/bin:/Users/localadmin/.local/bin:/Users/ericgallager/.gem/ruby/1.8/bin:/usr/local/osxbook/efi/gcc-4.1.0-glibc-2.3.6/i686-osxbook-linux-gnu/bin:/Users/ericgallager/.cabal/bin:/Users/ericgallager/bbbbin:/usr/local/src/smlnj/bin:/usr/local/cuda/bin:/Users/ericgallager/perl5/bin:/Users/ericgallager/node_modules/.bin:/usr/osxws/bin:/usr/local/share/npm/bin:/opt/local/libexec/gnubin:/Library/Frameworks/Python.framework/Versions/2.7/bin:/Library/Frameworks/Python.framework/Versions/3.2/bin:/usr/local/opt/ruby/bin:/usr/local/opt/ruby192/bin:/Users/ericgallager/.rvm/bin:/usr/local/share/npm/bin:/usr/local/share/python:/usr/local/opt/coreutils/libexec/gnubin
SUBDIR		= doc src tests
DISTDIR		= dist
DISTVER		=
DISTTAG		= release_${subst .,_,${DISTVER}}
DISTNAME	= MacPorts-${DISTVER}
DISTARCTAG	= ${DISTTAG}-archive
DISTARCNAME	= ${DISTNAME}-archive
SVNURL		= https://svn.macports.org/repository/macports


include Mk/macports.autoconf.mk


all:: Mk/macports.autoconf.mk

Mk/macports.autoconf.mk: Mk/macports.autoconf.mk.in src/config.h.in Makefile.in config.status
	./config.status
	${MAKE} clean

config.status: configure
	@if test -f ./config.status ; then	\
		set -x ;						\
		./config.status --recheck ;		\
	else								\
		set -x ;						\
		echo "Source tree not configured. Use ./configure" ; \
	fi

include Mk/macports.subdir.mk

install::
	[ ! -f $(DESTDIR)${sysconfdir}/macports/mp_version ] || rm -vf $(DESTDIR)${sysconfdir}/macports/mp_version
	$(INSTALL) -o ${DSTUSR} -g ${DSTGRP} -m 444 setupenv.bash  $(DESTDIR)${datadir}/macports/
	$(INSTALL) -o ${DSTUSR} -g ${DSTGRP} -m 444 macports-pubkey.pem  $(DESTDIR)${datadir}/macports/
# Only run these scripts when not building in a destroot
ifeq ($(DESTDIR),)
# create run user if it doesn't exist
	@if test -n "${DSCL}" -a -n "${DSEDITGROUP}" ; then \
        if ! ${DSCL} -q . -read /Groups/${RUNUSR} > /dev/null 2>&1 ; then \
            if test `id -u` -eq 0; then \
                echo "Creating group \"${RUNUSR}\"" ; \
                ${DSEDITGROUP} -q -o create ${RUNUSR} ; \
            else \
                echo "Not creating group \"${RUNUSR}\" (not root)" ; \
            fi ; \
        fi ; \
        if ! ${DSCL} -q . -list /Users/${RUNUSR} > /dev/null 2>&1 ; then \
            if test `id -u` -eq 0; then \
                echo "Creating user \"${RUNUSR}\"" ; \
                NEXTUID=501; \
                while test -n "`${DSCL} -q /Search -search /Users UniqueID $$NEXTUID`"; do \
                    let "NEXTUID=NEXTUID+1"; \
                done; \
                ${DSCL} -q . -create /Users/${RUNUSR} UniqueID $$NEXTUID ; \
                \
                ${DSCL} -q . -delete /Users/${RUNUSR} AuthenticationAuthority ; \
                ${DSCL} -q . -delete /Users/${RUNUSR} PasswordPolicyOptions ; \
                ${DSCL} -q . -delete /Users/${RUNUSR} dsAttrTypeNative:KerberosKeys ; \
                ${DSCL} -q . -delete /Users/${RUNUSR} dsAttrTypeNative:ShadowHashData ; \
                \
                ${DSCL} -q . -create /Users/${RUNUSR} RealName MacPorts ; \
                ${DSCL} -q . -create /Users/${RUNUSR} Password \* ; \
                ${DSCL} -q . -create /Users/${RUNUSR} PrimaryGroupID $$(${DSCL} -q . -read /Groups/${RUNUSR} PrimaryGroupID | /usr/bin/awk '{print $$2}') ; \
                ${DSCL} -q . -create /Users/${RUNUSR} NFSHomeDirectory ${localstatedir}/macports/home ; \
                ${DSCL} -q . -create /Users/${RUNUSR} UserShell /usr/bin/false ; \
            else \
                echo "Not creating user \"${RUNUSR}\" (not root)" ; \
            fi ; \
        fi ; \
        if test "$$(${DSCL} -q . -read /Users/${RUNUSR} NFSHomeDirectory)" = "NFSHomeDirectory: /var/empty" ; then \
            if test `id -u` -eq 0; then \
                echo "Updating home directory location for user \"${RUNUSR}\"" ; \
                ${DSCL} -q . -create /Users/${RUNUSR} NFSHomeDirectory ${localstatedir}/macports/home ; \
            else \
                echo "Not updating home directory location for user \"${RUNUSR}\" (not root)" ; \
            fi ; \
        fi ; \
        if test `sw_vers -productVersion | /usr/bin/awk -F . '{print $$2}'` -eq 4 -a `id -u` -eq 0; then \
            GID=`${DSCL} -q . -read /Groups/${RUNUSR} PrimaryGroupID | /usr/bin/awk '{print $$2}'` ; \
            if test "`${DSCL} -q . -read /Users/${RUNUSR} PrimaryGroupID 2>/dev/null | /usr/bin/awk '{print $$2}'`" != "$$GID"; then \
                echo "Fixing PrimaryGroupID for user \"${RUNUSR}\"" ; \
                ${DSCL} -q . -create /Users/${RUNUSR} PrimaryGroupID $$GID ; \
                ${DSCL} -q . -create /Users/${RUNUSR} RealName MacPorts ; \
            fi ; \
        fi ; \
    else \
        echo "Can't find ${DSCL} / ${DSEDITGROUP}, not creating user \"${RUNUSR}\"" ; \
    fi
# Add [default] tag to the central MacPorts repository, if it isn't already
	$(TCLSH) src/upgrade_sources_conf_default.tcl "${prefix}"
# Convert image directories (and direct mode installs) to image archives
	$(TCLSH) src/images_to_archives.tcl "${macports_tcl_dir}"
endif
ifndef SELFUPDATING
	@echo ""; echo "Congratulations, you have successfully installed the MacPorts system. To get the Portfiles and update the system, add ${prefix}/bin to your PATH and run:"; echo ""
	@echo "sudo port -v selfupdate"; echo ""
	@echo "Please read \"man port\", the MacPorts guide at http://guide.macports.org/ and Wiki at https://trac.macports.org/ for full documentation."; echo ""
else
	@echo ""; echo "Congratulations, you have successfully upgraded the MacPorts system."; echo ""
endif

group::
	@echo "creating a macports group..." && sudo dseditgroup -o create -n . macports && echo "done! use './configure --with-install-group=macports --with-shared-directory' if you haven't already"

rmgroup::
	@echo "deleting macports group..." && sudo dseditgroup -o delete -n . macports && echo "done! use 'make group' to re-create"


clean::

distclean::
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

# This target fetches a tagged distribution from svn, and generates tarballs and checksums for it
distfromsvn:
	@[ -n "${DISTVER}" ] || { echo Must specify DISTVER, like: make DISTVER=1.4.0 distfromsvn; exit 1; }
	[ -d ${DISTDIR} ] || mkdir ${DISTDIR}
	rm -f ${DISTDIR}/${DISTNAME}.chk.txt
	${MAKE} SVNTAG=${DISTTAG}/base/ PKGNAME=${DISTNAME} _dopkg
ifeq ($(ARC),yes) 
	${MAKE} SVNTAG=${DISTARCTAG} PKGNAME=${DISTARCNAME} _dopkg
endif

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
