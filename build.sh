#!/bin/sh

# EDIT THIS:
export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
IMAGE_NAME="pinephone-sdrescue.img"

# Cleanup first
rm -rf src/busybox/out
rm -rf src/linux/out
rm -rf usr

# Build Busybox
cd src/busybox
mkdir out
cp ../busybox_config out/.config
make O=out -j$(nproc --all)
cd ../..

# Build Linux Kernel
cd src/linux
mkdir out
patch -p1 -N < ../linux-disable_sysrq-msgs.diff || true
cp ../linux_config out/.config
make O=out -j$(nproc --all)
cd ../..

# Make initramfs
sudo cp -v src/busybox/out/busybox initramfs/bin/
cd initramfs
find . | cpio -H newc -o > ../initramfs.cpio
cd ..
cat initramfs.cpio | gzip > recovery.gz

# Create image
truncate --size 50M $IMAGE_NAME

cat << EOF | fdisk pinephone-sdrescue.img 
o
n
p
1
2048
102399
w
EOF

LOOP_DEVICE=$(losetup -f)
sudo losetup -P $LOOP_DEVICE $IMAGE_NAME
sudo mkfs.fat -F32 ${LOOP_DEVICE}p1
mkdir mount
sudo mount ${LOOP_DEVICE}p1 mount
sudo cp -v src/linux/out/arch/arm64/boot/Image.gz mount
sudo cp -v src/linux/out/arch/arm64/boot/dts/allwinner/sun50i-a64-pinephone.dtb mount
sudo cp -v recovery.gz mount
sudo mkimage -A arm -O linux -T script -C none -n "U-Boot boot script" -d src/boot.txt mount/boot.scr
sudo umount mount
rm -rf mount

wget http://dl-cdn.alpinelinux.org/alpine/edge/main/aarch64/u-boot-pine64-2020.01-r0.apk
tar xvf u-boot-pine64-2020.01-r0.apk
sudo dd if=usr/share/u-boot/pine64-lts/u-boot-sunxi-with-spl.bin of=${LOOP_DEVICE} bs=8k seek=1

sudo losetup -d $LOOP_DEVICE
