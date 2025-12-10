#!/bin/bash

set -e

sudo apt-get install -y llvm-19 clang-19 lld-19 bison flex bc

version=6.17.11

wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-$version.tar.xz

tar xvf linux-$version.tar.xz

mv linux-$version build

cd build

wget https://android.googlesource.com/kernel/common/+archive/refs/tags/android-15.0.0_r0.81/arch/arm64/configs.tar.gz
tar xvf configs.tar.gz microdroid_defconfig
cp microdroid_defconfig .config

./scripts/config --set-str SERIAL_8250_RUNTIME_UARTS 4 \
-e CGROUPS \
-e CGROUP_CPUACCT \
-e CGROUP_DEBUG \
-e CGROUP_DEVICE \
-e CGROUP_DMEM \
-e CGROUP_FAVOR_DYNMODS \
-e CGROUP_FREEZER \
-e CGROUP_MISC \
-e CGROUP_PERF \
-e CGROUP_PIDS \
-e CGROUP_RDMA \
-e CGROUP_SCHED \
-e CGROUP_WRITEBACK \
-e DEVTMPFS \
-e VIRTIO_NET \
-e NETDEVICES

echo | make LLVM=-19 ARCH=arm64 -j$(nproc) Image

