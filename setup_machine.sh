#! /bin/bash

# Note: This script assumes you already ran: vagrant up & vagrant ssh
# Important: Run setup_mysql.sh BEFORE running this script, setup_machine.sh.

# Script name: setup_machine.sh
# Description: This script sets up the server to run the Python Flask web app,
# create-jazz-lyric.
# Note: .flaskenv created near end of this script.
# Author: Kim Lew
# Currently: This shell script sets up a Vagrant VM CentOS 7 with required software.
# Later: Modify it to deploy the app onto AWS.

# Type: help set - to see meanings of these flags:
# -e  Exit immediately if a command exits with a non-zero status.
# -x  Print commands and their arguments as they are executed.

set -e

cd /home/vagrant
sudo yum update -y

# Check if nano already installed & install if not. "" or check exit code?
if ! command -v nano &> /dev/null; then
  sudo yum install nano -y
fi

# https://tecadmin.net/install-python-3-9-on-centos/
sudo yum install gcc openssl-devel bzip2-devel libffi-devel zlib-devel -y
# Check if wget already installed & install if not.
if ! command -v wget &> /dev/null; then
  sudo yum install wget -y
fi

# Check if Python aleady installed. If already there, skips next 7 lines.
if [[ "$(python3.9 --version)" != "Python 3.9.7" ]]; then
  echo "Getting and installing Python 3.9.7..."
  wget https://www.python.org/ftp/python/3.9.7/Python-3.9.7.tgz
  tar xzf Python-3.9.7.tgz
  cd Python-3.9.7
  sudo ./configure --enable-optimizations
  sudo make altinstall
  cd ..
  sudo rm Python-3.9.7.tgz*
fi
sudo yum install python3-pip -y
sudo pip3 install pipenv

echo
echo "YUM INSTALLED VERSIONS:"
python3.9 --version
pip3 --version
pipenv --version
sleep 5
echo

cd pythonapp-createjazzlyric
# python3.9 -m venv .venv
pipenv install
echo
echo "IN project folder & INSTALLING Python dependencies..."
echo

# FLASK_ENV - by default, is production, which doesn't do anything noticeable.
# development - see reloader starts working & your app is put into debug mode
# Default port for Flask here is 5000. So if I don't set to anything else, IS 5000.
# FLASK_RUN_PORT=8084
cat > .flaskenv <<EOF
  FLASK_APP=create_jazz_lyric
  FLASK_RUN_HOST=0.0.0.0
EOF

if [ ! -f '../mysql_pw.txt' ]; then
  echo
  echo "You must create mysql_pw.txt at the root level of the machine."
  exit 1
else
  {
    echo 'DB_HOST=localhost'
    echo 'DB_USER=root'
    echo "DB_PASSWORD=$(cat ../mysql_pw.txt)"
    echo 'DB_NAME=lyric_db'
  } > .env
fi
# At this point, when this script is done which is run by vagrant ssh, you are
# back on your Mac/local machine.
