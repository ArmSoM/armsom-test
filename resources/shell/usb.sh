#!/bin/bash

# 1. 统一解析 BOARD_ID
BOARD_ID=$(cat /proc/device-tree/compatible 2>/dev/null | tr '\0' '\n' | head -1 | cut -d ',' -f2 | cut -d '-' -f2-)


# 2. 根据不同板卡设置需求
case "$BOARD_ID" in
    "armsom-aim7-io")
        export LC_ALL=C
        fail() { echo "[FAIL] $*"; exit 1; }
        pass() { echo "[PASS] $*"; exit 0; }
        need() { command -v "$1" >/dev/null || fail "缺少命令: $1"; }
        [ "$(id -u)" -eq 0 ] || fail '请通过 sudo 运行测试'
        aim7_usb_test() {
            local d intf cls speed hid proto total=0 super=0 hids=0
            for d in /sys/bus/usb/devices/*; do
                [ -f "$d/idVendor" ] && [ -f "$d/speed" ] || continue
                cls=$(cat "$d/bDeviceClass")
                [ $cls != 09 ] || continue # Exclude root hubs and carrier hubs.
                # AX200 Bluetooth is internal, not a Type-A test device.
                [ $(cat "$d/idVendor"):$(cat "$d/idProduct") != 8087:0029 ] || continue
                total=$((total+1)); speed=$(cat "$d/speed"); hid=0
                if awk -v s="$speed" 'BEGIN {exit !(s>=5000)}'; then super=$((super+1)); fi
                for intf in "$d":*; do
                    [ -f "$intf/bInterfaceClass" ] || continue
                    [ $(cat "$intf/bInterfaceClass") = 03 ] || continue
                    proto=$(cat "$intf/bInterfaceProtocol")
                    [ $proto = 01 ] || [ $proto = 02 ] && hid=1
                done
                hids=$((hids+hid)) # Count physical devices once, not HID interfaces.
                echo "[INFO] ${d##*/} $(cat "$d/idVendor"):$(cat "$d/idProduct") speed=${speed}Mbps keyboard/mouse=$hid"
            done
            echo "[INFO] USB设备=$total，USB3=$super，键鼠设备=$hids；要求 >=4、>=2、>=2"
            [ "$total" -ge 4 ] && [ "$super" -ge 2 ] && [ "$hids" -ge 2 ] || fail 'USB数量、速率或键鼠数量未达标'
            pass 'USB检测通过'
        }
        aim7_usb_test "$@"
        exit $?
        ;;

    "armsom-cm5-io")
        REQ_USB2_3_COUNT=2 # 要求 USB2.0 + USB3.0 设备总数达到 2 个
        REQ_USB3_COUNT=0
        REQ_USB1_COUNT=2   # 要求 2 个 USB 1.x 键鼠设备 (1.5Mbps / 12Mbps)
        ;;
    "sige5")
        REQ_USB2_3_COUNT=0
        REQ_USB3_COUNT=1
        REQ_USB1_COUNT=0
        ;;
    "sige6")
        REQ_USB2_3_COUNT=2  # 要求 USB2.0 + USB3.0 设备总数达到 2 个
        REQ_USB3_COUNT=0
        REQ_USB1_COUNT=2   # 要求 2 个 USB 1.x 键鼠设备 (1.5Mbps / 12Mbps)
        ;;
    "armsom-sige7s")
        REQ_USB2_3_COUNT=2 # 要求 USB2.0 + USB3.0 设备总数达到 2 个
        REQ_USB3_COUNT=0
        REQ_USB1_COUNT=2   # 要求 2 个 USB 1.x 键鼠设备 (1.5Mbps / 12Mbps)
        ;;
    "armsom-cm7s-io")
        REQ_USB2_3_COUNT=2 # 要求 USB2.0 + USB3.0 设备总数达到 2 个
        REQ_USB3_COUNT=0
        REQ_USB1_COUNT=2   # 要求 2 个 USB 1.x 键鼠设备 (1.5Mbps / 12Mbps)
        ;;
    "w3" | "sige7" | *)
        REQ_USB2_3_COUNT=0
        REQ_USB3_COUNT=2
        REQ_USB1_COUNT=0
        ;;
esac

if [ "$BOARD_ID" = "armsom-cm5-io" ] || [ "$BOARD_ID" = "armsom-sige7s" ] || [ "$BOARD_ID" = "sige6" ] || [ "$BOARD_ID" = "armsom-cm7s-io" ]; then
    echo "[INFO] 当前板卡: $BOARD_ID | 目标需求 -> (USB3.0+USB2.0): ${REQ_USB2_3_COUNT}个, USB1.x(键鼠): ${REQ_USB1_COUNT}个"
else
    echo "[INFO] 当前板卡: $BOARD_ID | 目标需求 -> USB3.0: ${REQ_USB3_COUNT}个, USB1.x(键鼠): ${REQ_USB1_COUNT}个"
fi
echo "------------------------------------------------------------------"

ACTUAL_USB3_COUNT=0
ACTUAL_USB2_COUNT=0
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
    elif [ "$SPEED" = "480" ]; then
        ACTUAL_USB2_COUNT=$((ACTUAL_USB2_COUNT + 1))
        echo "[FIND USB2.0]     路径: $DEV_PATH | 速率: ${SPEED}M | 名称: $DEV_NAME"
    elif [ "$SPEED" = "1.5" ] || [ "$SPEED" = "12" ]; then
        ACTUAL_USB1_COUNT=$((ACTUAL_USB1_COUNT + 1))
        echo "[FIND USB1.x]     路径: $DEV_PATH | 速率: ${SPEED}M | 名称: $DEV_NAME"
    fi
done

echo "------------------------------------------------------------------"
ACTUAL_USB2_3_TOTAL=$((ACTUAL_USB3_COUNT + ACTUAL_USB2_COUNT))
echo "[INFO] 统计结果 -> USB3.0/3.1: ${ACTUAL_USB3_COUNT}个, USB2.0: ${ACTUAL_USB2_COUNT}个 (合计: ${ACTUAL_USB2_3_TOTAL}个), USB1.x: ${ACTUAL_USB1_COUNT}个"

PASS=true

if [ "$BOARD_ID" = "armsom-cm5-io" ] || [ "$BOARD_ID" = "armsom-sige7s" ] || [ "$BOARD_ID" = "sige6" ] || [ "$BOARD_ID" = "armsom-cm7s-io" ]; then
    # 判断 USB2.0 + USB3.0 总数是否达标
    if [ "$ACTUAL_USB2_3_TOTAL" -lt "$REQ_USB2_3_COUNT" ]; then
        echo "[FAIL] USB 2.0 + 3.0 接口识别未达标 (需要至少 $REQ_USB2_3_COUNT 个，实际识别到 $ACTUAL_USB2_3_TOTAL 个)"
        PASS=false
    fi
else
    # 其它板卡沿用原逻辑（严格判断 USB 3.0 数量）
    if [ "$ACTUAL_USB3_COUNT" -lt "$REQ_USB3_COUNT" ]; then
        echo "[FAIL] USB 3.0 接口识别未达标 (需要 $REQ_USB3_COUNT 个，实际识别到 $ACTUAL_USB3_COUNT 个)"
        PASS=false
    fi
fi

# 判断 USB 1.x (键鼠) 数量
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