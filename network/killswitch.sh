#! /bin/bash

# Displays help
function help(){
	echo $"Usage: $0 {start|stop}"
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

# Case first argument
case "${1}" in
    start)
       
        ifconfig eth0 down
        ifconfig wlan0 down

        # reset ufw settings
        ufw --force reset

        # set default behaviour of and enable ufw
        ufw default deny incoming
        ufw default deny outgoing
        ufw enable

        # allow local traffic
        ufw allow to 192.168.1.0/24
        ufw allow in from 192.168.1.0/24

        # bring connections back up
        ifconfig eth0 up
        ifconfig wlan0 up

        # allow vpn connection to be established
        ufw allow out 1194/udp

        # allow vpn ip address
        ufw allow in from 104.200.154.17 to any

        # allow all traffic over VPN interface
        ufw allow in on tun0 from any to any
        ufw allow out on tun0 from any to any

        # because network-manager is whiny little girl
        service networking restart
        service network-manager restart
         
    stop)
        ifconfig eth0 down
        ifconfig wlan0 down

        # reset ufw settings
        ufw --force reset

        # bring connections back up
        ifconfig eth0 up
        ifconfig wlan0 up

        service networking restart
        service network-manager restart

        ;;
  
    *)
        echo $"Usage: $0 {start|stop}"
        exit 1
esac
