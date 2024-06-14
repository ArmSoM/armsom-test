#!/bin/bash

#udhcpc -t 5 -n -i enP4p65s0

#dmesg | grep "enP4p65s0: link up"

# result=`dmesg | grep "enP4p65s0: link up"`
# if [ ${result} -eq 0 ];then
#     exit 1
# else
#     exit 0
# fi

 HOST=8.8.8.8
  log "Ping check : $HOST"
  ping -c 4 "$HOST" > /dev/null
  if [ $? -eq 0 ];then
    exit 0
  else
    exit 1
  fi
