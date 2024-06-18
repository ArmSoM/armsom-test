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

result=`dmesg | grep "unable to read the hardware clock" | wc -l`
if [ ${result} -ne 0 ];then
    exit 1
fi

result=`dmesg | grep "${rtc_string}" | wc -l`
if [ ${result} -ne 0 ];then
    exit 0
else
    exit 1
fi
