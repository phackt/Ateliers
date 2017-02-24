
#!/bin/bash

#####################################
# Displays help
#####################################
function help(){
	echo "Usage: $0 <root url> <bruteforce file> <egrep pattern for non matching text>"
	echo "Example: $0 \"http://192.168.1.13:8088/\" \"/tmp/dir.lst\" \"(pegasus_by_exomemory-d5ofhgw.jpg|File not found)\""
    exit 1
}

SAVEFILE="foundfiles-"$RANDOM".txt"

# Control number of arguments
if [[ $# -lt 2 ]] || [[ $# -gt 3 ]];then
	help
fi

# We are looping on the wordlist
cat ${2} | while read line;do

	# If extension is missing and trailing slash is missing, we add it
	ext=$(echo -n "${line}" | egrep "\.[^\.]*$")
	lastchar=$(echo -n "${line:(-1)}")

	if [[ -z "${ext}" ]] && [[ "${lastchar}" != "/" ]];then
		line="${line}""/"
	fi

	# building the url
	url="${1}${line}"

	echo "${url}"

	# curl
	resp=$(curl "${url}" 2>/dev/null)
	parse=""

	# If pattern has been submitted
	if [[ "X" != "X""${3}" ]];then
		parse=$(echo "${resp}" | egrep "${3}")
	fi

	if [[ ! -z "${resp}" ]] && [[ -z "${parse}" ]];then
		
		echo "---------------------------------------------------------"
		echo "${line} FOUND" | tee -a "${SAVEFILE}"
		echo "---------------------------------------------------------"
		echo 

		# Need to sudo apt-get install html2text
		echo "${resp}" | html2text
		echo
	fi
done