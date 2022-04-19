#! /usr/bin/env bash

# Script name: main.sh

# Description: This script runs all the other scripts required to setup the
# machine with MySQL and other programs, to be able to run the Python Flask app,
# Create Jazz Lyric. This script uses the commands:
# read - to read the desired database password from the user, with -s option to
# prevent echo-ing passwords characters to the terminal output.
# ssh - to run individual commands on the vagrant box

# Author: Kim Lew

hide_mid_chars() {
  PASSWD="$1"
  LEN="${#PASSWD}"
  FIRST="${PASSWD:0:1}"
  MID="${PASSWD:1:$((LEN-2))}"
  LAST="${PASSWD:$((LEN-1)):1}"
  STARS="${MID//?/*}"
  echo -n "Password is: ${FIRST}${STARS}${LAST}"
  echo
}
# Prompt user for root MySQL password, with -s so is silent mode/chars not shown,
# e.g., read -p "Type password: " -rs MYSQL_ROOT_PWD
# Verify password according to MySQL password policies in setup_mysql.sh.
read -rsep "Type a root password for MySQL: " PASSWORD_ROOT
echo
read -rsep "Re-type the root password for MySQL: " PASSWORD_CONFIRMED
echo
echo

hide_mid_chars "${PASSWORD_ROOT}"
if [ ! "${PASSWORD_ROOT}" = "${PASSWORD_CONFIRMED}" ]; then
  echo "Passwords entered do NOT match."
  echo -n "Confirmed "
  hide_mid_chars "${PASSWORD_CONFIRMED}"
  echo "Re-run main.sh."
  exit 1
fi
echo
echo "Setting up Create Jazz Lyric..."
echo

# -- Run commands these on your local computer. --
vagrant up
vagrant ssh-config > vagrant-ssh-config
chmod u+x copy_req_files_to_vm.sh
./copy_req_files_to_vm.sh

#  -- Use ssh to run commands in shell on VM/Virtual Machine/Deployment Machine. --
# Use vagrant ssh - for every command on VM, e.g., ssh -F vagrant-ssh-config, etc.

# ssh -F vagrant-ssh-config default -- copy_proj_to_vm.sh
ssh -F vagrant-ssh-config default -- chmod u+x setup_mysql.sh
ssh -F vagrant-ssh-config default -- chmod u+x setup_machine.sh

#  ssh -F vagrant-ssh-config default -- cat stuff.txt
ssh -F vagrant-ssh-config default -- cat \> mysql_pw.txt < <(echo "$PASSWORD_ROOT")  # bash named pipe, man process substitution redirection?
ssh -F vagrant-ssh-config default -- ./setup_mysql.sh
ssh -F vagrant-ssh-config default -- ./setup_machine.sh

# TRICKY Part: These 2 lines must be run on VM, but within this script, you are NOT on the VM.
# Change into the subdirectory, `pythonapp-createjazzlyric` if you are not there.
ssh -F vagrant-ssh-config default -- cd /home/vagrant/pythonapp-createjazzlyric \&\& pipenv run flask run

# In a Browser Tab: Check that the app is running at: <http://localhost:8084/>
# Note: The ports were forwarded in the `Vagrantfile` to port `8084`.
