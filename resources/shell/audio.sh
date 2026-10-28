#!/bin/bash

BOARD_ID=$(cat /proc/device-tree/compatible | tr '\0' '\n' | head -1 | cut -d ',' -f2 | cut -d '-' -f2-)

case "$BOARD_ID" in
    "armsom-cm5-io")
        echo "检测到 ArmSom CM5 IO 板，准备同时测试 Codec/DP/HDMI..."
        # 3. 后面继续放你原来的三个设备同时播放逻辑
        TEST_WAV="/opt/armsomtest/audio.wav"

        aplay -D plughw:0,0 "$TEST_WAV" >/dev/null 2>&1 & PID_CARD0=$!
        aplay -D plughw:1,0 "$TEST_WAV" >/dev/null 2>&1 & PID_CARD1=$!
        aplay -D plughw:2,0 "$TEST_WAV" >/dev/null 2>&1 & PID_CARD2=$!
        wait $PID_CARD0 $PID_CARD1 $PID_CARD2
        
        echo "三个设备同时播放完成！"
        exit 0
        ;;
    "armsom-sige7" | "armsom-sige5" | "armsom-sige7s")
        echo "检测到 Sige 系列板卡，执行适配逻辑..."
        aplay -D hw:2,0 /opt/armsomtest/audio.wav
        exit 0
        ;;
    "armsom-cm7s-io")
        echo "检测到 ArmSoM CM7S IO 板，准备同时测试 DP/HDMI/ES8388..."

        TEST_WAV="/opt/armsomtest/audio.wav"

        # 播放前配置 ES8388
        amixer -c 2 cset numid=34 15,15
        amixer -c 2 cset numid=55 on

        # 三个声卡同时播放
        aplay -D hw:0,0 "$TEST_WAV" >/dev/null 2>&1 & PID_CARD0=$!
        aplay -D hw:1,0 "$TEST_WAV" >/dev/null 2>&1 & PID_CARD1=$!
        aplay -D hw:2,0 "$TEST_WAV" >/dev/null 2>&1 & PID_CARD2=$!

        # 等待三个播放进程结束
        wait $PID_CARD0 $PID_CARD1 $PID_CARD2

        echo "三个声卡同时播放完成，请人工检查声音是否正常！"
        exit 0
        ;;
    "sige6")
        echo "检测到 ArmSom Sige6 板，开始播放音频..."
        TEST_WAV="/opt/armsomtest/audio.wav"
        aplay -D hw:0,0 "$TEST_WAV"
        echo "音频播放完成！"
        exit 0
        ;;
    *)
        echo "未知的板卡类型: $BOARD_ID，终止测试！"
        exit 1
        ;;
esac