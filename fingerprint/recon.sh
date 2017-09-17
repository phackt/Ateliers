#!/bin/bash

# TODO:
# dev knocktone.py un logging l'ecriture dans un fichier de log (nom knocktone_<action>_<timestamp>.log)

#####################################
# Aims at automating some bug bounty recon
#####################################

#####################################
# Variables section
#####################################
ALTDNS_DIR="/home/phackt/Documents/repo/altdns/"
AQUATONE_DIR="/home/phackt/aquatone/"
KNOCKTONE_DIR="/home/phackt/Documents/repo/pentest/fingerprint/knocktone/"
WORK_DIR="/tmp/recon-bb/"
WORDS_FILE=""
DOMAIN=""

# Script directory
SCRIPT_DIR=$(dirname $(readlink -f $0))

#####################################
# Help
#####################################
function help(){
    echo "Usage: $0 -d domain"
    echo "       -d domain        :domain to attack"
    echo "       -f file          :file used for subdomains words"
    echo "Example of command:"
    echo "$0 -d yahoo.com -f /home/batman/dns/bitquark_subdomains_top100K.txt"
    exit 1
}

if [ $# -ne 4 ];then
    help
fi

#####################################
# Getting options
#####################################
while getopts "d:f:" OPT;do
    case "${OPT}" in
        d)
            DOMAIN="${OPTARG}"
            ;;
        f)
			WORDS_FILE="${OPTARG}"
			if [ -f "${WORDS_FILE}" ];then
			    echo -e "\e[31m[!] ${WORDS_FILE} not found.\e[0m"
			    exit 1
			fi
        :)
            echo -e "\e[31m[!] Invalid option ${OPT}\e[0m"
            help
            ;;
    esac

################################
## First, recon using in // aquatone and knocktone
################################

# Launch knoctone.py in parallel of aquatone-discover in a detached xterm
echo "[*] Launch knocktone for subdomains discover"

xterm -T "knocktone DNS discover on domain ${DOMAIN}" -hold -e \
${KNOCKTONE_DIR}/knocktone.py generate ${WORDS_FILE} ${DOMAIN} && \
${KNOCKTONE_DIR}/knocktone.py dns ${KNOCKTONE_DIR}/domains.txt &

# First launch of aquatone-discover
echo "[*] Launch aquatone-discover for subdomains discover"

aquatone-discover --domain ${DOMAIN} --wordlist ${WORDS_FILE}

################################
## Second, permutations on resolved subdomains
## and resolve permutations with knocktone.py
################################

# Take discovered subdomains and apply altdns
echo "[*] Launch altdns to generate permutations"

mkdir -p ${WORK_DIR}/${DOMAIN} &>/dev/null
cat ${AQUATONE_DIR}/${DOMAIN}/hosts.txt | cut -d, -f1 | sort -u > ${WORK_DIR}/${DOMAIN}/hosts.txt
${ALTDNS_DIR}/altdns.py -w ${ALTDNS_DIR}/words.txt -i ${WORK_DIR}/${DOMAIN}/hosts.txt -o ${WORK_DIR}/${DOMAIN}/altdns.altered -n -t 10

# Launch the amazing knocktone.py
echo "[*] Launch knocktone to resolve permutations"

${KNOCKTONE_DIR}/knocktone.py dns ${WORK_DIR}/${DOMAIN}/altdns.altered

# Add the permuted subdomains resolved to the hosts.txt, hosts.json files from first aquatone-discover
# knocktone.py concat file1 file2 output_file
${KNOCKTONE_DIR}/knocktone.py concat ${KNOCKTONE_DIR}/hosts.json ${AQUATONE_DIR}/${DOMAIN}/hosts.json ${AQUATONE_DIR}/${DOMAIN}/hosts.json

# Do the same with txt result files
# N.B: altdns outputs only permutations, not original subdomains
cat ${KNOCKTONE_DIR}/hosts.txt ${AQUATONE_DIR}/${DOMAIN}/hosts.txt | sort -u > /tmp/sorted_hosts.txt
mv /tmp/sorted_hosts.txt ${AQUATONE_DIR}/${DOMAIN}/hosts.txt

################################
## Third, launch aquatone-scan, gather and takeover
## on all subdomains scope
################################
echo "[*] Launch aquatone scan, gather, and takeover discover"

aquatone-scan --domain ${DOMAIN} --ports large && \
aquatone-gather --domain ${DOMAIN} && \
aquatone-takeover --domain ${DOMAIN}

echo -e "\n\e[31m[!] Think to relaunch sub-subdomains bruteforce / permutations\e[0m"