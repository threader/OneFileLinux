## One File Linux
This is a Buildroot Linux userland toolset with either a mainline 'linux-next-master' branch kernel with Debian patches or (eventually) a stable LTS corresponding with Debian stable and patches from [GraphenOS's](https://github.com/GrapheneOS/linux-hardened) as far as that is possible - I had Debian running on 6.12.x with the GrapheneOS patches some time ago but never worked out the kinks.

Runs on any UEFI computer (PC or Mac) with 'some' effort. This project has diverged quite a bit from the original OFL I forked, It's now building with Buildroot and using the -march/mcpu/mtune 'native' flags, both for gcc and llvm/clang (see buildroot/packages/Makefile.mk or commit: 3400af3e0b45ee709262a3fd24494fb4cc8c26f0 in buildroot), this means the compiler uses the full instructionset avaialble for the architecture of the computer it's building on, and thereby will boot only/is only meanto to boot on that same computer (and QEMU/KVM with host-cpu-passtrough), 'make localyesconfig' is used to configure the kernel, this takes the current running config of the Linux kernel configuration (see build_kernel.sh) and builds-in the current config, currently the 'rootfs.cpio.xz' is 351mb, appended to the 'bzimage', currently approx. 690mb, the kernel commandline to boot is 'root=/dev/ram0'. I expect you to tweak the kernel .config. In my testing it passes secure boot. I've not quite landed on the BuildRoot '.config' so this is a bit bloated. I did run into a bit a problem with configuring a universal config as that would 'just work™', AMDGPU stuff expects to probe and find a AMDGPU and will fail to build if none is found.
This means i'll need to do some GPU detection and have at least a few flavours of 'cfg/buildroot_x86_64_glibc-systemd' (I settled on something that is Debian compatible for testing and BuldRoot seems to have settled on dropping sysv, I'll happily provide a Devuan sysv compatible BuildRoot config in the futue sometime if BuildRoot doesn't stop supporting sysv init),
GLIBC is built with the hardening flag -D_GLIBCXX_ASSERTIONS (see buildroot/package/glibc/glibc.mk or commit 31b82ca5447d9b4ecbbca06f194ba02b401f708f), llvm with the corresponding -D_LIBCPP_HARDENING_MODE=_LIBCPP_HARDENING_MODE_EXTENSIVE flag (see package/llvm-project/llvm-project.mk).
Other hardening features are to be explored like ```Hardened_malloc```, ```Fil-C``` and ```pkgsrc``` with the bsd emulation library - where some persistant storage would be nice... - once thigs are running as I intend.

## Building:

Building One File Linux.  

1. Clone repositry  
```console
git clone https://github.com/threader/OneFileLinux

# Grab the submodules:
git submodule update --init --recursive
# To pull updates later on.
git submodule update --recursive --remote
```

2. Copy the corresponding Buildroot config from ```OneFileLinux/cfg/buildroot_x86_64_glibc-systemd_*``` to OneFileLinux/buldroot/.config and run ```./build_kernel.sh```
	* This only builds the kernel and let's you verify that everything is in order before the main BuildRoot part. 

3. See if you are happy with the the output from ```OneFileLinux/kernel-hardening-checker/bin/kernel-hardening-checker -c cfg/current_building_kernel_config```

4. Run ```make``` in the Buildroot directory and a ```bzImage``` should eventually land in ```OneFileLinux/buildroot/output/images```.

# To Make changes in root filesystem
#`chroot output/images /bin/bash`

I optet to symlink ```OneFileLinux/buildroot/dl/linux/git/.git``` to ```OneFileLinux/linux/.git/``` to aid rapid development, the BuildRoot Linux sources used to build live under ```OneFileLinux/buildroot/output/build/linux-linux-next-master ``` - see ```build_kernel.sh ``` for reference.

So far _harden_malloc_ and _Fil-C - llvm-project-deluge_ are not yet used.


 
#### OLD README!! ####


### Main advantages

* **No installation required** — no need to create additional paritions. Just copy one file to EFI system partition and add new boot entry to NVRAM.
  
* **No USB flash needed** — once copied to EFI partition, OneFileLinux can boot any time from system disk.
  
* **No Boot Manager required (GRUB, rEFInd)** — boots directly by UEFI firmware, no additional software needed.
  
* **Doesn't change the boot sequence** — can boot only once, next reboot will return default settings.
  
* **Compatible with disk encryption** — works with macOS FileVault and dm-crypt. Because EFI system parition is not encrypted.

### Why?

Because it can? (Thank you original author - and [theregister.co.uk](https://www.theregister.com/2024/09/09/onefilelinux_esp_distro/), or I would never have known about OFL w/o.)

This can be useful in case of emergency.

#### Mount EFI System Partition 

`diskutil mount diskN` 

where diskN is your EFI disk number.  
To find your EFI disk number use `diskutil list` command.  
  
<img width="500" alt="macOS diskutil list EFI partition" src="https://hub.zhovner.com/img/diskutil-list-efi.png" />

For me it will be: `diskutil mount disk0s1`

  
#### Copy OneFileLinux.efi to EFI partition
  
`cp ~/Downloads/OneFileLinux.efi /Volumes/EFI/`

  
  
#### Set boot option in NVRAM

On macOS since El Capitan enabled by default SIP (System Integrity Protection) prohibits to change boot options.  
To check SIP state run `csrutil status`. In normal situation it should be enabled.  
  
If SIP is enabled you can run `bless` only from Recovery console, otherwise it returns error.  
To boot in Recovery mode press <b>CMD+R</b> while boot and go to **_Utilities —> Terminal_** from top menu.  
In recovery console follow steps 2 and 4 every time you need to boot OneFileLinux.  

`bless --mount /Volumes/EFI --setBoot --nextonly --file /Volumes/EFI/OneFileLinux.efi`
  
  
This command sets NVRAM option to boot OneFileLinux.efi only once. Next reboot will return default boot order. 
  
  
  
### Reboot 

Reboot to run OneFileLinux. Once you've done, type `reboot` in Linux console and go back to you'r OS. 
Every time when you need it again, follow steps 2 and 4 from recovery console.



## Run on PC
There are few ways how to run OneFileLinux on PC motherboard. Some motherboards have builtin UEFI Shell that can run any efi binary from console.
Some laptops, HP in particular, has a nice .efi file browser if you hit F9, no idea about the current state of that.
I will describe setup process for my old ThinkPad X220 that doesn't have UEFI shell. 
It can also be run via GRUB.

Disabling Secure Boot can be a bit of a hastle and has to be done correctly, best read https://wiki.ubuntu.com/UEFI/SecureBoot/DKMS and pay attention.

#### Copy OneFileLinux.efi to EFI partition 
  
If you use Windows 10 installed in EFI mode, you have EFI system partition 100 MB in size.  
You can mount the ESD/EFI partition to w: using this PowerShell command:
'''
mountvol w: /S
'''

You can do this with OneFileLinux.efi run from USB flash or any other linux distro.

#### Add NVRAM boot option

Read [Working with UEFI variables from PowerShell](https://oofhours.com/2019/10/05/working-with-uefi-variables-from-powershell/) and [Editing Boot Options in EFI](https://learn.microsoft.com/en-us/windows-hardware/drivers/devtest/editing-boot-options-in-efi) for Windows. _UNVERIFIED by me!_

On Linux, replace `/dev/sda` to you disk path and `--part 2` to your EFI partition number.  
  
`efibootmgr --disk /dev/sda --part 2 --create --label "One File Linux" --loader /OneFileLinux.efi`

#### Choose One File Linux from boot menu

On a ThinkPad X220, press F12 while power on to open boot menu. Hotkey depends on your motherboard.  
  
<img alt="ThinkPad X220 boot menu" width="600" src="https://hub.zhovner.com/img/thinkpad-x220-boot-menu.png" />

On HP it's F9.

## Run from USB flash
The only benefit from running OneFileLinux from USB flash, is that no additional software is required to create bootable flash drive.  
Just format flash drive as FAT32 in GPT scheme and copy OneFileLinux.efi to default path:
  
`\EFI\BOOT\BOOTx64.EFI`  


#### Format in GPT scheme in Windows  

Windows does not allow to format flash drive in GPT scheme from GUI, so you need to use command line tool.  
1. Open `cmd.exe` as administrtor 
2. Type`diskpart`
3. `list disk` to see all disks
4. `select disk <disknumber>`
5. `clean` do delete parition table
6. `convert gpt` to convert disk in GPT scheme
7. `exit`

Then format drive from `diskmgmt.msc` in FAT32.




