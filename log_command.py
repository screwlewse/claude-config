#!/usr/bin/env python3
import sys
import os
from datetime import datetime

def log_command():
    # Try to get notification details from various environment variables
    command = (
        os.environ.get('CLAUDE_NOTIFICATION_COMMAND', '') or
        os.environ.get('CLAUDE_COMMAND', '') or
        os.environ.get('NOTIFICATION_TEXT', '') or
        os.environ.get('NOTIFICATION_TITLE', '')
    )
    
    # If no command in env, try command line args
    if not command and len(sys.argv) > 1:
        command = ' '.join(sys.argv[1:])
    
    # If still no command, log all environment variables for debugging
    if not command:
        # Log available environment variables that might contain notification info
        env_vars = []
        for key, value in os.environ.items():
            if any(keyword in key.lower() for keyword in ['claude', 'notification', 'command', 'hook']):
                env_vars.append(f"{key}={value}")
        
        if env_vars:
            command = f"ENV_DEBUG: {'; '.join(env_vars)}"
        else:
            command = "NOTIFICATION_HOOK_TRIGGERED (no command data available)"
    
    # Create timestamp
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    
    # Create log filename with current date
    log_date = datetime.now().strftime('%Y-%m-%d')
    log_dir = os.path.expanduser('~/.claude/logs')
    log_file = os.path.join(log_dir, f'{log_date}-command-logs.log')
    
    # Ensure log directory exists
    os.makedirs(log_dir, exist_ok=True)
    
    # Create log entry
    log_entry = f'[{timestamp}] {command}\n'
    
    # Append to log file
    with open(log_file, 'a', encoding='utf-8') as f:
        f.write(log_entry)

if __name__ == '__main__':
    log_command()