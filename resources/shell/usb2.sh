#!/bin/bash

result=`dmesg | grep "new high-speed USB device" | wc -l`
if [ ${result} -ge 3 ];then
    exit 0
else
    exit 1
fi  