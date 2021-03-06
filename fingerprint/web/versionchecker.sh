#!/bin/bash

#####################################
# Croise les checksums des fichiers statiques
# les plus commités pour en déduire une
# fenêtre de versions probables
#####################################

#####################################
# Variables section
#####################################

declare -A INPUT_FILES

INPUT_DIR=""
GIT_REPO=""
GREP_PATTERN=".*"
VERBOSE_MODE=0

# Script directory
SCRIPT_DIR=$(dirname $(readlink -f $0))

#####################################
# Help
#####################################
function help(){
    echo "Usage: $0 -s source_dir [-g git_repo] [-p pattern] [-v]"
    echo "       -s source_dir    :input files directory path"
    echo "       [-g git_repo]    :GIT repository directory"
    echo "       [-p pattern]     :pattern used to grep GIT tags - example \"^7\.[0-9]+$\""
    echo "       [-v]             :verbose mode"
    echo
    echo "Example of command:"
    echo "./versionchecker.sh -s ./input -g ~/Documents/repo/drupal/ -p \"^[78]\.[0-9.]+$\" -v"
    exit 1
}

if [ $# -lt 2 ] || [ $# -gt 7 ];then
    help
fi

#####################################
# Getting options
#####################################
while getopts "s:g:p:v" OPT;do
    case "${OPT}" in
        s)
            INPUT_DIR="${OPTARG}"
            if [ ! -d "${INPUT_DIR}" ];then
                echo -e "\e[31m[!] Directory ${INPUT_DIR} not found\e[0m"
                help
            fi
            INPUT_DIR=$(readlink -f "${INPUT_DIR}")
            echo "[*] Input files directory: ${INPUT_DIR}"

            # Cleaning empty input files and directories
            echo -n "[*] Cleaning empty files and directory in ${INPUT_DIR} - "
            find "${INPUT_DIR}" -empty -delete &>/dev/null
            echo "Done"
            ;;
        g)
            GIT_REPO="${OPTARG}"
            if [ ! -d "${GIT_REPO}" ];then
                echo -e "\e[31m[!] GIT repository ${GIT_REPO} not found\e[0m"
                help
            fi
            GIT_REPO=$(readlink -f "${GIT_REPO}")
            echo "[*] GIT repository: ${GIT_REPO}"
            ;;
        p)
            GREP_PATTERN="${OPTARG}"
            if [ "X" == "X""${GREP_PATTERN}" ];then
                echo -e "\e[31m[!] Grep pattern is empty\e[0m"
                help
            fi
            echo "[*] Grep pattern: ${GREP_PATTERN}"
            ;;
        v)
            VERBOSE_MODE=1
            ;;
        :)
            echo -e "\e[31m[!] Invalid option ${OPT}\e[0m"
            help
            ;;
    esac

    # input dir is mandatory
    if [ "X""${INPUT_DIR}" == "X" ];then
        echo -e "\e[31m[!] Directory ${INPUT_DIR} is mandatory\e[0m"
        help
    fi
done

#####################################
# Function echo overriden
#####################################
function debug(){

    # Check if verbose mode is activated
    if [ ${VERBOSE_MODE} -eq 1 ];then
        builtin echo $*
    fi
}

#####################################
# Function versions comparison
#####################################
function version_gt(){
    test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1";
}

#####################################
# Function hashing the repository files
#####################################
function hash_files(){
    
    # Move to GIT repository
    cd "${GIT_REPO}"

    # Check if the hashes file is existing
    if [ -f "${SCRIPT_DIR}/work/hashes.txt" ];then
        echo -n "[*] ${SCRIPT_DIR}/work/hashes.txt found. Are you sure you want to overwrite and compute hashes [Y/n]: "
        read -e YESNO
    fi

    # Ok we can compute hashes from the GIT repository for every tags matching the specified pattern
    if [ "${YESNO,,}""X" != "nX" ]; then

        # Removing any lock file
        rm -f ".git/index.lock" &>/dev/null

        # Deleting existing hashes.txt file
        rm -f "${SCRIPT_DIR}/work/hashes.txt" &>/dev/null

        # Looping on each GIT tags
        for tag in $(git tag | egrep "${GREP_PATTERN}" | sort -V);do

            echo "[*] -----------------------"
            echo "[*] Looking for tag: ${tag}"

            # Forcing checkout
            git checkout -f "${tag}" &>/dev/null

            # Cleaning GIT tag (status should never change) - Removing untracked files
            git clean -d -fx . &>/dev/null

            # Cleaning GIT tag (status should never change) - Resetting to HEAD
            git reset --hard HEAD &>/dev/null

            # Go into INPUT_DIR
            cd "${INPUT_DIR}" &>/dev/null

            # Looping on each input file and finding them in the repository
            for file in $(find . -type f | sed "s/^..//g");do

                file_to_hash=$(find "${GIT_REPO}" -type f | grep "${file}")
                debug "[*] Looking in repo for file: ${file}"

                # We are checking if the filename is consistent
                if [ -f "${file_to_hash}" ];then
                    debug "[*] Found : ${file_to_hash}"
                    hash_tmp="${tag}:${file}:$(md5sum ${file_to_hash} | cut -d' ' -f1)"

                    debug "${hash_tmp}"
                    echo "${hash_tmp}" >> "${SCRIPT_DIR}/work/hashes.txt"
                else
                    echo -e "\e[31m[!] Finding ${file} in repository ${GIT_REPO} failed\e[0m"
                    echo -e "\e[31m[!] May be file is missing in repository\e[0m"
                    echo -e "\e[31m[!] Find result: ${file_to_hash}\e[0m"
                fi
            done

            # Come back to repo dir
            cd - &>/dev/null
        done
    fi
}

#####################################
# Function matching input hashes with repo's ones
#####################################
function get_versions(){
    
    # Have some hashes already been computed ? 
    if [ ! -f "${SCRIPT_DIR}/work/hashes.txt" ];then
        echo -e "\e[31m[!] ${SCRIPT_DIR}/work/hashes.txt is missing\e[0m"
        echo -e "\e[31m[!] You'd better specify a GIT repository in order to compute hashes first\e[0m"
        exit 1
    fi

    # Go into INPUT_DIR
    cd "${INPUT_DIR}" &>/dev/null

    # Performing a dos2unix on every files found in INPUT_DIR
    find . -type f -exec dos2unix {} \; &>/dev/null

    # Looping on each input file to hash it and find its matching versions
    for file in $(find . -type f | sed "s/^..//g");do

        file_to_check=$(readlink -f "${file}")

        # Check that the file is physically present in input directory
        if [ ! -f "${file_to_check}" ];then
            echo "[*] File ${file_to_check} can not be found."
        else

            # We are computing hash (of file previously downloaded from the target server)
            # We should take care about the encoding
            file_to_check_hash=$(md5sum "${file_to_check}" | cut -d' ' -f1)

            echo "[*] -----------------------"
            echo "[*] Checking filename ${file_to_check}: ${file_to_check_hash}"
            grep_hash=$(grep "${file_to_check_hash}" "${SCRIPT_DIR}/work/hashes.txt")

            # Looking if hash has been found in the computed hashes file hashes.txt
            if [ "X" != "X""${grep_hash}" ];then

                # Storing the versions for the current input file
                INPUT_FILES["${file}"]+=$(echo "${grep_hash}" | cut -d':' -f1)

                min_version_tmp=$(echo "${grep_hash}" | cut -d":" -f1 | sort -V | head -1)
                max_version_tmp=$(echo "${grep_hash}" | cut -d":" -f1 | sort -Vr | head -1)

                # We are looking for the highest value in low ones fork
                if version_gt ${min_version_tmp} ${min_version};then
                    min_version=${min_version_tmp}
                fi

                # We are looking for the lowest value in high ones fork
                if [ ${max_version} == 0 ];then
                    max_version=${max_version_tmp}
                elif version_gt ${max_version} ${max_version_tmp};then
                    max_version=${max_version_tmp}
                fi


                # We are adding a check in case of inconsistency (if for example a file has been manually replaced from another version)
                if version_gt ${min_version} ${max_version};then
                    echo -e "\e[31m[!] new max version found for current file: ${max_version}"
                    echo -e "\e[31m[!] current min version is: ${min_version}"
                    echo -e "\e[31m[!] Analysis is non consistent!"
                    echo -e "\e[31m[!] May be a file from another version has been manually updated!"
                    exit 1
                fi

                debug "${grep_hash}"

            else
                echo -e "\e[31m[!] Hash can not be found in computed hashes\e[0m"
                echo -e "\e[31m[!] Be sure the ${file} file is present in the GIT tags you have selected\e[0m"
                echo -e "\e[31m[!] Be sure encoding is the same between files compared (try find ${INPUT_DIR} -type f | xargs dos2unix)\e[0m"
                echo -e "\e[31m[!] Analysis is non consistent...14|\/|32!!!.\e[0m"
                exit 1
            fi
        fi
    done

    # come back to previous dir
    cd - &>/dev/null
}

#####################################
# Function finding relevant versions
#####################################
function display_relevant_versions(){
    nb_files=$(find "${INPUT_DIR}" -type f | wc -l)
    echo "[*] Number of input files: ${nb_files}"
    echo "[*] All input files have been found in the following versions: "
    echo "${INPUT_FILES[@]}" | sed 's/ /\n/g' | sort -V | uniq -c | sort -rg | awk '{if($1=='${nb_files}') print $NF}'
}

#####################################
# Main
#####################################

# Creating the missing directories
if [ ! -d "${SCRIPT_DIR}/work" ];then
    mkdir "${SCRIPT_DIR}/work"
fi

# Some checks
# Is the input directory empty ?
# Todo: ask for a specific CMS and automatically download relevant files from target and do the comparison
if [ "$(ls ${INPUT_DIR})""X" == "X" ];then
    echo -e "\e[31m[!] Input directory ${INPUT_DIR} is empty. Nothing to compare.\e[0m"
    exit 1
fi

# Kiff section
echo "        ___           ___           ___           ___                       ___           ___       "
echo "       /\\__\\         /\\  \\         /\\  \\         /\\  \\          ___        /\\  \\         /\\__\\      "
echo "      /:/  /        /::\\  \\       /::\\  \\       /::\\  \\        /\\  \\      /::\\  \\       /::|  |     "
echo "     /:/  /        /:/\\:\\  \\     /:/\\:\\  \\     /:/\\ \\  \\       \\:\\  \\    /:/\\:\\  \\     /:|:|  |     "
echo "    /:/__/  ___   /::\\~\\:\\  \\   /::\\~\\:\\  \\   _\\:\\~\\ \\  \\      /::\\__\\  /:/  \\:\\  \\   /:/|:|  |__   "
echo "    |:|  | /\\__\\ /:/\\:\\ \\:\\__\\ /:/\\:\\ \\:\\__\\ /\\ \\:\\ \\ \\__\\  __/:/\\/__/ /:/__/ \\:\\__\\ /:/ |:| /\\__\\  "
echo "    |:|  |/:/  / \\:\\~\\:\\ \\/__/ \\/_|::\\/:/  / \\:\\ \\:\\ \\/__/ /\\/:/  /    \\:\\  \\ /:/  / \\/__|:|/:/  /  "
echo "    |:|__/:/  /   \\:\\ \\:\\__\\      |:|::/  /   \\:\\ \\:\\__\\   \\::/__/      \\:\\  /:/  /      |:/:/  /   "
echo "     \\::::/__/     \\:\\ \\/__/      |:|\\/__/     \\:\\/:/  /    \\:\\__\\       \\:\\/:/  /       |::/  /    "
echo "      ~~~~          \\:\\__\\        |:|  |        \\::/  /      \\/__/        \\::/  /        /:/  /     "
echo "                     \\/__/         \\|__|         \\/__/                     \\/__/         \\/__/      "
echo "        ___           ___           ___           ___           ___           ___           ___     "
echo "       /\\  \\         /\\__\\         /\\  \\         /\\  \\         /\\__\\         /\\  \\         /\\  \\    "
echo "      /::\\  \\       /:/  /        /::\\  \\       /::\\  \\       /:/  /        /::\\  \\       /::\\  \\   "
echo "     /:/\\:\\  \\     /:/__/        /:/\\:\\  \\     /:/\\:\\  \\     /:/__/        /:/\\:\\  \\     /:/\\:\\  \\  "
echo "    /:/  \\:\\  \\   /::\\  \\ ___   /::\\~\\:\\  \\   /:/  \\:\\  \\   /::\\__\\____   /::\\~\\:\\  \\   /::\\~\\:\\  \\ "
echo "   /:/__/ \\:\\__\\ /:/\\:\\  /\\__\\ /:/\\:\\ \\:\\__\\ /:/__/ \\:\\__\\ /:/\\:::::\\__\\ /:/\\:\\ \\:\\__\\ /:/\\:\\ \\:\\__\\"
echo "   \\:\\  \\  \\/__/ \\/__\\:\\/:/  / \\:\\~\\:\\ \\/__/ \\:\\  \\  \\/__/ \\/_|:|~~|~    \\:\\~\\:\\ \\/__/ \\/_|::\\/:/  /"
echo "    \\:\\  \\            \\::/  /   \\:\\ \\:\\__\\    \\:\\  \\          |:|  |      \\:\\ \\:\\__\\      |:|::/  / "
echo "     \\:\\  \\           /:/  /     \\:\\ \\/__/     \\:\\  \\         |:|  |       \\:\\ \\/__/      |:|\\/__/  "
echo "      \\:\\__\\         /:/  /       \\:\\__\\        \\:\\__\\        |:|  |        \\:\\__\\        |:|  |    "
echo "       \\/__/         \\/__/         \\/__/         \\/__/         \\|__|         \\/__/         \\|__|    "
echo 
echo
echo "[*] Hint: for choosing relevant files to compare from a GIT repository:"
echo "[*] git log --all --pretty=format: --name-only | egrep -i \"(.js$|.html$|.css$)\" | sort | uniq -c | sort -rg | head -20"
echo

# Let's rumble!
if [ "X" != "X""${GIT_REPO}" ];then
    hash_files
fi

# min/max versions
min_version=0
max_version=0

get_versions

echo "[*] Thanks to strong and costly mathematical and statistical calculation:"
echo -e "\e[32m[*] min version: ${min_version}"
echo "[*] max version: ${max_version}"

display_relevant_versions
