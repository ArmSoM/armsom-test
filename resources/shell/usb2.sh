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

# 检测是否有包含 "new low-speed USB device" 的日志条目
count=$(dmesg | grep "usb 1-1.2" | grep -c "new low-speed USB device")
if [ ${count} -gt 0 ];then
    exit 0
else
    exit 1
fi
