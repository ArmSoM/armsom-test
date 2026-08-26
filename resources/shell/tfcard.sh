#!/bin/bash

# 1. 获取当前板卡型号 (BOARD_ID)
BOARD_ID=$(cat /proc/device-tree/compatible 2>/dev/null | tr '\0' '\n' | head -1 | cut -d ',' -f2 | cut -d '-' -f2-)
echo "[TFCard Check] 当前板卡型号: ${BOARD_ID}"

# 2. 根据不同板型指定 TF 卡对应的块设备节点
# 注：根据 RK3588 / RK3576 / RK3568 等不同总线设计，SDMMC 节点可能有所不同
case "$BOARD_ID" in
    "armsom-cm5-io")
        DEV_NODE="/dev/mmcblk1"
        ;;
    "armsom-sige7" | "armsom-sige5")
        DEV_NODE="/dev/mmcblk1"
        ;;
    *)
        # 默认匹配规则：查找系统中非 eMMC 的 SD/TF 块设备 (排除 eMMC 的 mmcblk0/boot0 等)
        DEV_NODE=$(ls /dev/mmcblk[1-9] 2>/dev/null | head -n 1)
        ;;
esac

# 3. 判断设备节点是否存在
if [ -z "$DEV_NODE" ] || [ ! -b "$DEV_NODE" ]; then
    echo "[FAIL] 未在系统中发现 TF 卡设备节点！"
    exit 1
fi

echo "[INFO] 识别到 TF 卡设备节点: ${DEV_NODE}"

# 4. 获取并校验卡容量大小 (单位：扇区/字节)
SIZE_BYTES=$(cat /sys/class/block/$(basename ${DEV_NODE})/size 2>/dev/null)
if [ -z "$SIZE_BYTES" ] || [ "$SIZE_BYTES" -le 0 ]; then
    echo "[FAIL] 无法读取 TF 卡容量，卡可能损坏或未插紧！"
    exit 1
fi

# 转换容量为 MB (每个扇区 512 字节)
SIZE_MB=$((SIZE_BYTES * 512 / 1024 / 1024))
echo "[INFO] TF 卡检测到的总容量: ${SIZE_MB} MB"

# 5. 执行数据总线读写实测（读取前 4MB 数据，校验物理 Pin 针脚与数据线收发是否正常）
echo "[INFO] 正在执行 TF 卡物理总线数据读取测试..."
dd if=${DEV_NODE} of=/dev/null bs=1M count=4 status=none 2>/dev/null

if [ $? -eq 0 ]; then
    echo "[PASS] TF 卡检测通过！容量: ${SIZE_MB}MB"
    exit 0
else
    echo "[FAIL] TF 卡数据读取异常，总线通信失败！"
    exit 1
fi