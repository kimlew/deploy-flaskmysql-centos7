#! /bin/bash

# This shell script is to deploy on a Vagrant VM CentOS 7.
# Will modify to use later to deploy on AWS.

# help set to see these flags:
# -e  Exit immediately if a command exits with a non-zero status.
# -x  Print commands and their arguments as they are executed.

set -e

sudo yum update -y

# # https://tecadmin.net/install-python-3-9-on-centos/
sudo yum install gcc openssl-devel bzip2-devel libffi-devel zlib-devel -y
sudo yum install wget -y
wget https://www.python.org/ftp/python/3.9.7/Python-3.9.7.tgz
tar xzf Python-3.9.7.tgz
cd Python-3.9.7
sudo ./configure --enable-optimizations
sudo make altinstall
cd ..
sudo rm Python-3.9.7.tgz*

sudo yum install python3-pip -y
sudo pip3 install pipenv

# TODO: Run setup_mysql.sh to install MySQL.

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

cat > .flaskenv <<EOF
  FLASK_APP=create_jazz_lyric
  FLASK_RUN_HOST=0.0.0.0
EOF

pipenv shell
