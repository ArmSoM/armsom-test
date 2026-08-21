#!/bin/bash

# 1. 统一解析 BOARD_ID
BOARD_ID=$(cat /proc/device-tree/compatible 2>/dev/null | tr '\0' '\n' | head -1 | cut -d ',' -f2 | cut -d '-' -f2-)

# 2. 根据不同板卡设置需求
case "$BOARD_ID" in
    "armsom-cm5-io")
        REQ_USB3_COUNT=2  # 要求 2 个 USB 3.0 设备 (5000Mbps)
        REQ_USB1_COUNT=2  # 要求 2 个 USB 1.x 键鼠设备 (1.5Mbps / 12Mbps)
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
echo "------------------------------------------------------------------"

ACTUAL_USB3_COUNT=0
ACTUAL_USB1_COUNT=0

for dev_dir in /sys/bus/usb/devices/*; do
    # 过滤 1: 忽略接口节点（路径带冒号，如 1-1:1.0，使用 case 语法兼容 dash/sh）
    case "$dev_dir" in
        *:*) continue ;;
    esac

    # 过滤 2: 必须包含 speed 节点
    [ -f "$dev_dir/speed" ] || continue

    # 过滤 3: 根据 bDeviceClass 过滤 Hub 节点 (09 表示 USB Hub)
    DEV_CLASS=""
    [ -f "$dev_dir/bDeviceClass" ] && DEV_CLASS=$(cat "$dev_dir/bDeviceClass" 2>/dev/null)
    if [ "$DEV_CLASS" = "09" ] || [ "$DEV_CLASS" = "0x09" ]; then
        continue
    fi

    # 提取设备信息
    SPEED=$(cat "$dev_dir/speed" 2>/dev/null)
    DEV_NAME=$(cat "$dev_dir/product" 2>/dev/null || echo "Unknown Device")
    DEV_PATH=$(basename "$dev_dir")

    # 匹配速率
    if [ "$SPEED" = "5000" ] || [ "$SPEED" = "10000" ]; then
        ACTUAL_USB3_COUNT=$((ACTUAL_USB3_COUNT + 1))
        echo "[FIND USB3.0/3.1] 路径: $DEV_PATH | 速率: ${SPEED}M | 名称: $DEV_NAME"
    elif [ "$SPEED" = "1.5" ] || [ "$SPEED" = "12" ]; then
        ACTUAL_USB1_COUNT=$((ACTUAL_USB1_COUNT + 1))
        echo "[FIND USB1.x]     路径: $DEV_PATH | 速率: ${SPEED}M | 名称: $DEV_NAME"
    elif [ "$SPEED" = "480" ]; then
        echo "[FIND USB2.0]     路径: $DEV_PATH | 速率: ${SPEED}M | 名称: $DEV_NAME (注: 属于USB 2.0)"
    fi
done

echo "------------------------------------------------------------------"
echo "[INFO] 统计结果 -> USB3.0/3.1: ${ACTUAL_USB3_COUNT}个, USB1.x: ${ACTUAL_USB1_COUNT}个"

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