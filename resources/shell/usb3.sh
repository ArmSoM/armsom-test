#!/bin/bash

result=`dmesg | grep " new SuperSpeed Gen 1 USB device" | wc -l`
if [ ${result} -ge 2 ];then
    exit 0
else
    exit 1
fi  