# Prep Vagrant CentOS 7 VM & deploy on VM to run Create Jazz Lyric app on web

**Note: Created CentOS 7 machine locally with Vagrant**

1. Copy `setup_machine.sh` with `scp` to the virtual machine/deployment machine, e.g.,<br>
  `scp -F vagrant-ssh-config setup_machine.sh vagrant@default:setup_machine.sh`

2. Create an ssh configuration file, e.g.,<br>
  `vagrant ssh-config > vagrant-ssh-config`

3. Make sure you created mysql_pw.txt outside of this script & put in the password you want for root for login to MySQL. This script assumes mysql_pw.txt already exists.

4. Run these commands to start the VM/virtual machine & run SSH:<br>

  ```
  vagrant up
  vagrant ssh
  ```

5. On the VM, run: `bash -x setup_machine.sh`

6. Verify versions shown in the Terminal output are correct on the virtual machine/deployment machine.

7. On the VM, run: `flask run`

8. The ports were forwarded in the Vagrantfile, so check that the app is running in the browser at: <http://127.0.0.1:8080/>
