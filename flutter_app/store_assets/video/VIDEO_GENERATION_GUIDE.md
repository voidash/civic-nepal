# Video Generation Guide for App Promotional Videos

This guide documents the complete process for generating promotional videos for apps using screen recording, TTS audio, and FFmpeg. Written based on the Nagarik Patro Flutter app video creation process.

---

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [The Golden Rules](#the-golden-rules)
4. [Step 1: Script Preparation](#step-1-script-preparation)
5. [Step 2: Audio Generation](#step-2-audio-generation)
6. [Step 3: Video Capture](#step-3-video-capture)
7. [Step 4: Merge Audio and Video](#step-4-merge-audio-and-video)
8. [Step 5: Concatenate Final Video](#step-5-concatenate-final-video)
9. [Troubleshooting](#troubleshooting)
10. [Quick Reference Commands](#quick-reference-commands)

---

## Overview

The video generation process follows these steps:

```
Script → Audio (TTS) → Video (Screen Recording) → Merge → Concatenate
```

**Key Principle:** Each segment covers ONE screen/feature with ONE audio file and ONE video file. This 1:1:1 relationship ensures perfect synchronization.

---

## Prerequisites

### Required Tools

```bash
# FFmpeg for video processing
brew install ffmpeg

# ADB for Android screen recording
brew install android-platform-tools

# Verify installations
ffmpeg -version
adb version
```

### Required Accounts

- **ElevenLabs** - For high-quality TTS (eleven_v3 model recommended)
- API key format: `sk_...`

### Android Device Setup

1. Enable Developer Options (tap Build Number 7 times)
2. Enable USB Debugging
3. Connect via USB
4. Verify connection: `adb devices`

---

## The Golden Rules

### Rule 1: One Activity Per Segment

Each segment must cover **ONE SINGLE** screen or feature.

**BAD:**
```
"Check the calendar, convert dates, and see forex rates"
→ Covers 3 screens in one audio = impossible to sync
```

**GOOD:**
```
Segment 1: "Full Bikram Sambat calendar with festivals"  → Calendar screen
Segment 2: "Convert dates instantly"                      → Date converter
Segment 3: "Daily forex rates from Nepal Rastra Bank"    → Forex screen
```

### Rule 2: Audio is King

Video speed is adjusted to match audio duration. **Audio is NEVER cut.**

- If video is longer → speed up video
- If video is shorter → slow down video
- Audio duration = final segment duration

---

## Step 1: Script Preparation

### Script Structure

Create a markdown file with this structure for each segment:

```markdown
## SCENE 1: Hook (3.3s)
**Audio:** `01_hook.mp3`
> "हरेक नेपालीको फोनमा चाहिने एउटा मात्र एप।"

| Time | Action | Screen |
|------|--------|--------|
| 0-3.3s | Gentle scroll | Home screen |
```

### Naming Convention

```
{number}_{name}.mp3   # Audio
{number}_{name}.mp4   # Video
```

Examples:
- `01_hook.mp3`, `01_hook.mp4`
- `02_calendar.mp3`, `02_calendar.mp4`
- `16_election_intro.mp3`, `16_election_intro.mp4`

### Script Tips

1. Keep each segment 2-8 seconds
2. Add emotional cues for TTS: `[enthusiastically]`, `[warmly]`, `[seriously]`
3. Write action descriptions clearly: "tap Calendar tab", "scroll down slowly"
4. Note any UI element coordinates if needed

---

## Step 2: Audio Generation

### Using ElevenLabs API

```bash
API_KEY="sk_your_key_here"
VOICE_ID="cgSgspJ2msm6clMCkdW9"  # Jessica voice - good for Nepali

generate_audio() {
    local filename=$1
    local text=$2

    curl -s -X POST "https://api.elevenlabs.io/v1/text-to-speech/${VOICE_ID}" \
        -H "xi-api-key: ${API_KEY}" \
        -H "Content-Type: application/json" \
        -d "{
            \"text\": \"${text}\",
            \"model_id\": \"eleven_v3\",
            \"voice_settings\": {
                \"stability\": 0.5,
                \"similarity_boost\": 0.75
            }
        }" \
        --output "${filename}.mp3"
}

# Example usage
generate_audio "01_hook" "हरेक नेपालीको फोनमा चाहिने एउटा मात्र एप।"
```

### Verify Audio Duration

```bash
ffprobe -v error -show_entries format=duration \
    -of default=noprint_wrappers=1:nokey=1 "01_hook.mp3"
```

### Common Issues

- **Audio cut off**: Regenerate - ElevenLabs sometimes truncates
- **Wrong pronunciation**: Rephrase or add phonetic hints
- **API blocked**: Disable VPN, check account limits

---

## Step 3: Video Capture

### Method 1: ADB Screen Recording

```bash
# Basic recording (max 180 seconds)
adb shell screenrecord --time-limit 10 --bit-rate 8000000 /sdcard/recording.mp4

# Pull to local machine
adb pull /sdcard/recording.mp4 ./01_hook.mp4
adb shell rm /sdcard/recording.mp4
```

### Method 2: Recording with Actions

Run actions in background while recording:

```bash
# Start recording with parallel actions
(sleep 0.5 && adb shell input tap 540 1001 && sleep 2 && adb shell input swipe 540 1800 540 1000 1500) &
adb shell screenrecord --time-limit 8 --bit-rate 8000000 /sdcard/scene.mp4
adb pull /sdcard/scene.mp4 ./output.mp4
```

### Navigation Commands

```bash
# Tap at coordinates
adb shell input tap X Y

# Swipe (scroll)
adb shell input swipe startX startY endX endY durationMs
adb shell input swipe 540 1800 540 1000 1500  # Scroll up

# Press back
adb shell input keyevent KEYCODE_BACK

# Press home
adb shell input keyevent KEYCODE_HOME

# Launch specific app
adb shell am start -n com.package.name/.MainActivity
```

### Getting UI Element Coordinates

```bash
# Dump UI hierarchy
adb shell uiautomator dump /sdcard/ui.xml
adb pull /sdcard/ui.xml /tmp/ui.xml

# Find element bounds
grep 'content-desc="ElementName"' /tmp/ui.xml

# Output example: bounds="[42,839][353,1164]"
# Center = ((42+353)/2, (839+1164)/2) = (197, 1001)
```

### Recording Tips

1. **Keep screen active** - Add small swipes to prevent static frame drops
2. **Force correct app** - Use `am start` before recording
3. **Allow load time** - Wait 1-2 seconds after navigation before recording
4. **Check recording** - Verify file size (should be 200KB-2MB per second)

---

## Step 4: Merge Audio and Video

### The Merge Formula

```
speed = video_duration / audio_duration
```

- `speed > 1`: Video plays faster (was longer than audio)
- `speed < 1`: Video plays slower (was shorter than audio)

### FFmpeg Merge Command

```bash
# Get durations
VIDEO_DUR=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 video.mp4)
AUDIO_DUR=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 audio.mp3)

# Calculate speed
SPEED=$(echo "scale=6; $VIDEO_DUR / $AUDIO_DUR" | bc)

# Merge with speed adjustment
ffmpeg -y -i video.mp4 -i audio.mp3 \
    -filter_complex "[0:v]setpts=PTS/${SPEED}[v]" \
    -map "[v]" -map 1:a \
    -c:v libx264 -preset fast \
    -c:a aac -b:a 192k \
    -t ${AUDIO_DUR} \
    output.mp4
```

### Batch Merge Script

```bash
#!/bin/bash

merge_segment() {
    local num=$1
    local name=$2

    local video="video/${num}_${name}.mp4"
    local audio="audio/${num}_${name}.mp3"
    local output="combined/${num}_${name}.mp4"

    video_dur=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$video")
    audio_dur=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$audio")
    speed=$(echo "scale=6; $video_dur / $audio_dur" | bc)

    echo "Merging $num: video=${video_dur}s audio=${audio_dur}s speed=${speed}x"

    ffmpeg -y -i "$video" -i "$audio" \
        -filter_complex "[0:v]setpts=PTS/${speed}[v]" \
        -map "[v]" -map 1:a \
        -c:v libx264 -preset fast \
        -c:a aac -b:a 192k \
        -t "$audio_dur" \
        "$output" 2>/dev/null
}

# Merge all segments
merge_segment "01" "hook"
merge_segment "02" "calendar"
# ... etc
```

---

## Step 5: Concatenate Final Video

### Using filter_complex concat

```bash
ffmpeg -y \
    -i 01_hook.mp4 \
    -i 02_calendar.mp4 \
    -i 03_widget.mp4 \
    -filter_complex "[0:v][0:a][1:v][1:a][2:v][2:a]concat=n=3:v=1:a=1[outv][outa]" \
    -map "[outv]" -map "[outa]" \
    -c:v libx264 -preset fast -crf 22 \
    -c:a aac -b:a 192k \
    final_output.mp4
```

### For Many Segments (20+)

```bash
# Build the command dynamically
inputs=""
filter=""
for i in $(seq -w 1 20); do
    inputs="$inputs -i ${i}_*.mp4"
    filter="$filter[$(($i-1)):v][$(($i-1)):a]"
done
filter="${filter}concat=n=20:v=1:a=1[outv][outa]"

ffmpeg -y $inputs \
    -filter_complex "$filter" \
    -map "[outv]" -map "[outa]" \
    -c:v libx264 -preset fast -crf 22 \
    -c:a aac -b:a 192k \
    final_output.mp4
```

### Reordering Segments

Simply change the input order:

```bash
# Original order: 1, 2, 3, 4, 5
# New order: 1, 2, 4, 5, 3  (move segment 3 to end)

ffmpeg -y \
    -i 01_hook.mp4 \
    -i 02_calendar.mp4 \
    -i 04_notification.mp4 \
    -i 05_forex.mp4 \
    -i 03_widget.mp4 \
    -filter_complex "..." \
    output.mp4
```

---

## Troubleshooting

### Audio Issues

| Problem | Cause | Solution |
|---------|-------|----------|
| Audio cut off | ElevenLabs truncation | Regenerate audio |
| Wrong duration | Encoding issue | Check with ffprobe |
| API error 476 bytes | Rate limit/VPN | Disable VPN, wait, retry |

### Video Issues

| Problem | Cause | Solution |
|---------|-------|----------|
| Only 1 frame captured | Static screen | Add swipe movements |
| Wrong app recorded | Another app in foreground | Use `am start` to force launch |
| Corrupted file | Recording interrupted | Increase time-limit buffer |
| Small file size | Encoding failed | Check adb connection |

### Merge Issues

| Problem | Cause | Solution |
|---------|-------|----------|
| Audio/video desync | Wrong speed calculation | Verify durations match |
| Video too fast/slow | Speed factor off | Recalculate speed |
| Black frames | Video shorter than audio | Use tpad filter |

### FFmpeg Errors

```bash
# "moov atom not found" - corrupted input
ffprobe -v error input.mp4  # Check if readable

# Re-encode corrupted file
ffmpeg -y -i input.mp4 -c:v libx264 -c:a aac fixed.mp4
```

---

## Quick Reference Commands

### Audio

```bash
# Generate audio (ElevenLabs)
curl -X POST "https://api.elevenlabs.io/v1/text-to-speech/VOICE_ID" \
    -H "xi-api-key: API_KEY" -H "Content-Type: application/json" \
    -d '{"text":"...", "model_id":"eleven_v3"}' -o audio.mp3

# Get duration
ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 file.mp3
```

### Video

```bash
# Record screen
adb shell screenrecord --time-limit 10 --bit-rate 8000000 /sdcard/rec.mp4

# Pull file
adb pull /sdcard/rec.mp4 ./local.mp4

# Tap
adb shell input tap X Y

# Swipe/scroll
adb shell input swipe 540 1800 540 1000 1500

# Launch app
adb shell am start -n com.package/.MainActivity

# Get UI coordinates
adb shell uiautomator dump /sdcard/ui.xml && adb pull /sdcard/ui.xml
```

### Processing

```bash
# Merge audio + video (adjust speed)
ffmpeg -y -i video.mp4 -i audio.mp3 \
    -filter_complex "[0:v]setpts=PTS/SPEED[v]" \
    -map "[v]" -map 1:a -c:v libx264 -c:a aac output.mp4

# Concatenate multiple videos
ffmpeg -y -i 1.mp4 -i 2.mp4 -i 3.mp4 \
    -filter_complex "[0:v][0:a][1:v][1:a][2:v][2:a]concat=n=3:v=1:a=1[v][a]" \
    -map "[v]" -map "[a]" output.mp4

# Get video duration
ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 file.mp4
```

---

## Directory Structure

Recommended project structure:

```
video_project/
├── SCRIPT.md              # Script with all segments
├── audio/                 # Generated audio files
│   ├── 01_hook.mp3
│   ├── 02_calendar.mp3
│   └── ...
├── video/                 # Raw screen recordings
│   ├── 01_hook.mp4
│   ├── 02_calendar.mp4
│   └── ...
├── combined/              # Merged audio+video
│   ├── 01_hook.mp4
│   ├── 02_calendar.mp4
│   └── ...
└── final_output.mp4       # Concatenated final video
```

---

## Checklist

Before starting:
- [ ] Script written with one activity per segment
- [ ] ElevenLabs API key ready
- [ ] Android device connected and verified
- [ ] FFmpeg installed
- [ ] Output directories created

For each segment:
- [ ] Audio generated and verified (not cut off)
- [ ] Video recorded with correct screen
- [ ] Duration checked (audio should match intent)
- [ ] Merged successfully

Final:
- [ ] All segments merged
- [ ] Correct order determined
- [ ] Final video concatenated
- [ ] Output verified by playback

---

*Last updated: January 2026*
*Based on Nagarik Patro promotional video creation*
