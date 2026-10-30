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
    "armsom-aim7-io")
        export LC_ALL=C
        fail() { echo "[FAIL] $*"; exit 1; }
        pass() { echo "[PASS] $*"; exit 0; }
        need() { command -v "$1" >/dev/null || fail "缺少命令: $1"; }
        [ "$(id -u)" -eq 0 ] || fail '请通过 sudo 运行测试'
        aim7_m2_test() {
            need nmcli; need iw; need timeout
            local p net iface scan
            for p in /sys/bus/pci/devices/*; do
                [ -f "$p/vendor" ] && [ -f "$p/device" ] || continue
                [ $(cat "$p/vendor"):$(cat "$p/device") = 0x8086:0x2723 ] || continue
                [ -L "$p/driver" ] && [ $(basename "$(readlink -f "$p/driver")") = iwlwifi ] || fail 'AX200未绑定iwlwifi驱动，请检查iwlwifi-cc-a0-72.ucode固件'
                for net in "$p"/net/*; do
                    [ -d "$net" ] || continue
                    iface=${net##*/}
                    [ -d /sys/class/net/$iface/phy80211 ] || continue
                    nmcli radio wifi on || fail 'WiFi无法开启，请检查rfkill'
                    scan=$(timeout 25 nmcli -g BSSID device wifi list ifname "$iface" --rescan yes) || fail 'AX200无线扫描失败'
                    [ -n "$scan" ] || fail '未扫描到无线AP，请检查天线及周边AP'
                    echo "[INFO] AX200 ${p##*/}，驱动iwlwifi，无线接口$iface，扫描到$(printf '%s\n' "$scan" | wc -l)个AP"
                    pass 'M.2 AX200枚举、驱动加载和无线扫描正常'
                done
                fail 'AX200未生成无线接口，检查固件及驱动日志'
            done
            fail 'M.2未发现Intel AX200 (8086:2723)'
        }
        aim7_m2_test "$@"
        exit $?
        ;;

    "armsom-cm5-io")
        PCIE_BDF="0000:01:00.0"
        DEV="/dev/nvme0n1"
        ;;
    "armsom-sige7")
        PCIE_BDF="0002:21:00.0"  # 请根据 sige7 的实际 lspci 地址微调
        DEV="/dev/nvme0n1"
        ;;
    "armsom-cm7s-io")
        PCIE_BDF="0004:41:00.0"
        DEV="/dev/nvme0n1"
        ;;
    "armsom-p2pro")
        PCIE_BDF="0000:01:00.0"
        DEV="/dev/nvme0n1"
        ;;
    "sige6")
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