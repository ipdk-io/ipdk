# Fio recipe

This recipe describes how to run fio from Host to an ideal target
with IPDK containers.

For this recipe 2 machines required.
They are referred as `storage-target-platform` and `proxy-container-platform`.
The containers running on those platforms are named `storage-target` and
`proxy-container` respectively.

To apply this scenario the following steps need to be applied:

1. Perform all steps described in [environment setup](environment_setup.md)

2. Run [hot-plug scenario](hot-plug.md) until a virtio-blk device is attached to
the vm(step 5)

3. Run fio. Execute the following command from `cmd-sender`
```
$ echo -e $(no_grpc_proxy= grpc_cli call <vm_ip>:50051 \
RunFio "pciAddress: '0000:01:00.0' fioArgs: '--direct=1 --rw=randrw --bs=4k --ioengine=libaio --iodepth=256 --runtime=1 --numjobs=4 --time_based --group_reporting --name=iops-test-job'")
```

Expected output
```
connecting to 192.168.53.76:50051
Rpc succeeded with OK status
fioOutput: "iops-test-job: (g=0): rw=randrw, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=libaio, iodepth=256
...
fio-3.29
Starting 4 processes

iops-test-job: (groupid=0, jobs=4): err= 0: pid=58: Tue May 31 15:43:41 2022
 read: IOPS=20.9k, BW=81.8MiB/s (85.8MB/s)(82.2MiB/1005msec)
 slat (nsec): min=789, max=12745k, avg=93034.77, stdev=440827.15
 clat (usec): min=2708, max=81274, avg=23768.74, stdev=7565.45
 lat (usec): min=3141, max=81276, avg=23861.91, stdev=7588.09
 clat percentiles (usec):
 | 1.00th=[ 8029], 5.00th=[12256], 10.00th=[14615], 20.00th=[18220],
 | 30.00th=[21103], 40.00th=[22676], 50.00th=[23987], 60.00th=[25035],
 | 70.00th=[26346], 80.00th=[28443], 90.00th=[31065], 95.00th=[33424],
 | 99.00th=[48497], 99.50th=[69731], 99.90th=[74974], 99.95th=[77071],
 | 99.99th=[78119]
 bw ( KiB/s): min=77869, max=86361, per=98.04%, avg=82115.00, stdev=1475.70, samples=8
 iops : min=19467, max=21590, avg=20528.50, stdev=368.94, samples=8
 write: IOPS=21.4k, BW=83.5MiB/s (87.5MB/s)(83.9MiB/1005msec); 0 zone resets
 slat (nsec): min=853, max=8977.0k, avg=93356.96, stdev=445000.49
 clat (usec): min=2546, max=81274, avg=23808.95, stdev=7555.22
 lat (usec): min=3204, max=81275, avg=23902.42, stdev=7572.43
 clat percentiles (usec):
 | 1.00th=[ 7898], 5.00th=[12387], 10.00th=[14615], 20.00th=[18220],
 | 30.00th=[21365], 40.00th=[22676], 50.00th=[23987], 60.00th=[25035],
 | 70.00th=[26346], 80.00th=[28705], 90.00th=[31327], 95.00th=[33424],
 | 99.00th=[49546], 99.50th=[68682], 99.90th=[74974], 99.95th=[76022],
 | 99.99th=[81265]
 bw ( KiB/s): min=78782, max=88923, per=98.09%, avg=83852.50, stdev=1623.16, samples=8
 iops : min=19695, max=22230, avg=20962.50, stdev=405.79, samples=8
 lat (msec) : 4=0.17%, 10=2.25%, 20=22.98%, 50=73.63%, 100=0.96%
 cpu : usr=0.80%, sys=1.57%, ctx=4785, majf=0, minf=59
 IO depths : 1=0.1%, 2=0.1%, 4=0.1%, 8=0.1%, 16=0.2%, 32=0.3%, >=64=99.4%
 submit : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
 complete : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.1%
 issued rwts: total=21043,21479,0,0 short=0,0,0,0 dropped=0,0,0,0
 latency : target=0, window=0, percentile=100.00%, depth=256

Run status group 0 (all jobs):
 READ: bw=81.8MiB/s (85.8MB/s), 81.8MiB/s-81.8MiB/s (85.8MB/s-85.8MB/s), io=82.2MiB (86.2MB), run=1005-1005msec
 WRITE: bw=83.5MiB/s (87.5MB/s), 83.5MiB/s-83.5MiB/s (87.5MB/s-87.5MB/s), io=83.9MiB (88.0MB), run=1005-1005msec

Disk stats (read/write):
 vda: ios=18762/19163, merge=0/0, ticks=70841/72050, in_queue=142891, util=93.09%
"

```
