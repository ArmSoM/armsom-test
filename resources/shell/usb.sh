#!/bin/bash

# 1. 统一解析 BOARD_ID
BOARD_ID=$(cat /proc/device-tree/compatible 2>/dev/null | tr '\0' '\n' | head -1 | cut -d ',' -f2 | cut -d '-' -f2-)

# 2. 根据不同板卡设置期望的 USB 3.0 和 USB 1.x (低速/全速键鼠) 数量
case "$BOARD_ID" in
    "armsom-cm5-io")
        REQ_USB3_COUNT=2  # 要求 2 个 USB 3.0 设备 (5000Mbps)
        REQ_USB1_COUNT=2  # 要求 2 个 USB 1.x 键盘/鼠标设备 (1.5Mbps / 12Mbps)
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

# 3. 实时读取 sysfs 中已连接设备的速率节点
# 5000  = USB 3.0 SuperSpeed
# 1.5 / 12 = USB 1.0 / 1.1 Low-Speed / Full-Speed
ACTUAL_USB3_COUNT=$(grep -h "^5000$" /sys/bus/usb/devices/*/speed 2>/dev/null | wc -l)
ACTUAL_USB1_COUNT=$(grep -hE "^(1\.5|12)$" /sys/bus/usb/devices/*/speed 2>/dev/null | wc -l)

echo "[INFO] 实际识别 -> USB3.0: ${ACTUAL_USB3_COUNT}个, USB1.x: ${ACTUAL_USB1_COUNT}个"

# 4. 双重条件校验
PASS=true

if [ "$ACTUAL_USB3_COUNT" -lt "$REQ_USB3_COUNT" ]; then
    echo "[FAIL] USB 3.0 接口识别未达标 (需要 $REQ_USB3_COUNT 个，实际识别到 $ACTUAL_USB3_COUNT 个)"
    PASS=false
fi

if [ "$ACTUAL_USB1_COUNT" -lt "$REQ_USB1_COUNT" ]; then
    echo "[FAIL] USB 1.x (键鼠) 接口识别未达标 (需要 $REQ_USB1_COUNT 个，实际识别到 $ACTUAL_USB1_COUNT 个)"
    PASS=false
fi

if [ "$PASS" = true ]; then
    echo "[PASS] USB 接口综合测试通过"
    exit 0
else
    exit 1
fi