#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>



@interface WhisperTranscribeApp : NSObject <NSApplicationDelegate>
@property (strong, nonatomic) NSStatusItem *statusItem;
@property (strong, nonatomic) AVAudioRecorder *audioRecorder;
@property (nonatomic) BOOL isRecording;
@property (strong, nonatomic) NSURL *recordingURL;
@property (nonatomic) BOOL fnKeyPressed;
@property (strong, nonatomic) id globalKeyMonitor;
@property (strong, nonatomic) id localKeyMonitor;
@property (nonatomic) NSInteger eventNumber;
@property (strong, nonatomic) NSRunningApplication *frontmostAppBeforeRecording;
@end

@implementation WhisperTranscribeApp

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    // Hide dock icon - menu bar only app
    [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
    
    // Create status bar item
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    
    NSStatusBarButton *button = self.statusItem.button;
    if (button) {
        button.image = [NSImage imageWithSystemSymbolName:@"mic" accessibilityDescription:@"Whisper Transcribe"];
        button.action = @selector(statusBarButtonClicked:);
        button.target = self;
    }
    
    NSLog(@"🎙️ WhisperTranscribe started!");
    
    // Initialize Fn key state
    self.fnKeyPressed = NO;
    self.eventNumber = 0;
    
    // DEBUG: Log what TCC cares about
    [self debugTCCStatus];
    
    // Try to access microphone immediately - this will trigger permission dialog
    [self requestMicrophonePermission];
    
    // Check and request Accessibility permission with proper prompting
    [self promptForAccessibilityPermissionOnce];
    
    // Skip CGPostEventAccess check for now - causing crashes on some macOS versions
    NSLog(@"⚠️ Skipping CGPostEventAccess check (API availability uncertain)");
    
    // Skip SKE check for now - was causing app to hang
    NSLog(@"⚠️ Skipping Secure Keyboard Entry check (was hanging app)");
    
    // Setup global Fn key monitoring (requires Input Monitoring)
    [self setupFnKeyMonitoring];
}

- (void)requestMicrophonePermission {
    // Create a temporary audio recorder to trigger permission dialog
    NSURL *tempURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"permission_test.wav"]];
    
    NSDictionary *settings = @{
        AVFormatIDKey: @(kAudioFormatLinearPCM),
        AVSampleRateKey: @16000,
        AVNumberOfChannelsKey: @1,
        AVLinearPCMBitDepthKey: @16,
        AVLinearPCMIsFloatKey: @NO,
        AVLinearPCMIsBigEndianKey: @NO
    };
    
    NSError *error;
    AVAudioRecorder *testRecorder = [[AVAudioRecorder alloc] initWithURL:tempURL settings:settings error:&error];
    
    if (error) {
        NSLog(@"❌ Permission test setup failed: %@", error.localizedDescription);
    } else {
        // This will trigger the microphone permission dialog
        if ([testRecorder record]) {
            NSLog(@"✅ Microphone permission granted");
            [testRecorder stop];
            [self showWelcomeDialog];
        } else {
            NSLog(@"❌ Microphone permission denied");
            [self showPermissionAlert];
        }
    }
    
    // Clean up test file
    [[NSFileManager defaultManager] removeItemAtURL:tempURL error:nil];
}

- (void)showWelcomeDialog {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"🎙️ WhisperTranscribe Ready";
    alert.informativeText = @"Microphone access granted!\n\n• Hold Fn key to start recording\n• Release Fn key to stop and transcribe\n• Text will auto-paste to cursor\n\nMenu bar icon shows recording status.";
    [alert addButtonWithTitle:@"OK"];
    [alert runModal];
}

- (void)showPermissionAlert {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Microphone Permission Required";
    alert.informativeText = @"WhisperTranscribe needs microphone access to record audio for transcription.\n\nPlease:\n1. Open System Settings\n2. Go to Privacy & Security > Microphone\n3. Enable WhisperTranscribe\n4. Restart the app";
    [alert addButtonWithTitle:@"Open System Settings"];
    [alert addButtonWithTitle:@"Cancel"];
    
    NSModalResponse response = [alert runModal];
    if (response == NSAlertFirstButtonReturn) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone"]];
    }
}

- (void)checkSecureKeyboardEntry {
    // Check for Secure Keyboard Entry which can block synthetic events
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/usr/sbin/ioreg";
    task.arguments = @[@"-l", @"-w", @"0"];
    
    NSPipe *pipe = [NSPipe pipe];
    task.standardOutput = pipe;
    
    [task launch];
    [task waitUntilExit];
    
    NSData *data = [[pipe fileHandleForReading] readDataToEndOfFile];
    NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    if ([output containsString:@"SecureInput"]) {
        NSLog(@"⚠️ WARNING: Secure Keyboard Entry may be active!");
        NSLog(@"💡 This can block auto-paste. Check Terminal > Secure Keyboard Entry");
        
        // Try to extract the PID
        NSRange range = [output rangeOfString:@"kCGSSessionSecureInputPID"];
        if (range.location != NSNotFound) {
            NSLog(@"🔍 Secure input detected in system");
        }
    } else {
        NSLog(@"✅ No Secure Keyboard Entry detected");
    }
}



- (void)debugTCCStatus {
    pid_t pid = getpid();
    NSString *exePath = [[NSBundle mainBundle] executablePath] ?: [[NSProcessInfo processInfo] arguments][0] ?: @"unknown";
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier] ?: @"unknown";
    Boolean trusted = AXIsProcessTrusted();
    
    NSLog(@"🔍 PERMISSION AUDIT:");
    NSLog(@"   PID: %d", pid);
    NSLog(@"   EXE: %@", exePath);
    NSLog(@"   Bundle ID: %@", bundleID);
    NSLog(@"   Accessibility: %s", trusted ? "✅ GRANTED" : "❌ DENIED");
    
    // Input Monitoring permission check not available on this macOS version
    NSLog(@"   Input Monitoring: ⚠️ Cannot check programmatically");
}

- (void)promptForAccessibilityPermissionOnce {
    // First check current status
    Boolean currentlyTrusted = AXIsProcessTrusted();
    NSLog(@"🔒 Current Accessibility trust: %s", currentlyTrusted ? "YES" : "NO");
    
    if (!currentlyTrusted) {
        NSLog(@"🔒 Prompting for Accessibility permission...");
        // Prompt with system dialog
        NSDictionary *options = @{(__bridge id)kAXTrustedCheckOptionPrompt: @YES};
        Boolean result = AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef)options);
        NSLog(@"🔒 After prompt, Accessibility trust: %s", result ? "YES" : "NO");
        
        if (!result) {
            // Show our own guidance
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                NSAlert *alert = [[NSAlert alloc] init];
                alert.messageText = @"Accessibility Permission Required";
                alert.informativeText = @"WhisperTranscribe needs Accessibility permission for auto-paste.\n\n1. System Settings should have opened\n2. Go to Privacy & Security > Accessibility\n3. Enable WhisperTranscribe\n4. Restart the app";
                [alert addButtonWithTitle:@"OK"];
                [alert runModal];
            });
        }
    }
}

- (void)checkAccessibilityPermission {
    // Check if the app has Accessibility permission
    NSDictionary *options = @{(__bridge id)kAXTrustedCheckOptionPrompt: @YES};
    Boolean accessEnabled = AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef)options);
    
    if (accessEnabled) {
        NSLog(@"✅ Accessibility permission granted");
    } else {
        NSLog(@"❌ Accessibility permission needed");
        // The system dialog should appear automatically due to kAXTrustedCheckOptionPrompt
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSAlert *alert = [[NSAlert alloc] init];
            alert.messageText = @"Accessibility Permission Required";
            alert.informativeText = @"WhisperTranscribe needs Accessibility permission to auto-paste transcribed text.\n\nIMPORTANT: If you already enabled it, try:\n1. Go to System Settings > Privacy & Security > Accessibility\n2. UNCHECK WhisperTranscribe\n3. RE-CHECK WhisperTranscribe\n4. Restart the app\n\nThis fixes 'stale permission' issues on modern macOS.";
            [alert addButtonWithTitle:@"Open System Settings"];
            [alert addButtonWithTitle:@"Continue Without Auto-Paste"];
            
            NSModalResponse response = [alert runModal];
            if (response == NSAlertFirstButtonReturn) {
                [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"]];
            }
        });
    }
}

- (void)setupFnKeyMonitoring {
    NSLog(@"🎹 Setting up Fn key monitoring...");
    
    // Monitor global key events for Fn key detection
    self.globalKeyMonitor = [NSEvent addGlobalMonitorForEventsMatchingMask:NSEventMaskFlagsChanged
                                                                   handler:^(NSEvent *event) {
        [self handleFnKeyEvent:event];
    }];
    
    // Monitor local key events as well (when app is focused)
    self.localKeyMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskFlagsChanged
                                                                  handler:^NSEvent *(NSEvent *event) {
        [self handleFnKeyEvent:event];
        return event;
    }];
    
    NSLog(@"✅ Fn key monitoring active");
}

- (void)handleFnKeyEvent:(NSEvent *)event {
    // Check for .flagsChanged events and look for .function modifier
    if (event.type == NSEventTypeFlagsChanged) {
        BOOL currentFnState = (event.modifierFlags & NSEventModifierFlagFunction) != 0;
        
        NSLog(@"🎹 Flag changed - Fn state: %s (was: %s)", 
              currentFnState ? "pressed" : "released", 
              self.fnKeyPressed ? "pressed" : "released");
        
        // Check for Fn key press (transition from not pressed to pressed)
        if (currentFnState && !self.fnKeyPressed) {
            self.fnKeyPressed = YES;
            NSLog(@"🎙️ Fn key pressed - starting recording");
            [self startFnRecording];
        }
        // Check for Fn key release (transition from pressed to not pressed)
        else if (!currentFnState && self.fnKeyPressed) {
            self.fnKeyPressed = NO;
            NSLog(@"⏹️ Fn key released - stopping recording");
            [self stopFnRecording];
        }
    }
}

- (void)startFnRecording {
    if (self.isRecording) return;
    
    // Store the currently frontmost application
    self.frontmostAppBeforeRecording = [[NSWorkspace sharedWorkspace] frontmostApplication];
    NSLog(@"🎯 Detected frontmost app: %@", self.frontmostAppBeforeRecording.localizedName);
    
    // Use system temp directory instead of user Documents to avoid permission request
    NSString *tempDir = NSTemporaryDirectory();
    NSString *filename = [NSString stringWithFormat:@"whisper_recording_%.0f.wav", [[NSDate date] timeIntervalSince1970]];
    self.recordingURL = [NSURL fileURLWithPath:[tempDir stringByAppendingPathComponent:filename]];
    
    // Audio settings for whisper.cpp
    NSDictionary *settings = @{
        AVFormatIDKey: @(kAudioFormatLinearPCM),
        AVSampleRateKey: @16000,
        AVNumberOfChannelsKey: @1,
        AVLinearPCMBitDepthKey: @16,
        AVLinearPCMIsFloatKey: @NO,
        AVLinearPCMIsBigEndianKey: @NO
    };
    
    NSError *error;
    self.audioRecorder = [[AVAudioRecorder alloc] initWithURL:self.recordingURL settings:settings error:&error];
    
    if (error) {
        NSLog(@"❌ Recording setup failed: %@", error.localizedDescription);
        return;
    }
    
    if ([self.audioRecorder record]) {
        self.isRecording = YES;
        [self updateStatusIcon];
        NSLog(@"🎙️ Fn recording started...");
    } else {
        NSLog(@"❌ Failed to start Fn recording");
    }
}

- (void)stopFnRecording {
    if (!self.isRecording) return;
    
    [self.audioRecorder stop];
    self.audioRecorder = nil;
    self.isRecording = NO;
    [self updateStatusIcon];
    
    NSLog(@"⏹️ Fn recording stopped");
    [self transcribeAudioSilently];
}

- (void)statusBarButtonClicked:(id)sender {
    NSMenu *menu = [[NSMenu alloc] init];
    
    NSString *statusText = self.isRecording ? @"Status: Recording..." : @"Status: Ready";
    NSMenuItem *statusItem = [[NSMenuItem alloc] initWithTitle:statusText action:nil keyEquivalent:@""];
    [menu addItem:statusItem];
    
    [menu addItem:[NSMenuItem separatorItem]];
    
    if (!self.isRecording) {
        NSMenuItem *recordItem = [[NSMenuItem alloc] initWithTitle:@"Start Recording" action:@selector(startRecording:) keyEquivalent:@""];
        recordItem.target = self;
        [menu addItem:recordItem];
    } else {
        NSMenuItem *stopItem = [[NSMenuItem alloc] initWithTitle:@"Stop Recording" action:@selector(stopRecording:) keyEquivalent:@""];
        stopItem.target = self;
        [menu addItem:stopItem];
    }
    
    [menu addItem:[NSMenuItem separatorItem]];
    
    NSMenuItem *quitItem = [[NSMenuItem alloc] initWithTitle:@"Quit" action:@selector(quit:) keyEquivalent:@"q"];
    quitItem.target = self;
    [menu addItem:quitItem];
    
    // Set menu and show it
    self.statusItem.menu = menu;
}

- (void)startRecording:(id)sender {
    if (self.isRecording) return;
    
    // Create temporary file
    NSString *tempDir = NSTemporaryDirectory();
    NSString *filename = [NSString stringWithFormat:@"whisper_recording_%.0f.wav", [[NSDate date] timeIntervalSince1970]];
    self.recordingURL = [NSURL fileURLWithPath:[tempDir stringByAppendingPathComponent:filename]];
    
    // Audio settings for whisper.cpp
    NSDictionary *settings = @{
        AVFormatIDKey: @(kAudioFormatLinearPCM),
        AVSampleRateKey: @16000,
        AVNumberOfChannelsKey: @1,
        AVLinearPCMBitDepthKey: @16,
        AVLinearPCMIsFloatKey: @NO,
        AVLinearPCMIsBigEndianKey: @NO
    };
    
    NSError *error;
    self.audioRecorder = [[AVAudioRecorder alloc] initWithURL:self.recordingURL settings:settings error:&error];
    
    if (error) {
        NSLog(@"❌ Recording setup failed: %@", error.localizedDescription);
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"Recording Error";
        alert.informativeText = error.localizedDescription;
        [alert addButtonWithTitle:@"OK"];
        [alert runModal];
        return;
    }
    
    if ([self.audioRecorder record]) {
        self.isRecording = YES;
        [self updateStatusIcon];
        NSLog(@"🎙️ Recording started...");
        
        // Show alert with record/stop option
        dispatch_async(dispatch_get_main_queue(), ^{
            NSAlert *alert = [[NSAlert alloc] init];
            alert.messageText = @"🔴 Recording";
            alert.informativeText = @"Speak now...\n\nClick 'Stop' when finished.";
            [alert addButtonWithTitle:@"Stop Recording"];
            [alert runModal];
            
            // User clicked stop
            [self stopRecording:nil];
        });
    } else {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"Recording Failed";
        alert.informativeText = @"Could not start recording. Check microphone permissions.";
        [alert addButtonWithTitle:@"OK"];
        [alert runModal];
    }
}

- (void)stopRecording:(id)sender {
    if (!self.isRecording) return;
    
    [self.audioRecorder stop];
    self.audioRecorder = nil;
    self.isRecording = NO;
    [self updateStatusIcon];
    
    NSLog(@"⏹️ Recording stopped");
    [self transcribeAudio];
}

- (void)transcribeAudio {
    if (!self.recordingURL) return;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        // Get paths to bundled whisper resources
        NSBundle *bundle = [NSBundle mainBundle];
        NSString *whisperPath = [bundle pathForResource:@"whisper-cli" ofType:nil inDirectory:@"whisper"];
        NSString *modelPath = [bundle pathForResource:@"ggml-large-v3-turbo" ofType:@"bin" inDirectory:@"whisper"];
        
        if (!whisperPath || !modelPath) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSAlert *alert = [[NSAlert alloc] init];
                alert.messageText = @"Internal Error";
                alert.informativeText = [NSString stringWithFormat:@"Whisper components not found:\nWhisper CLI: %@\nModel: %@", whisperPath ?: @"NOT FOUND", modelPath ?: @"NOT FOUND"];
                [alert addButtonWithTitle:@"OK"];
                [alert runModal];
            });
            return;
        }
        
        NSLog(@"🔄 Running transcription with: %@", whisperPath);
        
        // Run whisper.cpp
        NSTask *task = [[NSTask alloc] init];
        task.launchPath = whisperPath;
        task.arguments = @[
            @"-m", modelPath,
            @"-f", self.recordingURL.path,
            @"--no-timestamps",
            @"--language", @"en"
        ];
        
        // Separate stdout and stderr - transcription goes to stdout, debug to stderr
        NSPipe *stdoutPipe = [NSPipe pipe];
        NSPipe *stderrPipe = [NSPipe pipe];
        task.standardOutput = stdoutPipe;
        task.standardError = stderrPipe;
        
        [task launch];
        [task waitUntilExit];
        
        // Read stdout (actual transcription)
        NSData *stdoutData = [[stdoutPipe fileHandleForReading] readDataToEndOfFile];
        NSString *stdoutOutput = [[NSString alloc] initWithData:stdoutData encoding:NSUTF8StringEncoding];
        
        // Read stderr (debug info) for logging
        NSData *stderrData = [[stderrPipe fileHandleForReading] readDataToEndOfFile];
        NSString *stderrOutput = [[NSString alloc] initWithData:stderrData encoding:NSUTF8StringEncoding];
        
        NSLog(@"📝 Whisper stdout: %@", stdoutOutput);
        NSLog(@"🔧 Whisper stderr: %@", stderrOutput);
        
        // Extract transcribed text from stdout only
        NSString *transcribedText = [stdoutOutput stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        // Remove any remaining unwanted characters or patterns
        if ([transcribedText hasPrefix:@"["] && [transcribedText hasSuffix:@"]"]) {
            // Remove timestamp brackets if they somehow got through
            transcribedText = @"";
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (transcribedText.length > 0) {
                NSLog(@"✅ Transcribed: '%@'", transcribedText);
                [self pasteText:transcribedText];
            } else {
                NSAlert *alert = [[NSAlert alloc] init];
                alert.messageText = @"No Speech Detected";
                alert.informativeText = @"No clear speech was detected in the recording. Please try speaking more clearly.";
                [alert addButtonWithTitle:@"OK"];
                [alert runModal];
            }
            
            // Clean up
            [[NSFileManager defaultManager] removeItemAtURL:self.recordingURL error:nil];
            self.recordingURL = nil;
        });
    });
}

- (void)transcribeAudioSilently {
    if (!self.recordingURL) return;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        // Get paths to bundled whisper resources
        NSBundle *bundle = [NSBundle mainBundle];
        NSString *whisperPath = [bundle pathForResource:@"whisper-cli" ofType:nil inDirectory:@"whisper"];
        NSString *modelPath = [bundle pathForResource:@"ggml-large-v3-turbo" ofType:@"bin" inDirectory:@"whisper"];
        
        if (!whisperPath || !modelPath) {
            NSLog(@"❌ Whisper components not found");
            return;
        }
        
        NSLog(@"🔄 Running silent transcription...");
        
        // Run whisper.cpp
        NSTask *task = [[NSTask alloc] init];
        task.launchPath = whisperPath;
        task.arguments = @[
            @"-m", modelPath,
            @"-f", self.recordingURL.path,
            @"--no-timestamps",
            @"--language", @"en"
        ];
        
        // Separate stdout and stderr - transcription goes to stdout, debug to stderr
        NSPipe *stdoutPipe = [NSPipe pipe];
        NSPipe *stderrPipe = [NSPipe pipe];
        task.standardOutput = stdoutPipe;
        task.standardError = stderrPipe;
        
        [task launch];
        [task waitUntilExit];
        
        // Read stdout (actual transcription)
        NSData *stdoutData = [[stdoutPipe fileHandleForReading] readDataToEndOfFile];
        NSString *stdoutOutput = [[NSString alloc] initWithData:stdoutData encoding:NSUTF8StringEncoding];
        
        NSLog(@"📝 Silent transcription result: %@", stdoutOutput);
        
        // Extract transcribed text from stdout only
        NSString *transcribedText = [stdoutOutput stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        // Remove any remaining unwanted characters or patterns
        if ([transcribedText hasPrefix:@"["] && [transcribedText hasSuffix:@"]"]) {
            // Remove timestamp brackets if they somehow got through
            transcribedText = @"";
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (transcribedText.length > 0) {
                NSLog(@"✅ Silent transcription: '%@'", transcribedText);
                [self pasteTextSilently:transcribedText];
            } else {
                NSLog(@"⚠️ No speech detected in Fn recording");
                // No dialog - just fail silently for Fn key usage
            }
            
            // Clean up
            [[NSFileManager defaultManager] removeItemAtURL:self.recordingURL error:nil];
            self.recordingURL = nil;
        });
    });
}

- (void)pasteText:(NSString *)text {
    // Copy to clipboard
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    [pasteboard clearContents];
    [pasteboard setString:text forType:NSPasteboardTypeString];
    
    // Show result with paste option
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"✅ Transcription Complete";
    alert.informativeText = [NSString stringWithFormat:@"Transcribed: %@\n\nText copied to clipboard.", text];
    [alert addButtonWithTitle:@"Paste Now"];
    [alert addButtonWithTitle:@"Done"];
    
    NSModalResponse response = [alert runModal];
    if (response == NSAlertFirstButtonReturn) {
        [self performSimpleCmdVPaste];
    }
}

- (void)pasteTextSilently:(NSString *)text {
    // Copy to clipboard
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    [pasteboard clearContents];
    [pasteboard setString:text forType:NSPasteboardTypeString];
    
    NSLog(@"📋 Text copied to clipboard: '%@'", text);
    
    // Check Accessibility permission before attempting auto-paste
    Boolean accessEnabled = AXIsProcessTrusted();
    
    if (accessEnabled) {
        // Auto-paste with proper timing and focus management
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self performAppleScriptAutoPaste];
        });
    } else {
        NSLog(@"⚠️ Accessibility permission not granted - text in clipboard only");
        NSLog(@"💡 Enable WhisperTranscribe in System Settings > Privacy & Security > Accessibility");
    }
}

- (void)performAppleScriptAutoPaste {
    NSLog(@"🔄 Starting pasteboard + Cmd+V auto-paste...");
    
    // First, ensure the target app is focused
    if (self.frontmostAppBeforeRecording) {
        NSLog(@"🎯 Restoring focus to: %@", self.frontmostAppBeforeRecording.localizedName);
        [self.frontmostAppBeforeRecording activateWithOptions:NSApplicationActivateIgnoringOtherApps];
        
        // Small delay to ensure focus is restored
        usleep(100000); // 0.1 second
    }
    
    // Simple, reliable approach: pasteboard is already set, just send Cmd+V
    [self performSimpleCmdVPaste];
}



- (void)performSimpleCmdVPaste {
    NSLog(@"🔄 Trying AXUIElement direct text insertion...");
    
    // Check accessibility permission
    Boolean trusted = AXIsProcessTrusted();
    NSLog(@"🔒 AX trusted for paste: %s", trusted ? "YES" : "NO");
    
    if (!trusted) {
        NSLog(@"❌ Cannot paste - no Accessibility permission");
        return;
    }
    
    // Get text from clipboard
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    NSString *textToInsert = [pasteboard stringForType:NSPasteboardTypeString];
    
    if (!textToInsert || textToInsert.length == 0) {
        NSLog(@"❌ No text in clipboard to insert");
        return;
    }
    
    NSLog(@"📝 Attempting AXUIElement text insertion: '%@'", textToInsert);
    
    // Get the focused application
    AXUIElementRef systemWideElement = AXUIElementCreateSystemWide();
    AXUIElementRef focusedApp = NULL;
    AXError error = AXUIElementCopyAttributeValue(systemWideElement, kAXFocusedApplicationAttribute, (CFTypeRef*)&focusedApp);
    
    if (error != kAXErrorSuccess || !focusedApp) {
        NSLog(@"❌ Failed to get focused application");
        CFRelease(systemWideElement);
        return;
    }
    
    // Get the focused UI element in that application
    AXUIElementRef focusedElement = NULL;
    error = AXUIElementCopyAttributeValue(focusedApp, kAXFocusedUIElementAttribute, (CFTypeRef*)&focusedElement);
    
    if (error != kAXErrorSuccess || !focusedElement) {
        NSLog(@"❌ Failed to get focused UI element");
        CFRelease(focusedApp);
        CFRelease(systemWideElement);
        return;
    }
    
    // Try to set the value directly
    CFStringRef textRef = (__bridge CFStringRef)textToInsert;
    error = AXUIElementSetAttributeValue(focusedElement, kAXValueAttribute, textRef);
    
    if (error == kAXErrorSuccess) {
        NSLog(@"✅ AXUIElement text insertion successful!");
    } else {
        NSLog(@"❌ AXUIElement text insertion failed, error: %d", error);
        NSLog(@"🔄 Falling back to CGEvent Cmd+V...");
        
        // Fallback to CGEvent method
        [self performCGEventFallback];
    }
    
    // Clean up
    CFRelease(focusedElement);
    CFRelease(focusedApp);
    CFRelease(systemWideElement);
}

- (void)performCGEventFallback {
    NSLog(@"🔄 CGEvent fallback - Sending Cmd+V...");
    
    // Create CGEvent source
    CGEventSourceRef source = CGEventSourceCreate(kCGEventSourceStateCombinedSessionState);
    
    if (!source) {
        NSLog(@"❌ Failed to create CGEvent source!");
        return;
    }
    
    // Create Cmd+V events (V key is 0x09)
    CGEventRef cmdVDown = CGEventCreateKeyboardEvent(source, 0x09, true);
    CGEventRef cmdVUp = CGEventCreateKeyboardEvent(source, 0x09, false);
    
    if (!cmdVDown || !cmdVUp) {
        NSLog(@"❌ Failed to create CGEvents!");
        CFRelease(source);
        return;
    }
    
    // Set Command flag
    CGEventSetFlags(cmdVDown, kCGEventFlagMaskCommand);
    CGEventSetFlags(cmdVUp, kCGEventFlagMaskCommand);
    
    // Post the events
    CGEventPost(kCGHIDEventTap, cmdVDown);
    CGEventPost(kCGHIDEventTap, cmdVUp);
    
    NSLog(@"📤 CGEvent Cmd+V posted");
    
    // Clean up
    CFRelease(cmdVDown);
    CFRelease(cmdVUp);
    CFRelease(source);
}

- (void)performCGEventAutoPasteFallback {
    NSLog(@"🔄 Simple CGEvent auto-paste...");
    
    // Simple delay 
    usleep(200000); // 0.2 second delay
    
    // Use virtual key codes for Command and V keys
    const CGKeyCode kVK_Command = 55;  // Left Command key
    const CGKeyCode kVK_ANSI_V = 9;    // V key
    
    CGEventSourceRef source = CGEventSourceCreate(kCGEventSourceStateCombinedSessionState);
    
    // Create Command key down event
    CGEventRef commandKeyDown = CGEventCreateKeyboardEvent(source, kVK_Command, true);
    CGEventSetFlags(commandKeyDown, kCGEventFlagMaskCommand);
    
    // Create V key down event (while Command is held)
    CGEventRef vKeyDown = CGEventCreateKeyboardEvent(source, kVK_ANSI_V, true);
    CGEventSetFlags(vKeyDown, kCGEventFlagMaskCommand);
    
    // Create V key up event (while Command is still held)
    CGEventRef vKeyUp = CGEventCreateKeyboardEvent(source, kVK_ANSI_V, false);
    CGEventSetFlags(vKeyUp, kCGEventFlagMaskCommand);
    
    // Create Command key up event
    CGEventRef commandKeyUp = CGEventCreateKeyboardEvent(source, kVK_Command, false);
    CGEventSetFlags(commandKeyUp, 0); // No modifiers
    
    // Post the events in sequence
    CGEventPost(kCGHIDEventTap, commandKeyDown);
    usleep(10000);
    CGEventPost(kCGHIDEventTap, vKeyDown);
    usleep(10000);
    CGEventPost(kCGHIDEventTap, vKeyUp);
    usleep(10000);
    CGEventPost(kCGHIDEventTap, commandKeyUp);
    
    // Clean up
    CFRelease(commandKeyDown);
    CFRelease(vKeyDown);
    CFRelease(vKeyUp);
    CFRelease(commandKeyUp);
    CFRelease(source);
    
    NSLog(@"⌨️ Simple auto-paste completed");
}

- (void)updateStatusIcon {
    NSStatusBarButton *button = self.statusItem.button;
    if (button) {
        NSString *symbolName = self.isRecording ? @"mic.fill" : @"mic";
        button.image = [NSImage imageWithSystemSymbolName:symbolName accessibilityDescription:@"Whisper Transcribe"];
    }
}

- (void)quit:(id)sender {
    // Clean up key monitors
    if (self.globalKeyMonitor) {
        [NSEvent removeMonitor:self.globalKeyMonitor];
        self.globalKeyMonitor = nil;
    }
    if (self.localKeyMonitor) {
        [NSEvent removeMonitor:self.localKeyMonitor];
        self.localKeyMonitor = nil;
    }
    
    [NSApp terminate:nil];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    // Clean up key monitors when app terminates
    if (self.globalKeyMonitor) {
        [NSEvent removeMonitor:self.globalKeyMonitor];
    }
    if (self.localKeyMonitor) {
        [NSEvent removeMonitor:self.localKeyMonitor];
    }
}

@end

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSApplication *app = [NSApplication sharedApplication];
        WhisperTranscribeApp *delegate = [[WhisperTranscribeApp alloc] init];
        app.delegate = delegate;
        [app run];
    }
    return 0;
}