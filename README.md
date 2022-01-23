# Prepare Vagrant CentOS 7 VM to run Create Jazz Lyric Python Flask web app

**Note: Created CentOS 7 machine locally with Vagrant**

## On Your Computer

1. In the directory for the VM/virtual machine, where you have the Vagrantfile, start the VM & run SSH with these commands:

  ```
  vagrant up
  vagrant ssh
  ```

2. In a second terminal, go to the same directory and create a copy of the Vagrant ssh configuration file with: `vagrant ssh-config > vagrant-ssh-config`

3. Also in the second terminal, in the same directory, copy the required files to the VM, that set up the machine and are the app: `bash copy_req_files_to_vm.sh`

## In a Shell on the VM/Virtual Machine/Deployment Machine

1. **IMPORTANT**: You MUST create `mysql_pw.txt` on the VM before you run the next 2 Bash scripts. Create `mysql_pw.txt` at the the root directory, i.e., at the same level as the Bash setup scripts, `bash setup_machine.sh` and `bash setup_mysql.sh`. In `mysql_pw.txt`, put in a login password for the root user for MySQL on this VM.

2. From the root directory, set up MySQL with run: `bash setup_mysql.sh`

3. Verify MySQL has been installed & there are no error messages.

4. From the root directory, set up the machine wit run: `bash setup_machine.sh`

5. Verify versions shown in the Terminal output are correct. Also in the output, you should see: `✔ Successfully created virtual environment!`

6. Change into the subdirectory, `pythonapp-createjazzlyric` if you are not there, e.g., `cd /home/vagrant/pythonapp-createjazzlyric`

7. From there, run the app with: `pipenv run flask run`

## In a Browser Tab

1. The ports were forwarded in the `Vagrantfile` to port `8084`, so check that the app is running at: <http://localhost:8084/>
