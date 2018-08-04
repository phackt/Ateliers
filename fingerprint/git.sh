#!/bin/bash

#####################################
# Variables section
#####################################

declare -A INPUT_FILES

TIMEOUT=5
USERAGENT="Mozilla/5.0 (Windows NT 6.1; WOW64; rv:54.0) Gecko/20100101 Firefox/54.0"
URL=""
BRANCHES=()

# Script directory
SCRIPT_DIR=$(dirname $(readlink -f $0))
SCRIPT_NAME=$(basename $(readlink -f $0))
WORKDIR="/tmp/$(cat /proc/sys/kernel/random/uuid)"

# Useful for git ls-remote
export GIT_TERMINAL_PROMPT=0

#####################################
# Help
#####################################
function help(){
    echo "Usage: $0 -u git_url"
    echo
    echo "Example of command:"
    echo "${SCRIPT_NAME} -u https://monsite.com/.git/"
    exit 1
}

if [ $# -ne 2 ];then
    help
fi

#####################################
# Getting options
#####################################
while getopts "u:" OPT;do
    case "${OPT}" in
        u)
            URL="${OPTARG}"
            if [ "${URL: -1}" != "/" ];then
                URL=${URL}"/"
            fi
            echo -e "\e[33m[*] Looking for url: ${URL}\e[0m"
            ;;
        :)
            echo -e "\e[31m[!] Invalid option ${OPT}\e[0m"
            help
            ;;
    esac
done

# Delete if work dir exists
(rm -rf ${WORKDIR} && mkdir ${WORKDIR}) &>/dev/null

#####################################
# Functions declaration
#####################################
function check_traversal_dir(){
    test $(curl -k -s -A "${USERAGENT}" --connect-timeout ${TIMEOUT} "${URL}" | grep -e "\"HEAD\"" -e "\"refs/\"" | wc -l) -eq 2
    echo $?
}

function get_branches(){
	curl -k -s -A "${USERAGENT}" --connect-timeout ${TIMEOUT} "${URL}config" > "${WORKDIR}/config"
    
    while read branch;do
        BRANCHES+=("${branch}")
    done < <(grep "\[branch " "${WORKDIR}/config" | cut -d"\"" -f2)

    # Check if branch master has been found, otherwise we force the search
    hasmaster=0
    for element in "${BRANCHES[@]}";do if [ "${element}" == "master" ];then hasmaster=1;break;fi;done

    if [ ${hasmaster} -eq 0 ];then
    	BRANCHES+=("master")
    fi
}

function get_last_commit(){
    curl -k -s -A "${USERAGENT}" --connect-timeout ${TIMEOUT} "${URL}logs/refs/heads/$1" | tail -1
}

#####################################
# Scanning url
#####################################
isdirlist=$(check_traversal_dir)

get_branches

# check directory listing
if [ ${isdirlist} -eq 0 ];then
    echo -e "\e[32m[*] [directory listing OK]\e[0m"
fi

for branch in "${BRANCHES[@]}"
do
	lastcommit="$(get_last_commit ${branch})"

	# Checking if at least logs/refs/heads/master exists
	echo "${lastcommit}" | grep "</html>" &>/dev/null
	validlog=$?

	# Looking for valid master lastcommit
	if [ "${branch}" == "master" -a ${validlog} -eq 0 ];then continue;fi

    timestamp=$(echo "${lastcommit}" | cut -d$'\t' -f1 | rev | awk '{print $2}' | rev)
    timestamp_str="$(date +'%d-%m-%Y %H:%M:%S' -d@${timestamp})"
    echo -e "\e[32m[*] [${timestamp_str}]\e[0m last commit for branch \e[32m[${branch}]\e[0m:"
    echo "${lastcommit}"
done

echo "[*] .git/config:"
grep -P --color=always '(url *= *.*|\[credential\]|$)' "${WORKDIR}/config"

#Looking for public http repo
while read repo;do
	git -c user.email=john@doe.com -c user.name=johndoe ls-remote "${repo}" &> /dev/null
	if [ $? -eq 0 ];then
		echo -e "\e[32m[*] Repository \"${repo}\" can be accessed\e[0m"
	fi
done < <(grep -E 'url *= *http(s)?:\/\/.*' "${WORKDIR}/config" | cut -d"=" -f2 | sed 's/ //g')
echo

# delete work dir 
rm -rf "${WORKDIR}/config" &>/dev/null
