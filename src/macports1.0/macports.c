/*
 * macports.c
 * $Id: macports.c 64998 2010-03-19 00:48:35Z raimue@macports.org $
 *
 * Copyright (c) 2009 The MacPorts Project
 * Copyright (c) 2003 Apple Inc.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the copyright owner nor the names of contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

/* macports.c: Basically a C shim for all the Tcl stuff that MacPorts does
 */

// Includes
#ifdef HAVE_CONFIG_H
	#include <config.h>
#endif

#include <tcl.h>

#include "get_systemconfiguration_proxies.h"
#include "sysctl.h"

/* macports__version: Sends the MacPorts version to Tcl.
 * Arguments: a lot of them
 * Return value: Tcl
 */
static int
macports__version(ClientData clientData UNUSED, Tcl_Interp *interp, int objc, Tcl_Obj * CONST objv[])
{
	if (objc != 1) {
		Tcl_WrongNumArgs(interp, 1, objv, NULL);
		return TCL_ERROR;
	}
	Tcl_SetObjResult(interp, Tcl_GetVar2Ex(interp, "macports::autoconf::macports_version", NULL, 0));
	return TCL_OK;
}

/* Macports_Init: Initializes MacPorts's Tcl
 * Arguments: Tcl
 * Return value: Tcl
 */
int
Macports_Init(Tcl_Interp *interp)
{
	if (Tcl_InitStubs(interp, "8.4", 0) == NULL)
		return TCL_ERROR;
	Tcl_CreateObjCommand(interp, "macports::version", macports__version, NULL, NULL);
	Tcl_CreateObjCommand(interp, "get_systemconfiguration_proxies", GetSystemConfigurationProxiesCmd, NULL, NULL);
	Tcl_CreateObjCommand(interp, "sysctl", SysctlCmd, NULL, NULL);
	if (Tcl_PkgProvide(interp, "macports", "1.0") != TCL_OK)
		return TCL_ERROR;
	return TCL_OK;
}

/* Aren't all *.c files supposed to have a "main"? */

