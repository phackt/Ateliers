#!/bin/bash

#####################################
# Aims at automating some bug bounty recon
#####################################

#####################################
#####################################
# Variables section
#####################################
#####################################
TOOLS_DIR="${HOME}/tools/"
WORK_DIR="${HOME}/recon/"
LOG_DIR=""
WORDS_FILE=""
DOMAIN=""
SCAN=0

# Script directory
SCRIPT_DIR=$(dirname $(readlink -f $0))

# *****************
# Update these ones
# *****************
ALTDNS_DIR="${HOME}/Documents/repo/altdns/"
AQUATONE_DIR="${HOME}/aquatone/"
KNOCKTONE_DIR="${HOME}/Documents/repo/pentest/fingerprint/knocktone/"
BUCKETFINDER_DIR="${TOOLS_DIR}/bucket_finder/"

#####################################
#####################################
# Help
#####################################
#####################################
function help(){
    echo "Usage: $0 -d domain"
    echo "       -d domain        :domain to attack"
    echo "       -f file          :file used for subdomains words (launch subdomains discover)"
    echo "       -s               :launch scan on aquatone data"
    echo "Example of command:"
    echo "$0 -d yahoo.com -f /home/batman/dns/bitquark_subdomains_top100K.txt"
    exit 1
}

if [[ $# -lt 3 && $# -gt 5 ]];then
    help
fi

#####################################
#####################################
# Getting options
#####################################
#####################################
while getopts "d:f:s" OPT;do
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
        s)
            SCAN=1
            ;;
        :)
            echo -e "\e[31m[!] Invalid option ${OPT}\e[0m"
            help
            ;;
    esac
done

#####################################
#####################################
## Global actions
#####################################
#####################################

# Create working directory
rm -rf ${WORK_DIR}/${DOMAIN} && mkdir -p ${WORK_DIR}/${DOMAIN}/log

#####################################
# Check aquatone is installed
#####################################
aquatone-discover -h &>/dev/null || \
(curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash - && apt-get install -y nodejs && gem install aquatone)
if [ $? -ne 0 ];then
    echo -e "\e[31m[!] Fail to install aquatone from 'gem install aquatone'\e[0m"
    exit 1
fi

#####################################
# Check sslscan is installed (https://github.com/rbsec/sslscan/releases)
# Maybe manual install will be necessary if wrong package on repo (apt-cache madison sslscan)
#####################################
sslscan &>/dev/null || sudo apt-get install -y sslscan
if [ $? -ne 0 ];then
    echo -e "\e[31m[!] 'sudo apt-get install -y sslscan' failed\e[0m"
    exit 1
fi

#####################################
# Check altdns is installed
#####################################
${ALTDNS_DIR}/altdns.py -h &>/dev/null || \
(rm -rf ${ALTDNS_DIR} && git clone https://github.com/phackt/altdns.git ${ALTDNS_DIR} && pip install -r ${ALTDNS_DIR}/requirements.txt)
if [ $? -ne 0 ];then
    echo -e "\e[31m[!] Fail to install altdns from 'https://github.com/phackt/altdns.git'\e[0m"
    exit 1
fi

#####################################
# Check bucket_finder is installed
#####################################
${BUCKETFINDER_DIR}/bucket_finder.rb --help &>/dev/null || \
(mkdir -p ${TOOLS_DIR} &>/dev/null && wget -O ${TOOLS_DIR}/bucket_finder_1.1.tar.bz2 https://digi.ninja/files/bucket_finder_1.1.tar.bz2 && \
cd ${TOOLS_DIR} && tar jxvf bucket_finder_1.1.tar.bz2 && chmod +x ${BUCKETFINDER_DIR}/bucket_finder.rb && cd - &>/dev/null)
if [ $? -ne 0 ];then
    echo -e "\e[31m[!] Fail to install bucket_finder from 'https://digi.ninja/files/bucket_finder_1.1.tar.bz2'\e[0m"
    exit 1
fi

#####################################
# Check firefox is installed
#####################################
firefox -h &>/dev/null || sudo apt-get install -y firefox
if [ $? -ne 0 ];then
    echo -e "\e[31m[!] 'sudo apt-get install -y firefox' failed\e[0m"
    exit 1
fi

#####################################
#####################################
## First, recon using in // aquatone and knocktone
#####################################
#####################################

# Start subdomains discover
if [[ "X${WORDS_FILE}" != "X" && "X${DOMAIN}" != "X" ]];then

    #####################################
    # Launch knoctone.py in parallel of aquatone-discover in a detached xterm
    #####################################
    echo -e "\e[33m[*] Launch knocktone subdomains discover\e[0m"

    xterm -T "knocktone DNS discover on domain ${DOMAIN}" -hold -e \
    "${KNOCKTONE_DIR}/knocktone.py generate ${WORDS_FILE} ${DOMAIN} && ${KNOCKTONE_DIR}/knocktone.py dns ${KNOCKTONE_DIR}/domains.txt | tee ${LOG_DIR}/xterm_knocktone_dns.txt" &

    #####################################
    # First launch of aquatone-discover
    #####################################
    echo -e "\e[33m[*] Launch aquatone-discover for subdomains discover\e[0m"

    aquatone-discover --domain ${DOMAIN} --wordlist ${WORDS_FILE}

    #####################################
    #####################################
    ## Second, permutations on resolved subdomains
    ## and resolve permutations with knocktone.py
    #####################################
    #####################################

    #####################################
    # Take discovered subdomains and apply altdns
    #####################################
    echo -e "\e[33m[*] Launch altdns to generate permutations\e[0m"

    cat ${AQUATONE_DIR}/${DOMAIN}/hosts.txt | cut -d, -f1 | sort -u > ${WORK_DIR}/${DOMAIN}/hosts.txt
    ${ALTDNS_DIR}/altdns.py -w ${ALTDNS_DIR}/words.txt -i ${WORK_DIR}/${DOMAIN}/hosts.txt -o ${WORK_DIR}/${DOMAIN}/altdns.altered -n -t 10

    #####################################
    # Launch the amazing knocktone.py
    #####################################
    echo -e "\e[33m[*] Launch knocktone to resolve permutations\e[0m"

    ${KNOCKTONE_DIR}/knocktone.py dns ${WORK_DIR}/${DOMAIN}/altdns.altered

    # Add the permuted subdomains resolved to the hosts.txt, hosts.json files from first aquatone-discover
    # knocktone.py concat file1 file2 output_file
    ${KNOCKTONE_DIR}/knocktone.py concat ${KNOCKTONE_DIR}/hosts.json ${AQUATONE_DIR}/${DOMAIN}/hosts.json ${AQUATONE_DIR}/${DOMAIN}/hosts.json

    # Do the same with txt result files
    # N.B: altdns outputs only permutations, not original subdomains
    (cat ${KNOCKTONE_DIR}/hosts.txt ${AQUATONE_DIR}/${DOMAIN}/hosts.txt | sort -u > /tmp/sorted_hosts.txt) && \
    mv /tmp/sorted_hosts.txt ${AQUATONE_DIR}/${DOMAIN}/hosts.txt

    #####################################
    #####################################
    ## Third, launch aquatone-scan, gather and takeover
    ## on all subdomains scope
    #####################################
    #####################################
    echo -e "\e[33m[*] Launch aquatone scan, gather, and takeover discover\e[0m"

    aquatone-scan --domain ${DOMAIN} --ports huge && \
    aquatone-gather --domain ${DOMAIN} && \
    aquatone-takeover --domain ${DOMAIN}

    echo -e "\e[33m[*] Opening aquatone html report\e[0m"
    firefox ${AQUATONE_DIR}/${DOMAIN}/report/*.html &>/dev/null &

# End of subdomains discover
fi

# Start post discover actions
if [[ ${SCAN} -eq 1 && "X${DOMAIN}" != "X" ]];then

    #####################################
    #####################################
    ## Fourth, perform some post scan actions
    #####################################
    #####################################
    echo -e "\e[33m[*] Launch knocktone scan on headers found\e[0m"

    xterm -T "knocktone SCAN on domain ${DOMAIN}" -hold -e "${KNOCKTONE_DIR}/knocktone.py scan ${DOMAIN} | tee ${LOG_DIR}/xterm_knocktone_scan.txt" &

    #####################################
    # Stats on server found
    #####################################
    echo -e "\e[33m[*] Statistics about servers\e[0m"
    cat ${AQUATONE_DIR}/${DOMAIN}/headers/* | grep 'Server:' | sort | uniq -c | sort -nr

    #####################################
    # Look for SSL heartbleed vulnerability (CVE-2014-0160)
    #####################################
    echo -e "\e[33m[*] Look for SSL heartbleed vulnerability (CVE-2014-0160)\e[0m"

    cat ${AQUATONE_DIR}/${DOMAIN}/urls.txt | cut -d '/' -f 3 > ${WORK_DIR}/${DOMAIN}/heartbleed.txt
    sslscan --targets=${WORK_DIR}/${DOMAIN}/heartbleed.txt --no-ciphersuites --no-fallback --no-renegotiation --no-compression --no-check-certificate

    #####################################
    # Look for subdomains in html pages gathered by aquatone
    #####################################
    echo -e "\e[33m[*] Look for new subdomains in gathered html pages\e[0m"

    domain_regexp=$(echo ${DOMAIN} | sed 's/\./\\./g')
    cat ${AQUATONE_DIR}/${DOMAIN}/html/* | egrep -o '[a-z0-9\-\_\.]+\.'${domain_regexp} | sort -u > ${WORK_DIR}/${DOMAIN}/subdomainsinhtml.txt

    while read subdomain;do
        grep ${subdomain} ${AQUATONE_DIR}/${DOMAIN}/hosts.txt &>/dev/null
        if [ $? -eq 1 ];then
            echo -e "\e[32m[!] New subdomain found: ${subdomain}\e[0m"
        fi
    done < ${WORK_DIR}/${DOMAIN}/subdomainsinhtml.txt

    #####################################
    # Look for amazon s3 server in html pages
    #####################################
    echo -e "\e[33m[*] Look for new s3 buckets in gathered html pages\e[0m"

    domain_regexp=$(echo ".s3.amazonaws.com" | sed 's/\./\\./g')
    cat ${AQUATONE_DIR}/${DOMAIN}/html/* | egrep -o '[a-z0-9\-\_\.]+'${domain_regexp} | sort -u > ${WORK_DIR}/${DOMAIN}/s3bucketsinhtml.txt

    while read bucket;do
        echo -e "\e[32m[!] S3 bucket found: ${bucket}\e[0m"

        # We are saving the prefixes
        echo ${bucket%*${domain_regexp}} >> ${WORK_DIR}/${DOMAIN}/s3bucketsinhtml_prefixes.txt
    done < ${WORK_DIR}/${DOMAIN}/s3bucketsinhtml.txt

    #####################################
    # Look for s3 buckets
    #####################################
    echo -e "\e[33m[*] Look for s3 buckets\e[0m"

    domain_regexp=$(echo .${DOMAIN} | sed 's/\./\\./g')

    while read domain; do
        domain=$(echo ${domain} | cut -d, -f1)
        prefix=$(echo ${domain%.*})

        # We are saving the prefixes and domain found
        echo ${domain} >> ${WORK_DIR}/${DOMAIN}/all_buckets_prefixes.txt
        echo ${prefix} >> ${WORK_DIR}/${DOMAIN}/all_buckets_prefixes.txt
    done < ${AQUATONE_DIR}/${DOMAIN}/hosts.txt

    echo ${DOMAIN} >> ${WORK_DIR}/${DOMAIN}/all_buckets_prefixes.txt
    echo ${DOMAIN%.*}  >> ${WORK_DIR}/${DOMAIN}/all_buckets_prefixes.txt

    # We are concatenating the s3 buckets found in html pages with the subdomains prefixes (and got uniq sorted strings)
    cat ${WORK_DIR}/${DOMAIN}/s3bucketsinhtml_prefixes.txt >> ${WORK_DIR}/${DOMAIN}/all_buckets_prefixes.txt
    (cat ${WORK_DIR}/${DOMAIN}/all_buckets_prefixes.txt | sort -u > /tmp/all_buckets_prefixes.txt) && \
    mv /tmp/all_buckets_prefixes.txt ${WORK_DIR}/${DOMAIN}/all_buckets_prefixes.txt

    #####################################
    # Launch bucket_finder
    #####################################
    ${BUCKETFINDER_DIR}/bucket_finder.rb ${WORK_DIR}/${DOMAIN}/all_buckets_prefixes.txt | tee ${WORK_DIR}/${DOMAIN}/bucket_finder_results.txt

# End of post discover actions
fi

#####################################
#####################################
# End of script
#####################################
#####################################
exit 0
