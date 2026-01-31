#!/usr/bin/env python3
"""
Generate promotional video for Nagarik Patro app.

Pipeline:
1. Generate voiceover audio using gTTS
2. Record app screen using adb screenrecord
3. Capture screenshots at key moments
4. Stitch together with ffmpeg

Usage:
    python3 generate_video.py
"""

import os
import subprocess
import time
from pathlib import Path
from gtts import gTTS

# Script directory
SCRIPT_DIR = Path(__file__).parent
OUTPUT_DIR = SCRIPT_DIR / "output"
OUTPUT_DIR.mkdir(exist_ok=True)

# Video script with timing
VIDEO_SCRIPT = [
    {
        "text": "Introducing Nagarik Patro - the only Nepali calendar app you need.",
        "duration": 4,
        "action": "home",
    },
    {
        "text": "Full Bikram Sambat calendar with tithi, nakshatra, and festivals for every day.",
        "duration": 4,
        "action": "calendar",
    },
    {
        "text": "Convert dates between Bikram Sambat and Gregorian instantly.",
        "duration": 3,
        "action": "date_converter",
    },
    {
        "text": "Live foreign exchange rates updated daily from Nepal Rastra Bank.",
        "duration": 3,
        "action": "forex",
    },
    {
        "text": "Gold and silver prices per tola, updated every day.",
        "duration": 3,
        "action": "gold",
    },
    {
        "text": "Know your rights. The full Constitution of Nepal in Nepali and English.",
        "duration": 4,
        "action": "rights",
    },
    {
        "text": "Interactive maps showing all 77 districts and elected officials.",
        "duration": 4,
        "action": "map",
    },
    {
        "text": "Understand how Nepal's government works, with current cabinet members.",
        "duration": 4,
        "action": "government",
    },
    {
        "text": "No ads. No tracking. Download Nagarik Patro today.",
        "duration": 4,
        "action": "home_end",
    },
]


def generate_voiceover():
    """Generate voiceover audio files using gTTS."""
    print("Generating voiceover audio...")

    audio_files = []
    for i, segment in enumerate(VIDEO_SCRIPT):
        text = segment["text"]
        output_file = OUTPUT_DIR / f"voice_{i:02d}.mp3"

        print(f"  [{i+1}/{len(VIDEO_SCRIPT)}] {text[:50]}...")
        tts = gTTS(text=text, lang='en', slow=False)
        tts.save(str(output_file))
        audio_files.append(output_file)

    # Concatenate all audio files
    print("Concatenating audio files...")
    concat_file = OUTPUT_DIR / "concat_audio.txt"
    with open(concat_file, 'w') as f:
        for audio_file in audio_files:
            f.write(f"file '{audio_file.name}'\n")

    combined_audio = OUTPUT_DIR / "voiceover.mp3"
    subprocess.run([
        "ffmpeg", "-y", "-f", "concat", "-safe", "0",
        "-i", str(concat_file),
        "-c", "copy",
        str(combined_audio)
    ], cwd=OUTPUT_DIR, capture_output=True)

    print(f"Voiceover saved to: {combined_audio}")
    return combined_audio


def get_audio_duration(audio_file):
    """Get duration of audio file in seconds."""
    result = subprocess.run([
        "ffprobe", "-v", "error", "-show_entries", "format=duration",
        "-of", "default=noprint_wrappers=1:nokey=1", str(audio_file)
    ], capture_output=True, text=True)
    return float(result.stdout.strip())


def record_screen(duration_seconds):
    """Record device screen using adb screenrecord."""
    print(f"Recording screen for {duration_seconds} seconds...")

    video_file = "/sdcard/app_demo.mp4"
    local_file = OUTPUT_DIR / "screen_recording.mp4"

    # Start recording in background
    record_process = subprocess.Popen([
        "adb", "shell", "screenrecord",
        "--time-limit", str(min(duration_seconds + 5, 180)),  # Max 3 min
        "--bit-rate", "8000000",
        video_file
    ])

    return record_process, video_file, local_file


def navigate_app():
    """Navigate through the app using adb commands."""
    print("Navigating through app...")

    pkg = "com.nepal.constitution.nepal_civic"

    # Launch app
    subprocess.run(["adb", "shell", "am", "start", "-n", f"{pkg}/.MainActivity"],
                   capture_output=True)
    time.sleep(3)

    # Get screen dimensions for tap coordinates
    result = subprocess.run(["adb", "shell", "wm", "size"], capture_output=True, text=True)
    # Parse "Physical size: 1080x2400" format
    size_line = result.stdout.strip().split(": ")[-1]
    width, height = map(int, size_line.split("x"))

    actions = {
        "home": lambda: time.sleep(VIDEO_SCRIPT[0]["duration"]),
        "calendar": lambda: tap_text_or_coord("Calendar", width, height),
        "date_converter": lambda: (back(), tap_text_or_coord("Date Converter", width, height)),
        "forex": lambda: (back(), tap_text_or_coord("Forex", width, height)),
        "gold": lambda: (back(), tap_text_or_coord("Gold", width, height)),
        "rights": lambda: (back(), tap_text_or_coord("Constitutional Rights", width, height)),
        "map": lambda: (back(), tap_text_or_coord("District Map", width, height)),
        "government": lambda: (back(), tap_text_or_coord("Government", width, height)),
        "home_end": lambda: (back(), time.sleep(2)),
    }

    for segment in VIDEO_SCRIPT:
        action = segment["action"]
        duration = segment["duration"]
        print(f"  Action: {action} ({duration}s)")

        if action in actions:
            actions[action]()

        time.sleep(duration)


def tap_text_or_coord(text, width, height):
    """Tap on screen - using coordinates based on typical home screen layout."""
    # For now, use back button and rely on flow
    subprocess.run(["adb", "shell", "input", "tap", str(width//2), str(height//2)],
                   capture_output=True)
    time.sleep(1)


def back():
    """Press back button."""
    subprocess.run(["adb", "shell", "input", "keyevent", "KEYCODE_BACK"],
                   capture_output=True)
    time.sleep(0.5)


def pull_recording(video_file, local_file):
    """Pull recording from device."""
    print("Pulling recording from device...")
    time.sleep(2)  # Wait for recording to finish
    subprocess.run(["adb", "pull", video_file, str(local_file)], capture_output=True)
    subprocess.run(["adb", "shell", "rm", video_file], capture_output=True)
    return local_file


def combine_video_audio(video_file, audio_file, output_file):
    """Combine video and audio using ffmpeg."""
    print("Combining video and audio...")

    subprocess.run([
        "ffmpeg", "-y",
        "-i", str(video_file),
        "-i", str(audio_file),
        "-c:v", "libx264",
        "-c:a", "aac",
        "-map", "0:v:0",
        "-map", "1:a:0",
        "-shortest",
        str(output_file)
    ], capture_output=True)

    print(f"Final video saved to: {output_file}")


def create_video_simple():
    """Simplified video creation using screenshots and audio."""
    print("\n=== Nagarik Patro Video Generator ===\n")

    # Step 1: Generate voiceover
    voiceover = generate_voiceover()
    total_duration = get_audio_duration(voiceover)
    print(f"Total voiceover duration: {total_duration:.1f}s")

    # Step 2: Record screen while navigating
    print("\nStarting screen recording and app navigation...")
    record_proc, remote_video, local_video = record_screen(int(total_duration) + 10)

    # Step 3: Navigate app (this runs while recording)
    time.sleep(2)  # Let recording start
    navigate_app()

    # Step 4: Stop recording and pull file
    record_proc.terminate()
    time.sleep(2)
    subprocess.run(["adb", "shell", "pkill", "-l", "INT", "screenrecord"], capture_output=True)
    time.sleep(2)
    pull_recording(remote_video, local_video)

    # Step 5: Combine video and audio
    final_output = OUTPUT_DIR / "nagarik_patro_promo.mp4"
    combine_video_audio(local_video, voiceover, final_output)

    print(f"\n✓ Video created: {final_output}")
    print(f"  Duration: ~{total_duration:.0f}s")
    return final_output


if __name__ == "__main__":
    create_video_simple()
