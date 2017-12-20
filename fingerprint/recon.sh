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
WORK_DIR=""
LOG_DIR=""
WORDS_FILE=""
DOMAIN=""
COMPANY=""
SCAN=0
ALTDNS=0
USERAGENT="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.103 Safari/537.36"

# Script directory
SCRIPT_DIR=$(dirname $(readlink -f $0))

# *****************
# Update these ones
# *****************
ALTDNS_DIR="${HOME}/Documents/repo/altdns/"
AQUATONE_DIR="${HOME}/aquatone/"
KNOCKTONE_DIR="${HOME}/Documents/repo/pentest/fingerprint/knocktone/"
SECLISTS_DIR="${HOME}/Documents/repo/SecLists/"
BUCKETFINDER_DIR="${TOOLS_DIR}/bucket_finder/"
CORS_DIR="${HOME}/Documents/repo/pentest/fingerprint/cors/"
ALTDNS_WORDLIST="${ALTDNS_DIR}/words.txt"

#####################################
#####################################
# Help
#####################################
#####################################
function help(){
    echo "Usage: $0 -d <domain> -f <file> -a -s"
    echo "       -d domain        :domain to attack"
    echo "       -f file          :file used for subdomains words (launch subdomains discover)"
    echo "       -a               :launch altdns on subdomains found"
    echo "       -s               :launch scan on aquatone data"
    echo ""
    echo "Example of commands:"
    echo "$0 -d yahoo.com -f /home/batman/dns/bitquark_subdomains_top100K.txt -a"
    echo "$0 -d yahoo.com -f /home/batman/dns/bitquark_subdomains_top100K.txt -a -s"
    exit 1
}

if [[ $# -lt 3 || $# -gt 6 ]];then
    help
fi

#####################################
#####################################
# Getting options
#####################################
#####################################
while getopts "d:f:sa" OPT;do
    case "${OPT}" in
        d)
            DOMAIN="${OPTARG}"
            COMPANY="$(echo ${DOMAIN%.*} | rev | cut -d. -f1 | rev)"
            LOG_DIR="${HOME}/recon/${DOMAIN}/results/"
            WORK_DIR="${HOME}/recon/${DOMAIN}/work/"
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
        a)
            ALTDNS=1
            ;;
        :)
            echo -e "\e[31m[!] Invalid option ${OPT}\e[0m"
            help
            ;;
    esac
done

#####################################
# Function to check if lock file
#####################################
function checklock(){
	if [ -f /tmp/.lock.${DOMAIN} ];then
		echo -e "\e[31m[!] Recon is already running for domain ${DOMAIN}\e[0m" 
		exit 1
	fi
}

# Checking if already running for the current domain
checklock

#####################################
#####################################
## Global actions
#####################################
#####################################

# Create working directory
rm -rf ${HOME}/recon/${DOMAIN} && mkdir -p ${WORK_DIR} && mkdir -p ${LOG_DIR}

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
# Check awscli is installed
#####################################
aws s3 help &>/dev/null || (sudo apt-get install -y awscli && aws configure)
if [ $? -ne 0 ];then
    echo -e "\e[31m[!] 'sudo apt-get install -y awscli && aws configure' failed\e[0m"
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
# Check dirb is installed
#####################################
dirb &> /dev/null
if [ $? -ne 255 ];then
    echo -e "\e[31m[!] dirb is not installed. Please install from 'https://downloads.sourceforge.net/project/dirb/dirb/2.22/dirb222.tar.gz'\e[0m"
    exit 1
fi

#####################################
#####################################
## Recon using in // aquatone and knocktone
#####################################
#####################################

# Start subdomains discover
if [[ "X${WORDS_FILE}" != "X" && "X${DOMAIN}" != "X" ]];then

	# locking file
	touch /tmp/.lock.${DOMAIN}

    #####################################
    # Launch of aquatone-discover
    #####################################
    echo -e "\e[33m[*] Launch aquatone-discover for subdomains discover\e[0m"

    aquatone-discover --domain ${DOMAIN} --wordlist ${WORDS_FILE}

    #####################################
    # Bruteforce found subdomains with altdns permutations
    #####################################
    if [ ${ALTDNS} -eq 1 ];then

        ALTERED_WORDS_FILE=${WORK_DIR}/altdns.altered

        # Generate subdomains input file for altdns
        cat ${AQUATONE_DIR}/${DOMAIN}/hosts.txt | cut -d, -f1 | sort -u > ${WORK_DIR}/hosts.txt.tmp

        echo -e "\e[33m[*] Launch altdns to generate permutations\e[0m"
        ${ALTDNS_DIR}/altdns.py -w ${ALTDNS_WORDLIST} -i ${WORK_DIR}/hosts.txt.tmp -o ${ALTERED_WORDS_FILE} -n -t 10

        rm -f ${WORK_DIR}/hosts.txt.tmp

        #####################################
        # Launch knocktone.py
        #####################################
        echo -e "\e[33m[*] Launch knocktone to resolve permutations\e[0m"
        ${KNOCKTONE_DIR}/knocktone.py dns ${ALTERED_WORDS_FILE}

        # Add the permuted subdomains resolved to the hosts.txt, hosts.json files from first aquatone-discover
        # knocktone.py concat file1 file2 output_file
        ${KNOCKTONE_DIR}/knocktone.py concat ${KNOCKTONE_DIR}/hosts.json ${AQUATONE_DIR}/${DOMAIN}/hosts.json ${AQUATONE_DIR}/${DOMAIN}/hosts.json

        # Do the same with txt result files
        #
        # N.B: altdns outputs only permutations, not original subdomains
        #
        (cat ${KNOCKTONE_DIR}/hosts.txt ${AQUATONE_DIR}/${DOMAIN}/hosts.txt | sort -u > /tmp/sorted_hosts.txt) && \
        mv /tmp/sorted_hosts.txt ${AQUATONE_DIR}/${DOMAIN}/hosts.txt
    fi

# End of subdomains discover
fi

#####################################
#####################################
## Perform some post scan actions
#####################################
#####################################

# Start post discover actions
if [[ ${SCAN} -eq 1 && "X${DOMAIN}" != "X" ]];then

	# locking file
	touch /tmp/.lock.${DOMAIN}

    # We are testing that we previously ran aquatone-discover
    if [[ ! -f "${AQUATONE_DIR}/${DOMAIN}/hosts.txt" || ! -f "${AQUATONE_DIR}/${DOMAIN}/hosts.json" ]];then
        echo -e "\e[31m[!] Files ${AQUATONE_DIR}/${DOMAIN}/hosts.txt and ${AQUATONE_DIR}/${DOMAIN}/hosts.json not found\e[0m"
        echo -e "\e[31m[!] Please launch a subdomains discover first\e[0m"
        help
    fi

    #####################################
    ## Launch aquatone-scan, gather and takeover on all subdomains scope
    #####################################
    echo -e "\e[33m[*] Launch aquatone scan, gather, and takeover discover\e[0m"

    aquatone-scan --domain ${DOMAIN} --ports huge && \
    aquatone-gather --domain ${DOMAIN} --timeout 5 --threads 1 && \
    aquatone-takeover --domain ${DOMAIN}

    #####################################
    # Custom scan on headers found
    ##################################### 
    echo -e "\e[33m[*] Launch knocktone scan on headers found\e[0m"
    nohup ${KNOCKTONE_DIR}/knocktone.py scan ${DOMAIN} > ${LOG_DIR}/xterm_knocktone_scan.txt &
    
    #####################################
    # Stats on server found
    #####################################
    echo -e "\e[33m[*] Statistics about servers\e[0m"
    cat ${AQUATONE_DIR}/${DOMAIN}/headers/* | grep 'Server:' | sort | uniq -c | sort -nr

    #####################################
    # Look for subdomains in html pages gathered by aquatone
    #####################################
    echo -e "\e[33m[*] Look for new subdomains in gathered html pages\e[0m"

    domain_regexp=$(echo ${DOMAIN} | sed 's/\./\\./g')
    cat ${AQUATONE_DIR}/${DOMAIN}/html/* | egrep -o '[a-z0-9\-\_\.]+\.'${domain_regexp} | sort -u > ${WORK_DIR}/subdomainsinhtml.txt

    while read subdomain;do
        grep ${subdomain} ${AQUATONE_DIR}/${DOMAIN}/hosts.txt &>/dev/null
        if [ $? -eq 1 ];then
            echo -e "\e[32m[!] New subdomain found: ${subdomain}\e[0m"
        fi
    done < ${WORK_DIR}/subdomainsinhtml.txt

    # Check if file is not empty
    if [ ! -s ${WORK_DIR}/${DOMAIN}/subdomainsinhtml.txt ];
    then
    	rm -f ${WORK_DIR}/${DOMAIN}/subdomainsinhtml.txt
	fi

    #####################################
    # Look for amazon s3 servers in html pages
    #####################################
    echo -e "\e[33m[*] Look for new s3 servers in gathered html pages\e[0m"

    domain_regexp="[a-zA-Z0-9\.\-]*(s3-|s3.).*\.?amazonaws\.com[a-zA-Z0-9\.\-\/]*"
    cat ${AQUATONE_DIR}/${DOMAIN}/html/* | egrep -o "${domain_regexp}" | sort -u > ${WORK_DIR}/s3bucketsinhtml.txt

    while read domain;do
        echo -e "\e[32m[!] AWS S3 domain found: ${domain}\e[0m"

        # Getting the bucket name
        bucket=${domain%s3*}

        if [ "X" == "X""${bucket}" ];then
            # If path-style URL
            bucket=$(echo ${domain} | cut -d/ -f2)
        else
            # If virtual-hosted–style URL
            bucket=${bucket%.*}
        fi

        # We are saving the prefixes
        echo ${bucket} >> ${WORK_DIR}/s3bucketsinhtml_prefixes.txt
    done < ${WORK_DIR}/s3bucketsinhtml.txt

	# Check if file is not empty
    if [ ! -s ${WORK_DIR}/${DOMAIN}/s3bucketsinhtml.txt ];
    then
    	rm -f ${WORK_DIR}/${DOMAIN}/s3bucketsinhtml.txt
    fi

    #####################################
    # Look for s3 buckets (aws cli)
    #####################################
    echo -e "\e[33m[*] Bruteforce s3 buckets\e[0m"

    domain_regexp=$(echo .${DOMAIN} | sed 's/\./\\./g')

    while read domain; do
        domain=$(echo ${domain} | cut -d, -f1)
        domain_with_hyphens=$(echo ${domain} | sed 's/\./-/g')

        # Permutations on potential s3 names
        # dev.ftp.domain.com
        echo ${domain} >> ${WORK_DIR}/all_buckets_prefixes.txt

        # dev.ftp.domain
        echo ${domain%.*} >> ${WORK_DIR}/all_buckets_prefixes.txt

        # dev-ftp-domain-com
        echo ${domain_with_hyphens} >> ${WORK_DIR}/all_buckets_prefixes.txt

        # dev-ftp-domain
        echo ${domain_with_hyphens%-*} >> ${WORK_DIR}/all_buckets_prefixes.txt

        # dev-ftp.domain
        echo ${domain_with_hyphens%-*} | sed 's/-'${COMPANY}'/\.'${COMPANY}'/g' >> ${WORK_DIR}/all_buckets_prefixes.txt
    done < ${AQUATONE_DIR}/${DOMAIN}/hosts.txt

    # We are concatenating the s3 buckets found in html pages with the subdomains prefixes (and got uniq sorted strings)
    if [ -f "${WORK_DIR}/s3bucketsinhtml_prefixes.txt" ];then
        cat ${WORK_DIR}/s3bucketsinhtml_prefixes.txt >> ${WORK_DIR}/all_buckets_prefixes.txt
    fi

    # We are adding the altdns.altered file if it is existing
    if [ -f "${WORK_DIR}/altdns.altered" ];then
        cat ${WORK_DIR}/altdns.altered >> ${WORK_DIR}/all_buckets_prefixes.txt
    fi

    (cat ${WORK_DIR}/all_buckets_prefixes.txt | sort -u > /tmp/all_buckets_prefixes.txt) && \
    mv /tmp/all_buckets_prefixes.txt ${WORK_DIR}/all_buckets_prefixes.txt

    #####################################
    # Launch awscli and try to read/update bucket
    #####################################

    # First launch bucket_finder
    ${BUCKETFINDER_DIR}/bucket_finder.rb ${WORK_DIR}/all_buckets_prefixes.txt > ${WORK_DIR}/bucket_finder_results.tmp
    cat ${WORK_DIR}/bucket_finder_results.tmp | grep -i found | cut -d":" -f2 | cut -d" " -f2 | sort -u > ${WORK_DIR}/bucket_finder_results.txt

    rm -f ${WORK_DIR}/bucket_finder_results.tmp

    echo "H1 program (@phackt)" > haxor.txt

    # Validating buckets
    while read bucket;do
        echo -e "\n\e[33m[*] Look for bucket ${bucket}\e[0m"
        
        # Try to read bucket
        aws s3 ls s3://${bucket} &>/dev/null
        if [ $? -eq 0 ];then
            echo -e "\e[32m[!] Bucket ${bucket} is readable\e[0m" | tee -a ${LOG_DIR}/readable_buckets_found.txt
        fi

        # Try to write bucket
        aws s3 cp haxor.txt s3://${bucket} &>/dev/null
        if [ $? -eq 0 ];then
            echo -e "\e[32m[!] Bucket ${bucket} is writable\e[0m" | tee -a ${LOG_DIR}/writable_buckets_found.txt
        fi

        # Try to read bucket ACL
        aws s3api get-bucket-acl --bucket ${bucket} &>/dev/null
        if [ $? -eq 0 ];then
            echo -e "\e[32m[!] ${bucket} ACL can be displayed: run 'aws s3api get-bucket-acl --bucket ${bucket}'\e[0m" | tee -a ${LOG_DIR}/acl_buckets_found.txt
        fi

    done < ${WORK_DIR}/bucket_finder_results.txt
    rm -f haxor.txt

    #####################################
    # Launch cors.py to detect permissive SOP
    #####################################
    echo -e "\e[33m[*] Check for some permissive CORS\e[0m"
    ${CORS_DIR}/cors.py -f ${AQUATONE_DIR}/${DOMAIN}/urls.txt > ${WORK_DIR}/cors.txt

    #####################################
    # Look for some interesting files in root web folder
    #####################################
    mkdir -p ${WORK_DIR}/quickhits &>/dev/null

    # Loop on each url
    while read url;do

    	logfile="${WORK_DIR}/quickhits/"$(echo ${url} | sed 's/[\/\.\:]/_/g')"_quickhits.txt"

        # Delete existing log
        rm -f ${logfile} &>/dev/null

        echo -e "\e[33m[*] Check for some interesting files at ${url}\e[0m"

        # Fuzz with dirb, more reliable than wfuzz
        dirb ${url} ${SECLISTS_DIR}/Discovery/Web_Content/quickhits.txt -l -N 500 -r -t -a "${USERAGENT}" -o ${logfile} &>/dev/null
    done < ${AQUATONE_DIR}/${DOMAIN}/urls.txt

# End of post discover actions
fi

#####################################
#####################################
# End of script
#####################################
#####################################

# Unlocking file
rm -f /tmp/.lock.${DOMAIN}

echo "[!] 1) Think to launch GITROB as your convenience"
echo "[!] $ gitrob analyze ${COMPANY}"
echo ""
echo "[!] 2) Think to check on common crawl (should be done manually because of huuuuge data for a wilcard domain)"
echo "[!] $ ./cdx-index-client.py -c CC-MAIN-2017-47 '*.${DOMAIN}' --show-num-pages"
echo "[!] $ ./cdx-index-client.py -c CC-MAIN-2017-47 '*.${DOMAIN}' --fl url -z"
echo ""
echo "[!] 3) Check on bgp.he.net, censys, shodan for some interesting stuff"
echo ""
echo "[*] End of program"
exit 0
