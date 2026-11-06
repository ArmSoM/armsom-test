#!/bin/bash

# 1. 获取 BOARD_ID
BOARD_ID=$(cat /proc/device-tree/compatible 2>/dev/null | tr '\0' '\n' | head -1 | cut -d ',' -f2 | cut -d '-' -f2-)


# 2. 根据 BOARD_ID 匹配 RTC 芯片所在的 I2C 总线标识
case "$BOARD_ID" in
    "armsom-aim7-io")
        rtc_string="rtc-hym8563 4-0051"
        ;;

    "armsom-cm5-io")
        rtc_string="rtc-hym8563 2-0051"
        ;;
    "sige6")
        rtc_string="rtc-hym8563 14-0051"
        ;;
    "w3" | "cm5-io" | "sige7" | "sige7s" | "armsom-cm7s-io" | *)
        rtc_string="rtc-hym8563 6-0051"
        ;;
esac

# AIM7 also checks the live RTC and verifies that its counter advances.
if [ "$BOARD_ID" = "armsom-aim7-io" ]; then
    for RTC in /sys/class/rtc/rtc*; do
        [ "$(cat "$RTC/name" 2>/dev/null)" = "$rtc_string" ] || continue
        hwclock --show --rtc "/dev/${RTC##*/}" || exit 1
        FIRST=$(cat "$RTC/since_epoch") || exit 1
        sleep 2
        SECOND=$(cat "$RTC/since_epoch") || exit 1
        DELTA=$((SECOND - FIRST))
        [ "$DELTA" -ge 1 ] && [ "$DELTA" -le 5 ] && {
            echo "[PASS] RTC 读取正常，计时增加 ${DELTA}s"; exit 0;
        }
        echo "[FAIL] RTC 未正常计时"; exit 1
    done
    echo "[FAIL] 未找到 $rtc_string"; exit 1
fi

# 3. 检测 dmesg 日志中是否有该 RTC 的有效注册状态
if dmesg | grep "$rtc_string" | grep -qE "registered|valid"; then
    echo "[PASS] RTC 检测成功 [$BOARD_ID]: $rtc_string"
    exit 0
else
    echo "[FAIL] RTC 检测失败 [$BOARD_ID]: 未找到 $rtc_string"
    exit 1
fi