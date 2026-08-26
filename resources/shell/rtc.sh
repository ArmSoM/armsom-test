#!/bin/bash

# 1. 获取 BOARD_ID
BOARD_ID=$(cat /proc/device-tree/compatible 2>/dev/null | tr '\0' '\n' | head -1 | cut -d ',' -f2 | cut -d '-' -f2-)

# 2. 根据 BOARD_ID 匹配 RTC 芯片所在的 I2C 总线标识
case "$BOARD_ID" in
    "armsom-cm5-io")
        rtc_string="rtc-hym8563 2-0051"
        ;;
    "w3" | "cm5-io" | "sige7" | *)
        rtc_string="rtc-hym8563 6-0051"
        ;;
esac

# 3. 检测 dmesg 日志中是否有该 RTC 的有效注册状态
if dmesg | grep "$rtc_string" | grep -qE "registered|valid"; then
    echo "[PASS] RTC 检测成功 [$BOARD_ID]: $rtc_string"
    exit 0
else
    echo "[FAIL] RTC 检测失败 [$BOARD_ID]: 未找到 $rtc_string"
    exit 1
fi