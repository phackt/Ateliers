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
WORK_DIR="/tmp/recon/"
LOG_DIR=""
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
            LOG_DIR="${WORK_DIR}/${DOMAIN}/log"
            ;;
        f)
            WORDS_FILE="${OPTARG}"
            if [ ! -f "${WORDS_FILE}" ];then
                echo -e "\e[31m[!] ${WORDS_FILE} not found.\e[0m"
                exit 1
            fi
            ;;
        :)
            echo -e "\e[31m[!] Invalid option ${OPT}\e[0m"
            help
            ;;
    esac
done

################################
## Global actions
################################
rm -rf ${WORK_DIR}/${DOMAIN} && mkdir -p ${WORK_DIR}/${DOMAIN}/log

################################
## First, recon using in // aquatone and knocktone
################################

# Launch knoctone.py in parallel of aquatone-discover in a detached xterm
echo -e "\e[33m[*] Launch knocktone subdomains discover\e[0m"

xterm -T "knocktone DNS discover on domain ${DOMAIN}" -hold -e \
"${KNOCKTONE_DIR}/knocktone.py generate ${WORDS_FILE} ${DOMAIN} && ${KNOCKTONE_DIR}/knocktone.py dns ${KNOCKTONE_DIR}/domains.txt | tee ${LOG_DIR}/xterm_knocktone_dns.txt" &

# First launch of aquatone-discover
echo -e "\e[33m[*] Launch aquatone-discover for subdomains discover\e[0m"

#aquatone-discover --domain ${DOMAIN} --wordlist ${WORDS_FILE}

################################
## Second, permutations on resolved subdomains
## and resolve permutations with knocktone.py
################################

# Take discovered subdomains and apply altdns
echo -e "\e[33m[*] Launch altdns to generate permutations\e[0m"

cat ${AQUATONE_DIR}/${DOMAIN}/hosts.txt | cut -d, -f1 | sort -u > ${WORK_DIR}/${DOMAIN}/hosts.txt
${ALTDNS_DIR}/altdns.py -w ${ALTDNS_DIR}/words.txt -i ${WORK_DIR}/${DOMAIN}/hosts.txt -o ${WORK_DIR}/${DOMAIN}/altdns.altered -n -t 10

# Launch the amazing knocktone.py
echo -e "\e[33m[*] Launch knocktone to resolve permutations\e[0m"
read
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
echo -e "\e[33m[*] Launch aquatone scan, gather, and takeover discover\e[0m"

aquatone-scan --domain ${DOMAIN} --ports huge && \
aquatone-gather --domain ${DOMAIN} && \
aquatone-takeover --domain ${DOMAIN}

echo -e "\e[33m[*] Opening aquatone html report\e[0m"
firefox ${AQUATONE_DIR}/${DOMAIN}/report/*.html

################################
## Fourth, perform some post scan actions
################################
echo -e "\e[33m[*] Launch knocktone scan on headers found\e[0m"

xterm -T "knocktone SCAN on domain ${DOMAIN}" -hold -e "${KNOCKTONE_DIR}/knocktone.py scan ${DOMAIN} | tee ${LOG_DIR}/xterm_knocktone_scan.txt" &

# Stats on server found
echo -e "\e[33m[*] Statistics about servers\e[0m"
cat ${AQUATONE_DIR}/${DOMAIN}/headers/* | grep 'Server:' | sort | uniq -c | sort -nr

# Look for subdomains in html pages gathered by aquatone
echo -e "\e[33m[*] Look for new subdomains in gathered html pages\e[0m"

domain_regexp=$(echo ${DOMAIN} | sed 's/\./\\./g')
cat ${AQUATONE_DIR}/${DOMAIN}/html/* | egrep -o '[a-z0-9\-\_\.]+\.'${domain_regexp} | sort -u > ${WORK_DIR}/${DOMAIN}/subdomainsinhtml.txt

while read subdomain;do
    grep ${subdomain} ${AQUATONE_DIR}/${DOMAIN}/hosts.txt &>/dev/null
    if [ $? -eq 1 ];then
        echo -e "\e[32m[!] New subdomain found: ${subdomain}\e[0m"
    fi
done < ${WORK_DIR}/${DOMAIN}/subdomainsinhtml.txt

# Look for amazon s3 server in html pages
echo -e "\e[33m[*] Look for new s3 buckets in gathered html pages\e[0m"

domain_regexp=$(echo "s3.amazonaws.com" | sed 's/\./\\./g')
cat ${AQUATONE_DIR}/${DOMAIN}/html/* | egrep -o '[a-z0-9\-\_\.]+\.'${domain_regexp} | sort -u > ${WORK_DIR}/${DOMAIN}/s3bucketsinhtml.txt

while read bucket;do
    grep ${bucket} ${AQUATONE_DIR}/${DOMAIN}/hosts.txt &>/dev/null
    if [ $? -eq 1 ];then
        echo -e "\e[32m[!] New s3 bucket found: ${bucket}\e[0m"
    fi
done < ${WORK_DIR}/${DOMAIN}/s3bucketsinhtml.txt

# Look for SSL heartbleed vulnerability (CVE-2014-0160)
echo -e "\e[33m[*] Look for SSL heartbleed vulnerability (CVE-2014-0160)\e[0m"

sslscan &>/dev/null || apt-get install sslscan

cat ${AQUATONE_DIR}/${DOMAIN}/urls.txt | cut -d '/' -f 3 > ${WORK_DIR}/${DOMAIN}/heartbleed.txt
sslscan --targets=${WORK_DIR}/${DOMAIN}/heartbleed.txt --no-ciphersuites --no-fallback --no-renegotiation --no-compression --no-check-certificate

################################
# End of script
################################
echo -e "\n\e[31m[!] Nota Bene:\e[0m"
echo -e "\e[31m[!] Relaunch sub-subdomains bruteforce / permutations\e[0m"
echo -e "\e[31m[!] Remember to look for some ip-based hosting\e[0m"

exit 0
