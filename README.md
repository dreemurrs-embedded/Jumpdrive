# Jumpdrive

A swiss army knife for mobile devices, currently supporting:

- Pine64 PineTab
- Pine64 PinePhone
- Purism Librem 5
- Xiaomi Pocophone F1
- OnePlus 6
- OnePlus 6T

You can use this to flash a image **directly to eMMC**, troubleshooting a broken system, and a lot more.

### Table of Contents
- [Installation](#installation)
- [Building](#building)
- [List of projects being used in Jumpdrive](#this-project-is-built-on)

### Installation
Download the latest image for your device [here](https://github.com/dreemurrs-embedded/Jumpdrive/releases)


#### PinePhone / PineTab

Then use dd to flash the image to an SD card. Jumpdrive is pretty small, so there is no need for a large storage SD card.

Insert the SD card to the device, then boot it up, you should get a nice splash screen and you should see a new storage device after you plug the device to USB.

With the device plugged in, you can now flash a distro, or fix a unbootable installation.

**WARNING:**
In case eMMC isn't showing up try to charge your battery and try again. There are reports of people not being able to flash to eMMC with discharged battery.

#### Librem 5

Extract the downloaded JumpDrive release archive for the Librem 5, put the device into flash mode, then run the `boot-purism-librem5.sh` script from the release.

### Xiaomi Pocophone F1 / OnePlus 6 / OnePlus 6T

Boot the image using `fastboot boot`.

### Building

The dependencies are:

- aarch64-linux-gnu- toolchain
- u-boot tools
- mtools

Additional dependencies for the Purism Librem 5:
- arm-none-eabi- toolchain
- uuu

Additional dependencies for the Xiaomi Pocophone F1 / OnePlus 6 / OnePlus 6T:
- mkbootimg

```shell-session
$ git submodule update --init --recursive
Downloads the projects to build

$ make -j8 pine64-pinephone.img.xz
Builds everything needed for the pinephone image...

$ make -j8 initramfs-pine64-pinephone.gz
Generate only the initramfs for the pinephone

$ make -j8 all
Generates an image for every supported platform in parallel
```

### This project is built on:
- [Busybox](https://busybox.net) - which is [GPLv2](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html).
- [postmarketOS](https://postmarketos.org) scripts - which is [GPLv2](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html).
- [Pine64's kernel fork](https://gitlab.com/pine64-org/linux) - which is [GPLv2](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html).
- [U-Boot](https://github.com/u-boot/u-boot) - which has [multiple licenses](https://github.com/u-boot/u-boot/tree/master/Licenses)

