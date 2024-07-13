#!/bin/bash

# 执行 find 命令查找设备列表
find_output=$(find /sys/bus/sdio/devices/*)

# 检查 find 命令的输出是否为空
if [ -z "$find_output" ]; then
    return 1
    echo "failed"
else   
    # 遍历每个设备路径
    for dev_path in $find_output; do
        uevent_file="$dev_path/uevent"
        
        # 检查 uevent 文件是否存在并读取内容
        if [ -f "$uevent_file" ]; then
            uevent_content=$(cat "$uevent_file")
            
            # 检查 uevent 内容中是否包含 "02D0:AAE8"
            if [[ "$uevent_content" == *"02D0:AAE8"* ]]; then
                return_code=0
                echo "succes"
            else
                return_code=1
                echo "failed"    
            fi
        fi
    done
    
    echo "$return_code"
    return "$return_code"
fi