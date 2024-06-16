#!/bin/bash

board_model=$(cat /proc/device-tree/model)
case "$board_model" in
	"ArmSoM Sige5")
		usb2_num=1
		;;
	"Rockchip armsom sige5 Board")
		usb2_num=1
		;;
	"armsom w3")
		usb2_num=3
		;;
	*)
		usb2_num=3
		;;
esac

result=`dmesg | grep "new high-speed USB device" | wc -l`
if [ ${result} -ge ${usb2_num} ];then
    exit 0
else
    exit 1
fi
