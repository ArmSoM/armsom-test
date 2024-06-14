#!/bin/bash

ifconfig wlan0 down > /dev/null && ifconfig wlan0 up > /dev/null && ifconfig wlan0 | grep UP