# Manual Platform Channel Integration Tests

## Prerequisites

- Windows 10/11 or macOS 12+ machine
- Flutter SDK installed
- Admin/elevated privileges for process termination tests
- Test applications: Chrome, Discord, or any other common apps

---

## Windows Tests

### Test 1: Fullscreen Enforcement

**Steps:**
1. Run the app: `flutter run -d windows`
2. Call `WindowManagerChannel().enforceFullscreen()` from Dart
3. Verify window enters fullscreen with no title bar or window controls
4. Try Alt+F4 or clicking close button → should not close
5. Call `WindowManagerChannel().exitFullscreen()`
6. Verify window returns to normal with title bar and controls

**Expected:**
- Fullscreen covers entire screen (primary monitor)
- No visible window decorations
- Cannot exit fullscreen via UI
- exitFullscreen() restores normal state

---

### Test 2: Process Enumeration

**Steps:**
1. Open Chrome.exe and Notepad.exe
2. Call `ProcessManagerChannel().getRunningProcesses()`
3. Print the returned list

**Expected:**
- List contains "chrome.exe" and "notepad.exe"
- List contains current process names (case-insensitive)

---

### Test 3: Process Termination

**Steps:**
1. Open Chrome.exe
2. Call `ProcessManagerChannel().terminateProcess("chrome.exe")`
3. Observe Chrome window

**Expected:**
- Chrome closes immediately
- Method returns `true`
- Calling again (when Chrome is not running) returns `false`

**Note:** Requires admin privileges. If UAC prompt appears, accept it.

---

### Test 4: Clipboard Clear

**Steps:**
1. Copy text "Hello World" to clipboard (Ctrl+C from any app)
2. Call `ClipboardMonitorChannel().clearClipboard()`
3. Try pasting in Notepad (Ctrl+V)

**Expected:**
- Nothing pastes (clipboard is empty)
- No error thrown

---

### Test 5: Shortcut Blocking

**Steps:**
1. Call `ShortcutInterceptorChannel().blockSystemShortcuts()`
2. Try Alt+Tab
3. Try Win+D (show desktop)
4. Try PrintScreen
5. Try Ctrl+Esc (Start menu)
6. Listen to `ShortcutInterceptorChannel().violations` stream
7. Call `ShortcutInterceptorChannel().unblock()`
8. Try Alt+Tab again

**Expected:**
- While blocked: All shortcuts are blocked, violations stream emits event types ("ALT_TAB", "WIN_KEY", etc.)
- After unblock: Shortcuts work normally

---

## macOS Tests

### Test 1: Fullscreen Enforcement

**Steps:**
1. Run the app: `flutter run -d macos`
2. Call `WindowManagerChannel().enforceFullscreen()`
3. Verify window enters fullscreen
4. Try Escape key → should not exit
5. Call `WindowManagerChannel().exitFullscreen()`

**Expected:**
- Window enters fullscreen mode
- Escape does not exit fullscreen
- exitFullscreen() restores normal state

---

### Test 2: Process Enumeration

**Steps:**
1. Open Safari and Finder
2. Call `ProcessManagerChannel().getRunningProcesses()`

**Expected:**
- List contains "Safari" and "Finder"

---

### Test 3: Process Termination

**Steps:**
1. Open Safari
2. Call `ProcessManagerChannel().terminateProcess("Safari")`

**Expected:**
- Safari closes immediately
- Method returns `true`

**Note:** May require accessibility permissions in System Preferences.

---

### Test 4: Clipboard Clear

**Steps:**
1. Copy text to clipboard (Cmd+C)
2. Call `ClipboardMonitorChannel().clearClipboard()`
3. Try pasting (Cmd+V)

**Expected:**
- Nothing pastes

---

### Test 5: Shortcut Blocking

**Steps:**
1. Call `ShortcutInterceptorChannel().blockSystemShortcuts()`
2. Try Cmd+Tab
3. Try Cmd+Q
4. Try Cmd+Shift+3 (screenshot)
5. Listen to violations stream
6. Call `ShortcutInterceptorChannel().unblock()`

**Expected:**
- While blocked: Shortcuts blocked, violations emitted
- After unblock: Shortcuts work

---

## Known Limitations

- **Windows**: Clipboard blocking only clears clipboard, does not distinguish internal vs external paste (full implementation requires deeper OS hooks)
- **macOS**: Event monitor may not catch all key combinations (some system shortcuts require Accessibility permissions)
- **Both platforms**: EventChannel streams not fully implemented (violations log to console only in Phase 2)

---

## Troubleshooting

### Windows: "Hook failed" error
- Run as Administrator
- Check if another app is already using a keyboard hook

### macOS: "Permission denied"
- Open System Preferences → Security & Privacy → Accessibility
- Add the Flutter app to the allowed list

### Process termination fails silently
- Windows: Requires admin privileges for protected processes
- macOS: Requires Accessibility permissions
