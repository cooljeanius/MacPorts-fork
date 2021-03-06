# Test file for Pextlib's base32 commands.
# Syntax:
# tclsh base32.tcl <Pextlib name>

proc main {pextlibname} {
	load $pextlibname
	
	if {[base32encode "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"] != "SEOC8GKOVGE196NRUJ49IRTP4GJQSGF4CIDP6J54IMCHMU2IN1AG===="} {
		puts {[base32encode "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"] != "SEOC8GKOVGE196NRUJ49IRTP4GJQSGF4CIDP6J54IMCHMU2IN1AG===="}
		exit 1
	}

	if {[base32decode "SEOC8GKOVGE196NRUJ49IRTP4GJQSGF4CIDP6J54IMCHMU2IN1AG===="] != "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"} {
		puts {[base32decode "SEOC8GKOVGE196NRUJ49IRTP4GJQSGF4CIDP6J54IMCHMU2IN1AG===="] != "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"}
		exit 1
	}
}

main $argv
