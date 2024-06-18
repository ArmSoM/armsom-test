#!/bin/bash

# 检测是否有包含 "new low-speed USB device" 的日志条目
count=$(dmesg | grep "mmc" | grep -c "SDHC card")
if [ ${count} -gt 0 ];then
    exit 0
else
    exit 1
fi
