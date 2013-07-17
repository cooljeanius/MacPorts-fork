/*
 * threadWin.c --
 *
 * Windows specific aspects for the thread extension.
 *
 * see http://dev.activestate.com/doc/howto/thread_model.html
 *
 * Some of this code is based on work done by Richard Hipp on behalf of
 * Conservation Through Innovation, Limited, with their permission.
 *
 * Copyright (c) 1998 by Sun Microsystems, Inc.
 * Copyright (c) 1999,2000 by Scriptics Corporation.
 *
 * See the file "license.terms" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 * RCS: @(#) $Id: threadWin.c,v 1.5 2002/01/27 04:52:21 davygrvy Exp $
 */

#include "../generic/tclThread.h"
#include <windows.h>
#include <process.h>

#if 0
/* only Windows 2000 (XP, too??) has this function */
HANDLE (WINAPI *winOpenThreadProc)(DWORD, BOOL, DWORD);

void
ThreadpInit (void)
{
    HMODULE hKernel = GetModuleHandle("kernel32.dll");
    winOpenThreadProc = (HANDLE (WINAPI *)(DWORD, BOOL, DWORD))
	    GetProcAddress(hKernel, "OpenThread");
}

int
ThreadpKill (Tcl_Interp *interp, long id)
{
    HANDLE hThread;
    int result = TCL_OK;

    if (winOpenThreadProc) {
	hThread = winOpenThreadProc(THREAD_TERMINATE, FALSE, id);
	/*
	 * not to be misunderstood as "devilishly clever",
	 * but as evil in its pure form. (I'm assuming this is referring to the "666"?)
	 */
	TerminateThread(hThread, 666);
    } else {
	Tcl_AppendStringsToObj(Tcl_GetObjResult(interp),
		"Can't (yet) kill threads on this OS, sorry.", NULL);
	result = TCL_ERROR;
    }
    return result;
}
#endif
