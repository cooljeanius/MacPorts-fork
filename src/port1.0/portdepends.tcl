# et:ts=4
# portdepends.tcl
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

# the 'main' target is provided by this package
# main is a magic target and should not be replaced

package provide portdepends 1.0
package require portutil 1.0

# define options
options depends_build depends_run depends_lib
# Export options via PortInfo
options_export depends_build depends_lib depends_run

option_proc depends_build validate_depends_options
option_proc depends_run validate_depends_options
option_proc depends_lib validate_depends_options

proc validate_depends_options {option action args} {
    global targets
    switch -regex $action {
	set|append|delete {
	    foreach depspec $args {
			if {[regexp {([A-Za-z\./0-9]+):([A-Za-z0-9_/\-\.$^\?\+\(\)\|\\]+):([-A-Za-z\./0-9_]+)} "$depspec" match deppath depregex portname] == 1} {
				switch $deppath {
					lib {}
					bin {}
					path {}
					default {return -code error [format [msgcat::mc "unknown depspec type: %s"] $deppath]}
				}
			} else {
				return -code error [format [msgcat::mc "invalid depspec: %s"] $depspec]
			}
	    }
	}
    }
}
