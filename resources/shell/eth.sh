#!/bin/bash

#udhcpc -t 5 -n -i enP4p65s0

#dmesg | grep "enP4p65s0: link up"

# result=`dmesg | grep "enP4p65s0: link up"`
# if [ ${result} -eq 0 ];then
#     exit 1
# else
#     exit 0
# fi

# 使用grep命令获取包含 "Detected OV00d850 sensor, REVISION 0xb2" 的行数
count=$(dmesg | grep -c "Link is Up")

# 判断count的值
if [ ${count} -eq 1 ]; then
    # 如果出现两次，返回0表示成功
    exit 0
else
    # 如果不是两次，返回1表示失败
    exit 1
fi