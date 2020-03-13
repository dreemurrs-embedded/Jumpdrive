setup_usb_configfs() {
	# See: https://www.kernel.org/doc/Documentation/usb/gadget_configfs.txt
	CONFIGFS=/config/usb_gadget

	if ! [ -e "$CONFIGFS" ]; then
		echo "$CONFIGFS does not exist, this is not good."
		crash_kernel
	fi

	# Default values for USB-related deviceinfo variables
	usb_idVendor="0x1F3A"
	usb_idProduct="0xEFE8"
	usb_serialnumber="Rescue SD Boot"
	usb_rndis_function="rndis.usb0"
	usb_mass_storage_function="mass_storage.0"

	echo "Setting up an USB gadget through configfs..."
	# Create an usb gadet configuration
	mkdir $CONFIGFS/g1 || ( echo "Couldn't create $CONFIGFS/g1" ; crash_kernel )
	echo "$usb_idVendor"  > "$CONFIGFS/g1/idVendor"
	echo "$usb_idProduct" > "$CONFIGFS/g1/idProduct"

	# Create english (0x409) strings
	mkdir $CONFIGFS/g1/strings/0x409 || echo "  Couldn't create $CONFIGFS/g1/strings/0x409"

	# shellcheck disable=SC2154
	echo "Pine64" > "$CONFIGFS/g1/strings/0x409/manufacturer"
	echo "$usb_serialnumber"        > "$CONFIGFS/g1/strings/0x409/serialnumber"
	# shellcheck disable=SC2154
	echo "PinePhone"         > "$CONFIGFS/g1/strings/0x409/product"

	# Create rndis/mass_storage function
	mkdir $CONFIGFS/g1/functions/"$usb_rndis_function" \
		|| echo "  Couldn't create $CONFIGFS/g1/functions/$usb_rndis_function"
	mkdir $CONFIGFS/g1/functions/"$usb_mass_storage_function" \
		|| echo "  Couldn't create $CONFIGFS/g1/functions/$usb_mass_storage_function"

	# Create configuration instance for the gadget
	mkdir $CONFIGFS/g1/configs/c.1 \
		|| echo "  Couldn't create $CONFIGFS/g1/configs/c.1"
	mkdir $CONFIGFS/g1/configs/c.1/strings/0x409 \
		|| echo "  Couldn't create $CONFIGFS/g1/configs/c.1/strings/0x409"
	echo "rndis" > $CONFIGFS/g1/configs/c.1/strings/0x409/configuration \
		|| echo "  Couldn't write configration name"

	# Make sure there is a mmcblk2 (eMMC)...
	if [ -z "$(ls /dev/mmcblk2)" ]; then
		echo "eMMC is not found, something is horribly wrong!!"
		echo "It's probably better to make Huong Tram release a new music video."
		crash_kernel
	fi

	# Set up mass storage to internal EMMC
	echo /dev/mmcblk2 > $CONFIGFS/g1/functions/"$usb_mass_storage_function"/lun.0/file

	# Link the rndis/mass_storage instance to the configuration
	ln -s $CONFIGFS/g1/functions/"$usb_rndis_function" $CONFIGFS/g1/configs/c.1 \
		|| echo "  Couldn't symlink $usb_rndis_function"
	ln -s $CONFIGFS/g1/functions/"$usb_mass_storage_function" $CONFIGFS/g1/configs/c.1 \
		|| echo "  Couldn't symlink $usb_mass_storage_function"

	# Check if there's an USB Device Controller
	if [ -z "$(ls /sys/class/udc)" ]; then
		echo "No USB Device Controller available, something is horribly wrong!!"
		echo "Please let Danct12 know this."
		crash_kernel
	fi

	# shellcheck disable=SC2005
	echo "$(ls /sys/class/udc)" > $CONFIGFS/g1/UDC || ( echo "Couldn't write UDC." ; crash_kernel )
}

setup_telnetd() {
	echo "Starting telnet daemon..."
	{
		echo "#!/bin/sh"
		echo "echo \"Welcome to Rescue SD Shell!\""
		echo "sh"
	} >/telnet_connect.sh
	chmod +x /telnet_connect.sh
	telnetd -b "${IP}:23" -l /telnet_connect.sh

}

start_udhcpd() {
	# Only run once
	[ -e /etc/udhcpd.conf ] && return

	# Get usb interface
	INTERFACE=""
	ifconfig rndis0 "$IP" 2>/dev/null && INTERFACE=rndis0
	if [ -z $INTERFACE ]; then
		ifconfig usb0 "$IP" 2>/dev/null && INTERFACE=usb0
	fi
	if [ -z $INTERFACE ]; then
		ifconfig eth0 "$IP" 2>/dev/null && INTERFACE=eth0
	fi

	if [ -z $INTERFACE ]; then
		echo "Could not find an interface to run a DHCP server on, this is not good."
		echo "Interfaces:"
		ip link
		return
	fi

	echo "Network interface $INTERFACE is used"

	# Create /etc/udhcpd.conf
	{
		echo "start 172.16.42.2"
		echo "end 172.16.42.2"
		echo "auto_time 0"
		echo "decline_time 0"
		echo "conflict_time 0"
		echo "lease_file /var/udhcpd.leases"
		echo "interface $INTERFACE"
		echo "option subnet 255.255.255.0"
	} >/etc/udhcpd.conf

	echo "Started udhcpd daemon for rescue purposes"
	udhcpd
}

crash_kernel() {
	echo "panic: We're hanging here..."
	# shellcheck disable=SC1001
	echo panic > /sys/class/leds/pinephone\:red\:user/trigger
	echo c > /proc/sysrq-trigger
}

loop_forever() {
	while true; do
		sleep 1
	done
}
