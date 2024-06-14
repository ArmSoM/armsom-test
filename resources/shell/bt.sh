#!/bin/bash

bt_pcba_test > /dev/null
sleep 5
hciconfig hci0 up > /dev/null && hciconfig -a | grep UP