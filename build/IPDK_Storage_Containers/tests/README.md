# Dependencies
## Fedora
1. wget
```
$ sudo dnf install wget
```
2. docker
```
$ sudo dnf install docker
```
4. docker compose
```
$ sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
$ sudo chmod +x /usr/local/bin/docker-compose
$ sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
```
3. libguestfs-tools-c
```
$ sudo dnf install libguestfs-tools-c
```
# How to run
In order to run all possible tests
```
$ ./run.sh
```
To pass proxy
```
$ https_proxy=<https_proxy> \
http_proxy=<http_proxy> \
no_proxy=<no_proxy> \
./run.sh
```
To run a specific test
```
$ ./run.sh <name_of_test>
```
for example
```
$ ./run.sh hot-plug
$ # or
$ ./run.sh fio
```
Script returns a non-zero value in case of error and for example it can be
`echo`ed by the following command
```
$ ./run
$ echo $?
```

Also `run.sh` will download a `Fedora 33` image into `traffic-generator`
directory and setup login-password pair as root-root if there is no `vm.qcow2`
image provided in the directory. `run.sh` will also try to allocate 2048 2MB
hugepages if not yet allocated and it will request administrative privileges
to execute the operation.
