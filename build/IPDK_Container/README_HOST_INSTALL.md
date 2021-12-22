# Host Install

This method is supportd for either installing and using IPDK in a VM or on a
host natively. This is in support of being able to run containers attached to
the OVS-P4 switch.

## Steps To Install

### Bringup the Vagrant VM:
```
$ cd vagrant
$ vagrant up
```

###Login to the VM
```
$ vagrant ssh
Welcome to Ubuntu 20.04 LTS (GNU/Linux 5.4.0-31-generic x86_64)

                  ubuntu-20.04-amd64-docker (virtualbox)
                 _____ _____ _____ _____ _____ _____ _____
                |  |  |  _  |   __| __  |  _  |   | |_   _|
                |  |  |     |  |  |    -|     | | | | | |
                 \___/|__|__|_____|__|__|__|__|_|___| |_|
                       Sat May 23 14:38:33 UTC 2020
                            Box version: 0.1.1

  System information as of Wed 22 Dec 2021 05:47:40 PM UTC

  System load:  1.08               Processes:                141
  Usage of /:   12.1% of 38.65GB   Users logged in:          0
  Memory usage: 3%                 IPv4 address for docker0: 172.17.0.1
  Swap usage:   0%                 IPv4 address for eth0:    10.0.2.15

vagrant@ubuntu2004:~$
```

### Run the install script to install all dependencies and build components.

*NOTE*: This takes a long time, You also need to run these as root.

Without a proxy:

```
vagrant@ubuntu2004:~$ sudo su
root@ubuntu2004:~# /git/ipdk/scripts/host_install.sh
```

If using a proxy:

```
vagrant@ubuntu2004:~$ sudo su -
root@ubuntu2004:~# /git/ipdk/scripts/host_install.sh -p [proxy name]
```

Note: To skip installing and building dependencies in the future, add a `-s`
flag tot he host_install.sh script.

### Start P4-OVS.

```
root@ubuntu2004:~$ cd P4-OVS/
root@ubuntu2004:~/P4-OVS# source /root/P4-OVS/p4ovs_env_setup.sh /root/p4-sde/install
root@ubuntu2004:~/P4-OVS# /root/scripts/set_hugepages.sh
root@ubuntu2004:~/P4-OVS# /root/scripts/run_ovs.sh
```

5. Verify OVS is running:

```
root@ubuntu2004:~/P4-OVS# ovs-vsctl show
bc71e3b7-45a7-4bc8-9706-88dab5002526
root@ubuntu2004:~/P4-OVS#
```

### Next steps: Create some containers, create some OVS ports, build some P4 pipelines.
