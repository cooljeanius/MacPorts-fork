# et:ts=4
# portactivate.tcl
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

# the 'activate' target is provided by this package

package provide portactivate 1.0
package require portutil 1.0

set com.apple.activate [target_new com.apple.activate activate_main]
target_runtype ${com.apple.activate} always
target_state ${com.apple.activate} no
target_provides ${com.apple.activate} activate
target_requires ${com.apple.activate} main fetch extract checksum patch configure build destroot install
target_prerun ${com.apple.activate} activate_start

set_ui_prefix

proc activate_start {args} {
	global UI_PREFIX portname portversion portrevision variations os.platform os.arch portvariants
    
	if { ![info exists portvariants] } {
		set portvariants ""

		set vlist [lsort -ascii [array names variations]]

	 	# Put together variants in the form +foo+bar for the registry
		foreach v $vlist {
			if { ![string equal $v ${os.platform}] && ![string equal $v ${os.arch}] } {
				set portvariants "${portvariants}+${v}"
			}
		}
	}
}

proc activate_main {args} {
	global portname portversion portrevision portvariants
	registry_activate $portname ${portversion}_${portrevision}${portvariants}
    return 0
}
