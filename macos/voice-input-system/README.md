# System-Wide Voice Input for macOS

## 🎯 **Overview**
A system-wide voice transcription utility inspired by ChatGPT.app's voice feature. Hold Fn key anywhere on macOS to record voice input, then automatically insert transcribed text at cursor location.

## ✨ **Features**
- **Global Voice Input:** Works in any macOS application
- **Fn Key Activation:** Hold Fn to record, release to transcribe
- **Local Processing:** Uses OpenAI Whisper model locally (private, fast)
- **Auto-Insert:** Text appears automatically at cursor location
- **Menu Bar Utility:** Lightweight, stays out of the way

## 🔧 **Technical Stack**
- **Platform:** macOS 15.6.1+ (Apple Silicon optimized)
- **Implementation:** Native Objective-C
- **Audio:** AVAudioRecorder (16kHz mono)
- **Transcription:** whisper.cpp with Large-v3-turbo model
- **Text Insertion:** Accessibility APIs + AppleScript fallback

## 📋 **Quick Start**
See `FINAL_SOLUTION_PROMPT.md` for complete implementation guide.

## 🎙️ **Usage**
1. Launch app (appears in menu bar)
2. Hold Fn key anywhere on system
3. Speak your message
4. Release Fn key
5. Text automatically appears at cursor

## 💡 **Inspiration**
Built by analyzing ChatGPT.app's excellent voice input functionality and implementing a similar system-wide solution using OpenAI's Whisper technology.

## 📁 **Project Structure**
```
whisper-macos/
├── WhisperAppMac.m              # Main source file
├── build_objc/                  # Build output
├── whisper.cpp/                 # Whisper engine
├── FINAL_SOLUTION_PROMPT.md     # Complete implementation guide
└── archive/                     # Development history
```

**Status:** Production ready with working auto-paste functionality across macOS applications.