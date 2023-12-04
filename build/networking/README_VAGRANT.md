# Vagrant Setup

To ease usage of the IPDK container, a Vagrant environment is provided
which will spinup an Ubuntu VM with Docker already installed, allowing for a
quick way to play with the containerized version of networking-recipe.

### Supported Vagrant + Virtualbox Setups

The Vagrant setup is currently only tested with Virtualbox running on MacOS. As
more uses test and report things working, this will be updated.

It's also not advised to run multiple hypervisors at the same time, as this can lead
to trouble with sharing the CPU's virtualization extensions.

## Steps To Install

Note this method is using Vagrant with Virtualbox. Make sure you have nested
virtualization enabled on your guest VM. There are many articles published on
how to do this, but [this](https://stackoverflow.com/questions/54251855/virtualbox-enable-nested-vtx-amd-v-greyed-out)
one is quite useful. If your machine is behind any proxies, update proxy
settings accordingly.


### Clone IPDK repository
```
$ git clone https://github.com/ipdk-io/ipdk.git
```

### Bringup either Vagrant native or Vagrant container VM:

#### Vagrant Native
```
$ cd ipdk/build/networking/vagrant-native
$ vagrant up
```

#### Vagrant Container
```
$ cd ipdk/build/networking/vagrant-container
$ vagrant up
```

*NOTE*: If you are behind proxies, update Vagrantfile with appropriate proxy
settings.

### Login to the VM

After successfully building a vagrant VM, login to vagrant VM through SSH.
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

*NOTE*: This takes a long time, You also need to run these as root.
IPDK repository in host machine will be mounted into vagrant VM at location
/git/

## Specific Build Instructions to run IPDK on vagrant VM

Please see the specific build instructions to run IPDK container or native on vagrant VM:

* [Vagrant Container](vagrant-container/README.md)
* [Vagrant Native](vagrant-native/README.md)
