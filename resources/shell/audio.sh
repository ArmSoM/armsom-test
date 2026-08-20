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
        ;;
    "armsom-sige7" | "armsom-sige5")
        echo "检测到 Sige 系列板卡，执行适配逻辑..."
        ;;
    *)
        echo "未知的板卡类型: $BOARD_ID，终止测试！"
        exit 1
        ;;
esac