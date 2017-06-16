#! /bin/bash

declare -a IPS_ARRAY

# Displays help
function help(){
    echo "[!] Usage: $0 {start|stop}"
    exit 1
}

# Checking is root
if [ $(id -u) -ne 0 ]; then
    echo "[!] You'd better be root! Exiting..."
    exit
fi

if [ $# -eq 0 ] || [ $# -gt 2 ]; then
    help
fi

# Case first argument
case "${1}" in
start)

	# Dynamically find VPN gateway ips
	echo "[*] finding VPN gateways ips"
	for gateway in $(find /etc/openvpn/ -type f -name *.ovpn -exec grep "remote " {} \; | cut -d' ' -f2)
	do
		echo "[*] VPN gateway found: $gateway"
	    for ip in $(host $gateway | cut -d' ' -f4)
	    do
	    	IPS_ARRAY+=($ip)
	    done
	done

    echo "[*] shutdown interfaces"
    ifconfig eth0 down
    ifconfig wlan0 down

    echo "[*] reset rules"
    # reset ufw settings
    ufw --force reset

    echo "[*] deny all"
    # set default behaviour of and enable ufw
    ufw default deny incoming
    ufw default deny outgoing
    ufw enable

    echo "[*] allow lan traffic"
    # allow local traffic
    ufw allow to 192.168.1.0/24
    ufw allow in from 192.168.1.0/24

	echo "[*] bring connections back"
    # bring connections back up
    ifconfig eth0 up
    ifconfig wlan0 up

    echo "[*] allow udp 1198 for vpn connection"
    # allow vpn connection to be established
    ufw allow out 1198/udp

    echo "[*] allow all vpn gateway ip addresses"
    # allow vpn ip address
    for ip in ${IPS_ARRAY[@]}
	do
		echo "[*] ufw allow in from $ip to any"
        ufw allow in from $ip to any
	done    	

    echo "[*] allow traffic over VPN interface tun0"
    # allow all traffic over VPN interface
    ufw allow in on tun0 from any to any
    ufw allow out on tun0 from any to any
    
    echo "[*] restarting all services"
    # because network-manager is whiny little girl
    service networking restart
    service network-manager restart

    ;;
     
stop)

    echo "[*] shutdown interfaces"
    ifconfig eth0 down
    ifconfig wlan0 down

    echo "[*] reset rules"
    # reset ufw settings
    ufw --force reset
    ufw disable

	echo "[*] bring connections back"
    # bring connections back up
    ifconfig eth0 up
    ifconfig wlan0 up

    echo "[*] restarting all services"
    service networking restart
    service network-manager restart

    ;;

*)
    echo "[!] Usage: $0 {start|stop}"
    exit 1

    ;;
esac
