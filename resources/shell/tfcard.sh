#!/bin/bash

# 1. 统一解析 BOARD_ID
BOARD_ID=$(cat /proc/device-tree/compatible 2>/dev/null | tr '\0' '\n' | head -1 | cut -d ',' -f2 | cut -d '-' -f2-)

# 2. 根据不同板卡设置期望的 USB 3.0 和 USB 1.x 数量
case "$BOARD_ID" in
    "armsom-cm5-io" )
        REQ_USB3_COUNT=2  # 要求 2 个外接 USB 3.0 设备 (5000Mbps)
        REQ_USB1_COUNT=2  # 要求 2 个外接 USB 1.x 键鼠设备 (1.5Mbps / 12Mbps)
        ;;
    "sige5")
        REQ_USB3_COUNT=1
        REQ_USB1_COUNT=0
        ;;
    "w3" | "sige7" | *)
        REQ_USB3_COUNT=2
        REQ_USB1_COUNT=0
        ;;
esac

echo "[INFO] 当前板卡: $BOARD_ID | 目标需求 -> USB3.0: ${REQ_USB3_COUNT}个, USB1.x(键鼠): ${REQ_USB1_COUNT}个"

# 3. 实时读取 sysfs 并过滤 Hub 节点（Hub 的 bDeviceClass 为 09）
ACTUAL_USB3_COUNT=0
ACTUAL_USB1_COUNT=0

for dev in /sys/bus/usb/devices/*; do
    # 过滤非节点目录
    [ -f "$dev/speed" ] || continue
    
    # 获取设备 Class，过滤掉根控制器及外接 Hub (bDeviceClass 为 09)
    dev_class=""
    [ -f "$dev/bDeviceClass" ] && dev_class=$(cat "$dev/bDeviceClass" 2>/dev/null)
    [ "$dev_class" = "09" ] && continue

    # 获取当前外接设备的速率
    speed=$(cat "$dev/speed" 2>/dev/null)

    # 统计匹配项
    case "$speed" in
        "5000")
            ACTUAL_USB3_COUNT=$((ACTUAL_USB3_COUNT + 1))
            ;;
        "1.5" | "12")
            ACTUAL_USB1_COUNT=$((ACTUAL_USB1_COUNT + 1))
            ;;
    esac
done

echo "[INFO] 实际外接识别 -> USB3.0: ${ACTUAL_USB3_COUNT}个, USB1.x: ${ACTUAL_USB1_COUNT}个"

# 4. 双重条件校验
PASS=true

if [ "$ACTUAL_USB3_COUNT" -lt "$REQ_USB3_COUNT" ]; then
    echo "[FAIL] USB 3.0 接口识别未达标 (需要 $REQ_USB3_COUNT 个外接设备，实际识别到 $ACTUAL_USB3_COUNT 个)"
    PASS=false
fi

if [ "$ACTUAL_USB1_COUNT" -lt "$REQ_USB1_COUNT" ]; then
    echo "[FAIL] USB 1.x (键鼠) 接口识别未达标 (需要 $REQ_USB1_COUNT 个外接设备，实际识别到 $ACTUAL_USB1_COUNT 个)"
    PASS=false
fi

if [ "$PASS" = true ]; then
    echo "[PASS] USB 接口综合测试通过"
    exit 0
else
    exit 1
fi