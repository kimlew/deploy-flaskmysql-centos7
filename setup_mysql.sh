#! /usr/bin/env bash

# This script helps install MySQL on a machine with CentOS 7.
# Assumes you already did: vagrant up & vagrant ssh

set -e # To exit immediately if a command exits with a non-zero status.
sudo yum update -y
sudo yum install nano -y
sudo yum install wget -y
sudo yum install expect -y

# Check that MySQL is not installed, i.e., you haven't setup MySQL yet, nor
# changed temporary password so install MySQL.
# if [ (sudo yum repolist enabled | grep "mysql.*-community.*") == '' ]; then
if [ "$(sudo yum repolist enabled | grep "mysql.*-community.*")" == '' ] || ! command -v mysqld; then
# if sudo yum repolist enabled | grep -v "mysql.*-community.*" # -v means tell if pattern not found
  echo "GETTING and VERIFYING MySQL mysql80-community-release-el7-4"

  # -- MySQL File Download Check --
  # Create a new file with copied MD5 from the approved site, e.g., file with
  # the extension, .rpm.md5. Do a check with this file. Returns exit code 0
  # if successful. If NOT successful, give user an error message & exit code 1.
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
fi

# Best: Put MYSQL_ROOT_PWD in a file vs. in an environment variable.
# Assumes: Kim created mysql_pw.txt outside of this script & put in password
# she wanted for root.
# Could do a diff way & added a user prompt at front of script for password, BUT
# then it's not on file system & Kim can't reuse for other purposes.
MYSQL_PW_FILE='mysql_pw.txt'
if [ -f "$MYSQL_PW_FILE" ]; then
  MYSQL_ROOT_PWD=$(cat "$MYSQL_PW_FILE")
else
  echo "${MYSQL_PW_FILE} doesn't exist"
  exit 1
fi

# Verified MySQL is installed - so start here.
sudo systemctl start mysqld.service
sudo systemctl status mysqld

# From /var/log/mysqld.log, look for phrase for root@localhost:<space>
# & from there, get all characters up to new line character & save as
# MYSQL_TEMP_PWD. Note: This is 13 chars in from 'temporary password'.

echo "CHECKING for temporary password in /var/log/mysqld.log"
sudo grep 'temporary password' /var/log/mysqld.log
MYSQL_TEMP_PWD=$(sudo grep 'temporary password' /var/log/mysqld.log | awk '{print $13}')
echo "temp root password: ${MYSQL_TEMP_PWD}"
MYSQL_ROOT_PWD=$(<${MYSQL_PW_FILE})
echo "new root password: ${MYSQL_ROOT_PWD}"

echo "ABOUT to run expect..."

# -- TEST if mysql_secure_installation was already run: Run MySQL w temp password--
# Use "poo" vs. send "${MYSQL_TEMP_PWD}\r" - to test bad result case
# https://unix.stackexchange.com/questions/141346/how-to-get-exit-status-from-command-in-expect-script
#expect "\\$ "
#send "status=`echo $?\r`"

if expect -f '-' <<HERE
set timeout 5
spawn mysql -u root -p --execute "SHOW DATABASES;"
expect "Enter password:"
send "$MYSQL_TEMP_PWD\r"
expect eof
exit [lindex [wait] 3]
HERE
then
  # Temporary password still works - must run mysql_secure_installation.
  echo "Temporary password still works so have NOT run mysql_secure_installation yet."
  echo "WILL NOW run mysql_secure_installation."
  # TODO: Now run mysql_secure_installation program.
else
  # Temporary password doesn't work - so SKIP mysql_secure_installation.
  echo "SKIP running mysql_secure_installation. Already did since temporary password doesn't work."
fi

# At this point, can assume you have installed MySQL so use assigned root password.
echo
echo "TEST if root password runs MySQL."
if expect -f '-' <<HERE
set timeout 5
spawn mysql -u root -p --execute "SHOW DATABASES;"
expect "Enter password:"
send "$MYSQL_ROOT_PWD\r"
expect eof
exit [lindex [wait] 3]
HERE
then
  echo "ROOT password assigned in mysql_pw.txt WORKED!"
else
  echo "ROOT password assigned in mysql_pw.txt DID NOT WORK."
fi

# https://unix.stackexchange.com/questions/79310/expect-script-within-bash-exit-codes
# case "$?" in
#     0) echo "Password successfully changed on $host by $user" ;;
#     1) echo "Failure, password unchanged" ;;
#     2) echo "Failure, new and old passwords are too similar" ;;
#     3) echo "Failure, password must be longer" ;;
#     *) echo "Password failed to change on $host" ;;
# esac

# At this point: MySQL is installed b/c I can see the temporary password.
# NOW: Use temporary password for root to run the mysql_secure_installation
# program to change the root password.

# -f means to use a file & - means to use standard input as the file
# -c flag prefaces a command to be executed before any in the script
# Use HERE document vs. as a straight multiline string - to avoid quoting issues
# SECURE_MYSQL=$(expect -f '-'  <<HERE
# set timeout 10
# spawn mysql_secure_installation # sudo mysql_secure_installation -y
#
# expect "Enter password for user root:"
# send "${MYSQL_TEMP_PWD}\r"
#
# expect "Change the password for root ? \(Press y|Y for Yes, any other key for No) :"
# send "y\r"
#
# expect "New password:"
# send "${MYSQL_ROOT_PWD}\r"
#
# expect "Re-enter new password:"
# send "${MYSQL_ROOT_PWD}\r"
#
# expect "Do you wish to continue with the password provided?\(Press y|Y for Yes, any other key for No) :"
# send "y\r"
#
# expect "Remove anonymous users? \(Press y|Y for Yes, any other key for No) :"
# send "y\r"
#
# expect "Disallow root login remotely? \(Press y|Y for Yes, any other key for No) :"
# send "y\r"
#
# expect "Remove test database and access to it? \(Press y|Y for Yes, any other key for No) :"
# send "y\r"
#
# expect "Reload privilege tables now? \(Press y|Y for Yes, any other key for No) :"
# send "y\r"
# expect eof
# HERE
# )
# echo "$SECURE_MYSQL"

# -- Run MySQL --
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
