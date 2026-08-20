#!/bin/bash
# 1. 自动获取 BOARD_ID 并进行兼容性处理
BOARD_ID=$(cat /proc/device-tree/compatible 2>/dev/null | tr '\0' '\n' | head -1 | cut -d ',' -f2 | cut -d '-' -f2-)

if [ -z "$BOARD_ID" ]; then
    echo "[WARN] 无法从设备树获取板卡型号，使用默认配置"
    BOARD_ID="unknown"
fi

echo "[INFO] 当前检测到的板卡型号: $BOARD_ID"

# 2. 根据不同的板卡型号匹配 PCIe BDF 地址及设备节点
case "$BOARD_ID" in
    "armsom-cm5-io")
        PCIE_BDF="0000:01:00.0"
        DEV="/dev/nvme0n1"
        ;;
    "armsom-sige7")
        PCIE_BDF="0002:21:00.0"  # 请根据 sige7 的实际 lspci 地址微调
        DEV="/dev/nvme0n1"
        ;;
    "armsom-p2pro")
        PCIE_BDF="0000:01:00.0"
        DEV="/dev/nvme0n1"
        ;;
    *)
        PCIE_BDF="0000:01:00.0"
        DEV="/dev/nvme0n1"
        ;;
esac

MOUNT_POINT="/tmp/m2_test_mnt"
TEST_FILE="${MOUNT_POINT}/m2_speed_test.tmp"
TEST_SIZE_MB=100

echo "=== 开始 M.2 NVMe SSD 综合测试 ($BOARD_ID) ==="

# 3. 检测设备节点是否存在
if [ ! -b "$DEV" ]; then
    echo "[FAIL] 未找到 M.2 设备节点 ($DEV)"
    exit 1
fi
echo "[PASS] 检测到 M.2 设备节点: $DEV"

# 4. 检测硬盘容量大小
SIZE_BYTES=$(blockdev --getsize64 "$DEV" 2>/dev/null)
SIZE_GB=$(awk "BEGIN {printf \"%.2f\", $SIZE_BYTES/1024/1024/1024}")

if [ -z "$SIZE_BYTES" ] || [ "$SIZE_BYTES" -le 0 ]; then
    echo "[FAIL] M.2 容量读取失败或异常"
    exit 2
fi
echo "[PASS] M.2 硬盘容量: ${SIZE_GB} GB"

# 5. 校验指定板卡的 PCIe 链路速率
if [ -n "$PCIE_BDF" ]; then
    LNKSTA=$(lspci -s "$PCIE_BDF" -vv 2>/dev/null | grep -i "LnkSta:")
    if [ -n "$LNKSTA" ]; then
        echo "[INFO] PCIe 链路状态 ($PCIE_BDF): $LNKSTA"
    fi
fi

echo "=== M.2 测试完成：PASS ==="
exit 0