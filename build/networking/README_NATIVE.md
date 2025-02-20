# Native Install

This method is supported for either installing and using IPDK in a VM or on a
host natively. infrap4d will run natively on the host or inside of a VM, which
is different from the containerized version of IPDK, which runs infrap4d as a
container.

## Steps To Install

Install a supported OS on a physical machine or VM with:

+ x86_64 processor architecture
+ With 4 CPU cores, at least 8 GB of RAM.  Systems with more CPU cores
  may require more RAM due to more compilation commands being run in
  parallel.
+ At least 7 GB of free disk space.  The install should finish using
  only about 5 GB more than before the install begins, but it
  temporarily uses more disk space during the installation.

### Clone the repository

```bash
root@linux:~# cd <CLONE-PATH>
root@linux:~# git clone https://github.com/ipdk-io/ipdk.git
```

### Run the install script to install all dependencies and build components

*NOTE*: This takes a long time, You also need to run these as root.

Without a proxy:

```bash
root@linux:~# <CLONE-PATH>/ipdk/build/networking/scripts/host_install.sh -d <CLONE-PATH>
```

*Note*: Output of this command copies necessary files to `/root/` by
default.

If using a proxy:

```bash
root@linux:~# <CLONE-PATH>/ipdk/build/networking/scripts/host_install.sh -d <CLONE-PATH> -p [proxy name]
```

*Note*: Output of this command copies necessary files to `/root/` by
default.

If user wants to copy necessary dependent files to a specific location, use `--workdir` option.

```bash
root@linux:~# <CLONE-PATH>/ipdk/build/networking/scripts/host_install.sh -d <CLONE-PATH> --workdir=/root/<my_own_dir>
```
To skip installing and building dependencies in the future, add a `-s`
flag to the host_install.sh script.

## Run P4 use case, either via VHOST ports or TAP ports

### 1.1 Run the rundemo_TAP_IO.sh script

If `host_install.sh` is executed with default source directory.

```bash
root@linux:~# /<CLONE-PATH>/ipdk/build/networking/scripts/rundemo_TAP_IO.sh
```

If `host_install.sh` is executed with `--workdir` option.

```bash
root@linux:~# /<CLONE-PATH>/ipdk/build/networking/scripts/rundemo_TAP_IO.sh --workdir=/root/<my_own_dir>
```

*Note*: rundemo_TAP_IO.sh does start infrap4d, create TAP ports, set the
pipeline, configure rules and then validates traffic between TAP ports.

### 1.2 Run the rundemo.sh script

If `host_install.sh` is executed with default source directory.

```bash
root@linux:~# /<CLONE-PATH>/ipdk/build/networking/scripts/rundemo.sh
```

If `host_install.sh` is executed with `--workdir` option.

```bash
root@linux:~# /<CLONE-PATH>/ipdk/build/networking/scripts/rundemo.sh --workdir=/root/<my_own_dir>
```

Verify infrap4d is running:

```bash
root@linux:~# ps -ef | grep infrap4d
```

### Connect to the guest VMs serial consoles

You will need two login windows, one for each VM:

```bash
root@linux:~# telnet localhost 6551
```

And in another window:

```bash
root@linux:~# telnet localhost 6552
```

### Verify guest is finished booting

It may take 6-9 minutes for both guest VMs to finish booting. You can
watch each VM boot over the serial console.

```bash
[  307.519991] cloud-init[1249]: Cloud-init v. 21.4-0ubuntu1~20.04.1 running 'modules:config' at Thu, 06 Jan 2022 15:27:13 +0000. Up 297.85 seconds.
[  OK  ] Finished Apply the settings specified in cloud-config.
         Starting Execute cloud user/final scripts...
ci-info: no authorized SSH keys fingerprints found for user ubuntu.
<14>Jan  6 15:27:31 cloud-init: #############################################################
<14>Jan  6 15:27:31 cloud-init: -----BEGIN SSH HOST KEY FINGERPRINTS-----
<14>Jan  6 15:27:31 cloud-init: 1024 SHA256:XtiIx3+4O9dXfAapcvgVy9bTY0AadTx67JgIirP8fDU root@vm1 (DSA)
<14>Jan  6 15:27:31 cloud-init: 256 SHA256:8KKnft4X6/5ANZjy4c9Pf8nLPghM25r2h7KQCcmMWJQ root@vm1 (ECDSA)
<14>Jan  6 15:27:31 cloud-init: 256 SHA256:BOyEUuM4iXqSIlaoCcp+wOsLB3w+ZBZLPxxNdEY7WkQ root@vm1 (ED25519)
<14>Jan  6 15:27:32 cloud-init: 3072 SHA256:GYvOtfpGNz7ILw0XZPkKOVZZZ/rRmafsDE1vcq5vptA root@vm1 (RSA)
<14>Jan  6 15:27:32 cloud-init: -----END SSH HOST KEY FINGERPRINTS-----
<14>Jan  6 15:27:32 cloud-init: #############################################################
-----BEGIN SSH HOST KEY KEYS-----
ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBHN14OCnYTeMh09qRzmWhtXsCgMOQu5S4WLksyBkQsNFil50MPdN8EoE0hh4dw70UzctiMXmQW/vStGeeyLv7OA= root@vm1
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHtOReNwl7HPAz5EUR/6mRdACoNszPBcSS9tCUeot7CE root@vm1
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC4yha3xcGv+ISubnNDJvnunNXR1RgG2wCUzBz8Cry7DABZ3ykBsAl86y7tmbKa8/OcOl/rwMEQw9UzNU4zFxbB+m8V7hyEcIqdIMrkjwWg2rLZP9LIN+ia7xIm0SjRjH7D4TuGdGp31
-----END SSH HOST KEY KEYS-----
[  317.197933] cloud-init[1278]: Cloud-init v. 21.4-0ubuntu1~20.04.1 running 'modules:final' at Thu, 06 Jan 2022 15:27:29 +0000. Up 313.74 seconds.
[  317.254438] cloud-init[1278]: ci-info: no authorized SSH keys fingerprints found for user ubuntu.
[  317.296920] cloud-init[1278]: Cloud-init v. 21.4-0ubuntu1~20.04.1 finished at Thu, 06 Jan 2022 15:27:32 +0000. Datasource DataSourceNoCloud [seed=/dev/vda][dsmode=net].  Up s
[  OK  ] Finished Execute cloud user/final scripts.
[  OK  ] Reached target Cloud-init target.
```

*NOTE*: If VM's are not up even after waiting for 6-9 minutes, check if
hugepages are mounted to `/mnt/huge`.
  Example: Command to mount huge pages is `mount -t hugetlbfs nodev /mnt/huge`

### Ping across VMs

Once you reach the following, you can login as the user `ubuntu` with the
defined password `IPDK`. Then you can ping from vm1 to vm2, and P4-OVS will
be used for networking traffic:

```bash
root@linux:~# telnet localhost 6551
ubuntu@vm1:~$ ping -c 5 2.2.2.2
PING 2.2.2.2 (2.2.2.2) 56(84) bytes of data.
64 bytes from 2.2.2.2: icmp_seq=1 ttl=64 time=0.317 ms
64 bytes from 2.2.2.2: icmp_seq=2 ttl=64 time=0.309 ms
64 bytes from 2.2.2.2: icmp_seq=3 ttl=64 time=0.779 ms
64 bytes from 2.2.2.2: icmp_seq=4 ttl=64 time=0.317 ms
64 bytes from 2.2.2.2: icmp_seq=5 ttl=64 time=0.310 ms

--- 2.2.2.2 ping statistics ---
5 packets transmitted, 5 received, 0% packet loss, time 4011ms
rtt min/avg/max/mdev = 0.309/0.406/0.779/0.186 ms
ubuntu@vm1:~$
```
