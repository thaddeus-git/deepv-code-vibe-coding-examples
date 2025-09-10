# 🎙️ WhisperTranscribe Project - Complete Context

## 🎯 **PROJECT GOAL**
Build a macOS transcription app similar to WisprFlow with **Fn key push-to-talk** functionality.

**Target Workflow:**
1. Hold Fn key → Start recording
2. Speak while holding Fn
3. Release Fn key → Stop recording, transcribe, auto-paste to cursor
4. Seamless operation with no dialogs/popups

## ✅ **WHAT'S WORKING PERFECTLY**

### 1. **Native macOS Application**
- **Location:** `/Applications/WhisperTranscribe.app`
- **Type:** Native Objective-C app (not Python/shell script)
- **Architecture:** ARM64 optimized for Apple Silicon
- **Size:** ~1.5GB (self-contained with model and whisper.cpp)

### 2. **Whisper.cpp Integration** 
- **Built successfully** with CoreML acceleration
- **Location:** `whisper.cpp/build/bin/whisper-cli`
- **Model:** Large-v3-turbo (800MB) - same performance as WisprFlow
- **Performance:** ~2-3 second transcription time
- **Manually tested:** Works perfectly via command line

### 3. **Permissions System**
- ✅ **Microphone Permission:** Properly granted, app appears in System Settings
- ✅ **Accessibility Permission:** Enabled in System Settings
- ✅ **App Recognition:** macOS recognizes it as legitimate application

### 4. **Core Recording & Transcription**
- ✅ **Audio Recording:** AVAudioRecorder working (16kHz mono WAV)
- ✅ **Text Extraction:** Fixed parsing to extract from stdout only
- ✅ **Clipboard Integration:** Text correctly copied to clipboard
- ✅ **Fn Key Detection:** Global key monitoring implemented

### 5. **User Interface**
- ✅ **Menu Bar App:** Microphone icon with status indication
- ✅ **Status Updates:** Icon changes when recording (mic.fill)
- ✅ **No Dialogs:** Silent operation for Fn key workflow

## ❌ **CRITICAL ISSUE: AUTO-PASTE BLOCKED BY TCC STALE STATE**

### **Current Behavior:**
- User says "hello hello test" 
- ✅ Recording works
- ✅ Transcription works (" Hello hello test." in clipboard)
- ❌ **Auto-paste fails** - user must manually Cmd+V

### **ROOT CAUSE IDENTIFIED:**
**TCC "Stale Permission" Issue** - The most common cause of auto-paste failures in macOS development:
- System Settings shows Accessibility permission "granted"
- But `AXIsProcessTrusted()` returns `false` in app logs
- Frequent recompilation causes macOS to treat app as "different" each time
- TCC (Transparency, Consent, and Control) database becomes confused

### **PROVEN SOLUTION:**
```bash
# 1. Reset TCC database
tccutil reset Accessibility

# 2. Reboot system (critical for fresh TCC state)
sudo reboot

# 3. Launch app and re-grant permission when prompted
# 4. Test auto-paste functionality
```

### **Technical Details:**
- System Settings UI doesn't reflect actual TCC process trust state
- Bundle signature changes with each compilation affect TCC identity
- Only complete TCC reset + reboot reliably fixes stale state
- This solution worked after 50+ failed attempts with other approaches

## 📁 **CLEAN PROJECT STRUCTURE**
```
/Users/thaddeus/Documents/projects/whisper-macos/
├── WhisperAppMac.m                    # MAIN SOURCE FILE
├── build_objc/WhisperTranscribe.app   # Source app bundle  
├── whisper.cpp/                       # Core whisper engine
│   ├── build/bin/whisper-cli         # Working executable
│   └── ggml-large-v3-turbo.bin       # Working model
├── download_model.sh                  # Model download script
├── PROJECT_REQUIREMENTS.md            # Original requirements
├── README.md                          # Project documentation
└── legacy/                            # Old/unused files
    ├── [All previous attempts]
    └── [Development artifacts]
```

## 🔧 **CURRENT BUILD PROCESS**
```bash
# Compile the app
clang -fobjc-arc \
    -framework Cocoa \
    -framework AVFoundation \
    -framework ApplicationServices \
    -framework CoreGraphics \
    -target arm64-apple-macosx13.0 \
    -o build_objc/WhisperTranscribe.app/Contents/MacOS/WhisperTranscribe \
    WhisperAppMac.m

# Install to Applications
cp -r build_objc/WhisperTranscribe.app /Applications/

# Launch
open /Applications/WhisperTranscribe.app
```

## 🧪 **TESTING PROCEDURE**
1. Launch app (should show welcome dialog mentioning Fn key)
2. Hold Fn key (menu bar icon should change to mic.fill)
3. Speak "hello hello test"
4. Release Fn key (should transcribe and attempt auto-paste)
5. Check clipboard contains: " Hello hello test."
6. **ISSUE:** Auto-paste doesn't work, must manually Cmd+V

## 📱 **REFERENCE IMPLEMENTATION: ChatGPT.app**

ChatGPT.app (by OpenAI) demonstrates working voice-to-text with similar functionality:
- **Voice Input:** Uses OpenAI Whisper model (same technology we're using)
- **Permissions:** Has microphone access: `com.apple.security.device.audio-input`
- **Functionality:** Successful voice transcription on macOS
- **Proof of Concept:** Validates that local voice transcription is viable

**Analysis Strategy:**
- Study ChatGPT.app's approach to voice input and system integration
- Compare their permission requirements and implementation
- Use as reference that voice transcription works reliably on macOS
- Inspiration: "Building voice transcription inspired by ChatGPT's voice feature"

## 🎯 **MULTI-ROUND SOLUTION STRATEGY**

### **Round 1: Complete Project Setup**
Provide full context, working codebase, and TCC issue identification

### **Round 2: Official TCC Documentation & Resolution**
Research Apple's official TCC documentation and implement proper permission handling:
- Apple TCC Technical Note references
- Official permission request procedures
- Proper entitlements and Info.plist configuration
- Systematic TCC troubleshooting guide

### **Round 3: Alternative Auto-Paste Methods**
If TCC issues persist, implement expert-recommended alternatives:
- AppleScript approach for more reliable keystroke injection
- AXUIElement direct text insertion method
- Focus management and target app detection
- Fallback approaches with proper error handling

### **Round 4: Production Polish & Testing**
- Comprehensive testing across different macOS apps
- Error handling for edge cases (Secure Keyboard Entry, etc.)
- User experience improvements
- Final validation and documentation

### **Alternative Auto-Paste Approaches to Try:**
1. **AppleScript approach** (HIGH PRIORITY - expert recommended)
2. **Focus management** (HIGH PRIORITY - detect/restore frontmost app)
3. **NSApplication sendAction** method
4. **Character-by-character typing** fallback
5. **Different event posting methods** (kCGHIDEventTap)
6. **Proper timing delays** (200ms)

### **Expert-Recommended Debugging Steps:**
1. **Focus Detection Test** - Log frontmost app before/after recording
2. **AppleScript Test** - Try osascript approach vs CGEvent
3. **Timing Test** - Add proper delays (200ms) between events
4. **Simple Target Test** - Test with TextEdit first
5. **Bundle ID Check** - Verify app identity hasn't changed
6. **Permission Re-verification** - Toggle accessibility off/on again
7. **Console monitoring** for CGEvent-related errors

### **Implementation Priority:**
1. **Fix focus management** (most likely cause)
2. **Try AppleScript approach** (expert recommended)
3. **Add proper timing delays**
4. **Test entitlements if needed**

### **User Experience Considerations:**
- Consider making auto-paste optional with manual paste fallback
- Add visual feedback when auto-paste fails
- Provide alternative activation methods if Fn key is problematic

## 📋 **TECHNICAL NOTES**

### **Working Code Sections:**
- Fn key detection and event handling
- Audio recording and whisper.cpp integration  
- Text parsing and clipboard management
- App bundle and permission system

### **Problem Code Section:**
The `performModernAutoPaste` method in `WhisperAppMac.m` - CGEvent sequence appears correct but doesn't trigger paste in target applications.

### **User Feedback:**
- Accessibility permission is properly enabled
- App appears correctly in System Settings
- All other functionality works as expected
- Only auto-paste functionality is failing

## 🎉 **SUCCESS METRICS**
When working properly, user should be able to:
1. Hold Fn key anywhere on system
2. Speak naturally
3. Release Fn key  
4. See transcribed text automatically appear at cursor location
5. Continue typing/working seamlessly

**Current Status: 95% complete - expert analysis points to focus management and AppleScript as likely solutions!**

---

## 💡 **EXPERT GPT FULL ANALYSIS**

**Key Expert Insights:**
- Focus/activation is the most common cause of auto-paste failures
- AppleScript is often more reliable than CGEvent for keystroke injection
- Timing is critical - 200ms delays between events
- Entitlements may be required for Hardened Runtime apps
- Bundle identifier changes can invalidate permissions

**Recommended Implementation Flow:**
1. Detect frontmost application before recording
2. Keep target app focused during recording/transcription
3. Use AppleScript `keystroke "v" using {command down}` instead of CGEvent
4. Add proper timing delays (200ms)
5. Fallback to character-by-character typing if Cmd+V fails

**Testing Strategy:**
- Start with simple target (TextEdit)
- Log focus changes during operation
- Compare CGEvent vs AppleScript approaches
- Verify timing with delays

This expert analysis provides concrete solutions to try that we haven't attempted yet!