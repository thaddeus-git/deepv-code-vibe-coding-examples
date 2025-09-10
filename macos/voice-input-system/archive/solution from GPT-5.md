Great question. There are basically three proven architectures people use to get voice → text → into the current cursor on macOS, plus a grab-bag of perms you must request.

1) “Dictate then paste” (most common & robust)
	•	Recognize speech in your app (Apple’s Speech framework or Whisper-based libs).
	•	Copy the transcript to the pasteboard, then synthesize ⌘V so it lands at the caret in the front app.
	•	Works in almost every editor and avoids AX text-field quirks.
	•	Requires Accessibility (to post the ⌘V key events) and often Input Monitoring (if you also listen globally for hotkeys/Fn).  ￼ ￼

Docs / examples
	•	Apple Speech framework overview (Swift): SFSpeechRecognizer (authorization, live/file requests).  ￼
	•	Posting key events: Core Graphics CGEvent reference.  ￼
	•	Global monitors & the “needs Accessibility/Input Monitoring” caveat: NSEvent monitoring doc + pqrs examples.  ￼ ￼

Open-source repos that already do this
	•	ashwin-pc/whisper-dictation – menu bar app, press Fn/Globe to record, transcribes with Whisper, auto-pastes at cursor.  ￼
	•	dbpprt/whispr – menubar app in Rust using whisper.cpp; local transcription, pastes to caret.  ￼
	•	ykdojo/super-voice-assistant – macOS app using WhisperKit; hotkey to record, auto-paste.  ￼

2) “Type it in” with synthetic key events
	•	Instead of pasting, emit per-character keydown/keyup via CGEvent to simulate real typing.
	•	Feels natural, but slower and can be blocked by Secure Keyboard Entry; still needs Accessibility. Many apps treat it like human typing though.  ￼

3) Build a real Input Method (IME) so text is inserted by the system
	•	Create a custom input source with InputMethodKit; your IME becomes the active keyboard and inserts text at the insertion point natively (best fidelity with IME/marked-text/IME-aware editors).
	•	Heavier lift (separate target, distribution, UX to switch input sources) and docs are… sparse—but it’s the most “system-correct” approach.  ￼

Docs / references for IME route
	•	InputMethodKit overview and classes (IMKServer, IMKInputController).  ￼
	•	Legacy class reference (but still clarifying insertion-point behavior).  ￼
	•	Apple’s user-facing doc on custom input sources (context on how they appear).  ￼

⸻

Permissions you’ll almost certainly need
	•	Accessibility: to post key events (⌘V or per-char typing) or to run global monitors in some cases.  ￼
	•	Input Monitoring: to capture global hotkeys/Fn or install a CGEventTap. (Catalina+ requirement.)  ￼

⸻

When to choose which
	•	Want speed, reliability, and minimal work? → Pasteboard + synth ⌘V.  ￼
	•	Need apps to behave as if a human typed (e.g., trigger autocorrect/shortcuts as you go)? → Per-char CGEvents.  ￼
	•	Building a power user tool that should behave like a real keyboard/input source across all editors (marked text, composition, IME correctness)? → InputMethodKit IME.  ￼

⸻

Bonus: Fresh Apple guidance
	•	Apple’s 2025 WWDC session on the Speech framework (improvements, samples).  ￼

If you tell me which route you prefer (paste-and-V vs. per-char vs. IME), I’ll drop in a minimal Swift starter showing the permissions checks and the insertion step for that approach.