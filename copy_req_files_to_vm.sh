#! /usr/bin/env bash

# Script name: copy_proj_to_vm.sh
# Description: Run this script BEFORE your run: setup_mysql.sh & setup_machine.sh
# This script transfers those 2 setup files & the project files &
# folders for the create-jazz-lyric Python Flask web app to the deployment machine.
# Author: Kim Lew

# --- Using Vagrant Configuration File ----------------------------------------
# Assumes: vagrant-ssh-config was created as early step in README.

VAG_SSH_CFG='vagrant-ssh-config'
SRC_REQ_FILES_DIR='/Users/kimlew/code/vagrant_vm_centos7_create_jazz/'  # On Mac.
SRC_PROJ_DIR='/Users/kimlew/code/vagrant_vm_centos7_create_jazz/pythonapp-createjazzlyric/'  # On Mac.
DEST_REQ_FILES_AT_ROOT_DIR='/home/vagrant/'  # VM root directory.
DEST_PROJ_DIR='/home/vagrant/pythonapp-createjazzlyric/'  # On VM.

# --- Copy files needed at root directory on VM to set up VM. ---
scp -F "${VAG_SSH_CFG}" "${SRC_REQ_FILES_DIR}"setup_mysql.sh vagrant@default:"${DEST_ROOT_DIR}"setup_mysql.sh
scp -F "${VAG_SSH_CFG}" "${SRC_REQ_FILES_DIR}"setup_machine.sh vagrant@default:"${DEST_ROOT_DIR}"setup_machine.sh

# --- Copy project files & folders for app, pythonapp-createjazzlyric ---
# Note: scp -r  recursively copies entire directory, pythonapp-createjazzlyric
scp -F "${VAG_SSH_CFG}" -r "${SRC_PROJ_DIR}". vagrant@default:"${DEST_PROJ_DIR}"


# --- Using .pem Key -----------------------------------------------------------
# Note: Use .pem key to use SSH, plus AWS requires it.
# TODO: Can take IP address in as an arg.

# PEM_KEY='/Users/kimlew/.ssh/url-shortener.pem'
# Question: How do I get IP address for VM again?
# IP_ADDR='35.165.16.130'

# echo "${PEM_KEY}"
# echo
# echo "${PEM_KEY}" vagrant@"${IP_ADDR}"
# echo "${PEM_KEY}" "${SRC_LOC}"Pipfile ec2-user@"${IP_ADDR}":"${DEST_DIR}"

# ssh -i "${PEM_KEY}" vagrant@"${IP_ADDR}" -- 'mkdir -p pythonapp-createjazzlyric'

# --- Files needed on a VM to set up VM. ---
# scp -i "${PEM_KEY}" "${SRC_LOC}"vagrant-ssh-config vagrant@"${IP_ADDR}":"${DEST_ON_VM}"
# scp -i "${PEM_KEY}" "${SRC_LOC}"setup_machine.sh vagrant@"${IP_ADDR}":"${DEST_ON_VM}"
# scp -i "${PEM_KEY}" "${SRC_LOC}"setup_mysql.sh vagrant@"${IP_ADDR}":"${DEST_ON_VM}"

# --- Project files & folders for app, pythonapp-createjazzlyric ---
# scp -i "${PEM_KEY}" "${SRC_LOC}"Pipfile vagrant@"${IP_ADDR}":"${DEST_PROJ_DIR}"
# scp -i "${PEM_KEY}" "${SRC_LOC}"Pipfile.lock vagrant@"${IP_ADDR}":"${DEST_PROJ_DIR}"
# scp -i "${PEM_KEY}" "${SRC_LOC}"README.md vagrant@"${IP_ADDR}":"${DEST_PROJ_DIR}"

# TODO: scp folder, static & all files
# TODO: scp folder, templates & all files
# TODO: scp file, conn_vars_dict.py
# TODO: scp file, create_mysql_db.sql
# TODO: scp file, create_jazz_lyric.py
