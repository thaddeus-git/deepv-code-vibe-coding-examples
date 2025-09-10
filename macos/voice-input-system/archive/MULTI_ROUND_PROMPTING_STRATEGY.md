# Multi-Round Prompting Strategy: Building Voice Transcription App

## 🎯 **Inspired by ChatGPT.app's Voice Feature**

Building a local voice transcription app similar to ChatGPT.app's voice input functionality, using OpenAI's Whisper model for fast, accurate transcription.

---

## 📋 **ROUND 1: Project Setup & Context Analysis**

### **Magic Prompt for Round 1:**

```
I want to build a macOS voice transcription app inspired by ChatGPT.app's excellent voice input feature. 

**GOAL:** Hold Fn key → speak → release key → auto-paste transcription to cursor location

**REFERENCE:** ChatGPT.app proves this works (they use OpenAI Whisper successfully)

**CONTEXT:** I have a detailed project analysis showing a 95% working implementation with only auto-paste failing due to TCC permission issues.

**KEY INSIGHT:** The app records perfectly, transcribes accurately, copies to clipboard correctly, but CGEvent auto-paste fails despite Accessibility permissions appearing "granted" in System Settings. This is likely a TCC "stale permission" state.

**REQUEST:**
1. Review the attached context document for complete technical details
2. Confirm the TCC stale state diagnosis 
3. Prepare systematic approach for Round 2 TCC resolution

**TECHNICAL SPECS:**
- macOS 15.6.1 Sequoia, Apple Silicon M3
- Native Objective-C implementation
- Local whisper.cpp with Large-v3-turbo model
- Menu bar app, Fn key push-to-talk

[Attach CONTEXT_COMPLETE.md]

Expected outcome: Confirmation of approach and preparation for TCC resolution in Round 2.
```

**Expected Response:** AI confirms TCC diagnosis, reviews codebase status, prepares official documentation research for Round 2.

---

## 📋 **ROUND 2: Official TCC Documentation & Resolution**

### **Prompt for Round 2:**

```
Great analysis! Now let's solve the TCC permission issue using Apple's official documentation.

**OBJECTIVE:** Research and implement proper TCC (Transparency, Consent, and Control) handling based on Apple's official guidelines.

**SPECIFIC RESEARCH NEEDED:**
1. **Apple TCC Technical Notes** - Find official documentation on:
   - TCC database management and reset procedures
   - How app signatures affect TCC identity
   - Proper permission request sequences

2. **Official Entitlements Documentation** - Research:
   - Required entitlements for Accessibility API usage
   - Info.plist usage description requirements
   - Hardened Runtime compatibility

3. **Apple Sample Code** - Find official examples of:
   - CGEvent usage with proper permissions
   - AXUIElement implementation
   - System event handling best practices

**IMPLEMENTATION REQUEST:**
1. Update Info.plist with proper usage descriptions
2. Add required entitlements if needed
3. Implement systematic TCC verification logging
4. Provide step-by-step TCC reset procedure with Apple's recommended approach

**EXPECTED OUTCOME:** Working auto-paste using Apple's official TCC best practices.

If TCC resolution doesn't work, prepare alternative approaches for Round 3.
```

**Expected Response:** AI researches Apple docs, provides official TCC procedures, implements proper permission handling, tests solution.

---

## 📋 **ROUND 3: Alternative Auto-Paste Implementation** 

### **Prompt for Round 3:**

```
If TCC resolution from Round 2 didn't fully solve auto-paste, let's implement expert-recommended alternative approaches.

**ALTERNATIVE METHODS TO IMPLEMENT:**

1. **AppleScript Approach** (High Priority)
   ```applescript
   tell application "System Events"
       keystroke "v" using {command down}
   end tell
   ```
   - Often more reliable than CGEvent
   - Research NSAppleEventsUsageDescription requirements

2. **AXUIElement Direct Text Insertion**
   - Use AXUIElementSetAttributeValue with kAXValueAttribute
   - Direct text insertion without simulating keystrokes
   - Better compatibility across different apps

3. **Focus Management & Target Detection**
   - Properly detect frontmost application before recording
   - Maintain target app focus during transcription
   - Restore focus before attempting paste

4. **Enhanced Error Handling**
   - Detect Secure Keyboard Entry blocking
   - Graceful fallbacks when auto-paste fails
   - User feedback for different failure modes

**IMPLEMENTATION PRIORITY:**
1. Try AppleScript approach first
2. Implement AXUIElement as fallback
3. Add comprehensive error handling
4. Test across multiple applications (TextEdit, Notes, Terminal, etc.)

**EXPECTED OUTCOME:** Robust auto-paste that works across different macOS applications with proper fallback handling.
```

**Expected Response:** AI implements multiple auto-paste approaches, provides comprehensive testing, achieves reliable functionality.

---

## 📋 **ROUND 4: Production Polish & Comprehensive Testing**

### **Prompt for Round 4:**

```
Excellent! Now let's polish the solution for production use and comprehensive testing.

**PRODUCTION IMPROVEMENTS:**

1. **User Experience Enhancements**
   - Visual feedback for recording state
   - Error notifications when auto-paste fails
   - Optional manual paste fallback mode
   - Preferences for different activation methods

2. **Comprehensive App Testing**
   - Test in TextEdit, Notes, Mail, Terminal, VS Code, etc.
   - Handle edge cases (password fields, secure input)
   - Verify functionality across system updates

3. **Error Handling & Diagnostics**
   - Detailed logging for troubleshooting
   - User-friendly error messages
   - Automatic permission verification
   - Graceful degradation when features unavailable

4. **Documentation & Distribution**
   - User setup instructions
   - Troubleshooting guide
   - Known limitations and workarounds
   - Optional code signing for distribution

**FINAL VALIDATION:**
- Test complete workflow end-to-end
- Verify reliability across different system states
- Confirm user experience matches ChatGPT.app quality
- Document any remaining limitations

**EXPECTED OUTCOME:** Production-ready voice transcription app with reliable auto-paste functionality inspired by ChatGPT.app's voice feature.
```

**Expected Response:** AI provides polished, production-ready application with comprehensive testing and documentation.

---

## 🎯 **Success Criteria for Each Round**

### **Round 1 Success:**
- ✅ Context analyzed and approach confirmed
- ✅ TCC stale state diagnosed correctly  
- ✅ Systematic plan prepared for Round 2

### **Round 2 Success:**
- ✅ Apple official TCC documentation researched
- ✅ Proper entitlements and permissions implemented
- ✅ TCC reset procedure following Apple guidelines
- ✅ Auto-paste working OR clear reason why not

### **Round 3 Success:**
- ✅ Alternative auto-paste methods implemented
- ✅ AppleScript and/or AXUIElement approaches working
- ✅ Robust error handling and fallbacks
- ✅ Testing across multiple applications

### **Round 4 Success:**
- ✅ Production-quality user experience
- ✅ Comprehensive testing and validation
- ✅ Complete documentation and setup guide
- ✅ App ready for real-world usage

## 💡 **Why This Multi-Round Approach Works**

### **1. Systematic Problem Solving**
- Each round has a specific, focused objective
- Builds on previous round's results
- Prevents overwhelm with too much at once

### **2. Official Documentation Focus**
- Round 2 specifically targets Apple's official guidelines
- Reduces guesswork and trial-and-error
- Ensures compliance with macOS security model

### **3. Fallback Strategy Built-In**
- Round 3 prepared for if TCC doesn't solve everything
- Multiple technical approaches available
- Comprehensive error handling included

### **4. Production Readiness**
- Round 4 ensures real-world usability
- Testing across different scenarios
- Professional-quality end result

**Total Expected Duration:** 4 focused rounds instead of 50+ trial-and-error iterations.

**Key Advantage:** Each round has clear success criteria and builds systematically toward the final goal.