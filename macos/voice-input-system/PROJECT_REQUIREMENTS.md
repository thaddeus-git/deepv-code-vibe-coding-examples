# macOS Transcription App - Project Requirements

## Overview
Building a WisprFlow-like transcription app for macOS ARM with local, fast transcription capabilities.

## Questions & Requirements (Please edit your answers below)

### 1. App Type & Interface
- **Native macOS app (Swift/SwiftUI) or web-based (Electron/Tauri)?** 
  - Answer: ______The native one,You can pick the modern type. Compatible is not a problem. _________

- **UI Style - Menu bar app, floating window, or full application?**
  - Answer: ______A menu bar is enough. _________

- **Push-to-talk button or always listening with wake word?**
  - Answer: ______No, I have to press the Fn button. _________

### 2. Transcription Engine
- **Preferred local model (Whisper.cpp, faster-whisper, or other)?**
  - Answer: ______Actually, I don't know. I only know the product or model called Wispr from OpenAPI .I can do the search for you if you need. _________

- **Model size preference (tiny/base/small for speed vs large for accuracy)?**
  - Answer: _______Maybe we can try large as long as the performance is good. Or try to guess what model the current APP(https://wisprflow.ai/) is using. It takes like 0.1 second to transcribe and accuracy is super great. ________

- **Real-time streaming transcription or process after recording ends?**
  - Answer: ______Actually, I don't know. I think both are great. Maybe start from an easier one. _________

### 3. Output & Integration
- **Where should transcribed text go (clipboard, specific apps, text file)?**
  - Answer: _______It should go directly to the Blinking arrow in a file or input place like terminal________

- **Should it auto-paste into active application?**
  - Answer: _______I think so.________

- **Need text formatting/punctuation correction?**
  - Answer: _______Let's try the original and consider this later. ________

### 4. User Experience
- **Global hotkey to start/stop recording?**
  - Answer: _______The Fn button. When I press it, it starts. When I release it, it stops. ________

- **Visual feedback during recording (waveform, pulsing icon)?**
  - Answer: ________This is optional, and we can do this later. But if it's too easy for you, then yes, a wave or pulsing icon floating on the bottom of the whole screen. _______

- **Notification when transcription is ready?**
  - Answer: _______I don't think we need notifications. ________

### 5. Technical Preferences
- **Maximum recording length?**
  - Answer: ________I don't know yet, maybe read the official document and see the suggestions for the maximum. _______

- **Should recordings be saved or discarded after transcription?**
  - Answer: _______No need to save. ________

- **Any specific microphone preferences or use system default?**
  - Answer: _______The system defaults ________

### 6. Privacy & Storage
- **All processing local (no cloud services)?**
  - Answer: ________Yes, locally. _______

- **Store transcription history or session-only?**
  - Answer: _______Let's consider this later. ________

## Next Steps
Once you've filled in the answers, I'll:
1. Set up the development environment
2. Choose the appropriate transcription model
3. Create the app architecture
4. Build the core functionality