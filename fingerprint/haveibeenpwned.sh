#!/bin/bash

#####################################
# Domains arrays
#####################################

# Default domains included
declare -a commons_domains=(
"aol.com"
"att.net"
"comcast.net"
"facebook.com"
"gmail.com"
"gmx.com"
"googlemail.com"
"google.com"
"hotmail.com"
"hotmail.co.uk"
"mac.com"
"me.com"
"mail.com"
"msn.com"
"live.com"
"sbcglobal.net"
"verizon.net"
"yahoo.com"
"ymail.com"
"yahoo.co.uk"
"protonmail.com"
)

# Other global domains
# declare -a others_domains=(
# "email.com"
# "games.com"
# "gmx.net"
# "hush.com"
# "hushmail.com"
# "icloud.com"
# "inbox.com"
# "lavabit.com"
# "love.com"
# "outlook.com"
# "pobox.com"
# "rocketmail.com"
# "safe-mail.net"
# "wow.com"
# "ygm.com"
# "ymail.com"
# "zoho.com"
# "fastmail.fm"
# "yandex.com"
# "iname.com"
# )

# United States ISP domains
# declare -a usa_domains=(
# "bellsouth.net"
# "charter.net"
# "comcast.net"
# "cox.net"
# "earthlink.net"
# "juno.com"
# )

# British ISP domains
# declare -a uk_domains=(
# "btinternet.com"
# "virginmedia.com"
# "blueyonder.co.uk"
# "freeserve.co.uk"
# "live.co.uk"
# "ntlworld.com"
# "o2.co.uk"
# "orange.net"
# "sky.com"
# "talktalk.co.uk"
# "tiscali.co.uk"
# "virgin.net"
# "wanadoo.co.uk"
# "bt.com"
# )

declare -a asia_domains=(
"sina.com"
"qq.com"
"naver.com"
"hanmail.net"
"daum.net"
"nate.com"
"yahoo.co.jp"
"yahoo.co.kr"
"yahoo.co.id"
"yahoo.co.in"
"yahoo.com.sg"
"yahoo.com.ph"
)

# French ISP domains
declare -a fr_domains=(
"hotmail.fr"
"live.fr"
"laposte.net"
"yahoo.fr"
"wanadoo.fr"
"orange.fr"
"gmx.fr"
"sfr.fr"
"neuf.fr"
"free.fr"
)

# German ISP domains
# declare -a de_domains=(
# "gmx.de"
# "hotmail.de"
# "live.de"
# "online.de"
# "t-online.de"
# "web.de"
# "yahoo.de"
# )

# Russian ISP domains
# declare -a ru_domains=(
# "mail.ru"
# "rambler.ru"
# "yandex.ru"
# "ya.ru"
# "list.ru"
# )

# Belgian ISP domains
# declare -a ru_domains=(
# "hotmail.be"
# "live.be"
# "skynet.be"
# "voo.be"
# "tvcablenet.be"
# "telenet.be"
# )

# Argentinian ISP domains
# declare -a ar_domains=(
# "hotmail.com.ar"
# "live.com.ar"
# "yahoo.com.ar"
# "fibertel.com.ar"
# "speedy.com.ar"
# "arnet.com.ar"
# )

# Domains used in Mexico
# declare -a mx_domains=(
# "hotmail.com"
# "gmail.com"
# "yahoo.com.mx"
# "live.com.mx"
# "yahoo.com"
# "hotmail.es"
# "live.com"
# "hotmail.com.mx"
# "prodigy.net.mx"
# "msn.com"
# )

# Domains used in Brazil
# declare -a br_domains=(
# "yahoo.com.br"
# "hotmail.com.br"
# "outlook.com.br"
# "uol.com.br"
# "bol.com.br"
# "terra.com.br"
# "ig.com.br"
# "itelefonica.com.br"
# "r7.com"
# "zipmail.com.br"
# "globo.com"
# "globomail.com"
# "oi.com.br"
# )

#####################################
# Global variables
#####################################
BRUTE_MODE=0

#####################################
# /!\ Declare here the final list of domains
#####################################

final_domains=("${commons_domains[@]}" "${asia_domains[@]}")

#####################################
# Displays help
#####################################

function help(){
    echo "Usage: $0 [-f <input file>] [-b] [-h]"
    echo "       [-f <input file>] search input emails in file instead of stdin"
    echo "       [-b] Bruteforce mail domain"
    exit 1
}

if [ $# -lt 2 ] && [ $# -gt 3 ];then
    help
fi

#####################################
# Getting options
#####################################
while getopts "f:bh" OPT;do
    case ${OPT} in
        f)
            INPUT_FILE=${OPTARG}
            echo "[*] input file: ${INPUT_FILE}"
            ;;
        b)
            BRUTE_MODE=1
            echo "[*] Bruteforce mode activated"
            ;;
        :|h)
            echo "Invalid option ${OPT}"
            help
            ;;
    esac
done

#####################################
# Function check emails
#####################################
function check_email(){

    email=$1
    echo "[*] check email $1"

    # check for email found
    haveibeenpwned ${email}

    # check if bruteforce mode is activated
    if [ ${BRUTE_MODE} -eq 1 ];then
        
        # check for others domains
        for domain in "${final_domains[@]}";do

            # do not repeat request for existing domain found in input
            original_domain=$(echo -n $1 | cut -d@ -f2)

            # check if mail domain has already been checked
            if [ "${domain}" != "${original_domain}" ];then

                email=$(echo -n $1 | cut -d@ -f1)"@${domain}"
                echo "[*] check email ${email}"
                haveibeenpwned ${email}
            fi
        done  
    fi
    
}

#####################################
# Function haveibeenpwned.com API
#####################################
function haveibeenpwned(){

    # request haveibeenpwned
    response=$(curl --silent https://haveibeenpwned.com/api/v2/breachedaccount/$1)
    if [ "X""${response}" != "X" ];then
        echo  "FOUND $1 pwned in: "
        echo "${response}" | json_pp
    fi

    # https://haveibeenpwned.com/API/v2#AcceptableUse
    # Requests to the breaches and pastes APIs are limited to one per every 1500 milliseconds
    sleep 1.5
}

#####################################
# Reading emails
#####################################
echo "[!] haveibeenpwned API needs 1500 milliseconds between requests"

if [ "X" != "X"${INPUT_FILE} ];then

    #read from file
    for email in $(cat ${INPUT_FILE} | grep -o '[^ ]*@[^ ]*');do 
        check_email ${email}
    done

else

    # read from stdin
    echo -n "Enter email: "
    read email
    check_email ${email}

fi
