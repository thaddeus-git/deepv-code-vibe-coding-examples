# Single-Round Voice Input System for macOS

## 🎯 **Project Goal**
Build a system-wide voice input solution for macOS that allows voice transcription in ANY desktop application, inspired by ChatGPT.app's voice feature.

**Target Functionality:**
- Hold Fn key anywhere on the system → start recording
- Speak naturally → local Whisper transcription  
- Release Fn key → automatically insert text at cursor location
- Works in TextEdit, Terminal, VS Code, browsers, any macOS app

## 📋 **Complete Single-Round Solution Prompt**

```
I want to build a system-wide voice input solution for macOS inspired by ChatGPT.app's voice feature.

**SYSTEM REQUIREMENTS:**
- macOS 15.6.1 Sequoia on Apple Silicon M3
- Global Fn key push-to-talk (works anywhere on desktop)
- Local OpenAI Whisper transcription (fast, private)
- Auto-insert transcribed text at cursor in ANY application
- Menu bar utility app (no dock icon)

**TECHNICAL SPECIFICATIONS:**
- Native Objective-C implementation
- Use existing whisper.cpp with Large-v3-turbo model
- Target: /Applications/ installation, self-contained
- ARM64 optimized for Apple Silicon

**CRITICAL SOLUTIONS TO IMPLEMENT:**

1. **TCC Permission Handling:**
   - Request Accessibility permission with proper prompts
   - Handle TCC stale state: include tccutil reset procedure
   - Verify permissions with AXIsProcessTrusted() logging
   - Add required Info.plist usage descriptions

2. **Global Key Monitoring:**
   - NSEvent global monitor for Fn key (NSEventModifierFlagFunction)
   - Proper event handling for flagsChanged events
   - Background operation without stealing focus

3. **Audio Recording & Transcription:**
   - AVAudioRecorder for 16kHz mono WAV
   - Execute whisper.cpp binary with captured audio
   - Parse stdout output for clean transcription text
   - Copy result to clipboard automatically

4. **System-Wide Text Insertion:**
   - Use AXUIElement approach: AXUIElementSetAttributeValue with kAXValueAttribute
   - Fallback to AppleScript: tell System Events to keystroke "v" using {command down}
   - Maintain target app focus during operation
   - Handle special cases (password fields, secure input)

5. **App Structure:**
   - Menu bar only app with microphone icon
   - Bundle whisper.cpp binary and model in Resources
   - Proper build process with all frameworks
   - Clean error handling and user feedback

**BUILD CONFIGURATION:**
```bash
clang -fobjc-arc \
    -framework Cocoa \
    -framework AVFoundation \
    -framework ApplicationServices \
    -framework CoreGraphics \
    -target arm64-apple-macosx13.0 \
    -o WhisperVoiceInput.app/Contents/MacOS/WhisperVoiceInput \
    WhisperVoiceInput.m
```

**SUCCESS CRITERIA:**
- Hold Fn in any app → speak → release → text appears at cursor
- Works in TextEdit, Terminal, VS Code, browsers
- No manual paste required
- Fast transcription (2-3 seconds)
- Reliable permission handling

**REFERENCE IMPLEMENTATION:**
ChatGPT.app demonstrates this functionality works (they use Whisper successfully for voice input).

Please implement the complete working solution with proper TCC handling, global key monitoring, and reliable text insertion across all macOS applications.
```

## 🎯 **Key Solution Components**

### **TCC Resolution (Known Solution):**
```bash
# If permissions fail:
tccutil reset Accessibility
sudo reboot
# Re-grant permission when prompted
```

### **Text Insertion Hierarchy:**
1. **AXUIElement direct insertion** (most reliable)
2. **AppleScript keystroke** (fallback)
3. **CGEvent Cmd+V** (last resort)

### **Proven Technical Stack:**
- Native Objective-C (not Electron)
- whisper.cpp with Large-v3-turbo model
- AVAudioRecorder for audio capture
- NSEvent global monitoring for Fn key
- Accessibility APIs for text insertion

## 💡 **Why This Single-Round Approach Works**

### **1. Complete Requirements Specified**
- Exact macOS version and hardware
- Specific functionality requirements
- Clear success criteria

### **2. Known Solutions Included**
- TCC handling procedures (the actual fix)
- Text insertion method hierarchy
- Proven technical stack choices

### **3. Reference Implementation**
- ChatGPT.app proves the concept works
- Same underlying technology (Whisper)
- Validates feasibility

### **4. System-Wide Focus**
- Not just "an app" but a system utility
- Works across all desktop applications
- Proper global event handling

**Expected Result:** Working system-wide voice input in single implementation round, avoiding the 50+ iteration cycle by including all known solutions upfront.