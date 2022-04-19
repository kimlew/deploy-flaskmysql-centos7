#! /usr/bin/env bash

# Script name: copy_req_files_to_vm.sh

# Description: The script, main.sh, runs this script BEFORE setup_mysql.sh &
# setup_machine.sh are run. This script transfers those 2 setup files, plus the
# project files & folders for the Create Jazz Lyric Python Flask web app to the
# deployment machine.
# Note: This script uses a copy of the Vagrant configuration file,
# vagrant-ssh-config, which is created in main.sh.

# Author: Kim Lew

VAG_SSH_CFG='vagrant-ssh-config'
SRC_REQ_FILES_DIR='/Users/kimlew/code/vagrant_vm_centos7_create_jazz/'  # On Mac.
SRC_PROJ_DIR='/Users/kimlew/code/vagrant_vm_centos7_create_jazz/pythonapp-createjazzlyric/'  # On Mac.
DEST_REQ_FILES_AT_ROOT_DIR='/home/vagrant/'  # VM root directory.
DEST_PROJ_DIR='/home/vagrant/pythonapp-createjazzlyric/'  # On VM.

# --- Copy files needed at root directory on VM to set up VM. ---
scp -F "${VAG_SSH_CFG}" "${SRC_REQ_FILES_DIR}"setup_mysql.sh vagrant@default:"${DEST_ROOT_DIR}"setup_mysql.sh
scp -F "${VAG_SSH_CFG}" "${SRC_REQ_FILES_DIR}"setup_machine.sh vagrant@default:"${DEST_ROOT_DIR}"setup_machine.sh

# --- Copy project files & folders for app, pythonapp-createjazzlyric ---
# Note: scp -r recursively copies entire directory, pythonapp-createjazzlyric
scp -F "${VAG_SSH_CFG}" -r "${SRC_PROJ_DIR}" vagrant@default:"${DEST_PROJ_DIR}"
