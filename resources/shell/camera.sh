#!/bin/bash

# 使用grep命令获取包含 "Detected OV00d850 sensor, REVISION 0xb2" 的行数
count=$(dmesg | grep "13850" | grep -c "Detected OV00d850 sensor, REVISION 0xb2")

# 判断count的值
if [ ${count} -eq 1 ]; then
    # 如果出现两次，返回0表示成功
    exit 0
else
    # 如果不是两次，返回1表示失败
    exit 1
fi
		