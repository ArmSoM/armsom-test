#!/bin/bash

# 1. 获取 dmesg 日志（存入变量避免多次调用）
LOG=$(dmesg)

# 2. 从设备树获取当前板型 BOARD_ID
BOARD_ID=$(cat /proc/device-tree/compatible 2>/dev/null | tr '\0' '\n' | head -1 | cut -d ',' -f2 | cut -d '-' -f2-)

echo "[Info] 当前识别出的板卡类型: ${BOARD_ID}"

# 3. 检查传感器的具体函数
check_ov13850() {
    local count=$(echo "$LOG" | grep "13850" | grep -c "Detected OV00d850 sensor, REVISION 0xb2")
    [ "$count" -ge 1 ]
}

check_imx219() {
    local count=$(echo "$LOG" | grep -i "imx219" | grep -c -E "Detected|probe success|found")
    [ "$count" -ge 1 ]
}

# 4. 根据不同的板子类型执行不同的检测逻辑
case "$BOARD_ID" in
    "armsom-cm5-io")
        echo "正在对 cm5-io 进行摄像头检测..."
        # 例如：cm5-io 支持 imx219 或 ov13850 (可根据实际需求调整顺序或逻辑)
        if check_imx219; then
            echo "[PASS] 检测到 IMX219 摄像头！"
            exit 0
        elif check_ov13850; then
            echo "[PASS] 检测到 OV13850 摄像头！"
            exit 0
        else
            echo "[FAIL] cm5-io 未检测到任何已知摄像头！"
            exit 1
        fi
        ;;

    "armsom-sige7" | "armsom-sige5")
        echo "检测到 Sige 系列板卡 ($BOARD_ID)，执行适配检测逻辑..."
        if check_ov13850; then
            echo "[PASS] 检测到 OV13850 摄像头！"
            exit 0
        elif check_imx219; then
            echo "[PASS] 检测到 IMX219 摄像头！"
            exit 0
        else
            echo "[FAIL] Sige 板卡未检测到已知摄像头！"
            exit 1
        fi
        ;;

    *)
        echo "未知/未适配的板卡类型: ${BOARD_ID}，跳过或判定失败！"
        exit 1
        ;;
esac