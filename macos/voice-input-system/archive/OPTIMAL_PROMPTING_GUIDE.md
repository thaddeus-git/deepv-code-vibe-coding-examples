# Optimal Prompting Guide: How to Get AI to Solve Complex macOS Development Issues

## 🎯 **The Problem We Solved**
Building a macOS transcription app similar to WisprFlow with auto-paste functionality took 50+ iterations when it could have been solved in 5-10 with better prompting.

## 📋 **Single-Round Optimal Prompt Template**

### **Initial Comprehensive Prompt (Round 1)**

```
I want to build a macOS transcription app similar to WisprFlow with the following requirements:

**CORE FUNCTIONALITY:**
- Fn key push-to-talk recording
- Local Whisper.cpp transcription (ARM64 optimized)  
- Automatic paste of transcription to active app cursor location
- Menu bar only app (no dock icon)

**CRITICAL CONSTRAINTS:**
- macOS 15.6.1 (Sequoia) on Apple Silicon M3
- Must work with system security/TCC properly
- Target: /Applications/ installation, ad-hoc signed
- Should work like WisprFlow.ai (analyze their approach if needed)

**TECHNICAL APPROACH PREFERENCES:**
- Native Objective-C/Swift (not Electron)
- Use existing whisper.cpp binary
- Minimal external dependencies
- Proper macOS conventions and permissions

**DEBUGGING REQUIREMENTS:**
- Comprehensive logging for all permission checks
- Step-by-step systematic troubleshooting
- TCC/permission state verification at each step
- Never assume permissions are working - always verify

**SUCCESS CRITERIA:**
- Auto-paste works in TextEdit and other native apps
- No manual Cmd+V required
- Handles permission prompts gracefully
- Stable, doesn't crash or hang

**CRITICAL: Follow this methodology:**
1. Start with basic permission verification (don't assume anything works)
2. Implement simplest approach first, add complexity only if needed
3. Add extensive debug logging to verify each step
4. Test each component independently before integration
5. If permissions seem granted but features don't work, suspect TCC stale state

Please create a complete working implementation with proper error handling and systematic debugging. If you encounter permission issues, immediately suggest TCC reset procedures.
```

### **Follow-up Prompts (Rounds 2-3 if needed)**

**If Initial Implementation Fails:**
```
The app compiles but auto-paste doesn't work. Following systematic debugging approach:

1. What debug logs show about permission state?
2. Is AXIsProcessTrusted() actually returning true?
3. Should we reset TCC permissions (tccutil reset Accessibility)?
4. Are CGEvents being created successfully but not delivered?
5. What does analyzing WisprFlow.app reveal about their approach?

Please prioritize TCC troubleshooting over implementing alternative APIs.
```

**If Permission Issues Persist:**
```
Permission debugging shows [insert specific error logs]. 

Following GPT-5's systematic approach:
1. Reset TCC completely: tccutil reset Accessibility
2. Reboot system for fresh TCC state  
3. Re-grant permissions to newly compiled app
4. Test basic AXIsProcessTrusted() verification
5. Only then test CGEvent/AXUIElement functionality

Implement this step-by-step with verification at each stage.
```

## 🎯 **Key Prompt Elements That Would Have Accelerated Solution**

### **1. Explicit Debugging Methodology**
```
**CRITICAL: Use systematic debugging approach:**
- Verify basic assumptions first (don't skip permission checks)
- Add comprehensive logging for each step
- Test each component independently  
- If permissions appear granted but don't work, suspect TCC stale state
- Reset TCC before trying complex workarounds
```

### **2. Reference Implementation Analysis**
```
**CRITICAL: Analyze existing working solution:**
- Check WisprFlow.app entitlements: codesign -d --entitlements :- 
- Compare their permission requests in Info.plist
- If they use different approach, explain why and adapt
- Don't reinvent wheel if proven solution exists
```

### **3. TCC-Aware Development Process**
```
**CRITICAL: Handle TCC properly:**
- Frequent recompilation creates stale permission issues
- Always include tccutil reset in troubleshooting steps
- Test with fresh system reboots when permissions fail
- Never assume System Settings UI reflects actual process trust
```

### **4. Specific Technology Constraints**
```
**CRITICAL: Target exact environment:**
- macOS 15.6.1 Sequoia on Apple Silicon M3
- Ad-hoc signed, /Applications/ installation
- Must work with standard TCC/security model
- No private APIs or workarounds
```

## 📝 **Multi-Round Prompting Strategy**

### **Round 1: Complete Specification + Implementation**
- Full requirements with constraints
- Explicit debugging methodology  
- Reference to working solutions (WisprFlow)
- Request complete working implementation

### **Round 2: Systematic Debugging (if needed)**
- Share specific error logs/symptoms
- Request systematic troubleshooting approach
- Emphasize TCC reset procedures
- Ask for step-by-step verification

### **Round 3: Alternative Approaches (if needed)**
- If basic approach fails, explore alternatives
- Compare with reference implementations
- Consider different technical approaches
- Maintain systematic debugging principles

## 🔍 **Critical Insights That Should Be in Prompts**

### **1. macOS Development Gotchas**
```
**Key Issues to Address:**
- TCC permission stale state with frequent recompilation
- Secure Keyboard Entry blocking synthetic input in terminals
- Difference between Accessibility and Input Monitoring permissions
- App Translocation affecting permission identity
```

### **2. Problem-Solving Approach**
```
**Methodology:**
1. Implement simplest approach first (don't overengineer)
2. Verify each assumption with logging
3. Use systematic troubleshooting (permission checks → TCC reset → retest)
4. Learn from existing working solutions
5. Add complexity only when simple approaches fail
```

### **3. Success Indicators**
```
**How to Know You're on Right Track:**
- AXIsProcessTrusted() returns true in logs
- CGEvents created without errors
- Auto-paste works in some apps (TextEdit) but not others (Terminal)
- No crashes or hangs during operation
```

## 🎯 **The "Magic Prompt" (Single Round Solution)**

```
Build a macOS transcription app like WisprFlow with auto-paste. CRITICAL: Use systematic debugging approach - verify all permissions with logging, suspect TCC stale state if permissions appear granted but don't work, and include tccutil reset procedures. Target macOS 15.6.1 M3, native Objective-C, proper TCC handling. Analyze WisprFlow.app approach first. Start simple, add complexity only if needed.

Requirements:
- Fn key push-to-talk
- Local whisper.cpp transcription  
- Auto-paste to cursor location
- Menu bar app, /Applications/ install

Implementation priority:
1. Basic permission verification with extensive logging
2. Simple CGEvent or AXUIElement auto-paste
3. TCC troubleshooting if permissions fail
4. Reference WisprFlow implementation for comparison

Include complete debug logging for permission state verification.
```

## 💡 **Why This Would Work Better**

### **Prevents Common Mistakes:**
1. **Overengineering** - Explicitly requests simple approach first
2. **Permission Assumptions** - Demands verification logging  
3. **Ignoring TCC Issues** - Highlights TCC reset as primary troubleshooting
4. **Reinventing Wheel** - Requests analysis of working solution (WisprFlow)

### **Provides Clear Success Path:**
1. **Systematic approach** - Step-by-step methodology
2. **Specific constraints** - Exact technical environment
3. **Expected obstacles** - TCC issues, permission gotchas
4. **Verification steps** - How to confirm each stage works

### **Includes Expert Knowledge:**
1. **macOS-specific issues** - TCC stale state, Secure Keyboard Entry
2. **Development gotchas** - Frequent recompilation problems
3. **Proven solutions** - Reference existing working apps
4. **Debugging techniques** - Systematic troubleshooting approach

**The key insight: Include the debugging methodology and common gotchas in the initial prompt, don't discover them through trial and error.**