# Prepare Vagrant CentOS 7 VM to run Create Jazz Lyric Python Flask web app

**Note: Created CentOS 7 machine locally with Vagrant**

## On Your Computer

1. Create a copy of the Vagrant ssh configuration file, e.g., `vagrant ssh-config > vagrant-ssh-config`

2. Copy required files to the VM with: `copy_req_files_to_vm.sh`

3. Start the VM & run SSH with these commands:

  ```
  vagrant up
  vagrant ssh
  ```

## On the VM

1. **IMPORTANT**: This script assumes `mysql_pw.txt` already exists on the VM. If you haven't done this yet, create `mysql_pw.txt` at the same level as the Bash setup scripts, `bash setup_machine.sh` and `bash setup_mysql.sh`, and put in the root user's password to login into MySQL on this VM.

2. From the root directory, run: `bash setup_mysql.sh`

3. Verify MySQL has been installed & there are no error messages.

4. Change directories if you are not at the root directory, since you might still be in the subdirectory, pythonapp-createjazzlyric.

  ```
  cd ..
  ```

5. From the root directory, run: `bash setup_machine.sh`

6. Verify versions shown in the Terminal output are correct on the virtual machine/deployment machine. You should also see a Python environment shell, e.g., ``

## On the VM

1. You should be in the subdirectory, `pythonapp-createjazzlyric`. From there, run the app with:

`pipenv run flask run`

`python3 create_jazz_lyric.py` Use?: `pipenv install gunicorn & ???`

1. The ports were forwarded in the `Vagrantfile` to port `8084`, so on a browser, check that the app is running at: <http://localhost:8084/>

<http://127.0.0.1:8080/> OR <http://127.0.0.1:5000/> Problem: `This site can't be reached`
