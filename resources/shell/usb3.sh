#!/bin/bash

board_model=$(cat /proc/device-tree/model)
case "$board_model" in
	"ArmSoM Sige5")
		usb3_num=1
		;;
	"Rockchip armsom sige5 Board")
		usb3_num=1
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
# 检测是否有包含 "new low-speed USB device" 的日志条目
count=$(dmesg | grep "usb 1-1.1" | grep -c "new low-speed USB device")
if [ ${count} -gt 0 ];then
    exit 0
else
    exit 1
fi