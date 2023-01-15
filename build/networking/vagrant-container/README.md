## Vagrant login

Connec to vagrant box via ssh.
```
[root@mmachine vagrant-container]# vagrant ssh
vagrant@ubuntu2004:~$ sudo su
```

### Run IPDK container in Vagrant box

IPDK repository on host machine is mounted to `/git/` directory on the vagrant.
Either use this mounted repository or clone a fresh IPDK repository on any
directory.

```
root@ubuntu2004:~# cd /git/
root@ubuntu2004:~# cd ipdk/build/
```

Follow instructions from [IPDK Container] (https://github.com/ipdk-io/ipdk/blob/main/build/networking/README_DOCKER.md) to build and start an IPDK container.
