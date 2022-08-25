#!/bin/bash

# Text format and colors

# Text Reset
Color_Off='\033[0m'
# White
White='\033[0;37m'
# Blue
Blue='\033[0;34m'
# Background Red
On_Red='\033[41m'
# Background Yellow
On_Yellow='\033[43m'
# Background Blue
On_Blue='\033[44m'
# Background Cyan
On_Cyan='\033[46m'
# Background Green
On_Green='\033[42m'
# Background Purple
On_Purple='\033[45m'
# Underline White
UWhite='\033[4;37m'
# Light purple
LPurple='\033[1;35m'

Log () {
    initial=$2
    if [ -z $2 ]; then
        initial=$White
    fi
    echo -e "${initial}$1$Color_Off"
}


ApplyPatches () {
    cat $1 | while read p
    do
        IFS=' ' read -r repo patchurl <<< $p
        cd $_INITIAL_DIR;
        Log "\nApplying patch on ${repo} from ${patchurl}\n" $On_Yellow
        if [[ $patchurl == *api.github* ]]
        then
            # clone and apply with api
            # Uses the official github CLI to get the changes to apply (gh api)
            # Uses the native patch utility apply the changes (patch)
            gh api ${patchurl}/files | python "$_SCRIPT_DIR/main.py" --method=patch
        else
            # Uses default git clone to get the changes to apply (git clone)
            # Uses git utilities to apply the changes (git apply)
            cd $repo
            wget -O $_TEMP_FILE_NAME $patchurl
            git apply $_TEMP_FILE_NAME
            rm $_TEMP_FILE_NAME
        fi
    done
}


# $1: Target folder
# $2: Repo URL
# $3: Branch
# $4: revision
# $5: extra path (used to be contanenated in the directory path in the current execution)
PrepareRepo () {
    if [ -z $3 ]; then
        branch=$ODOO_VERSION
    else
        branch=$3
    fi

    target_path="$_INITIAL_DIR/$5$1"
    Log "\n\nSetting up the repository $1\n" $On_Blue
    Log "repo url:"
    Log "$2\n\n" $UWhite
    if [ ! -d $target_path ]; then
        git clone $2 -b $branch $target_path --depth=1
    fi
    if [ ! -z $4 ]; then
        Log "\nChecking out $1 to commit $4\n" $Blue
        cd $target_path;
        git checkout $4;
        cd $_INITIAL_DIR;
    fi

    # Cloning OCA dependencies (recursive call)
    # We need to ensure all code is available before we start patching
    if test -f "$target_path/oca_dependencies.txt"; then
        Log "\nDownloading code dependency from $target_path/oca_dependencies.txt\n" $On_Purple
        cat "$target_path/oca_dependencies.txt" | while read p
        do
            IFS=' ' read -r repo url oca_branch revision <<< $p
            if [ -z $url ]; then # Some lines does not have url
                Log "\nMissing dependency $repo\n" $On_Red
                echo "$p" >> "$_INITIAL_DIR/$MISSING_REPOS_FILE" 
            else
                if [ "$repo" == "#" ]; then
                    Log "\nIgnoring bad formatted line\n" $On_Red
                else
                    PrepareRepo "$repo" "$url" "$oca_branch" "$revision" "extra_addons/"
                fi
            fi
        done
    fi

    # Applying required patches
    if test -f "$target_path/patches.txt"; then
        Log "\nApplying patch file $target_path/patches.txt\n" $On_Yellow
        ApplyPatches "$target_path/patches.txt"
    fi

    # Install Python dependencies
    if test -f "$target_path/requirements.txt"; then
        Log "\nInstalling python requirements from file $target_path/requirements.txt\n" $On_Cyan
        pip install -r "$target_path/requirements.txt"
    fi

}


_SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
_INITIAL_DIR=$( pwd )
_TEMP_FILE_NAME=".temporalpatchfileABI0612"

source $_SCRIPT_DIR/variables.sh

Log "\nInitializing workspace for $MAIN_REPO_NAME...\n" $On_Green

rm -f "$_INITIAL_DIR/$MISSING_REPOS_FILE"; touch "$_INITIAL_DIR/$MISSING_REPOS_FILE";

PrepareRepo "odoo" $ODOO_REPO $ODOO_VERSION
PrepareRepo $MAIN_REPO_NAME $MAIN_REPO $ODOO_VERSION "" "extra_addons/"

$_INITIAL_DIR/odoo/odoo-bin -c "$_INITIAL_DIR/$ODOO_CONFIG_FILE" -s --stop-after-init

extra_dirs=$(ls -d $_INITIAL_DIR/extra_addons/* | python "$_SCRIPT_DIR/main.py" --method=addons --repo=$MAIN_REPO_NAME --pwd="$_INITIAL_DIR/extra_addons")

if [ -s "$_INITIAL_DIR/$MISSING_REPOS_FILE" ]; then
    python "$_SCRIPT_DIR/main.py" --method=unify --file=$_INITIAL_DIR/$MISSING_REPOS_FILE
    Log "\nCould not find the following repositories:\n" $On_Red
    cat $_INITIAL_DIR/$MISSING_REPOS_FILE
    Log "\nYou can see them on:"
    Log "$_INITIAL_DIR/$MISSING_REPOS_FILE" $UWhite
fi

Log "\n\nProcess finalized!\n\n" $On_Green
Log "\nCopy & paste the addons path string showed below for this workspace on your odoo configuration file, saved on:\n"
Log "$_INITIAL_DIR/$ODOO_CONFIG_FILE" $UWhite
Log "\n$extra_dirs"
Log "\n\nbesitos te huele la cola\n\n" $LPurple
