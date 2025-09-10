# Voice Input System for macOS

System-wide voice transcription inspired by ChatGPT.app. Hold Fn key anywhere to record voice, auto-paste transcription.

## Features
- Global voice input in any macOS application
- Fn key activation (hold to record, release to transcribe)
- Local Whisper processing (private, fast)
- Automatic text insertion at cursor

## Quick Start
1. Download: [voice-input-system-v1.0.0-macos-arm64.dmg](releases/voice-input-system-v1.0.0-macos-arm64.dmg)
2. Install to Applications folder
3. Grant Microphone and Accessibility permissions
4. Hold Fn key anywhere, speak, release to auto-paste

## Technical Details
- Native Objective-C implementation
- whisper.cpp with Large-v3-turbo model
- AVAudioRecorder + Accessibility APIs
- Works on macOS 15.6.1+ Apple Silicon

