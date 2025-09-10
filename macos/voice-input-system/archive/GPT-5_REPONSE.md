Alright — let’s treat this like a stubborn Sequoia (macOS 15) privacy/tcc puzzle. You’ve already done the right groundwork. The fact that Cmd+V works manually and your CGEvents post without error but nothing appears strongly suggests a policy gate or receiver-side block, not a coding bug.

Below is a focused plan with checks you can run right now (and the exact APIs/commands), then answers to your questions.

⸻

High-signal checks (do these in order)
	1.	Verify “post event” permission via CoreGraphics (separate from AX)
	•	Apple DTS confirms there are dedicated APIs for input monitoring and posting events:
CGPreflightPostEventAccess, CGRequestPostEventAccess, plus the listen variants. Use these to verify you’re allowed to inject events independent of AX. If CGPreflightPostEventAccess() returns false, posting will be blocked. Call CGRequestPostEventAccess() once to trigger the OS flow.  ￼
	•	Docs for these symbols exist (lightweight, but real):  ￼
Obj-C snippet (call this at launch before you send keys):

extern bool CGPreflightPostEventAccess(void);
extern bool CGRequestPostEventAccess(void);

static BOOL ensureCanPostEvents(void) {
    if (CGPreflightPostEventAccess()) return YES;
    return CGRequestPostEventAccess() ? YES : NO;
}

If this returns NO, guide the user to Privacy settings (and re-launch after approval).

	2.	Check for Secure Keyboard Entry (SKE)
	•	When SKE is on, macOS blocks keystroke monitoring and can interfere with synthetic events being accepted (especially in terminals or password fields). Apple documents how Terminal toggles this; third-party docs and tooling confirm its global impact.  ￼ ￼
	•	Quick CLI to find who has secure input:

ioreg -l -w 0 | grep SecureInput

You’ll see kCGSSessionSecureInputPID; map that PID to a process (ps -o pid,comm -p <pid>). Alex Chan has a nice write-up.  ￼

	•	Also try a GUI check with Hammerspoon’s EventViewer or Karabiner’s EventViewer; they’ll show input activity and often reveal when secure input is active.  ￼ ￼

	3.	Differentiate Permissions
	•	Accessibility → needed for many “control your computer” actions and often required for CGEvent posting.  ￼ ￼
	•	Input Monitoring → required to listen globally (event taps / NSEvent global monitors). It’s separate from AX. Use IOHIDCheckAccess(kIOHIDRequestTypeListenEvent) to check; if you’re relying on global monitors (Fn detection), you’ll want it.  ￼
	•	Your symptom (typing fails but monitoring works) still fits “post access not granted / receiver rejecting / secure input”.
	4.	Receiver/Focus sanity
	•	Post only when the frontmost app is the expected target and the current responder can accept paste. Give the OS a moment after activating the app:

[[NSRunningApplication currentApplication] activateWithOptions:NSApplicationActivateIgnoringOtherApps];
// Then poll NSWorkspace.sharedWorkspace.frontmostApplication.bundleIdentifier == targetBundleID
// Once frontmost, usleep(150000) and post events


	•	Avoid protected fields (password sheets, some secure text views) — synthetic input is intentionally ignored there.

	5.	Automation (for AppleScript path)
	•	Your “osascript not allowed to send keystrokes” is Automation (AppleEvents) gating, not AX. Add NSAppleEventsUsageDescription and use AEDeterminePermissionToAutomateTarget(..., askUserIfNeeded=true) once per target (or System Events).  ￼

⸻

Concrete answers to your questions

1) Is Input Monitoring required for CGEventPost to work?
	•	Not strictly. Input Monitoring is about listening. For posting events, rely on CGPost access (see CGPreflightPostEventAccess/CGRequestPostEventAccess). Apple DTS: “If you’re just using CGEventTap there’s CGPreflight/CGRequest… for listen and post access. You only need Accessibility if you’re doing other Accessibility stuff.” In practice, many apps still require/ask for AX to post reliably across apps, but the canonical check is the CGPostEventAccess calls.  ￼

2) How do we check if Secure Keyboard Entry is blocking our events?
	•	Programmatically, you can query secure input state (various tools expose it) or use the CLI above to find kCGSSessionSecureInputPID. Apple’s Terminal doc explains SKE and how to toggle it (Terminal ▸ Secure Keyboard Entry). If SKE is on in a terminal (or any app), expect your global monitors and injections to misbehave.  ￼ ￼

3) Are there debugging tools to see if CGEvents reach their destination?
	•	There’s no official “CGEvent inspector” for other processes, but:
	•	Karabiner-EventViewer shows whether key events are being produced/received at a system level (handy sanity check).  ￼
	•	If EventViewer shows your physical keys but not your injected keys, your post permission or secure input is the culprit.
	•	You can also add a local event tap (CGEventTapCreate at .session with a high priority) just to confirm your posted events round-trip through the event system in your own session. If your local tap never sees your injected events, CGPreflightPostEventAccess is likely failing or SKE is active.

4) Could an ad-hoc signature block delivery?
	•	Ad-hoc signing is generally OK for local dev, but TCC sometimes keys authorization to the exact executable path and signature. If you rebuild frequently, TCC can get confused. If in doubt:
	•	Move the app to /Applications (you already did), remove old copies, then reset and re-grant:
tccutil reset Accessibility (and optionally reset listen/post access via your CGRequest calls). Apple support articles cover re-granting AX.  ￼
	•	Also, if you try the Automation route (AppleScript/System Events), missing NSAppleEventsUsageDescription will definitely block it on modern macOS.  ￼

5) Should we try AXUIElement text insertion instead of CGEvent?
	•	It can work (setting kAXValueAttribute on the focused text field), but it’s inconsistent across apps and bypasses normal editor behaviors (IME, autocorrect, keyboard shortcuts). It’s best as a fallback for known editors. CGEvents (or pasteboard + ⌘V) are still the most broadly compatible when allowed. Apple’s AX API overview notes the variability of AX interactions per app.  ￼

⸻

Targeted fixes for your codebase
	1.	Gate posting on CGPost access

if (!ensureCanPostEvents()) {
    // Show UI: “Enable ‘Allow to control your computer’ and approve keystroke posting”
    return;
}


	2.	Detect and surface Secure Input
	•	Show a non-blocking banner if secure input is active and name the offending app:

ioreg -l -w 0 | grep SecureInput
# parse kCGSSessionSecureInputPID → ps -o comm= -p <pid>

(If it’s Terminal/iTerm/Alacritty, instruct users to disable “Secure Keyboard Entry”.)  ￼ ￼

	3.	AppleScript fallback (only if user opts in)
	•	Add NSAppleEventsUsageDescription to Info.plist.
	•	Before sending keystrokes via System Events, call:

// Ask for per-target consent
// AEDeterminePermissionToAutomateTarget(..., typeWildCard, typeWildCard, true)

This fixes the “not allowed to send keystrokes” error path.  ￼

	4.	Make sure the same process that checks/post events is the one listed in Privacy
	•	AX/Input Monitoring/CGPost access all apply to the current executable. If you moved posting into a helper, that helper needs its own entries. (Common gotcha.) Apple’s AX trust docs clarify trust is for the current process.  ￼

⸻

Why your current setup still fails (most likely)
	•	You granted Accessibility, but did not obtain “post event” access via the CG APIs, and/or Secure Keyboard Entry is active in a foreground/ever-running terminal, causing the system to ignore injected events. The CG preflight/request APIs + SKE check will disambiguate this immediately.  ￼ ￼

⸻

If all else fails
	•	Test in TextEdit with no terminals running and SKE off. If CGPreflightPostEventAccess() returns true and TextEdit still doesn’t paste after a short focus delay, reset TCC:
tccutil reset Accessibility → relaunch app → call CGRequestPostEventAccess() and your AX prompting path again. Then retest.  ￼

⸻

Quick reference links
	•	AXIsProcessTrustedWithOptions (prompt): Apple docs.  ￼
	•	Post/listen access APIs: Apple DTS answer + CG* docs.  ￼ ￼
	•	Input Monitoring (IOHIDCheckAccess): Apple docs + WWDC19.  ￼
	•	Secure Keyboard Entry: Apple Terminal doc; finding the process holding secure input.  ￼ ￼
	•	Automation/AppleEvents permission & API: NSAppleEventsUsageDescription; AEDeterminePermissionToAutomateTarget.  ￼

If you paste the return values from CGPreflightPostEventAccess() and the output of the ioreg … SecureInput command, I can pinpoint which gate is currently blocking your auto-paste.