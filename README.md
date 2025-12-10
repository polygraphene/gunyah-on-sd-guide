# About

A guide to run protected VM with gunyah on a SD 8 elite device. The VM can host microdroid kernel or debian or any arm64 linux.

> [!NOTE]  
> For sd 8 gen 2 or gen 3 devices, you might need this guide: https://github.com/polygraphene/gunyah-on-sd-guide/blob/main/PVMFW.md

## Environment

1. Lenovo Legion Tablet Y700 gen4
2. Snapdragon 8 elite
3. Android 15
4. ZUXOS\_1.1.11.044\_250524\_PRC
5. Unlocked bootloader
6. root with APatch

It might work on other devices with gunyah hypervisor. I would appreciate it if you could leave a comment with the results if you try it.

## Instruction

### 1. Download prerequisites
Go to [releases v0.0.2](https://github.com/polygraphene/gunyah-on-sd-guide/releases/tag/v0.0.2) to download `crosvm-a16`, `libbinder_ndk.so` and `libbinder.so`.
Then put those files to the device.

```
adb push crosvm-a16 libbinder_ndk.so libbinder.so /data/local/tmp
adb shell chmod 755 /data/local/tmp/crosvm-a16
```

### 2. Execute crosvm
Open root shell on the device, then:
```
# cd /data/local/tmp
# ulimit -l unlimited
# LD_PRELOAD=./libbinder_ndk.so:./libbinder.so /data/local/tmp/crosvm-a16 --log-level debug run \
  --disable-sandbox --no-balloon --protected-vm-without-firmware --swiotlb 64 \
  --params '' -i /apex/com.android.virt/etc/microdroid_initrd_debuggable.img \
  --mem 4096 --cpus 4 \
  /apex/com.android.virt/etc/fs/microdroid_kernel
[2025-06-26T14:13:15.053037677+00:00 DEBUG crosvm::crosvm::sys::linux] creating hypervisor: Gunyah { device: Some("/dev/gunyah"), qcom_trusted_vm_id: None, qcom_trusted_vm_pas_id: None }
[    0.000000][    T0] Booting Linux on physical CPU 0x0000000000 [0x000f0480]
[    0.000000][    T0] Linux version 6.6.30-android15-5-g2485db222497-ab11868669 (kleaf@build-host) (Android (11368308, +pgo, +bolt, +lto, +mlgo, based on r510928) clang version 18.0.0 (https://android.googlesource.com/toolchain/llvm-project 477610d4d0d988e69dbc3fae4fe86bff3f07f2b5), LLD 18.0.0) #1 SMP PREEMPT Tue May 21 12:52:48 UTC 2024
[    0.000000][    T0] KASLR enabled
[    0.000000][    T0] random: crng init done
[    0.000000][    T0] Machine model: linux,dummy-virt
[    0.000000][    T0] stackdepot: disabled
...
[    0.619496][    T1] init: bool android::init::BlockDevInitializer::InitDevices(std::set<std::string>): partition(s) not found in /sys, waiting for their uevent(s): super, vbmeta_a
[   10.635020][    T1] init: Wait for partitions returned after 10013ms
[   10.637150][    T1] init: bool android::init::BlockDevInitializer::InitDevices(std::set<std::string>): partition(s) not found after polling timeout: super, vbmeta_a
[   10.642295][    T1] init: Failed to create devices required for first stage mount
[   10.645314][    T1] Kernel panic - not syncing: Attempted to kill init! exitcode=0x00007f00
[   10.647309][    T1] CPU: 0 PID: 1 Comm: init Not tainted 6.6.30-android15-5-g2485db222497-ab11868669 #1
```

It can run the kernel, but the init stops because no proper disks are specified.

You could investigate how the disk is created, for example by examining the behavior of the `vm run-microdroid --protected` command, but in my case, I shifted toward running Debian with a custom kernel.

### 3. Get the kernel
You can skip it if you download `kernel` file from release page.

If you want to build it yourself, see https://github.com/polygraphene/gunyah-on-sd-guide/blob/main/build-linux.sh. This scripts build kernel in `build/arch/arm64/boot/Image`.

Put them in the devices.
```
adb push arch/arm64/boot/Image /data/local/tmp/kernel
```

### 4. Download debian root fs

Download debian root fs built by google for use with the [Terminal App](https://www.androidpolice.com/android-15-linux-terminal-app/).

```
$ wget https://dl.google.com/android/ferrochrome/3500000/aarch64/images.tar.gz
$ adb push images.tar.gz /data/local/tmp
$ adb shell
(android) $ cd /data/local/tmp
(android) $ tar xvf images.tar.gz root_part
```

### 5. Execute crosvm again for Debian

Execute in root shell of the device:
```
# cd /data/local/tmp
# ulimit -l unlimited
# LD_PRELOAD=./libbinder_ndk.so:./libbinder.so /data/local/tmp/crosvm-a16 --log-level debug run \
  --disable-sandbox --no-balloon --protected-vm-without-firmware --swiotlb 64 \
  --params 'root=/dev/vda' --mem 4096 --cpus 4 \
  --rwdisk root_part /data/local/tmp/kernel
[2025-06-26T14:23:53.664752121+00:00 WARN  crosvm::crosvm::cmdline] Deprecated disk flags such as --[rw]disk or --[rw]root are passed. Use --block instead.
[2025-06-26T14:23:53.664898527+00:00 DEBUG crosvm::crosvm::sys::linux] creating hypervisor: Gunyah { device: Some("/dev/gunyah"), qcom_trusted_vm_id: None, qcom_trusted_vm_pas_id: None }
[2025-06-26T14:23:53.665037277+00:00 INFO  crosvm::crosvm::sys::linux::device_helpers] Trying to attach block device: root_part
[2025-06-26T14:23:53.665094881+00:00 INFO  disk] disk size 6308216320
[    0.000000][    T0] Booting Linux on physical CPU 0x0000000000 [0x000f0480]
[    0.000000][    T0] Linux version 6.15.3 (root@8f2d3f1b4350) (Ubuntu clang version 19.1.1 (1ubuntu1~24.04.2), Ubuntu LLD 19.1.1) #10 SMP PREEMPT Wed Jun 25 17:12:44 UTC 2025
[    0.000000][    T0] KASLR enabled
[    0.000000][    T0] random: crng init done
[    0.000000][    T0] Machine model: linux,dummy-virt
...
[    0.670087][    T1] Freeing unused kernel memory: 768K
[    0.670765][    T1] Run /sbin/init as init process
SELinux:  Could not open policy file <= /etc/selinux/targeted/policy/policy.34:  No such file or directory
[    0.759051][    T1] systemd[1]: Failed to find module 'autofs4'
[    0.806353][    T1] systemd[1]: systemd 252.31-1~deb12u1 running in system mode (+PAM +AUDIT +SELINUX +APPARMOR +IMA +SMACK +SECCOMP +GCRYPT -GNUTLS +OPENSSL +ACL +BLKID +CURL +ELFUTILS +FIDO2 +IDN2 -IDN +IPTC +KMOD +LIBCRYPTSETUP +LIBFDISK +PCRE2 -PWQUALITY +P11KIT +QRENCODE +TPM2 +BZIP2 +LZ4 +XZ +ZLIB +ZSTD -BPF_FRAMEWORK -XKBCOMMON +UTMP +SYSVINIT default-hierarchy=unified)
[    0.813939][    T1] systemd[1]: Detected virtualization vm-other.
[    0.815371][    T1] systemd[1]: Detected architecture arm64.

Welcome to Debian GNU/Linux 12 (bookworm)!

[    0.819293][    T1] systemd[1]: No hostname configured, using default hostname.
[    0.820558][    T1] systemd[1]: Hostname set to <localhost>.
...
[  OK  ] Reached target time-set.target - System Time Set.
You are in emergency mode. After logging in, type "journalctl -xb" to view
system logs, "systemctl reboot" to reboot, "systemctl default" or "exit"
to boot into default mode.
Press Enter for maintenance
(or press Control-D to continue):
root@localhost:~# uname -a
Linux localhost 6.15.3 #10 SMP PREEMPT Wed Jun 25 17:12:44 UTC 2025 aarch64 GNU/Linux
root@localhost:~# cat /etc/debian_version
12.8
root@localhost:~#
```

It will launch in maintenance shell because some services are not working.
This root fs image contains some services for Terminal App. Those services should be disabled. Also needs proper fstab.

### 6. Edit root fs
To launch systemd properly (not maintenance shell), we need to disable some services for our VM. Launch VM and run the following commands.
If you can't edit file because of readonly filesystem, use `--params 'root=/dev/vda rw init=/bin/sh'`.

```sh
# (In the VM)
# cd /etc/systemd/system
# rm forwarder_guest_launcher.service ip_addr_reporter.service shutdown_runner.service ttyd.service virtiofs.service virtiofs_internal.service
# echo "/dev/vda / ext4 rw,discard,errors=remount-ro,x-systemd.growfs 0 1" > /etc/fstab
# reboot (or exit)
```

## FAQ

### `vm` command causes `Permission denied` error 
```
thread 'main' panicked at packages/modules/Virtualization/virtualizationmanager/src/main.rs:134:42:
Failed to remove memlock rlimit: Status(-5, EX_ILLEGAL_STATE): 'Permission denied (os error 13)'
Error: Failed to connect to VirtualizationService
```

If you encounter this error on `vm run` or `vm info` commands, you need to run following command (or disable SELinux):
```
magiskpolicy --live "allow virtualizationservice magisk process { setrlimit }"
```

---

### failed to initialize virtual machine Out of memory (os error 12)
When `crosvm` put following erorr:

```
[2025-06-25T13:13:35.669951209+00:00 DEBUG crosvm::crosvm::sys::linux] creating hypervisor: Gunyah { device: Some("/dev/gunyah") }
[2025-06-25T13:13:35.670223397+00:00 INFO  crosvm::crosvm::sys::linux::device_helpers] Trying to attach block device: disk1.img
[2025-06-25T13:13:35.670261053+00:00 INFO  disk] disk size 1048576,
[2025-06-25T13:13:35.670272564+00:00 INFO  disk] Disk image file is hosted on file system type f2f52010
[2025-06-25T13:13:35.681230845+00:00 ERROR crosvm] exiting with error 1: the architecture failed to build the vm

Caused by:
    failed to initialize virtual machine Out of memory (os error 12)
```

Check dmesg and if you see following logs,

```
[ 8846.526582] misc gunyah: Failed to allocate parcel for DTB: -12
[ 8846.526811] gunyah_rsc_mgr hypervisor:qcom,resource-manager-rpc@940e2b5e1215cfb9: RM rejected message 51000015. Error: 7
[ 8846.526815] misc gunyah: Failed to reclaim parcel: -22
[ 8846.526819] misc gunyah: Failed to reclaim firmware parcel: -22
```

run the following command before executing `crosvm`

```
ulimit -l unlimited
```

This error is caused by the following code.  
https://github.com/OnePlusOSS/android_kernel_oneplus_sm8750/blob/8e66bb68fe6735e93ef5dd59c184cf6341b0098d/drivers/virt/gunyah/vm_mgr_mem.c#L510  
`account_locked_vm` is a function that manages the size of locked memory belonging to the calling process. By default on Android, the maximum amount of locked memory is 64 kB, which leads to an `Out of memory` error. You need to work around this by using `ulimit`.

When the VM is launched using the `vm` command, `virtmgr` applies a setting equivalent to `ulimit`.
https://cs.android.com/android/platform/superproject/main/+/main:packages/modules/Virtualization/android/virtmgr/src/main.rs;l=115;drc=198eb9768cf9b74aa5a345cdd89079b3e23c36b8

## Note

1. For networking setup see [Network instruction](https://github.com/polygraphene/gunyah-on-sd-guide/blob/main/NETWORK.md)
2. I'm trying to enable graphics acceleration (virtio\_gpu), but currently not working. If anyone knows anything about it, please let me know.
3. [packages/modules/Virtualization/docs](https://cs.android.com/android/platform/superproject/main/+/main:packages/modules/Virtualization/docs/;drc=2cb8e7397b171e0eea0d0c16e099a004da157e80) contains many documents about AVF and pvmfw.

## Related works

1. [gunyah-script](https://github.com/Imacolombian346/gunyah-script) by @Imacolombian346
   - Convenient scripts to run VMs more easily

## Links
AVF documentation  
https://cs.android.com/android/platform/superproject/main/+/main:packages/modules/Virtualization/docs/;drc=2cb8e7397b171e0eea0d0c16e099a004da157e80
