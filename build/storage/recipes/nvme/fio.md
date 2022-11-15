# Fio recipe

This recipe describes how to run fio from a host to an ideal target
with IPDK containers.

For this recipe, two physical machines are required.
They are referred to as `storage-target-platform` and `ipu-storage-container-platform`.
The containers running on those platforms are named `storage-target` and
`ipu-storage-container` respectively.

To apply this scenario the following steps need to be applied:

1. Perform all steps described in [environment setup](../environment_setup.md)


2. Run [hot-plug scenario](hot-plug.md) until an NVMe device with attached
namespace exists in the vm(step 7)


3. Run fio. Execute the following command from `cmd-sender`
```
$ echo -e $(no_grpc_proxy="" grpc_cli call <host_ip_where_vm_is_run>:50051 \
        RunFio "diskToExercise: { deviceHandle: '$nvme0' volumeId: '$malloc0'} \
        fioArgs: '{\"rw\":\"randrw\",\"runtime\":5, \"numjobs\": 1, \
            \"time_based\": 1, \"group_reporting\": 1 }'")
```

Expected output
```
connecting to 192.168.53.76:50051
Rpc succeeded with OK status
fioOutput: "job (/dev/nvme0n1): (g=0): rw=randrw, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=libaio, iodepth=256
...
fio-3.29
Starting 4 processes

job (/dev/nvme0n1): (groupid=0, jobs=4): err= 0: pid=32: Thu Sep 22 11:04:43 2022
 read: IOPS=21.4k, BW=83.4MiB/s (87.5MB/s)(84.5MiB/1013msec)
 slat (nsec): min=1127, max=12230k, avg=84547.05, stdev=780058.77
 clat (usec): min=2030, max=51525, avg=23478.74, stdev=6644.60
 lat (usec): min=2033, max=54303, avg=23563.48, stdev=6663.49
 clat percentiles (usec):
 | 1.00th=[ 9896], 5.00th=[11600], 10.00th=[14615], 20.00th=[19530],
 | 30.00th=[20579], 40.00th=[21365], 50.00th=[22414], 60.00th=[23987],
 | 70.00th=[27132], 80.00th=[28967], 90.00th=[31327], 95.00th=[33162],
 | 99.00th=[43254], 99.50th=[44303], 99.90th=[51643], 99.95th=[51643],
 | 99.99th=[51643]
 bw ( KiB/s): min=82292, max=86664, per=98.90%, avg=84478.00, stdev=676.63, samples=8
 iops : min=20572, max=21666, avg=21119.00, stdev=169.35, samples=8
 write: IOPS=21.7k, BW=84.9MiB/s (89.0MB/s)(86.0MiB/1013msec); 0 zone resets
 slat (nsec): min=1171, max=11961k, avg=96010.15, stdev=829836.22
 clat (usec): min=2029, max=51522, avg=23360.47, stdev=6611.01
 lat (usec): min=2030, max=51524, avg=23456.69, stdev=6637.58
 clat percentiles (usec):
 | 1.00th=[ 9765], 5.00th=[11469], 10.00th=[14615], 20.00th=[19530],
 | 30.00th=[20579], 40.00th=[21365], 50.00th=[22414], 60.00th=[23725],
 | 70.00th=[26608], 80.00th=[28967], 90.00th=[31065], 95.00th=[32637],
 | 99.00th=[43779], 99.50th=[44303], 99.90th=[51643], 99.95th=[51643],
 | 99.99th=[51643]
 bw ( KiB/s): min=84605, max=87531, per=99.01%, avg=86068.00, stdev=466.93, samples=8
 iops : min=21151, max=21882, avg=21516.50, stdev=116.72, samples=8
 lat (msec) : 4=0.05%, 10=1.05%, 20=22.94%, 50=75.79%, 100=0.16%
 cpu : usr=1.78%, sys=2.74%, ctx=736, majf=0, minf=53
 IO depths : 1=0.1%, 2=0.1%, 4=0.1%, 8=0.1%, 16=0.1%, 32=0.3%, >=64=99.4%
 submit : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
 complete : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.1%
 issued rwts: total=21632,22014,0,0 short=0,0,0,0 dropped=0,0,0,0
 latency : target=0, window=0, percentile=100.00%, depth=256

Run status group 0 (all jobs):
 READ: bw=83.4MiB/s (87.5MB/s), 83.4MiB/s-83.4MiB/s (87.5MB/s-87.5MB/s), io=84.5MiB (88.6MB), run=1013-1013msec
 WRITE: bw=84.9MiB/s (89.0MB/s), 84.9MiB/s-84.9MiB/s (89.0MB/s-89.0MB/s), io=86.0MiB (90.2MB), run=1013-1013msec

Disk stats (read/write):
 nvme0n1: ios=19160/19467, merge=0/0, ticks=199017/202255, in_queue=401271, util=95.89%

```

To exercise all volumes attached to a device, just leave `volumeId` argument in a command.
```
$ echo -e $(no_grpc_proxy="" grpc_cli call <host_ip_where_vm_is_run>:50051 \
        RunFio "diskToExercise: { deviceHandle: '$nvme0' } \
        fioArgs: '{\"rw\":\"randrw\",\"runtime\":10, \
            \"time_based\": 1, \"iodepth\": 32, \
            \"direct\": 1, \"ioengine\": \"libaio\" }'")
```
Expected output with 2 attached volumes
```
fioOutput: "job (/dev/nvme0n1): (g=0): rw=randread, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=libaio, iodepth=32
job (/dev/nvme0n2): (g=0): rw=randread, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=libaio, iodepth=32
fio-3.29
Starting 2 processes

job (/dev/nvme0n1): (groupid=0, jobs=1): err= 0: pid=39: Mon Nov 7 15:57:14 2022
 read: IOPS=6724, BW=26.3MiB/s (27.5MB/s)(263MiB/10013msec)
 slat (nsec): min=872, max=97402, avg=3454.77, stdev=2310.89
 clat (usec): min=521, max=21986, avg=4753.67, stdev=3945.17
 lat (usec): min=534, max=21992, avg=4757.32, stdev=3945.05
 clat percentiles (usec):
 | 1.00th=[ 2409], 5.00th=[ 2606], 10.00th=[ 2671], 20.00th=[ 2737],
 | 30.00th=[ 2769], 40.00th=[ 2802], 50.00th=[ 2802], 60.00th=[ 2868],
 | 70.00th=[ 2900], 80.00th=[ 3752], 90.00th=[12649], 95.00th=[12780],
 | 99.00th=[13435], 99.50th=[13829], 99.90th=[15795], 99.95th=[16909],
 | 99.99th=[21890]
 bw ( KiB/s): min=26384, max=27464, per=50.04%, avg=26918.80, stdev=269.95, samples=20
 iops : min= 6596, max= 6866, avg=6729.70, stdev=67.49, samples=20
 lat (usec) : 750=0.01%
 lat (msec) : 2=0.05%, 4=79.98%, 10=0.49%, 20=19.43%, 50=0.05%
 cpu : usr=1.85%, sys=3.61%, ctx=57010, majf=0, minf=43
 IO depths : 1=0.1%, 2=0.1%, 4=0.1%, 8=0.1%, 16=0.1%, 32=100.0%, >=64=0.0%
 submit : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
 complete : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.1%, 64=0.0%, >=64=0.0%
 issued rwts: total=67329,0,0,0 short=0,0,0,0 dropped=0,0,0,0
 latency : target=0, window=0, percentile=100.00%, depth=32
job (/dev/nvme0n2): (groupid=0, jobs=1): err= 0: pid=40: Mon Nov 7 15:57:14 2022
 read: IOPS=6724, BW=26.3MiB/s (27.5MB/s)(263MiB/10013msec)
 slat (nsec): min=865, max=60886, avg=3487.73, stdev=2166.24
 clat (usec): min=938, max=22036, avg=4753.05, stdev=3944.38
 lat (usec): min=954, max=22041, avg=4756.72, stdev=3944.26
 clat percentiles (usec):
 | 1.00th=[ 2409], 5.00th=[ 2606], 10.00th=[ 2704], 20.00th=[ 2737],
 | 30.00th=[ 2769], 40.00th=[ 2802], 50.00th=[ 2802], 60.00th=[ 2868],
 | 70.00th=[ 2900], 80.00th=[ 3916], 90.00th=[12649], 95.00th=[12780],
 | 99.00th=[13435], 99.50th=[13698], 99.90th=[15795], 99.95th=[16909],
 | 99.99th=[21890]
 bw ( KiB/s): min=26248, max=27328, per=50.05%, avg=26924.25, stdev=306.98, samples=20
 iops : min= 6562, max= 6832, avg=6731.05, stdev=76.76, samples=20
 lat (usec) : 1000=0.01%
 lat (msec) : 2=0.12%, 4=79.88%, 10=0.52%, 20=19.42%, 50=0.05%
 cpu : usr=1.50%, sys=3.96%, ctx=56755, majf=0, minf=43
 IO depths : 1=0.1%, 2=0.1%, 4=0.1%, 8=0.1%, 16=0.1%, 32=100.0%, >=64=0.0%
 submit : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
 complete : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.1%, 64=0.0%, >=64=0.0%
 issued rwts: total=67336,0,0,0 short=0,0,0,0 dropped=0,0,0,0
 latency : target=0, window=0, percentile=100.00%, depth=32

Run status group 0 (all jobs):
 READ: bw=52.5MiB/s (55.1MB/s), 26.3MiB/s-26.3MiB/s (27.5MB/s-27.5MB/s), io=526MiB (552MB), run=10013-10013msec

Disk stats (read/write):
 nvme0n1: ios=66595/0, merge=0/0, ticks=315688/0, in_queue=315688, util=99.06%
 nvme0n2: ios=66597/0, merge=0/0, ticks=315684/0, in_queue=315683, util=99.06%
"
```