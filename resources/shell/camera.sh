#!/bin/bash

#gst-launch-1.0 v4l2src device=/dev/video11 ! video/x-raw,format=NV12,width=3840,height=2160, framerate=30/1 ! xvimagesink
#gst-launch-1.0 v4l2src device=/dev/video11 ! video/x-raw,format=NV12,width=3840,height=2160, framerate=30/1 ! waylandsink
gst-launch-1.0 v4l2src device=/dev/video-camera0 ! video/x-raw,format=NV12,width=3840,height=2160, framerate=30/1 ! waylandsink
		