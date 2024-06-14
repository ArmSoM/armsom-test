#!/bin/bash

result=`dmesg | grep "mmcblk1" | wc -l`
if [ ${result} -ne 0 ];then
    exit 0
else
    exit 1
fi