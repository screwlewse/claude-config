#!/usr/bin/env python3
import sys
import subprocess
import os

def play_sound(sound_type="done"):
    """Play notification sound based on type"""
    sounds_dir = "/Users/davidg/.claude/sounds"
    
    # Sound file mappings
    sound_files = {
        "done": f"{sounds_dir}/done/jobs-done_1.mp3",
        "error": f"{sounds_dir}/error.mp3",
        "start": f"{sounds_dir}/start.mp3"
    }
    
    sound_file = sound_files.get(sound_type, sound_files["done"])
    
    # Check if sound file exists
    if os.path.exists(sound_file):
        try:
            # Use afplay on macOS to play the sound
            subprocess.run(["afplay", sound_file], check=True, capture_output=True)
        except subprocess.CalledProcessError:
            # Fallback to system beep if afplay fails
            subprocess.run(["osascript", "-e", "beep"], capture_output=True)
    else:
        # Fallback to system beep if file doesn't exist
        subprocess.run(["osascript", "-e", "beep"], capture_output=True)

if __name__ == "__main__":
    sound_type = sys.argv[1] if len(sys.argv) > 1 else "done"
    play_sound(sound_type)