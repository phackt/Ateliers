#! /bin/bash

# How to start the OSCP lab ....

echo "Looking for the low hanging fruits in OSCP Lab ......................."
echo "Starring PH4CK7 ......................................................"
echo

# Purge
if [ -e up.txt ];then rm -i up.txt;fi
if [ -e hostnames.txt ];then rm -i hostnames.txt;fi

##############################
############ IPS #############
##############################
SUBNET=""
while [ -z "$SUBNET" ]
do
	echo -n "[+] Enter the subnet to scan (CIDR): "
	read SUBNET
done

echo
echo "[+] Pinging subnet"
nmap -sn -oG up_tmp.txt $SUBNET

echo
echo "[+] Creating file with ips up: check up.txt"
cat up_tmp.txt | while read line
do 
	echo $line | grep Host | cut -d" "  -f2 | tee -a up.txt
done
gedit up.txt &>/dev/null &

echo
echo "[+] Please press any key to continue..."
read
##############################
############ /IPS ############
##############################

##############################
############ PORTS ###########
##############################
echo
echo "[+] Getting info about the top 20 ports on ips up: check top20.txt"
nmap -Pn -sT -A --top-ports=20 --open -iL up.txt -oG top20_grep.txt | tee top20.txt
gedit top20.txt &>/dev/null &

echo
echo "[+] Please press any key to continue..."
read
##############################
############ /PORTS ##########
##############################

##############################
############ DNS #############
##############################
echo
echo "[+] Retrieving DNS servers"
grep -i domain top20_grep.txt | tee domains.txt
DNSSERVER=$(cat domains.txt | head -1 | cut -d" " -f2)

if [ -z "$DNSSERVER" ]
then
	echo "[!] No DNS server found!"
fi

# Looking if DNS server have been found
if [ ! -z "$DNSSERVER" ]
then

	echo
	echo "[+] Resolving hostnames with DNS server $DNSSERVER: check hostnames.txt"
	IP=$(python -c "x='$SUBNET';print x[:x.rfind('.')]")

	for i in $(seq 1 254)
	do 
		host $IP.$i $DNSSERVER | grep -i "domain name" | tee -a hostnames.txt
	done
	gedit hostnames.txt &>/dev/null &

	NB_IPS=$(wc -l up.txt | cut -d" " -f1)
	NB_HOSTNAMES=$(wc -l hostnames.txt | cut -d" " -f1)

	echo
	echo "[+] Found $NB_IPS hosts up: check up.txt"
	echo "[+] Found $NB_HOSTNAMES resolved: check hostnames.txt"
	if [ $NB_IPS -ne $NB_HOSTNAMES ]
	then
		echo "[!] Seems there is a gap between hosts resolved and hosts up!"	
	fi

fi

echo
echo "[+] Please press any key to continue..."
read
##############################
############ /DNS ############
##############################

##############################
###### LOW HANGING FRUIT #####
##############################
echo
echo "[+] Looking for the low hanging fruit my sweet: check common_vulns.txt"
nmap -Pn -p 21,80,139,443,445 --script ftp-anon,ftp-vuln*,http*webdav*,http-vuln*,smb-enum-shares,smb-vuln* -iL up.txt -oG common_vulns_grep.txt | tee common_vulns.txt
gedit common_vulns.txt &>/dev/null &
##############################
###### /LOW HANGING FRUIT ####
##############################