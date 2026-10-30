#!/bin/bash

# 1. 自动读取并获取 BOARD_ID
BOARD_ID=$(cat /proc/device-tree/compatible 2>/dev/null | tr '\0' '\n' | head -1 | cut -d ',' -f2 | cut -d '-' -f2-)


echo "=== 开始网口测试 ==="
echo "[INFO] 当前检测到的 BOARD_ID: [$BOARD_ID]"

# 2. 根据 BOARD_ID 动态配置网口参数（请按实际板卡需求修改）
case "$BOARD_ID" in
    "armsom-aim7-io")
        export LC_ALL=C
        fail() { echo "[FAIL] $*"; exit 1; }
        pass() { echo "[PASS] $*"; exit 0; }
        need() { command -v "$1" >/dev/null || fail "缺少命令: $1"; }
        [ "$(id -u)" -eq 0 ] || fail '请通过 sudo 运行测试'
        aim7_eth_test() {
            need ip; need ping
            local iface=end0 gateway speed
            [ -d /sys/class/net/$iface ] || fail '未发现板载网口 end0'
            [ $(cat /sys/class/net/$iface/carrier) = 1 ] || fail '网线未连接'
            speed=$(cat /sys/class/net/$iface/speed)
            [ $speed = 1000 ] || fail "网口协商速率为 ${speed}Mbps，要求1000Mbps"
            ip -4 -o addr show dev "$iface" scope global | grep -q 'inet ' || fail '网口未获取IPv4地址'
            gateway=$(ip -4 route show default dev "$iface" | awk '/via/ {print $3; exit}')
            [ -n "$gateway" ] || fail '网口没有默认网关'
            echo "[INFO] $iface ${speed}Mbps，测试网关 $gateway"
            ping -I "$iface" -c 3 -W 2 "$gateway" || fail '绑定有线网口的网关连通测试失败'
            pass '千兆网口及网络连通性正常'
        }
        aim7_eth_test "$@"
        exit $?
        ;;
  "armsom-cm5-io")
        IFACE="end0"
        EXPECTED_SPEED=1000
        TARGET_IP="192.168.10.1"
        ;;
    "armsom-w3")
        IFACE="eth0"
        EXPECTED_SPEED=1000
        TARGET_IP="192.168.10.1"
        ;;
    "armsom-p2pro")
        IFACE="end0"
        EXPECTED_SPEED=100   # 百兆网口示例
        TARGET_IP="192.168.10.1"
        ;;
    "sige6")
        IFACE="eth0"
        EXPECTED_SPEED=1000
        TARGET_IP="192.168.10.1"
        ;;
    "armsom-sige7s")
        IFACE="enP4p65s0"
        EXPECTED_SPEED=1000
        TARGET_IP="192.168.10.1"
        ;;
    "armsom-cm7s-io")
        IFACE="end1"
        EXPECTED_SPEED=1000
        TARGET_IP="192.168.10.1"
        ;;
    *)
        # 未匹配到具体型号时的默认策略
        IFACE="end0"
        EXPECTED_SPEED=1000
        TARGET_IP="192.168.10.1"
        echo "[WARN] 未知板卡类型 [$BOARD_ID]，使用默认配置 (网口: $IFACE)"
        ;;
esac

echo "[INFO] 测试网口: $IFACE, 预期速率: ${EXPECTED_SPEED}Mbps, 目标网关: $TARGET_IP"

# 3. 检测网卡节点是否存在
if [ ! -d "/sys/class/net/$IFACE" ]; then
    echo "[FAIL] 网卡 $IFACE 不存在"
    exit 1
fi

# 4. 检测物理网线连接状态 (Carrier)
CARRIER=$(cat /sys/class/net/$IFACE/carrier 2>/dev/null)
if [ "$CARRIER" != "1" ]; then
    echo "[FAIL] 网线未插入或链路处于 Down 状态"
    exit 2
fi
echo "[PASS] 物理网线连接正常"

# 5. 读取网口速率和双工模式并校验
SPEED=$(cat /sys/class/net/$IFACE/speed 2>/dev/null)
DUPLEX=$(cat /sys/class/net/$IFACE/duplex 2>/dev/null)
echo "[INFO] 实际协商速率: ${SPEED} Mbps, 双工: ${DUPLEX}"

if [ "$SPEED" -lt "$EXPECTED_SPEED" ]; then
    echo "[WARN] 网口速率异常 (实际: ${SPEED}M, 预期: ${EXPECTED_SPEED}M)"
fi

# 6. 检测 IPv4 地址获取情况
IP=$(ip -4 addr show $IFACE | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
if [ -z "$IP" ]; then
    echo "[FAIL] 未获取到 IPv4 地址"
    exit 3
fi
echo "[PASS] 已获取 IP 地址: $IP"


echo "=== 板卡 [$BOARD_ID] 网口 [$IFACE] 测试完成：PASS ==="
exit 0