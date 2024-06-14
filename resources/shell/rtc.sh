#!/bin/bash

result=`dmesg | grep "unable to read the hardware clock" | wc -l`
if [ ${result} -ne 0 ];then
    exit 1
fi

result=`dmesg | grep "rtc-hym8563 6-0051: registered" | wc -l`
if [ ${result} -ne 0 ];then
    exit 0
else
    exit 1
fi