#!/bin/bash

# 使用grep命令获取包含 "Detected OV00d850 sensor, REVISION 0xb2" 的行数
count=$(dmesg | grep "13850" | grep -c "Detected OV00d850 sensor, REVISION 0xb2")

# 判断count的值
if [ ${count} -eq 1 ]; then
    # 如果出现两次，返回0表示成功
    exit 0
else
    # 如果不是两次，返回1表示失败
    exit 1
fi
		


# #!/bin/bash

# BOARD_ID=$(cat /proc/device-tree/compatible | tr '\0' '\n' | head -1 | cut -d ',' -f2 | cut -d '-' -f2-)

# case "$BOARD_ID" in
#     "armsom-cm5-io")

#         gst-launch-1.0 v4l2src device=/dev/video11 ! video/x-raw,format=NV12,width=2112,height=1568,framerate=30/1 ! videoscale ! video/x-raw,width=640,height=480 ! xvimagesink
#         ;;
#     "armsom-sige7" | "armsom-sige5")
#         echo "检测到 Sige 系列板卡，执行适配逻辑..."
#         ;;
#     *)
#         echo "未知的板卡类型: $BOARD_ID，终止测试！"
#         exit 1
#         ;;
# esac