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
echo -e $(no_grpc_proxy="" grpc_cli call <host_ip_where_vm_is_run>:50051 \
        RunFio "diskToExercise: { deviceHandle: '$nvme0' volumeId: '$malloc0'} \
        fioArgs: '{\"rw\":\"randrw\", \"direct\":1, \"bs\":\"4k\", \
        \"iodepth\":256, \"ioengine\":\"libaio\", \"runtime\":1, \
        \"name\":\"iops_test-job\", \"time_based\": 1, \"numjobs\": 4,  \
        \"group_reporting\": 1 }}'")
```

Expected output
```
connecting to 192.168.53.76:50051
Rpc succeeded with OK status
fioOutput: "iops-test-job: (g=0): rw=randrw, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=libaio, iodepth=256
...
fio-3.29
Starting 4 processes

iops_test-job: (groupid=0, jobs=4): err= 0: pid=32: Thu Sep 22 11:04:43 2022
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
