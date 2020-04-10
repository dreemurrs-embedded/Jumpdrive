# Jumpdrive for PinePhone

This image is a swiss army knife solution for **PinePhone eMMC**.

You can use this to flash a image **directly to eMMC**, troubleshooting a broken system, and a lot more.

## This project is built on:
- [Busybox](https://busybox.net) - which is [GPLv2](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html).
- [postmarketOS](https://postmarketos.org) scripts - which is [GPLv2](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html).
- [Pine64's kernel fork](https://gitlab.com/pine64-org/linux) - which is [GPLv2](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html).
- [U-Boot](https://github.com/u-boot/u-boot) - which has [multiple licenses](https://github.com/u-boot/u-boot/tree/master/Licenses)

## Building

The dependencies are:

- aarch64-linux-gnu- toolchain
- u-boot tools
- mtools

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
