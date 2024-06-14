#!/bin/bash

v4l2-ctl -d /dev/video20 --set-fmt-video=width=1920,height=1080,pixelformat=NV24 --stream-mmap=3 --stream-skip=100 --stream-to=/oem/NV24.yuv --stream-count=1 --stream-poll
		