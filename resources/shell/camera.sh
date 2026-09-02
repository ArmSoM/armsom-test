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
    
    "sige6")
        echo "检测到全志 Sige6 板卡，使用专用测试程序检测摄像头..."

        if ! command -v csi_test_mplane >/dev/null; then
            echo "[FAIL] csi_test_mplane 命令未找到，请确认程序路径"
            exit 1
        fi

        # 获取传感器列表
        MEDIA_OUTPUT=$(media-ctl -d /dev/media0 -p 2>/dev/null)
        if [ -z "$MEDIA_OUTPUT" ]; then
            echo "[FAIL] media-ctl 无法获取拓扑信息"
            exit 1
        fi

        HAS_IMX219=$(echo "$MEDIA_OUTPUT" | grep -q "imx219" && echo "yes" || echo "no")
        HAS_OV13850=$(echo "$MEDIA_OUTPUT" | grep -q "ov13850_mipi" && echo "yes" || echo "no")

        # 如果两个传感器都未检测到，直接失败
        if [ "$HAS_IMX219" = "no" ] && [ "$HAS_OV13850" = "no" ]; then
            echo "[FAIL] 未检测到任何传感器！"
            exit 1
        fi

        # 测试函数：尝试抓图，检查文件是否生成，失败后重试一次
        test_camera() {
            local dev=$1
            local w=$2
            local h=$3
            local mode=$4
            local tmp_dir="/tmp"

            rm -f ${tmp_dir}/fb${dev}_y${mode}_*.bin

            # 第一次尝试
            csi_test_mplane $dev 0 $w $h $tmp_dir $mode 5 >/dev/null 2>&1
            if ls ${tmp_dir}/fb${dev}_y${mode}_*.bin 1>/dev/null 2>&1; then
                rm -f ${tmp_dir}/fb${dev}_y${mode}_*.bin
                return 0
            fi

            # 重试一次
            sleep 1
            csi_test_mplane $dev 0 $w $h $tmp_dir $mode 5 >/dev/null 2>&1
            if ls ${tmp_dir}/fb${dev}_y${mode}_*.bin 1>/dev/null 2>&1; then
                rm -f ${tmp_dir}/fb${dev}_y${mode}_*.bin
                return 0
            fi

            return 1
        }

        SUCCESS_COUNT=0

        # 测试 IMX219（video0）
        if [ "$HAS_IMX219" = "yes" ]; then
            echo "检测到 IMX219，测试 /dev/video0 (1920x1080)..."
            if test_camera 0 1920 1080 5; then
                echo "[PASS] IMX219 抓图成功"
                SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
            else
                echo "[FAIL] IMX219 抓图失败"
            fi
        else
            echo "[WARN] 未检测到 IMX219 传感器，跳过"
        fi

        # 测试 OV13850（video8）
        if [ "$HAS_OV13850" = "yes" ]; then
            echo "检测到 OV13850，测试 /dev/video8 (2112x1568)..."
            if test_camera 8 2112 1568 5; then
                echo "[PASS] OV13850 抓图成功"
                SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
            else
                echo "[FAIL] OV13850 抓图失败"
            fi
        else
            echo "[WARN] 未检测到 OV13850 传感器，跳过"
        fi

        # 判断：是否所有检测到的传感器都成功？
        # 根据您的要求：两个摄像头都接上，所以期望成功数为2（如果两个都检测到）
        EXPECTED_COUNT=0
        [ "$HAS_IMX219" = "yes" ] && EXPECTED_COUNT=$((EXPECTED_COUNT + 1))
        [ "$HAS_OV13850" = "yes" ] && EXPECTED_COUNT=$((EXPECTED_COUNT + 1))

        if [ "$SUCCESS_COUNT" -eq "$EXPECTED_COUNT" ] && [ "$EXPECTED_COUNT" -gt 0 ]; then
            echo "[PASS] 所有已检测到的摄像头均抓图成功！"
            exit 0
        else
            echo "[FAIL] 部分摄像头抓图失败（成功 ${SUCCESS_COUNT}/${EXPECTED_COUNT}）"
            exit 1
        fi
        ;;

    *)
        echo "未知/未适配的板卡类型: ${BOARD_ID}，跳过或判定失败！"
        exit 1
        ;;
esac