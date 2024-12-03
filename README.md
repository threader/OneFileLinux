## One File Linux
This will attempt to provide a configurable 'minimal' Buildroot Linux userland toolset and a mainline Linux kernel with patches from [GraphenOS's](https://github.com/GrapheneOS/linux-hardened), how much space your end .efi file depends on what you include and is limited by the FS the .efi lives on, with say Rufus NTFS .efi driver and similar, you could run (or save) your life from it.

Runs on any UEFI computer (PC or Mac) with minimal effort. Since this project has diverged a bit from the original OFL, there are now really three files, the kernel and modules as well as an 'optional' 2gb .img, the kernel .config requires tweaking to include the proper drivers to function, I'm currently testing this virtually and it appears to pass secure boot.

<img width=600 alt="One File Linux" src="https://hub.zhovner.com/img/one-file-linux.png" />

**Download:** https://github.com/zhovner/OneFileLinux/releases
* NB: I, threader, will probably wont do _many_ releases. Only stable milestones and PoC. 

About in russian: https://habrahabr.ru/post/349758/
### Main advantages

* **No installation required** — no need to create additional paritions. Just copy one file to EFI system partition and add new boot entry to NVRAM.
  
* **No USB flash needed** — once copied to EFI partition, OneFileLinux can boot any time from system disk.
  
* **No Boot Manager required (GRUB, rEFInd)** — boots directly by UEFI firmware, no additional software needed.
  
* **Doesn't change the boot sequence** — can boot only once, next reboot will return default settings.
  
* **Compatible with disk encryption** — works with macOS FileVault and dm-crypt. Because EFI system parition is not encrypted.

### Why?

Because we can? (Thank you original author btw! - and [theregister.co.uk](https://www.theregister.com/2024/09/09/onefilelinux_esp_distro/) for that article, I would never have known about OFL w/o.)

This can be useful when you need Linux on bare metal, in case of emergency, to boot/chroot further into encrypted volumes and images etc. file hashing for securely booting onwards etc.

In comparison with Live USB flash, OneFileLinux lives permanently in EFI partition and can boot at any time later in a hardend read only env.  

  
## Run on Macbook
* NB: I threader, don not have a MacBook.

#### 1. Download OneFileLinux.efi from link above.  
  
  

#### 2. Mount EFI System Partition 

`diskutil mount diskN` 

where diskN is your EFI disk number.  
To find your EFI disk number use `diskutil list` command.  
  
<img width="500" alt="macOS diskutil list EFI partition" src="https://hub.zhovner.com/img/diskutil-list-efi.png" />

For me it will be: `diskutil mount disk0s1`

  
  
  
#### 3. Copy OneFileLinux.efi to EFI partition
  
`cp ~/Downloads/OneFileLinux.efi /Volumes/EFI/`

  
  
#### 4. Set boot option in NVRAM

On macOS since El Capitan enabled by default SIP (System Integrity Protection) prohibits to change boot options.  
To check SIP state run `csrutil status`. In normal situation it should be enabled.  
  
If SIP is enabled you can run `bless` only from Recovery console, otherwise it returns error.  
To boot in Recovery mode press <b>CMD+R</b> while boot and go to **_Utilities —> Terminal_** from top menu.  
In recovery console follow steps 2 and 4 every time you need to boot OneFileLinux.  

`bless --mount /Volumes/EFI --setBoot --nextonly --file /Volumes/EFI/OneFileLinux.efi`
  
  
This command sets NVRAM option to boot OneFileLinux.efi only once. Next reboot will return default boot order. 
  
  
  
### 5. Reboot 

Reboot to run OneFileLinux. Once you've done, type `reboot` in Linux console and go back to you'r OS. 
Every time when you need it again, follow steps 2 and 4 from recovery console.



## Run on PC
There are few ways how to run OneFileLinux on PC motherboard. Some motherboards have builtin UEFI Shell that can run any efi binary from console.
Some laptops, HP in particular, has a nice .efi file browser if you hit F9, no idea about the current state of that.
I will describe setup process for my old ThinkPad X220 that doesn't have UEFI shell. 
It can also be run via GRUB.

Disabling Secure Boot can be a bit of a hastle and has to be done correctly, best read https://wiki.ubuntu.com/UEFI/SecureBoot/DKMS and pay attention.

#### 1. Copy OneFileLinux.efi to EFI partition 
  
If you use Windows 10 installed in EFI mode, you have EFI system partition 100 MB in size.  
You can mount the ESD/EFI partition to w: using this PowerShell command:
'''
mountvol w: /S
'''

You can do this with OneFileLinux.efi run from USB flash or any other linux distro.

#### 2. Add NVRAM boot option

Read [Working with UEFI variables from PowerShell](https://oofhours.com/2019/10/05/working-with-uefi-variables-from-powershell/) and [Editing Boot Options in EFI](https://learn.microsoft.com/en-us/windows-hardware/drivers/devtest/editing-boot-options-in-efi) for Windows. _UNVERIFIED by me!_

On Linux, replace `/dev/sda` to you disk path and `--part 2` to your EFI partition number.  
  
`efibootmgr --disk /dev/sda --part 2 --create --label "One File Linux" --loader /OneFileLinux.efi`

#### 3. Choose One File Linux from boot menu

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



## Building:

Building One File Linux.  

This version of OFL is based on Buildroot Linux and Linus Torvald's kernel with hardening patches from [https://github.com/GrapheneOS](GraphenOS's) linux-hardened most by Daniel Micay, but also Serge Hallyn and  mr. 'anthraxx' and others.

The build will default to "CFLAGS=-march=native -mcpu=native -mtune=native" and that will need to be changed in the buildroot config if you are building for a different system then the one you are building on.

Buildroot handles grabbing the kernel sources and the linux/ that used to live here is now a symlink to the buildroot output directory.
I optet to symlink buildroot/dl/linux/git/.git to linux/.git , hopefully to aid rapid development , as the sources buildroot actuelly uses to build are in buildroot/output/build/linux-main_ofl/ - setup.sh is suppsed to run sometime after buildroot has gotten the sources and symlink this in place?

Requires the Debian package: libelf-dev libopenssl-dev

1. Clone repositry  
```console
git clone https://github.com/threader/OneFileLinux

# Grab the submodules:
git submodule update --init --recursive
# To pull updates later on.
git submodule update --recursive --remote
```

2. Set up Buildroot and Linux desired kernel .config - either manually or trough 'make menuconfig' 
	* I think i will split this into two parts, one for a base .cpio and one for an ext4 image that can be mapped via GRUB.

3. Run the kernel-hardening-checker followed by lk-reducer

4. Run the Buildroot build. - i will fix build.sh to do this when things are clear

#5. Make changes in root filesystem and kernel 
#`chroot output/images /bin/ash`

#5. Build  
`./build.sh`
