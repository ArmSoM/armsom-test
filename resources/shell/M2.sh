#!/bin/bash

# result=`lspci | grep Class | wc -l`  //buildroot
# if [ ${result} -ne 4 ];then
#     exit 1
# else
#     exit 0
# fi

# result=`ls /dev/nvme0* | grep nvme | wc -l`
# if [ ${result} -ge 2 ];then
#     exit 0
# else
#     exit 1
# fi

result=`lspci | grep memory | wc -l`
if [ ${result} -ge 1 ];then
    exit 0
else
    exit 1
fi