#! /usr/bin/env bash

# This script helps install MySQL on a machine with CentOS 7.
# Assumes you already did: vagrant up & vagrant ssh

set -e # To exit immediately if a command exits with a non-zero status.
sudo yum update -y
sudo yum install nano -y
sudo yum install wget -y
sudo yum install expect -y

# MAKE SURE you have already created mysql_pw.txt outside of this script & put
# in the password you want for root.
# This script assumes mysql_pw.txt already exists.
# BEST TO Put MYSQL_ROOT_PWD in a file vs. in an environment variable so it is
# on the filesystem & can be reuses for other purposes. You can't reuse if done
# a diff way, i.e., add a user prompt at front of script for password.

MYSQL_PW_FILE='mysql_pw.txt'
if [ -f "$MYSQL_PW_FILE" ]; then
  MYSQL_ROOT_PWD=$(cat "$MYSQL_PW_FILE")
else
  echo "${MYSQL_PW_FILE} doesn't exist"
  exit 1
fi

# From /var/log/mysqld.log, look for phrase for root@localhost:<space>
# & from there, get all characters up to new line character & save as
# MYSQL_TEMP_PWD. Note: This is 13 chars in from 'temporary password'.
# Temporary password is created with MySQL installation in /var/log/mysqld.log.
# Assign to variable to use if mysql_secure_installation has NOT been run yet."
echo
echo "GETTING temporary password"
sudo grep 'temporary password' /var/log/mysqld.log
MYSQL_TEMP_PWD=$(sudo grep 'temporary password' /var/log/mysqld.log | awk '{print $13}')
echo "temp root password: ${MYSQL_TEMP_PWD}"
echo
echo "GETTING assigned root password"
MYSQL_ROOT_PWD=$(<${MYSQL_PW_FILE})
echo "new root password: ${MYSQL_ROOT_PWD}"
echo

run_mysql_secure_installation() {
  # -f flag means to use a file & - means to use standard input as the file
  # -c flag prefaces a command to be executed before any in the script
  # Use HERE document vs. as a straight multiline string - to avoid quoting issues
SECURE_MYSQL=$(expect -f '-' <<HERE
set timeout 10
spawn mysql_secure_installation

expect "Enter password for user root:"
send "${MYSQL_TEMP_PWD}\r"

expect {
  "Change the password for root ? \(Press y|Y for Yes, any other key for No) :" {
    send "y\r"
  }
  "The existing password for the user account root has expired. Please set a new password." {
  }
}
expect "New password:"
send "${MYSQL_ROOT_PWD}\r"

expect "Re-enter new password:"
send "${MYSQL_ROOT_PWD}\r"

expect {
  "Do you wish to continue with the password provided?\(Press y|Y for Yes, any other key for No) :" {
    send "y\r"
  }
  "Change the password for root ? \(Press y|Y for Yes, any other key for No) :" {
    send "n\r"
}

expect "Remove anonymous users? \(Press y|Y for Yes, any other key for No) :"
send "y\r"

expect "Disallow root login remotely? \(Press y|Y for Yes, any other key for No) :"
send "y\r"

expect "Remove test database and access to it? \(Press y|Y for Yes, any other key for No) :"
send "y\r"

expect "Reload privilege tables now? \(Press y|Y for Yes, any other key for No) :"
send "y\r"
expect eof
HERE
)
echo "$SECURE_MYSQL"
echo "DONE."
# echo "mysql_secure_installation has been run & root password has been assigned for MySQL."
echo
}

# Check if MySQL IS installed, i.e., you already set up MySQL yet & already
# changed temporary password - so NO need to install MySQL.
# Next: Check if mysql_secure_installation has been run.
# -v means tell if pattern not found
if ! [ "$(sudo yum repolist enabled | grep "mysql.*-community.*")" == '' ] || command -v mysqld; then
  echo "MySQL is already installed."
  echo

  # Case 1: CHECK if assignedroot password works with MySQL.
  # If it root password exists, exit with 0 & skip rest of code since it means
  # MySQL is installed AND mysql_secure_installation has already been run.
  # Case 2: else - only the temporary password exists so far which means
  # MySQL is installed BUT mysql_secure_installation has NOT been run yet, so run.
  echo "TEST if root password runs MySQL, i.e., mysql_secure_installation was already run."
  echo
  if expect -f '-' <<HERE
  set timeout 5
  spawn mysql -u root -p --execute "quit"
  expect "Enter password:"
  send "$MYSQL_ROOT_PWD\r"
  expect eof
  exit [lindex [wait] 3]
HERE
  then
    echo
    echo "ROOT password assigned in mysql_pw.txt WORKED! MySQL is installed & mysql_secure_installation was run."
    exit
  else
    echo
    echo "RUNNING the program, mysql_secure_installation..."
    echo
    run_mysql_secure_installation
  fi
else
  # MySQL is NOT installed, i.e., you haven't set up MySQL yet, nor changed
  # temporary password - so install MySQL. Then call run_mysql_secure_installation().
  # B4: [ "$(sudo yum repolist enabled | grep "mysql.*-community.*")" == '' ] || ! command -v mysqld; then

  echo "MySQL is NOT installed yet. GETTING and VERIFYING"
  echo "MySQL mysql80-community-release-el7-4 and installing MySQL."

  # CHECK for MySQL File Download.
  # Create a new file with the extension .rpm.md5 with contents of the copied
  # MD5 from the approved site. With this file, perform an md5sum --check.
  # If successful, returns exit code 0. If NOT successful, give user an error
  # message & exit code 1.
  if ! [ -f mysql80-community-release-el7-4.noarch.rpm ]; then
    wget https://dev.mysql.com/get/mysql80-community-release-el7-4.noarch.rpm
  fi

  if ! [ -f mysql80-community-release-el7-4.noarch.rpm.md5 ]; then
    echo "8b55d5fc443660fab90f9dc328a4d9ad mysql80-community-release-el7-4.noarch.rpm" > mysql80-community-release-el7-4.noarch.rpm.md5
  fi

  if ! md5sum --check mysql80-community-release-el7-4.noarch.rpm.md5; then
    # Not verifiable MySQL file. Show error here & exit from the script.
    echo "FAILED md5sum check for the MySQL file. Exiting the script."
    exit 1
  fi
  # OR use GnuPG signatures to verify the integrity of the packages you download.
  # At this point: Passed md5sum check for the MySQL file.

  # Note: rpm might fail if MySQL is already installed.
  # TODO: Add a check here for if mysql80-community-release is already installed.
  # man rpm & Google: How to tell if an rpm package already installed.
  # sudo rpm -ivh mysql80-community-release-el7-4.noarch.rpm || true
  MYSQL_PKG="mysql80-community-release-el7-4.noarch.rpm"
  rpm -q "${MYSQL_PKG}"
  if [ $? = 1 ]; then
    rpm -e "${MYSQL_PKG}"
    sudo rpm -ivh "${MYSQL_PKG}"
  fi
  sudo yum repolist enabled | grep "mysql.*-community.*"
  sudo yum install mysql-server -y
  echo "DONE installing MySQL."
  echo
fi

# Verify MySQL server works - by starting mysqld.service
sudo systemctl start mysqld.service
sudo systemctl status mysqld

# CHECK if mysql_secure_installation has been run.
echo "ROOT password assigned in mysql_pw.txt DID NOT WORK."

# Run MySQL w temp password.
# Use "poo" vs. send "${MYSQL_TEMP_PWD}\r" - to test bad result case
# https://unix.stackexchange.com/questions/141346/how-to-get-exit-status-from-command-in-expect-script
#expect "\\$ "
#send "status=`echo $?\r`"

echo "CHECKING if mysql_secure_installation has already been run..."
if expect -f '-' <<HERE
set timeout 5
spawn mysql -u root -p --connect-expired-password --execute "quit"
expect "Enter password:"
send "$MYSQL_TEMP_PWD\r"
expect eof
exit [lindex [wait] 3]
HERE
then
  echo
  echo "Temporary password still works so you have NOT run mysql_secure_installation yet."
  # Confirmed that temporary password still works. Use temporary password for root
  # to run the program, mysql_secure_installation & to change the root password.

  echo "RUNNING the program, mysql_secure_installation..."
  echo
  run_mysql_secure_installation
fi

echo "NOW start MySQL with given root password..."
# RUN_MYSQL=$(expect -f '-'  <<HERE
# set timeout 5
# spawn mysql -u root -p
# expect "Enter password:"
# send "${MYSQL_ROOT_PWD}\r"
# expect eof
# HERE
# )
# echo "$RUN_MYSQL"

# Final Test: Manually uninstall MySQL on this VM to test entire script.
# sudo yum erase mysql-community-server -y
# sudo rm -rf /var/lib/mysql
# sudo rm /var/log/mysqld.log

# FINAL Final Test: Destroy this CentOS 7 VM with vagrant destroy & create a
# new one with vagrant up. Re-scp this file & re-run on clean VM.
