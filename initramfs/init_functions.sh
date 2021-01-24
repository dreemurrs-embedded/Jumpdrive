## SPDX-License-Identifier: GPL-2.0-only
## Init functions for JumpDrive
## Copyright (C) 2020 - postmarketOS
## Copyright (C) 2020 - Danctl12 <danct12@disroot.org>

setup_usb_configfs() {
	# See: https://www.kernel.org/doc/Documentation/usb/gadget_configfs.txt
	CONFIGFS=/config/usb_gadget

	if ! [ -e "$CONFIGFS" ]; then
		fatal_error "$CONFIGFS does not exist"
	fi

	# Default values for USB-related deviceinfo variables
	usb_idVendor="0x1209" # Generic
	usb_idProduct="0x4201" # Random ID
	usb_serialnumber="Jumpdrive"
	usb_rndis_function="rndis.usb0"
	usb_mass_storage_function="mass_storage.0"

	echo "Setting up an USB gadget through configfs..."
	# Create an usb gadet configuration
	mkdir $CONFIGFS/g1 || ( fatal_error "Couldn't create $CONFIGFS/g1" )
	echo "$usb_idVendor"  > "$CONFIGFS/g1/idVendor"
	echo "$usb_idProduct" > "$CONFIGFS/g1/idProduct"

	# Create english (0x409) strings
	mkdir $CONFIGFS/g1/strings/0x409 || echo "  Couldn't create $CONFIGFS/g1/strings/0x409"

	# shellcheck disable=SC2154
	echo "$MANUFACTURER" > "$CONFIGFS/g1/strings/0x409/manufacturer"
	echo "$usb_serialnumber"        > "$CONFIGFS/g1/strings/0x409/serialnumber"
	# shellcheck disable=SC2154
	echo "$PRODUCT"         > "$CONFIGFS/g1/strings/0x409/product"

	# Create rndis/mass_storage function
	mkdir $CONFIGFS/g1/functions/"$usb_rndis_function" \
		|| echo "  Couldn't create $CONFIGFS/g1/functions/$usb_rndis_function"
	mkdir $CONFIGFS/g1/functions/"$usb_mass_storage_function" \
		|| echo "  Couldn't create $CONFIGFS/g1/functions/$usb_mass_storage_function"
	mkdir $CONFIGFS/g1/functions/"$usb_mass_storage_function/lun.1" \
		|| echo "  Couldn't create $CONFIGFS/g1/functions/$usb_mass_storage_function/lun.1"

	# Create configuration instance for the gadget
	mkdir $CONFIGFS/g1/configs/c.1 \
		|| echo "  Couldn't create $CONFIGFS/g1/configs/c.1"
	mkdir $CONFIGFS/g1/configs/c.1/strings/0x409 \
		|| echo "  Couldn't create $CONFIGFS/g1/configs/c.1/strings/0x409"
	echo "rndis" > $CONFIGFS/g1/configs/c.1/strings/0x409/configuration \
		|| echo "  Couldn't write configration name"

	# Make sure the node for the eMMC exists
	if [ -z "$(ls $EMMC)" ]; then
		fatal_error "$EMMC could not be opened, possible eMMC defect"
	fi

	# Set up mass storage to internal EMMC
	echo $EMMC > $CONFIGFS/g1/functions/"$usb_mass_storage_function"/lun.0/file
	echo $SD > $CONFIGFS/g1/functions/"$usb_mass_storage_function"/lun.1/file

	# Rename the mass storage device
	echo "JumpDrive eMMC" > $CONFIGFS/g1/functions/"$usb_mass_storage_function"/lun.0/inquiry_string
	echo "JumpDrive microSD" > $CONFIGFS/g1/functions/"$usb_mass_storage_function"/lun.1/inquiry_string

	# Link the rndis/mass_storage instance to the configuration
	ln -s $CONFIGFS/g1/functions/"$usb_rndis_function" $CONFIGFS/g1/configs/c.1 \
		|| echo "  Couldn't symlink $usb_rndis_function"
	ln -s $CONFIGFS/g1/functions/"$usb_mass_storage_function" $CONFIGFS/g1/configs/c.1 \
		|| echo "  Couldn't symlink $usb_mass_storage_function"

	# Check if there's an USB Device Controller
	if [ -z "$(ls /sys/class/udc)" ]; then
		fatal_error "No USB Device Controller available"
	fi

	# shellcheck disable=SC2005
	echo "$(ls /sys/class/udc)" > $CONFIGFS/g1/UDC || ( fatal_error "Couldn't write to UDC" )
}

setup_telnetd() {
	echo "Starting telnet daemon..."
	{
		echo "#!/bin/sh"
		echo "echo \"Welcome to Jumpdrive Shell!\""
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

start_serial_getty() {
	if [ -n "$SERIAL_CON" ] && [ -n "$SERIAL_BAUD" ]; then
		# Serial console isn't supposed to be quitted, so if task is finished, relaunch it.
		sh -c "while true; do getty -l /bin/sh -n $SERIAL_BAUD $SERIAL_CON linux; done" &
	else
		echo "Not setting up serial shell, SERIAL_CON and/or SERIAL_BAUD is not defined."
	fi
}

fatal_error() {
	clear

	# Move cursor into position for error message
	echo -e "\033[$ERRORLINES;0H"

	gzip -c -d error.ppm.gz > /error.ppm
	fbsplash -s /error.ppm
	
	# Print the error message over the error splash
	echo "  $1"

	loop_forever
}

loop_forever() {
	while true; do
		sleep 1
	done
}
