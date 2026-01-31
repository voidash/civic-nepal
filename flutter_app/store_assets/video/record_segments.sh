#!/bin/bash
# Record screen segments for Nagarik Patro promo video
# Each segment matches the voiceover audio duration

OUTPUT_DIR="/Users/cdjk/github/probe/constitution/flutter_app/store_assets/video/output/screens"
PKG="com.nepal.constitution.nepal_civic"

mkdir -p "$OUTPUT_DIR"

# Function to record screen for given duration
record_screen() {
    local name=$1
    local duration=$2
    local remote_file="/sdcard/screen_${name}.mp4"
    local local_file="${OUTPUT_DIR}/${name}.mp4"

    echo "Recording $name for ${duration}s..."
    adb shell screenrecord --time-limit $duration --bit-rate 8000000 "$remote_file" &
    RECORD_PID=$!
    sleep $((duration + 1))
    wait $RECORD_PID 2>/dev/null
    sleep 1
    adb pull "$remote_file" "$local_file" 2>/dev/null
    adb shell rm "$remote_file" 2>/dev/null
    echo "  Saved: $local_file"
}

# Function to tap on element by content description
tap_desc() {
    local desc=$1
    echo "  Tapping: $desc"
    # Get UI dump and find element
    adb shell uiautomator dump /sdcard/ui.xml 2>/dev/null
    local bounds=$(adb shell cat /sdcard/ui.xml | grep -o "content-desc=\"$desc\"[^>]*bounds=\"\[[0-9]*,[0-9]*\]\[[0-9]*,[0-9]*\]\"" | grep -o "bounds=\"\[[0-9,\[\]]*\"" | head -1)

    if [ -n "$bounds" ]; then
        # Parse bounds [x1,y1][x2,y2] and calculate center
        local coords=$(echo $bounds | grep -o '\[.*\]' | tr -d '[]"' | tr ',' ' ')
        local x1=$(echo $coords | awk '{print $1}')
        local y1=$(echo $coords | awk '{print $2}')
        local x2=$(echo $coords | awk '{print $3}')
        local y2=$(echo $coords | awk '{print $4}')
        local cx=$(( (x1 + x2) / 2 ))
        local cy=$(( (y1 + y2) / 2 ))
        adb shell input tap $cx $cy
        sleep 1
    else
        echo "    Warning: Element not found"
    fi
}

# Function to press back
go_back() {
    adb shell input keyevent KEYCODE_BACK
    sleep 0.5
}

# Function to scroll down
scroll_down() {
    adb shell input swipe 540 1500 540 800 300
    sleep 0.5
}

# Launch app fresh
echo "=== Starting Recording Session ==="
adb shell am force-stop $PKG
sleep 1
adb shell am start -n "$PKG/.MainActivity"
sleep 3

# SCENE 1: Hook - Home screen (3.5s + buffer = 5s)
echo ""
echo "=== Scene 1: Hook (Home) ==="
record_screen "01_hook" 5

# SCENE 2: Calendar (12.2s + buffer = 14s)
echo ""
echo "=== Scene 2: Calendar ==="
# Tap on Calendar in bottom nav
adb shell input tap 180 2242  # Bottom nav Calendar button
sleep 2
record_screen "02_calendar" 14

# SCENE 3: Date Converter (7.3s + buffer = 9s)
echo ""
echo "=== Scene 3: Date Converter ==="
go_back
sleep 1
# From home, tap on मिति परिवर्तक
adb shell input tap 797 1812  # Date Converter tile
sleep 2
record_screen "03_date" 9

# SCENE 4: Financial - Forex, Gold, IPO (12s + buffer = 14s)
echo ""
echo "=== Scene 4: Financial (Forex → Gold → IPO) ==="
go_back
sleep 1
# First tap Forex
adb shell input tap 283 2065  # Forex tile (विदेशी मुद्रा)
sleep 3
# Start recording and navigate during recording
adb shell screenrecord --time-limit 14 --bit-rate 8000000 /sdcard/screen_04_financial.mp4 &
sleep 4
go_back
sleep 1
adb shell input tap 797 2065  # Gold tile (सुन/चाँदी)
sleep 3
go_back
sleep 1
adb shell input tap 900 2242  # IPO tab in bottom nav
sleep 4
wait
adb pull /sdcard/screen_04_financial.mp4 "$OUTPUT_DIR/04_financial.mp4" 2>/dev/null
adb shell rm /sdcard/screen_04_financial.mp4 2>/dev/null
echo "  Saved: $OUTPUT_DIR/04_financial.mp4"

# SCENE 5: Rights (11.6s + buffer = 13s)
echo ""
echo "=== Scene 5: Rights ==="
# Go to home first
adb shell input tap 540 2242  # Home tab
sleep 2
# Tap on अधिकार
adb shell input tap 882 1001  # Rights tile
sleep 2
record_screen "05_rights" 13

# SCENE 6: Maps (11.7s + buffer = 13s)
echo ""
echo "=== Scene 6: Maps ==="
go_back
sleep 1
# Tap on नक्सा
adb shell input tap 540 1001  # Map tile
sleep 2
record_screen "06_maps" 13

# SCENE 7: Government (9.3s + buffer = 11s)
echo ""
echo "=== Scene 7: Government ==="
go_back
sleep 1
# Tap on सरकार
adb shell input tap 197 1001  # Government tile
sleep 2
record_screen "07_government" 11

# SCENE 8: Utilities (5.6s + buffer = 7s)
echo ""
echo "=== Scene 8: Utilities ==="
go_back
sleep 1
# Show citizenship merger
adb shell input tap 283 1482  # नागरिकता मर्जर
sleep 2
adb shell screenrecord --time-limit 7 --bit-rate 8000000 /sdcard/screen_08_utilities.mp4 &
sleep 3
go_back
sleep 1
adb shell input tap 797 1482  # फोटो कम्प्रेस
sleep 3
wait
adb pull /sdcard/screen_08_utilities.mp4 "$OUTPUT_DIR/08_utilities.mp4" 2>/dev/null
adb shell rm /sdcard/screen_08_utilities.mp4 2>/dev/null
echo "  Saved: $OUTPUT_DIR/08_utilities.mp4"

# SCENE 9: CTA - Back to Home (9s + buffer = 10s)
echo ""
echo "=== Scene 9: CTA (Home) ==="
go_back
sleep 1
adb shell input tap 540 2242  # Home tab
sleep 2
record_screen "09_cta" 10

echo ""
echo "=== Recording Complete ==="
ls -la "$OUTPUT_DIR"
