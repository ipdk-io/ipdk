# Fio recipe

This recipe describes how to run fio from Host to an ideal target
with IPDK containers.

For this recipe 2 machines required. They are referred as `storage-target`
and `proxy-container`.

To apply this scenario the following steps need to be applied:

1. Perform all steps described in [environment setup](environment_setup.md)

2. Run [hot-plug scenario](hot-plug.md) until a virtio-blk device is attached to
the vm(step 5)

3. Run fio. Execute the following command from `proxy-container` platform
```
$ no_grpc_proxy= grpc_cli call <vm_ip>:50051 \
RunFio "pciAddress: '0000:00:04.0' fioArgs: '--direct=1 --rw=randrw --bs=4k --ioengine=libaio --iodepth=256 --runtime=1 --numjobs=4 --time_based --group_reporting --name=iops-test-job'"
```

Expected output
```
connecting to 192.168.53.76:50051
fioOutput: "iops-test-job: (g=0): rw=randrw, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=libaio, iodepth=256\n...\nfio-3.21\nStarting 4 processes\n\niops-test-job: (groupid=0, jobs=4): err= 0: pid=18: Fri Feb 25 07:18:16 2022\n  read: IOPS=18.0k, BW=74.2MiB/s (77.8MB/s)(742MiB/10008msec)\n    slat (usec): min=2, max=11636, avg=102.74, stdev=479.43\n    clat (usec): min=6703, max=62683, avg=26796.45, stdev=9296.56\n     lat (usec): min=6707, max=62704, avg=26899.45, stdev=9327.52\n    clat percentiles (usec):\n     |  1.00th=[11469],  5.00th=[12125], 10.00th=[12780], 20.00th=[16909],\n     | 30.00th=[22938], 40.00th=[25035], 50.00th=[26870], 60.00th=[29492],\n     | 70.00th=[31851], 80.00th=[34866], 90.00th=[38536], 95.00th=[41681],\n     | 99.00th=[48497], 99.50th=[51643], 99.90th=[56886], 99.95th=[58459],\n     | 99.99th=[60556]\n   bw (  KiB/s): min=55800, max=100312, per=99.78%, avg=75797.47, stdev=2986.36, samples=76\n   iops        : min=13950, max=25078, avg=18949.37, stdev=746.59, samples=76\n  write: IOPS=18.0k, BW=74.1MiB/s (77.7MB/s)(742MiB/10008msec); 0 zone resets\n    slat (usec): min=2, max=9856, avg=103.06, stdev=476.92\n    clat (usec): min=5141, max=62700, avg=26812.92, stdev=9302.68\n     lat (usec): min=6695, max=62704, avg=26916.24, stdev=9334.34\n    clat percentiles (usec):\n     |  1.00th=[11469],  5.00th=[12125], 10.00th=[12780], 20.00th=[16909],\n     | 30.00th=[22938], 40.00th=[25035], 50.00th=[26870], 60.00th=[29492],\n     | 70.00th=[31851], 80.00th=[34866], 90.00th=[38536], 95.00th=[41681],\n     | 99.00th=[48497], 99.50th=[51643], 99.90th=[56361], 99.95th=[57934],\n     | 99.99th=[60031]\n   bw (  KiB/s): min=56728, max=100464, per=99.83%, avg=75788.21, stdev=2943.55, samples=76\n   iops        : min=14182, max=25116, avg=18947.05, stdev=735.89, samples=76\n  lat (msec)   : 10=0.06%, 20=24.99%, 50=74.23%, 100=0.72%\n  cpu          : usr=2.21%, sys=4.23%, ctx=41669, majf=0, minf=55\n  IO depths    : 1=0.1%, 2=0.1%, 4=0.1%, 8=0.1%, 16=0.1%, 32=0.1%, >=64=99.9%\n     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%\n     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.1%\n     issued rwts: total=190063,189952,0,0 short=0,0,0,0 dropped=0,0,0,0\n     latency   : target=0, window=0, percentile=100.00%, depth=256\n\nRun status group 0 (all jobs):\n   READ: bw=74.2MiB/s (77.8MB/s), 74.2MiB/s-74.2MiB/s (77.8MB/s-77.8MB/s), io=742MiB (778MB), run=10008-10008msec\n  WRITE: bw=74.1MiB/s (77.7MB/s), 74.1MiB/s-74.1MiB/s (77.7MB/s-77.7MB/s), io=742MiB (778MB), run=10008-10008msec\n\nDisk stats (read/write):\n  vda: ios=187480/187373, merge=0/0, ticks=1237509/1230145, in_queue=2467655, util=99.67%\n"
```
