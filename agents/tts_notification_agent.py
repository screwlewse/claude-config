#!/usr/bin/env python3
"""
TTS Notification Agent - ElevenLabs Integration
Specialized sub-agent for generating professional task completion notifications
Reports back to prime agent in hierarchical system
"""

import os
import json
import time
import logging
import requests
import random
import subprocess
from datetime import datetime
from pathlib import Path
from typing import Dict, Any, Optional, Tuple, List
import hashlib


class TTSNotificationAgent:
    """
    Specialized sub-agent for TTS notifications using ElevenLabs API.
    Designed to operate within Claude Code's hierarchical agent system.
    """
    
    def __init__(self, config_path: Optional[str] = None):
        """Initialize the TTS Notification Agent"""
        self.agent_id = "tts-notification-agent-v1"
        self.config = self._load_config(config_path)
        self.logger = self._setup_logging()
        self.api_key = os.getenv('ELEVENLABS_API_KEY')
        self.base_url = self.config['configuration']['api_settings']['base_url']
        self.sounds_dir = Path.home() / '.claude' / 'sounds'
        self.sounds_dir.mkdir(parents=True, exist_ok=True)
        
    def _load_config(self, config_path: Optional[str] = None) -> Dict[str, Any]:
        """Load agent configuration"""
        if config_path is None:
            config_path = Path.home() / '.claude' / 'agents' / 'tts_notification_agent.json'
        
        try:
            with open(config_path, 'r') as f:
                return json.load(f)
        except FileNotFoundError:
            return self._get_default_config()
    
    def _get_default_config(self) -> Dict[str, Any]:
        """Return default configuration if config file is missing"""
        return {
            "configuration": {
                "api_settings": {
                    "base_url": "https://api.elevenlabs.io/v1",
                    "timeout": 30,
                    "retry_attempts": 3
                },
                "voice_settings": {
                    "default_voice_id": "21m00Tcm4TlvDq8ikWAM",
                    "stability": 0.75,
                    "similarity_boost": 0.85,
                    "style": 0.0,
                    "use_speaker_boost": True
                },
                "output_settings": {
                    "format": "mp3_44100_128",
                    "filename_pattern": "task_completed_{timestamp}.mp3"
                },
                "default_messages": {
                    "task_completed": "Task completed successfully.",
                    "task_failed": "Task execution encountered an error.",
                    "system_ready": "System ready for next task."
                }
            }
        }
    
    def _setup_logging(self) -> logging.Logger:
        """Setup logging for the agent"""
        log_dir = Path.home() / '.claude' / 'logs'
        log_dir.mkdir(parents=True, exist_ok=True)
        
        logger = logging.getLogger(self.agent_id)
        logger.setLevel(logging.INFO)
        
        # File handler
        fh = logging.FileHandler(log_dir / 'tts_agent.log')
        fh.setLevel(logging.INFO)
        formatter = logging.Formatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
        fh.setFormatter(formatter)
        logger.addHandler(fh)
        
        return logger
    
    def validate_prerequisites(self) -> Tuple[bool, str]:
        """Validate API key and other prerequisites"""
        if not self.api_key:
            return False, "ELEVENLABS_API_KEY environment variable not set"
        
        if not self.sounds_dir.exists():
            try:
                self.sounds_dir.mkdir(parents=True, exist_ok=True)
            except Exception as e:
                return False, f"Cannot create sounds directory: {str(e)}"
        
        return True, "Prerequisites validated successfully"
    
    def play_random_sound(self, folder_name: str) -> Dict[str, Any]:
        """
        Play a random sound file from the specified folder
        Returns structured response for prime agent
        """
        start_time = time.time()
        
        try:
            # Get sound files from the specified folder
            folder_path = self.sounds_dir / folder_name
            if not folder_path.exists():
                return self._create_error_response(
                    f"Sound folder '{folder_name}' does not exist", start_time
                )
            
            # Find all audio files in the folder
            audio_extensions = {'.mp3', '.wav', '.m4a', '.aac', '.ogg'}
            audio_files = [
                f for f in folder_path.iterdir() 
                if f.is_file() and f.suffix.lower() in audio_extensions
            ]
            
            if not audio_files:
                return self._create_error_response(
                    f"No audio files found in '{folder_name}' folder", start_time
                )
            
            # Select random file
            selected_file = random.choice(audio_files)
            
            # Play the file using afplay (macOS)
            try:
                subprocess.run(['afplay', str(selected_file)], check=True)
            except subprocess.CalledProcessError as e:
                return self._create_error_response(
                    f"Failed to play audio file: {str(e)}", start_time
                )
            
            execution_time = time.time() - start_time
            
            # Log success
            self.logger.info(
                f"Random sound played from '{folder_name}': {selected_file.name} "
                f"({execution_time:.2f}s)"
            )
            
            # Return success response for prime agent
            return {
                "status": "success",
                "agent_id": self.agent_id,
                "operation": "play_random_sound",
                "result": {
                    "message": f"Random sound played from '{folder_name}' folder",
                    "file_played": selected_file.name,
                    "file_path": str(selected_file),
                    "folder": folder_name,
                    "total_files_in_folder": len(audio_files),
                    "execution_time_seconds": round(execution_time, 2)
                },
                "timestamp": datetime.now().isoformat(),
                "reporting_to": "prime_agent"
            }
            
        except Exception as e:
            return self._create_error_response(str(e), start_time)
    
    def generate_task_completion_notification(
        self, 
        message: Optional[str] = None,
        voice_id: Optional[str] = None,
        filename_override: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Generate task completion TTS notification
        DEPRECATED: Use play_random_sound('done') instead
        Returns structured response for prime agent
        """
        # Redirect to play random sound from 'done' folder
        return self.play_random_sound('done')
    
    def _call_elevenlabs_api(self, text: str, voice_id: str) -> bytes:
        """Make API call to ElevenLabs TTS service"""
        url = f"{self.base_url}/text-to-speech/{voice_id}"
        
        headers = {
            "Accept": "audio/mpeg",
            "Content-Type": "application/json",
            "xi-api-key": self.api_key
        }
        
        voice_settings = self.config['configuration']['voice_settings']
        data = {
            "text": text,
            "model_id": "eleven_monolingual_v1",
            "voice_settings": {
                "stability": voice_settings['stability'],
                "similarity_boost": voice_settings['similarity_boost'],
                "style": voice_settings.get('style', 0.0),
                "use_speaker_boost": voice_settings.get('use_speaker_boost', True)
            }
        }
        
        timeout = self.config['configuration']['api_settings']['timeout']
        max_retries = self.config['configuration']['api_settings']['retry_attempts']
        
        for attempt in range(max_retries):
            try:
                response = requests.post(url, json=data, headers=headers, timeout=timeout)
                
                if response.status_code == 200:
                    return response.content
                else:
                    error_msg = f"ElevenLabs API error: {response.status_code} - {response.text}"
                    if attempt == max_retries - 1:
                        raise Exception(error_msg)
                    else:
                        self.logger.warning(f"API attempt {attempt + 1} failed: {error_msg}")
                        time.sleep(1)  # Brief delay before retry
                        
            except requests.exceptions.RequestException as e:
                if attempt == max_retries - 1:
                    raise Exception(f"Network error calling ElevenLabs API: {str(e)}")
                else:
                    self.logger.warning(f"Network attempt {attempt + 1} failed: {str(e)}")
                    time.sleep(1)
    
    def _create_error_response(self, error_message: str, start_time: float) -> Dict[str, Any]:
        """Create standardized error response for prime agent"""
        execution_time = time.time() - start_time
        
        self.logger.error(f"TTS notification generation failed: {error_message}")
        
        return {
            "status": "error",
            "agent_id": self.agent_id,
            "operation": "generate_task_completion_notification",
            "error": {
                "message": error_message,
                "execution_time_seconds": round(execution_time, 2),
                "fallback_available": True,
                "fallback_type": "text_notification"
            },
            "timestamp": datetime.now().isoformat(),
            "reporting_to": "prime_agent"
        }
    
    def get_agent_status(self) -> Dict[str, Any]:
        """Return current agent status for prime agent"""
        valid, validation_msg = self.validate_prerequisites()
        
        return {
            "agent_id": self.agent_id,
            "status": "ready" if valid else "configuration_error",
            "configuration_valid": valid,
            "configuration_message": validation_msg,
            "sounds_directory": str(self.sounds_dir),
            "api_key_configured": bool(self.api_key),
            "timestamp": datetime.now().isoformat(),
            "reporting_to": "prime_agent"
        }
    
    def cleanup_old_files(self, days_old: int = 7) -> Dict[str, Any]:
        """Clean up old TTS files and report to prime agent"""
        try:
            cutoff_time = time.time() - (days_old * 24 * 60 * 60)
            cleaned_files = []
            
            for file_path in self.sounds_dir.glob("task_completed_*.mp3"):
                if file_path.stat().st_mtime < cutoff_time:
                    file_path.unlink()
                    cleaned_files.append(str(file_path))
            
            self.logger.info(f"Cleaned up {len(cleaned_files)} old TTS files")
            
            return {
                "status": "success",
                "agent_id": self.agent_id,
                "operation": "cleanup_old_files",
                "result": {
                    "files_cleaned": len(cleaned_files),
                    "cleaned_file_paths": cleaned_files,
                    "cutoff_days": days_old
                },
                "timestamp": datetime.now().isoformat(),
                "reporting_to": "prime_agent"
            }
            
        except Exception as e:
            return {
                "status": "error",
                "agent_id": self.agent_id,
                "operation": "cleanup_old_files",
                "error": {"message": str(e)},
                "timestamp": datetime.now().isoformat(),
                "reporting_to": "prime_agent"
            }


    def play_completion_sound(self) -> Dict[str, Any]:
        """Play a random sound for task completion"""
        return self.play_random_sound('done')
    
    def play_question_sound(self) -> Dict[str, Any]:
        """Play a random sound when waiting for user input"""
        return self.play_random_sound('question')
    
    def play_error_sound(self) -> Dict[str, Any]:
        """Play a random sound for errors"""
        return self.play_random_sound('error')
    
    def list_available_sounds(self) -> Dict[str, Any]:
        """List all available sound folders and their contents"""
        try:
            folders = {}
            for folder in self.sounds_dir.iterdir():
                if folder.is_dir():
                    audio_extensions = {'.mp3', '.wav', '.m4a', '.aac', '.ogg'}
                    audio_files = [
                        f.name for f in folder.iterdir() 
                        if f.is_file() and f.suffix.lower() in audio_extensions
                    ]
                    folders[folder.name] = audio_files
            
            return {
                "status": "success",
                "agent_id": self.agent_id,
                "operation": "list_available_sounds",
                "result": {
                    "folders": folders,
                    "total_folders": len(folders),
                    "sounds_directory": str(self.sounds_dir)
                },
                "timestamp": datetime.now().isoformat(),
                "reporting_to": "prime_agent"
            }
        except Exception as e:
            return {
                "status": "error",
                "agent_id": self.agent_id,
                "operation": "list_available_sounds",
                "error": {"message": str(e)},
                "timestamp": datetime.now().isoformat(),
                "reporting_to": "prime_agent"
            }


def main():
    """Main function for testing the agent"""
    import sys
    
    agent = TTSNotificationAgent()
    
    # If command line argument provided, play sound from that folder
    if len(sys.argv) > 1:
        folder_name = sys.argv[1]
        result = agent.play_random_sound(folder_name)
        print(json.dumps(result, indent=2))
        return
    
    # Default: show available sounds and test
    status = agent.list_available_sounds()
    print("Available sounds:")
    print(json.dumps(status, indent=2))
    
    # Test playing a completion sound
    print("\nTesting completion sound...")
    result = agent.play_completion_sound()
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()