
#!/bin/bash

#####################################
# Displays help
#####################################

function help(){
	echo "Usage: $0 <root url> <bruteforce file>"
    exit 1
}

if [ $# -ne 2 ]; then
	help
fi

# We are reading and simply curling
cat ${2} | while read line;do

	# UPDATE the url here
	resp=$(curl "${1}${line}" 2>/dev/null)

	if [[ ! -z $resp ]];then
		
		echo "---------------------------------------------------------"
		echo "${line}"
		echo "---------------------------------------------------------"
		echo 

		# Need to sudo apt-get install html2text
		echo $resp | html2text
		echo
	fi

done