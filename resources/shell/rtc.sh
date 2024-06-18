#!/bin/bash

board_model=$(cat /proc/device-tree/model)
case "$board_model" in
	"ArmSoM Sige5")
		rtc_string="rtc-hym8563 2-0051: rtc information is valid"
		;;
	"Rockchip armsom sige5 Board")
		rtc_string="rtc-hym8563 2-0051: rtc information is valid"
		;;
	"armsom w3")
		rtc_string="rtc-hym8563 6-0051: registered"
		;;
	*)
		rtc_string="rtc-hym8563 6-0051: registered"
		;;
esac


# 检测rtc是否有包含 "registered as rtc0" 的日志条目
count=$(dmesg | grep "rtc-hym8563" | grep -c "registered as rtc0")
if [ ${count} -gt 0 ];then
    exit 0
else
    exit 1
fi
