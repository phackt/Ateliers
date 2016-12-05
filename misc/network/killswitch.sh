#! /bin/bash

# Displays help
function help(){
	echo $"Usage: $0 {start|stop} ip_gateway"
        exit 1
}

# Checking is root
if [ $(id -u) -ne 0 ]; then
	echo "You'd better be root! Exiting..."
	exit
fi

if [ $# -eq 0 ] || [ $# -gt 2 ]; then
	help
fi

gateway=''

# Case first argument
case "${1}" in
    start)
        if [ "X"${2} != "X" ]; then
		gateway=${2}
	else
		help
        fi

        iptables -P OUTPUT DROP
        iptables -A OUTPUT -o lo -j ACCEPT
        iptables -A OUTPUT -o tun0 -j ACCEPT
        iptables -A OUTPUT -d ${gateway} -j ACCEPT
        ;;
         
    stop)
        iptables -F
        ;;
  
    *)
        echo $"Usage: $0 {start|stop} ip_gateway"
        exit 1
esac
