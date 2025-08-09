#!/usr/bin/env python3

import os
import sys
import random
import subprocess
from pathlib import Path

def play_sound(category):
    """Play a random sound from the specified category folder."""
    sounds_dir = Path.home() / '.claude' / 'sounds' / category
    
    if not sounds_dir.exists():
        print(f"Error: Sound category '{category}' not found at {sounds_dir}")
        return False
    
    # Get all audio files in the directory
    audio_extensions = {'.mp3', '.wav', '.m4a', '.aac', '.ogg', '.flac'}
    sound_files = [f for f in sounds_dir.glob('*') if f.suffix.lower() in audio_extensions and f.is_file()]
    
    if not sound_files:
        print(f"Error: No audio files found in {sounds_dir}")
        return False
    
    # Pick a random sound file
    selected_file = random.choice(sound_files)
    
    try:
        # Use afplay on macOS to play the audio file
        subprocess.run(['afplay', str(selected_file)], check=True)
        return True
    except subprocess.CalledProcessError as e:
        print(f"Error playing sound: {e}")
        return False
    except FileNotFoundError:
        print("Error: afplay command not found (macOS required)")
        return False

def main():
    if len(sys.argv) != 2:
        print("Usage: play_sound.py <category>")
        print("Available categories:")
        sounds_dir = Path.home() / '.claude' / 'sounds'
        if sounds_dir.exists():
            for category in sorted(sounds_dir.iterdir()):
                if category.is_dir():
                    print(f"  - {category.name}")
        sys.exit(1)
    
    category = sys.argv[1]
    success = play_sound(category)
    sys.exit(0 if success else 1)

if __name__ == '__main__':
    main()