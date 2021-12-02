#! /usr/bin/env bash

# This script helps install MySQL on a machine with CentOS 7.
# Assumes you already did: vagrant up & vagrant ssh

# Options to immediately exit:
# -e - the command that gives a non-zero status
# -o pipefail - the whole pipeline when 1st command has non-zero status code
set -eo pipefail

sudo yum update -y
sudo yum install nano -y
sudo yum install wget -y
sudo yum install expect -y

# Note: This script assumes mysql_pw.txt already exists.
# MAKE SURE you have already created mysql_pw.txt outside of this script & put
# in the password you want for root.
# Note: Put MYSQL_ROOT_PWD in a file vs. in an environment variable so it is
# on the filesystem & can be reused for other purposes. You can't reuse it if
# you do a diff way, e.g., you add a user prompt for password at start of script.

MYSQL_PW_FILE='mysql_pw.txt'
if [ -f "$MYSQL_PW_FILE" ]; then
  MYSQL_ROOT_PWD=$(cat "$MYSQL_PW_FILE")
else
  echo "${MYSQL_PW_FILE} doesn't exist. Create it and add root password."
  exit 1
fi
#=== FUNCTION ==================================================================
run_mysql_secure_installation() {
  # Temporary password is created with MySQL installation in /var/log/mysqld.log.
  # Assign to variable to use if mysql_secure_installation has NOT been run yet."
  # From /var/log/mysqld.log, look for phrase for root@localhost:<space>
  # & from there, get all characters up to new line character & save as
  # MYSQL_TEMP_PWD. Note: This is 13 chars in from 'temporary password'.
  # -- expect part --
  # -f flag means to use a file & to use standard input as the file
  # -c flag prefaces a command to be executed before any in the script
  # Use HERE document vs. as a straight multiline string - to avoid quoting issues
  echo
  echo "GETTING assigned root password from file..."
  MYSQL_ROOT_PWD=$(<${MYSQL_PW_FILE})
  echo "new root password: ${MYSQL_ROOT_PWD}"
  echo

expect -f '-' <<HERE
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
  "Change the password for root ? \(\(Press y|Y for Yes, any other key for No) :" {
    send "n\r"
  }
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

echo "RAN mysql_secure_installation & root password has been assigned for MySQL."
echo
}

#-------------------------------------------------------------------------------
# CHECKING for MySQL - GET, VERIFY & INSTALL MySQL package
#-------------------------------------------------------------------------------
if [ "$(sudo yum repolist enabled | grep "mysql.*-community.*")" != '' ] && command -v mysqld; then
  echo "MySQL package repos AND MySQL server are already installed."
  echo
else
  # MySQL is NOT installed Get, verify & install MySQL package.
  echo
  echo "MySQL is NOT installed yet. GETTING and VERIFYING MySQL mysql80-community-release-el7-4."

  # CHECK if MySQL package downloaded.
  # Create a new file with the extension .rpm.md5 with contents of the copied
  # MD5 from the approved site. With this file, perform an md5sum --check.
  # If successful, returns exit code 0. If NOT successful, give user error
  # message & returns exit code 1.
  if ! [ -f mysql80-community-release-el7-4.noarch.rpm ]; then
    wget https://dev.mysql.com/get/mysql80-community-release-el7-4.noarch.rpm
  fi

  if ! [ -f mysql80-community-release-el7-4.noarch.rpm.md5 ]; then
    echo "8b55d5fc443660fab90f9dc328a4d9ad mysql80-community-release-el7-4.noarch.rpm" > mysql80-community-release-el7-4.noarch.rpm.md5
  fi

  # CHECK if retrieved MySQL package file passes md5sum check.
  # CAN ALSO: Use GnuPG signatures to verify the integrity of downloaded packages.
  if ! md5sum --check mysql80-community-release-el7-4.noarch.rpm.md5; then
    # Not verifiable MySQL file. Show error here & exit from the script.
    echo "FAILED md5sum check for the MySQL file. Exiting the script."
    exit 1
  fi
  echo "GOT & VERIFIED MySQL package."

  # CHECK if you can successfully query mysql80-community-release package, i.e.,
  # 0 exit code - means package is already installed. BUT rpm command might FAIL.
  # So for a clean install, erase the package & then install it.
  # rpm -v means pattern was not found
  echo
  MYSQL_PKG="mysql80-community-release-el7-4.noarch.rpm"
  if rpm -q "${MYSQL_PKG%.noarch.rpm}"; then
    echo "Erasing previously installed MySQL package to ensure MySQL installation is clean."
    sudo rpm -e "${MYSQL_PKG%.noarch.rpm}"
  fi
  echo
  echo "NOW installing MySQL package & MySQL Server."
  sudo rpm -ivh "${MYSQL_PKG}"
  sudo yum install mysql-server -y
  echo "DONE installing MySQL package with MySQL client & tools. DONE installing MySQL server."
  echo
fi

# Must start mysqld.service to try running MySQL client.
sudo systemctl start mysqld.service
sudo systemctl status mysqld

#-------------------------------------------------------------------------------
# RUNNING mysql_secure_installation
#-------------------------------------------------------------------------------
# CHECK if mysql_secure_installation was already run & root password assigned.
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
fi

# CHECK ODD CASE: At this point, MySQL is installed, mysql_secure_installation
# has NOT been run, BUT mysqld.log file has lost temporary password. In this
# odd case, /var/log/mysqld.log ONLY starts at the current point & loses all of
# the past logged messages of actions.
# Note: Without the if, when this line is run and fails, you are exited from script.
# MYSQL_TEMP_PWD=$(sudo grep 'temporary password' /var/log/mysqld.log | awk '{print $13}')
echo
if ! MYSQL_TEMP_PWD=$(sudo grep 'temporary password' /var/log/mysqld.log | awk '{print $13}'); then
  echo
  echo "Error: The file, /var/log/mysqld.log which is installed with MySQL does"
  echo "not have the temporary password, even though MySQL package is installed."
  echo "You must manually run these 3 commands:"
  echo " sudo yum erase mysql"
  echo " sudo yum erase mysql-community-server"
  echo " sudo rm -rf /var/lib/mysql"
  echo "Then re-run this script."
  exit 1
fi

# CHECK if temporary password can be used to RUN MySQL.
# Note: Tested BAD result case with "boo" vs. send "${MYSQL_TEMP_PWD}\r"
# expect part - confirms that temporary password still works. Use temporary
# password for root to run the program, mysql_secure_installation & to change
# the root password - which the function, run_mysql_secure_installation does.
echo
echo "NO assigned ROOT password yet."
echo "CHECKING if temp root password ${MYSQL_TEMP_PWD} works with MySQL..."
echo
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
  echo "Temporary password exists so you have NOT run mysql_secure_installation yet."
  echo "RUNNING mysql_secure_installation program with temp root password..."
  echo
  run_mysql_secure_installation
fi

# TEST CASE 1: Manually uninstall MySQL client, db files,  MySQL server, &
# server-related files with these commands & re-run script. Use these 4 commands:
#  sudo yum erase mysql  # Removes the client.
#  sudo rm -rf /var/lib/mysql  # Deletes the database files.*
#  sudo yum erase mysql-community-server  # Deletes server config files.
#  sudo rm /var/log/mysqld.log  # Data directory related to mysqld/the server.

# *Note: Database files store ALL .passwords including the temp root one &
# assigned root one. After the the MySQL package installation, you can't log in
# to MySQL with the temp root password which is in the /var/log/mysqld.log file
# and also in the database b/c you don't have access to either. So this script
# Note: MySQL DOES put the temp password in the /var/log/mysqld.log BUT only
# when it detects there is NO assigned root password.

# TEST CASE 2: Destroy this CentOS 7 VM with: vagrant destroy.
# Then create a new VM with: vagrant up.
# Then scp this file again & re-run script on the clean VM.
