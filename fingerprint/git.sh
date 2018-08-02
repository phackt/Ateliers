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

#####################################
# Functions declaration
#####################################
function check_traversal_dir(){
    test $(curl -k -s -A "${USERAGENT}" --connect-timeout ${TIMEOUT} "${URL}" | grep -e "\"HEAD\"" -e "\"refs/\"" | wc -l) -eq 2
    echo $?
}

function get_branches(){
    while read branch;do
        BRANCHES+=(${branch})
    done < <(curl -k -s -A "${USERAGENT}" --connect-timeout ${TIMEOUT} "${URL}config" | grep branch | cut -d"\"" -f2)
}

function get_last_log(){
    curl -k -s -A "${USERAGENT}" --connect-timeout ${TIMEOUT} "${URL}logs/refs/heads/$1" | tail -1
}

#####################################
# Scanning url
#####################################
isdirlist=$(check_traversal_dir)

get_branches

# check directory listing
if [ ${isdirlist} -eq 0 ];then
    echo -e "[*] [\e[32mdirectory listing OK\e[0m]"
fi

for branch in "${BRANCHES[@]}"
do
    lastlog="$(get_last_log ${branch})"
    timestamp=$(echo "${lastlog}" | cut -d$'\t' -f1 | rev | awk '{print $2}' | rev)
    timestamp_str="$(date -d @${timestamp})"
    echo -e "[*] [\e[32m${timestamp_str}\e[0m] last log for branch [\e[32m${branch}\e[0m]"
    echo "${lastlog}"
done
