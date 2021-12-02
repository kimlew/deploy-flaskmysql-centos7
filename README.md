# Prepare Vagrant CentOS 7 VM to run Create Jazz Lyric Python web app

**Note: Created CentOS 7 machine locally with Vagrant**

1. IMPORTANT: This script assumes mysql_pw.txt already exists.<br>
  Make sure you created mysql_pw.txt outside of this script & put in the password you want for root for login into MySQL on this VM.

2. Create an ssh configuration file, e.g.,<br>
  `vagrant ssh-config > vagrant-ssh-config`

3. Copy `setup_machine.sh` & `setup_mysql.sh` with `scp` to the virtual machine/deployment machine, e.g.,<br>
  `scp -F vagrant-ssh-config setup_machine.sh vagrant@default:setup_machine.sh`<br>
  `scp -F vagrant-ssh-config setup_mysql.sh vagrant@default:setup_mysql.sh`

4. Start the VM/virtual machine & run SSH with these commands:<br>

  ```
  vagrant up
  vagrant ssh
  ```

5. On the VM, run:<br>
  `bash -x setup_machine.sh`<br>

6. Verify versions shown in the Terminal output are correct on the virtual machine/deployment machine.<br>

7. On the VM, run:<br>
  `bash -x setup_mysql.sh`

8. Verify MySQL has been installed & there are no error messages.

9. On the VM, run: `flask run`

10. The ports were forwarded in the Vagrantfile, so check that the app is running in the browser at: <http://127.0.0.1:8080/>
