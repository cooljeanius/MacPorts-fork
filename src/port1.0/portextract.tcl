# et:ts=4
# portextract.tcl
#
# Copyright (c) 2002 - 2003 Apple Computer, Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. Neither the name of Apple Computer, Inc. nor the names of its contributors
#    may be used to endorse or promote products derived from this software
#    without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#

package provide portextract 1.0
package require portutil 1.0

set com.apple.extract [target_new com.apple.extract extract_main]
target_init ${com.apple.extract} extract_init
target_provides ${com.apple.extract} extract
target_requires ${com.apple.extract} fetch checksum
target_prerun ${com.apple.extract} extract_start

# define options
options extract.only
commands extract

# Set up defaults
# XXX call out to code in portutil.tcl XXX
# This cleans the distfiles list of all site tags
default extract.only {[disttagclean $distfiles]}

default extract.dir {${workpath}}
default extract.cmd gzip
default extract.pre_args -dc
default extract.post_args {{| tar -xf -}}

set UI_PREFIX "---> "

proc extract_init {args} {
    global extract.only extract.dir extract.cmd extract.pre_args extract.post_args distfiles use_bzip2 use_zip workpath

    if {[exists use_bzip2]} {
		option extract.cmd bzip2
    } elseif {[exists use_zip]} {
		option extract.cmd unzip
		option extract.pre_args -q
		option extract.post_args "-d [option extract.dir]"
    }
    if {[string length [binaryInPath ${extract.cmd}]] == 0} {
	return -code error "[format [msgcat::mc "This port requires '%s' to be extracted, which can not be found on this system."] [option extract.cmd]]"
    }
}

proc extract_start {args} {
    global UI_PREFIX

    ui_msg "$UI_PREFIX [format [msgcat::mc "Extracting %s"] [option portname]]"
}

proc extract_main {args} {
    global UI_PREFIX

    if {![exists distfiles] && ![exists extract.only]} {
	# nothing to do
	return 0
    }

    foreach distfile [option extract.only] {
	ui_info "$UI_PREFIX [format [msgcat::mc "Extracting %s"] $distfile]"
	option extract.args "[option distpath]/$distfile"
	if {[catch {system "[command extract]"} result]} {
	    return -code error "$result"
	}
	ui_info [msgcat::mc "Done"]
    }
    return 0
}
