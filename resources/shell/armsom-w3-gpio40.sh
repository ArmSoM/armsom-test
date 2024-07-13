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
board_model=$(cat /proc/device-tree/model)
case "$board_model" in
	"ArmSoM Sige5")
		GPIO40="111 112 100 28 14 22 79 78 149 150 151 148 104 119 128 95 20 23 96 24 21"
		;;
	"Rockchip armsom sige5 Board")
		GPIO40="111 112 100 28 14 22 79 78 149 150 151 148 104 119 128 95 20 23 96 24 21"
		;;
	"armsom w3")
		GPIO40="139 138 115 113 109 111 112 100 148 42 41 43 44 45 150 149 63 47 114 103 110 105 0 106 107"
		;;
	*)
		GPIO40="130 131 1 0 138 134 133 44 145 63 144 106 107"
		;;
esac
GPIOLED="15"
GPIOS="$GPIO40 $GPIOLED"

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
    if [ -f $DIR ] ; then
      echo  out > $DIR
    fi
  done
}

hi_gpio() {
  for IN in $GPIOS ; do
    VALUE=/sys/class/gpio/gpio$IN/value
    if [ -f $VALUE ] ; then
      echo 1 > $VALUE
    fi
  done
}

on_off_led()
{
ONOFF=$1
  for IN in $GPIOS ; do
    VALUE=/sys/class/gpio/gpio$IN/value
    if [ -f $VALUE ] ; then
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
