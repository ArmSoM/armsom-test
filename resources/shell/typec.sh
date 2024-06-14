#!/bin/bash

result=`dmesg | grep "android_work: sent uevent USB_STATE=CONNECTED" | wc -l`
if [ ${result} -eq 0 ]; then
    exit 1
else
    exit 0
fi  