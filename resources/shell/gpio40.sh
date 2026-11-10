#!/bin/bash
# 40PIN LED治具测试：各板型在下面的 case 中配置 GPIO40，共用 gpio40_test()。
#
# 引脚配置：
#   GPIO40 填 Linux GPIO 编号，不是40PIN排针的物理脚号；不要重复填写。
#   Rockchip 编号 = bank * 32 + group * 8 + X，A/B/C/D 对应 group 0/1/2/3。
#   例如 GPIO1_B2 = 1 * 32 + 1 * 8 + 2 = 42；Sige6 沿用全志的GPIO编号。
#   电源、GND、调试串口及明确预留的外设引脚不加入列表（如 AIM7 PIN32）。
#   新增板型时先核对原理图和设备树，在 case 中添加对应的 GPIO40 列表。
#
# 执行方法（需先接好LED治具）：
#   bash gpio40.sh                  仅列出候选GPIO，不操作引脚。
#   sudo bash gpio40.sh --run-gpio   开始闪烁；界面的“开始”按钮调用此命令。
#
# 共用检测流程：
#   1. 使用 flock 防止重复并发运行，并读取 debugfs 的 pinmux-pins 检查占用。
#   2. 仅操作 MUX 和 GPIO 均为 UNCLAIMED、且未被 sysfs 导出的候选引脚；
#      已占用或无法唯一确认状态的引脚跳过，不强制修改外设复用。
#      无法读取 pinctrl 信息或没有可用GPIO时，返回失败。
#   3. 导出可用GPIO并设置输出低电平，然后统一高/低各0.5秒，循环10次，
#      闪烁约10秒。正常结束、出错或收到可捕获的退出信号时，将本次导出的
#      GPIO设为输入并释放；不接管其他程序已导出的GPIO，可再次点击开始重测。
#   4. 脚本执行成功只代表闪烁流程完成，不能自动判定LED是否正常。
#      界面显示“等待人工确认”，操作员观察后点击“通过”才标记测试通过。
#
# 依赖：Bash、root权限、flock、sysfs GPIO及可读取的debugfs pinctrl信息。
export LC_ALL=C
BOARD_ID=$(tr '\0' '\n' < /proc/device-tree/compatible | head -1 | cut -d, -f2)
case "$BOARD_ID" in rk[0-9]*-*) BOARD_ID=${BOARD_ID#*-} ;; esac

case "$BOARD_ID" in
    armsom-aim7-io)
        # Omit PIN3/5,11/36,15,27/28,31/33 (RTC/cameras), PIN32 (LCD).
        GPIO40="128 46 47 129 58 61 59 42 41 56 43 44 45 103 130 57 133 137"
        ;;
    armsom-cm5-io)
        # CM5-IO V1.1 第7页 + CM5 V1.3 第11/12页；以下为物理PIN:GPIO。
        # 3:140 5:141 7:20 16:89 18:88 19:97 21:98 23:96 24:99。
        # 排除 PIN8/10 GPIO28/29（调试串口）；PIN22（ADC，不能作GPIO）。
        # 排除 PIN27/29 GPIO111/112（CAM2 I2C）、PIN31 GPIO126（CAM2复位），
        # PIN28 GPIO94（与风扇PWM共用）；不操作电源、GND和底板未连接脚：
        # PIN11/12/13/15/26/32/33/35/36/37/38/40。
        # PIN16/18 还复用红/绿LED控制、UART4、I2C6；被驱动占用时自动跳过。
        GPIO40="140 141 20 89 88 97 98 96 99"
        ;;
    armsom-cm7s-io)
        # J4, schematic V1.0 page8. GPIO13/14 (PIN8/10): debug UART.
        # GPIO63/62 (PIN3/5) also carry CAM4/CAM3 clocks: skip when claimed.
        GPIO40="63 62 39 130 131 18 42 41 43 57 58 59 139 52 54 106 32 33 40
                44 45 56 138 61 20 21"
        ;;
    armsom-sige7)
        # Sige7 V1.1 原理图第22页 J4，以下为物理PIN:GPIO。
        # 3:139 5:138 7:115 11:113 12:109 13:112 15:111 18:148
        # 19:42 21:41 23:43 24:44 26:45 27:150 28:149 29:63
        # 32:114 33:103 35:110 36:105 38:106 40:107。
        # 排除 PIN8/10（UART2调试串口）、PIN16（蓝牙UART8 RTS）、
        # PIN22（ADC）、PIN31（摄像头时钟复用）、PIN37（REFCLK复用）、
        # 电源和GND。已被驱动占用的候选GPIO在运行时跳过。
        GPIO40="139 138 115 113 109 112 111 148 42 41 43 44 45 150 149
                63 114 103 110 105 106 107"
        ;;
    armsom-sige7s)
        # Sige7s V1.0 第23页 CON1，以实际网络名及SoC引脚定义为准，
        # 不使用连接器符号内遗留的GPIO文字；以下为物理PIN:GPIO。
        # 3:29 5:28 7:47 11:128 12:39 13:129 15:130 16:33 18:32
        # 19:42 21:41 22:40 23:43 24:44 26:45 27:136 28:137
        # 29:131 31:132 32:105 33:133 35:134 36:138 37:135 38:139 40:115。
        # 排除 PIN8/10 GPIO13/14（UART2调试串口）、电源和GND。
        # 当前SDK默认占用：PIN7 SPDIF、PIN16/18 UART6、PIN27/28 RTC I2C6、
        # PIN32 风扇PWM2，公共函数会自动跳过，不关闭外设或强制修改复用。
        # PIN3/5 I2C1、PIN19/21/23/24/26 SPI0、PIN29/31 UART0、
        # PIN33/35 UART3、PIN36/38 CAN1、PIN40 PWM15若启用，也按占用跳过。
        GPIO40="29 28 47 128 39 129 130 33 32 42 41 40 43 44 45
                136 137 131 132 105 133 134 138 135 139 115"
        ;;
    sige6|armsom-sige6)
        # GPIO354/355: debug UART; GPIO94: fan. Remove duplicate GPIO359.
        GPIO40="313 312 356 357 358 359 108 109 107 315 362 321 360 322 325
                320 32 33 326 106 111 314 361 110 324 323"
        ;;
    *) echo "[FAIL] 不支持的板型: $BOARD_ID"; exit 1 ;;
esac

# One implementation for every board. Run in a subshell so EXIT cleanup keeps
# access to its GPIO list on normal completion, error, and interruption alike.
gpio40_test() (
    fail() { echo "[FAIL] $*"; exit 1; }
    echo "[INFO] $BOARD_ID 40PIN 候选GPIO: $GPIO40"
    [ "${1:-}" = --run-gpio ] || {
        echo '[INFO] 接好LED治具后执行 gpio40.sh --run-gpio；结果需人工确认'
        exit 0
    }
    [ "$(id -u)" -eq 0 ] || fail '请通过 sudo 运行测试'
    command -v flock >/dev/null || fail '缺少命令: flock'
    exec 8>/run/armsom-gpio40.lock
    flock -n 8 || fail '40PIN测试正在运行'

    # Rockchip has one controller; Allwinner may have main and R controllers.
    local pinmux_files=() file gpio val i owned='' lines=()
    for file in /sys/kernel/debug/pinctrl/*/pinmux-pins; do
        [ ! -r "$file" ] || pinmux_files+=("$file")
    done
    [ ${#pinmux_files[@]} -gt 0 ] || fail '无法检查pinctrl占用，拒绝操作GPIO'
    cleanup_gpio() {
        local g
        for g in $owned; do
            echo in > "/sys/class/gpio/gpio$g/direction" 2>/dev/null || :
            echo "$g" > /sys/class/gpio/unexport 2>/dev/null || :
        done
    }
    trap cleanup_gpio EXIT
    trap 'exit 130' INT TERM HUP

    for gpio in $GPIO40; do
        mapfile -t lines < <(grep -h -E "^pin $gpio " "${pinmux_files[@]}")
        if [ ${#lines[@]} -ne 1 ]; then
            echo "[SKIP] GPIO$gpio 无法唯一确认pinctrl状态"; continue
        fi
        if [[ ${lines[0]} != *'(MUX UNCLAIMED)'* || ${lines[0]} != *'(GPIO UNCLAIMED)'* ]] ||
                [ -d "/sys/class/gpio/gpio$gpio" ]; then
            echo "[SKIP] GPIO$gpio 已被占用，不改复用/方向"; continue
        fi
        echo "$gpio" > /sys/class/gpio/export || fail "GPIO$gpio导出失败"
        owned="$owned $gpio"
        echo low > "/sys/class/gpio/gpio$gpio/direction" || fail "GPIO$gpio方向设置失败"
        echo "[INFO] GPIO$gpio 已加入LED测试"
    done
    [ -n "$owned" ] || fail '没有可用GPIO'
    echo '[INFO] LED 将闪烁约10秒，可在结束后再次点击开始重测'
    for ((i=0; i<10; i++)); do
        for val in 1 0; do
            for gpio in $owned; do
                echo "$val" > "/sys/class/gpio/gpio$gpio/value" || fail "GPIO$gpio写入失败"
            done
            sleep 0.5
        done
    done
    cleanup_gpio
    trap - EXIT INT TERM HUP
    echo '[INFO] LED闪烁完成，已释放本脚本GPIO；请人工判定40PIN是否通过'
)

gpio40_test "$@"
