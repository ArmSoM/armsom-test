#!/bin/bash

# 1. 获取 BOARD_ID
BOARD_ID=$(cat /proc/device-tree/compatible 2>/dev/null | tr '\0' '\n' | head -1 | cut -d ',' -f2 | cut -d '-' -f2-)


# 2. 根据 BOARD_ID 匹配 RTC 芯片所在的 I2C 总线标识
case "$BOARD_ID" in
    "armsom-aim7-io")
        export LC_ALL=C
        fail() { echo "[FAIL] $*"; exit 1; }
        pass() { echo "[PASS] $*"; exit 0; }
        need() { command -v "$1" >/dev/null || fail "缺少命令: $1"; }
        [ "$(id -u)" -eq 0 ] || fail '请通过 sudo 运行测试'
        aim7_rtc_test() {
            need hwclock
            local r first second delta
            for r in /sys/class/rtc/rtc*; do
                [ -f "$r/name" ] || continue
                [ "$(cat "$r/name")" = 'rtc-hym8563 4-0051' ] || continue
                hwclock --show --rtc "/dev/${r##*/}" || fail 'RTC读取失败或时间无效，请先校时'
                first=$(cat "$r/since_epoch") || fail 'RTC计时读取失败'
                sleep 2
                second=$(cat "$r/since_epoch") || fail 'RTC计时读取失败'
                delta=$((second-first))
                [ "$delta" -ge 1 ] && [ "$delta" -le 5 ] || fail "RTC未正常走时: delta=$delta"
                pass "RTC位于i2c4，读取及走时正常（${delta}s）"
            done
            fail '未发现i2c4上的HYM8563 RTC'
        }
        aim7_rtc_test "$@"
        exit $?
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

# 3. 检测 dmesg 日志中是否有该 RTC 的有效注册状态
if dmesg | grep "$rtc_string" | grep -qE "registered|valid"; then
    echo "[PASS] RTC 检测成功 [$BOARD_ID]: $rtc_string"
    exit 0
else
    echo "[FAIL] RTC 检测失败 [$BOARD_ID]: 未找到 $rtc_string"
    exit 1
fi