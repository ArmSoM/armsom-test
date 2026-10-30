#!/bin/bash
#GPIO40_NO_IGPIO="13 14 3 17 58 25 27 7 4 5 6 8 12 11 100 21 54 59 57 22 23 24 60"
#IGPIOSORG="21 3 2 5 4 9"
#IGPIO + 101 = GPIO
#IGPIOS="122  104 103 106 105 110"
#GPIO40="13 14 122 104 103 3 17 58 25 27 106 105 7 4 110 5 6 8 12 11 100 21 54 59 57 22 23 24 60"
#BPI-M4 https://youtu.be/SVegH35v-_k
# GPIO40="17 16 21 9 8 42 3 43 44 11 10 31 18 47 19 20 22 45 23 41 40 50 4 2 53 34 5 6"
# GPIOLED="128 97 98"
# GPIO pin脚计算公式：pin = bank * 32 + number
# GPIO 小组编号计算公式：number = group * 8 + X
# 1 - VCC_IO                                    2 - VCC_5V0
# 3 - I2C7_SDA_M3 = GPIO4_B3_u = 139            4 - VCC_5V0
# 5 - I2C7_SCL_M3 = GPIO4_B2_u = 138            6 - GND
# 7 - SPI1_CS1_M1 = GPIO3_C3_d = 115            8 - UART2_TX_M0
# 9 - GND                                       10 - UART2_RX_M0
# 11 - SPI1_CLK_M1 = GPIO3_C1_d = 113           12 - I2S2_SCLK_TX_M1 = GPIO3_B5_u = 109
# 13 - SPI1_MOSI_M1 = GPIO3_B7_d = 111          14 - GND
# 15 - SPI1_MISO_M1 = GPIO3_C0_d = 112          16 - UART8_RTSn_M1_BT = GPIO3_A4_d = 100
# 17 - VCC_IO                                   18 - GPIO4_C4 = 148
# 19 - SPI0-MOSI = GPIO1_B2_d = 42              20 - GND
# 21 - SPI0-MISO = GPIO1_B1_d = 41              22 - SARADC_IN4
# 23 - SPI0-CLK = GPIO1_B3_d = 43               24 - SPI0-CS0 = GPIO1_B4_d = 44
# 25 - GND                                      26 - SPI0-CS1 = GPIO1_B5_d = 45
# 27 - GPIO4-C6 = 150                           28 - GPIO4_C5 = 149
# 29 - GPIO1-D7 = 63                            30 - GND
# 31 - GPIO1_B7 = 47                            32 - SPI1_CS0_M1 = GPIO3_C2_d = 114
# 33 - PWM8_M0 = GPIO3_A7_u = 103               34 - GND
# 35 - I2S2_LRCK_TX_M1 = GPIO3_B6_d = 110       36 - I2S2_LRCK_RX_M1 = GPIO3_B1_d = 105
# 37 - GPIO0-A0 = 0                             38 - I2S2_SDI_M1  = GPIO3_B2_d = 106
# 39 - GND                                      40 - I2S2_SDO_M1 = GPIO3_B3_u = 107

#通过将40pin导出为gpio，基于syfs控制gpio。让40pin接LED外设，通过40LED亮灭来测试40pin
# board_model=$(cat /proc/device-tree/model)
BOARD_ID=$(cat /proc/device-tree/compatible | tr '\0' '\n' | head -1 | cut -d ',' -f2 | cut -d '-' -f2-)


case "$BOARD_ID" in
    "armsom-aim7-io")
        export LC_ALL=C
        fail() { echo "[FAIL] $*"; exit 1; }
        pass() { echo "[PASS] $*"; exit 0; }
        need() { command -v "$1" >/dev/null || fail "缺少命令: $1"; }
        [ "$(id -u)" -eq 0 ] || fail '请通过 sudo 运行测试'
        aim7_gpio_test() {
            # Physical pin:Linux GPIO. Pins shared with RTC/cameras are intentionally omitted.
            # Omit 3/5 (I2C4 RTC+CAM1), 11/36 (OV reset), 15 (CAM3 PWDN),
            # 27/28 (I2C2 CAM0), 31/33 (OV MCLK). PWM10 pin32 is reserved too.
            local mapping='7:128 8:46 10:47 12:129 13:58 16:61 18:59 19:42 21:41 22:56 23:43 24:44 26:45 29:103 35:130 37:57 38:133 40:137'
            echo "[INFO] AIM7 40PIN 可测试物理引脚:GPIO：$mapping"
            [ "${1:-}" = --run-gpio ] || { echo '[INFO] 仅列出引脚；执行 gpio40.sh --run-gpio 后才会操作GPIO。接LED治具人工判断。'; return 0; }
            local pinmux=/sys/kernel/debug/pinctrl/pinctrl-rockchip-pinctrl/pinmux-pins
            [ -r "$pinmux" ] || fail '无法检查pinctrl占用，拒绝操作GPIO'
            need flock
            exec 8>/run/armsom-aim7-gpio.lock
            flock -n 8 || fail '40PIN测试正在运行'
            local owned='' entry pin gpio line i val
            cleanup_gpio() {
                local g
                for g in $owned; do
                    echo in > "/sys/class/gpio/gpio$g/direction" 2>/dev/null || :
                    echo "$g" > /sys/class/gpio/unexport 2>/dev/null || :
                done
            }
            trap cleanup_gpio EXIT
            trap 'exit 130' INT TERM HUP
            for entry in $mapping; do
                pin=${entry%:*}; gpio=${entry#*:}
                line=$(grep -E "^pin $gpio " "$pinmux")
                if ! printf '%s\n' "$line" | grep -Fq '(MUX UNCLAIMED)' || ! printf '%s\n' "$line" | grep -Fq '(GPIO UNCLAIMED)' || [ -d /sys/class/gpio/gpio$gpio ]; then
                    echo "[SKIP] PIN$pin GPIO$gpio 已被占用，不改复用/方向"; continue
                fi
                echo "$gpio" > /sys/class/gpio/export || fail "GPIO$gpio导出失败"
                owned="$owned $gpio"
                echo low > "/sys/class/gpio/gpio$gpio/direction" || fail "GPIO$gpio方向设置失败"
                echo "[INFO] PIN$pin GPIO$gpio 已加入LED测试"
            done
            [ -n "$owned" ] || fail '没有可用GPIO'
            for i in 1 2 3 4 5; do
                for val in 1 0; do
                    for gpio in $owned; do
                        echo "$val" > "/sys/class/gpio/gpio$gpio/value" || fail "GPIO$gpio写入失败"
                    done
                    sleep 0.5
                done
            done
            echo '[INFO] LED闪烁完成，已释放本脚本GPIO；请人工判定40PIN是否通过'
        }
        aim7_gpio_test "$@"
        exit $?
        ;;

	"armsom-cm5-io")
  # gpio 111 112 开启摄像头的时候会占用,  28 29 调试串口，94 风扇
		GPIO40="140 141 20 97 98 96 126 89 88 99"
		;;
  "armsom-cm7s-io")
  # gpio 13 14 调试串口
		GPIO40="63 62 39 130 131 18 42 41 43 57 58 59 139 52 54 106 32 33 40
            44 45 56 138 61 20 21"
		;;
  "sige6")
  # gpio 354 355调试串口，94 风扇
		GPIO40="313 312 356 357 358 359 359 108 109 107 315 362 321 360 322 325
            320 32 33 326 106 111 314 361 110 324 323"
		;;
	*)
		GPIO40="140 141 20 97 98 96 126 89 88 99" 
		;;
esac

GPIOS="$GPIO40"

export_gpio() {
  for IN in $GPIOS ; do
    EXPORT=/sys/class/gpio/export
    VALUE=/sys/class/gpio/gpio$IN/value
    if [ ! -f $VALUE ] ; then
      echo $IN > $EXPORT
    fi
  done
}
out_gpio() {
  for IN in $GPIOS ; do
    DIR=/sys/class/gpio/gpio$IN/direction
    if [ -f "$DIR" ] ; then
      echo  out > $DIR
    fi
  done
}

hi_gpio() {
  for IN in $GPIOS ; do
    VALUE=/sys/class/gpio/gpio$IN/value
    if [ -f "$VALUE" ] ; then
      echo 1 > $VALUE
    fi
  done
}

on_off_led()
{
ONOFF=$1
  for IN in $GPIOS ; do
    VALUE=/sys/class/gpio/gpio$IN/value
    if [ -f "$VALUE" ] ; then
      echo $ONOFF > $VALUE
      sleep .1
    fi
  done
}

main() {
    export_gpio
    out_gpio
    hi_gpio

    for i in `seq 5`
      do
         on_off_led 0
         sleep .5
         on_off_led 1
         sleep .5
      done
}

main
