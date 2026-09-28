# Manual Platform Channel Integration Tests

## Prerequisites

- Windows 10/11 or macOS 12+ machine
- Flutter SDK installed
- Admin/elevated privileges for process termination tests
- Test applications: Chrome, Discord, or any other common apps

---

## Windows Tests

## Phase 5 release-gate evidence (2026-09-28)

This release gate is limited to the authenticated student desktop app. Proctor
and host UI walkthroughs are deferred and are not inferred from this checklist.
The Phase 3 backend/host-read contract evidence remains the source for that
separate scope.

### Build identity

- Flutter: `3.41.9` / Dart `3.11.5`
- App version: `1.0.0+1`
- `pte-app` source: `2fc7e4b3f526c051407968a3a473ecdadcfae7e1`
- Release source state also includes the uncommitted Phase 5 fixture and DI
  wiring shown in the working tree; no commit or push was performed.
- `pte-api` source used for contract review: `244ebc245c5d4f341aa933b14a0c000866159347`
- `pte-web` source used for contract review: `e693cde8753ee8abc629764899780152159d84e0`
- No credentials, tokens, or environment values are recorded here.

### Release artifacts

| Artifact | Command | Result | SHA-256 |
|---|---|---|---|
| Production release | `flutter build windows --release --dart-define=PTE_LOCKDOWN_ACTIVATION_FAILURE_FIXTURE=false` | Built successfully; startup smoke process observed | `B61AADDA7BC4608C885DA1867021FA5C65A6B7E4B7AD9BA59211DFED0B2D5B38` |
| Controlled failure release | `flutter build windows --release --dart-define=PTE_LOCKDOWN_ACTIVATION_FAILURE_FIXTURE=true` | Built successfully; non-distributable | `D3CA9215D043AE864D9769892AC3CCFA88F05E5384CAFED8434F8A85BA3B521E` |

The two artifacts were built after separate `flutter clean` runs and have
different hashes. The production command does not enable `DEV_SKIP_AUTH` or
the failure fixture.

### Automated release-gate evidence

- Failure fixture test: passed; the injected window channel fails before the
  native fullscreen call.
- Scoped analyzer: passed.
- Production and controlled-failure Windows release builds: passed.
- Native plugin sources and runner registration were inspected; no native
  source change was required for this phase.

### Authenticated Windows matrix

The following rows require interactive execution with a fresh release binary
and a real authenticated local session. They remain deferred until executed;
source/unit evidence must not be substituted for desktop evidence.

| Scenario | Expected result | Observed result | Status |
|---|---|---|---|
| Practice `NONE` | Windowed; task 1 opens; no hooks | Not run in this non-interactive pass | Deferred |
| Practice `STANDARD` | Fullscreen/hooks before task 1 | Not run in this non-interactive pass | Deferred |
| Controlled activation failure | Task is blocked; retryable error | Artifact built; interactive run pending | Deferred |
| Fullscreen exit | Warning, local/server audit, attempt continues | Not run in this non-interactive pass | Deferred |
| Blocked shortcut | Warning, local/server audit, attempt continues | Not run in this non-interactive pass | Deferred |
| Clipboard change/paste | Warning, local/server audit, attempt continues | Not run in this non-interactive pass | Deferred |
| Official `STRICT` | Existing strict behavior | Not run in this non-interactive pass | Deferred |
| Offline then reconnect | One server row per client event ID | Not run in this non-interactive pass | Deferred |

The release gate remains open for interactive student testing. Do not
distribute the controlled-failure artifact.

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
