#!/bin/bash

board_model=$(cat /proc/device-tree/model)
case "$board_model" in
	"ArmSoM Sige5")
		usb3_num=1
		usb3_log_string="Host supports USB 3.0 SuperSpeed"
		;;
	"Rockchip armsom sige5 Board")
		usb3_num=1
		usb3_log_string="Host supports USB 3.0 SuperSpeed"
		;;
	"armsom w3")
		usb3_num=2
		usb3_log_string=" new SuperSpeed Gen 1 USB device"
		;;
	*)
		usb3_num=2
		usb3_log_string=" new SuperSpeed Gen 1 USB device"
		;;
esac

result=`dmesg | grep "${usb3_log_string}" | wc -l`
if [ ${result} -ge ${usb3_num} ];then
    exit 0
else
    exit 1
fi
