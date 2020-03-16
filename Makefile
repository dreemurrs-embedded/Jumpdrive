CROSS_FLAGS = ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu-

all: jumpdrive.img.xz

jumpdrive.img.xz: jumpdrive.img
	xz -c jumpdrive.img > jumpdrive.img.xz
	
initramfs/bin/busybox: src/busybox src/busybox_config
	mkdir -p build/busybox
	cp src/busybox_config build/busybox/.config
	make -C src/busybox O=../../build/busybox $(CROSS_FLAGS)
	cp build/busybox/busybox initramfs/bin/busybox
	
initramfs/splash.ppm.gz: splash/jumpdrive.ppm
	gzip < splash/jumpdrive.ppm > initramfs/splash.ppm.gz
	
initramfs.cpio: initramfs/bin/busybox initramfs/init initramfs/init_functions.sh initramfs/splash.ppm.gz
	cd initramfs; find . | cpio -H newc -o > ../initramfs.cpio
	
initramfs.gz: initramfs.cpio
	gzip < initramfs.cpio > initramfs.gz
	
Image.gz: src/linux_config
	mkdir -p build/linux
	cp src/linux_config build/linux/.config
	make -C src/linux O=../../build/linux $(CROSS_FLAGS) olddefconfig
	make -C src/linux O=../../build/linux $(CROSS_FLAGS)
	cp build/linux/arch/arm64/boot/Image.gz Image.gz
	cp build/linux/arch/arm64/boot/dts/allwinner/sun50i-a64-pinephone.dtb sun50i-a64-pinephone.dtb

jumpdrive.img: fat.img u-boot-sunxi-with-spl.bin
	rm -f jumpdrive.img
	truncate --size 50M jumpdrive.img
	parted -s jumpdrive.img mktable msdos
	parted -s jumpdrive.img mkpart primary fat32 2048s 100%
	parted -s jumpdrive.img set 1 boot on
	dd if=u-boot-sunxi-with-spl.bin of=jumpdrive.img bs=8k seek=1
	dd if=fat.img of=jumpdrive.img seek=1024 bs=1k

boot.scr: src/boot.txt
	mkimage -A arm -O linux -T script -C none -n "U-Boot boot script" -d src/boot.txt boot.scr
	
u-boot-sunxi-with-spl.bin:
	wget http://dl-cdn.alpinelinux.org/alpine/edge/main/aarch64/u-boot-pine64-2020.01-r0.apk
	tar -xvf u-boot-pine64-2020.01-r0.apk usr/share/u-boot/pine64-lts/u-boot-sunxi-with-spl.bin --strip-components 4
	

fat.img: initramfs.gz Image.gz boot.scr
	rm -f fat.img
	truncate --size 40M fat.img
	mkfs.fat -F32 fat.img
	
	mcopy -i fat.img Image.gz ::Image.gz
	mcopy -i fat.img sun50i-a64-pinephone.dtb ::sun50i-a64-pinephone.dtb
	mcopy -i fat.img initramfs.gz ::initramfs.gz
	mcopy -i fat.img boot.scr ::boot.scr

.PHONY: clean

clean:
	rm -rf build
	rm -f initramfs/bin/busybox
	rm -f fat.img
	rm -f jumpdrive.img
	rm -f jumpdrive.img.xz
	rm -f *.dtb
	rm -f u-boot-pine64-2020.01-r0.apk
	rm -f u-boot-sunxi-with-spl.bin
	rm -f initramfs/splash.ppm.gz
	rm -f initramfs/bin/busybox
	rm -f initramfs.cpio
	rm -f initramfs.gz
	rm -f Image.gz
	rm -f boot.scr
