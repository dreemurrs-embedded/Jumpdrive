# Rescue SD for PinePhone

This image is a swiss army knife solution for **PinePhone eMMC**.

You can use this to flash a image **directly to eMMC**, troubleshooting a broken system, and a lot more.

## This project is built on:
- [Busybox](https://busybox.net) - which is [GPLv2](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html).
- [postmarketOS](https://postmarketos.org) scripts - which is [GPLv2](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html).
- [Pine64's kernel fork](https://gitlab.com/pine64-org/linux) - which is [GPLv2](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html).
- [U-Boot](https://github.com/u-boot/u-boot) - which has [multiple licenses](https://github.com/u-boot/u-boot/tree/master/Licenses)

## Building

Run `make` inside this directory and it will build jumpdrive.img.xz that can be flashed to SD.

The dependencies are:

- aarch64-linux-gnu- toolchain
- u-boot tools
- mtools
