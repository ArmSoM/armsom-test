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
# count=$(dmesg | grep "usb 1-1.2" | grep -c "new low-speed USB device")
# if [ ${count} -gt 0 ];then
#     exit 0
# else
#     exit 1
# fi
# 使用grep命令获取包含 "Detected OV00d850 sensor, REVISION 0xb2" 的行数
count=$(dmesg | grep "imx219" | grep -c "Chip ID 0x0314")

# 判断count的值
if [ ${count} -eq 1 ]; then
    # 如果出现两次，返回0表示成功
    exit 0
else
    # 如果不是两次，返回1表示失败
    exit 1
fi
