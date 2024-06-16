#!/bin/bash

board_model=$(cat /proc/device-tree/model)
case "$board_model" in
	"ArmSoM Sige5")
		typec_num=2
		typec_check_cmd="ls /sys/class/typec/"
		;;
	"Rockchip armsom sige5 Board")
		typec_num=2
		typec_check_cmd="ls /sys/class/typec/"
		;;
	"armsom w3")
		typec_num=2
		typec_check_cmd="dmesg | grep \"android_work: sent uevent USB_STATE=CONNECTED\""
		;;
	*)
		typec_num=2
		typec_check_cmd="dmesg | grep \"android_work: sent uevent USB_STATE=CONNECTED\""
		;;
esac

result=`${typec_check_cmd}|wc -l`
if [ ${result} -eq ${typec_num} ]; then
    exit 0
else
    exit 1
fi
