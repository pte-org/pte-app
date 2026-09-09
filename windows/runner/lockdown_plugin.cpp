#include "lockdown_plugin.h"

#include <flutter/event_channel.h>
#include <flutter/event_stream_handler_functions.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <string>

namespace lockdown_plugin {

LockdownPlugin* LockdownPlugin::instance_ = nullptr;

namespace {
constexpr char kWindowChannel[] = "com.pte.lockdown/window";
constexpr char kProcessChannel[] = "com.pte.lockdown/process";
constexpr char kClipboardChannel[] = "com.pte.lockdown/clipboard";
constexpr char kShortcutChannel[] = "com.pte.lockdown/shortcuts";
constexpr char kWindowEvents[] = "com.pte.lockdown/window/events";
constexpr char kProcessEvents[] = "com.pte.lockdown/process/events";
constexpr char kShortcutEvents[] = "com.pte.lockdown/shortcuts/events";
constexpr char kClipboardEvents[] = "com.pte.lockdown/clipboard/events";
constexpr UINT kClipboardUpdate = WM_CLIPBOARDUPDATE;

std::wstring Widen(const std::string& value) {
  if (value.empty()) return {};
  int length = MultiByteToWideChar(CP_UTF8, 0, value.data(),
                                   static_cast<int>(value.size()), nullptr, 0);
  std::wstring result(length, L'\0');
  MultiByteToWideChar(CP_UTF8, 0, value.data(),
                      static_cast<int>(value.size()), result.data(), length);
  return result;
}

std::string Narrow(const wchar_t* value) {
  if (!value) return {};
  const int length = WideCharToMultiByte(CP_UTF8, 0, value, -1, nullptr, 0,
                                         nullptr, nullptr);
  if (length <= 1) return {};
  std::string result(length, '\0');
  WideCharToMultiByte(CP_UTF8, 0, value, -1, result.data(), length, nullptr,
                      nullptr);
  result.pop_back();
  return result;
}
}  // namespace

void LockdownPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  auto plugin = std::make_unique<LockdownPlugin>(registrar);
  auto* plugin_pointer = plugin.get();

  auto window_channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      registrar->messenger(), kWindowChannel,
      &flutter::StandardMethodCodec::GetInstance());
  window_channel->SetMethodCallHandler(
      [plugin_pointer](const auto& call, auto result) {
        if (call.method_name() == "enforceFullscreen") {
          plugin_pointer->EnforceFullscreen(call, std::move(result));
        } else if (call.method_name() == "exitFullscreen") {
          plugin_pointer->ExitFullscreen(call, std::move(result));
        } else {
          result->NotImplemented();
        }
      });

  auto process_channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      registrar->messenger(), kProcessChannel,
      &flutter::StandardMethodCodec::GetInstance());
  process_channel->SetMethodCallHandler(
      [plugin_pointer](const auto& call, auto result) {
        if (call.method_name() == "getRunningProcesses") {
          plugin_pointer->GetRunningProcesses(call, std::move(result));
        } else if (call.method_name() == "terminateProcess") {
          plugin_pointer->TerminateProcess(call, std::move(result));
        } else {
          result->NotImplemented();
        }
      });

  auto clipboard_channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      registrar->messenger(), kClipboardChannel,
      &flutter::StandardMethodCodec::GetInstance());
  clipboard_channel->SetMethodCallHandler(
      [plugin_pointer](const auto& call, auto result) {
        if (call.method_name() == "blockExternalPaste") {
          plugin_pointer->BlockExternalPaste(call, std::move(result));
        } else if (call.method_name() == "clearClipboard") {
          plugin_pointer->ClearClipboard(call, std::move(result));
        } else if (call.method_name() == "unblock") {
          plugin_pointer->UnblockClipboard(call, std::move(result));
        } else {
          result->NotImplemented();
        }
      });

  auto shortcut_channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      registrar->messenger(), kShortcutChannel,
      &flutter::StandardMethodCodec::GetInstance());
  shortcut_channel->SetMethodCallHandler(
      [plugin_pointer](const auto& call, auto result) {
        if (call.method_name() == "blockSystemShortcuts") {
          plugin_pointer->BlockSystemShortcuts(call, std::move(result));
        } else if (call.method_name() == "unblock") {
          plugin_pointer->UnblockShortcuts(call, std::move(result));
        } else {
          result->NotImplemented();
        }
      });

  auto set_events = [registrar, plugin_pointer](const char* name,
                                                  auto assign_sink,
                                                  auto clear_sink) {
    auto channel = std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
        registrar->messenger(), name, &flutter::StandardMethodCodec::GetInstance());
    channel->SetStreamHandler(std::make_unique<flutter::StreamHandlerFunctions<flutter::EncodableValue>>(
        [assign_sink](const flutter::EncodableValue*,
                      std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&& sink) {
          assign_sink(std::move(sink));
          return nullptr;
        },
        [clear_sink](const flutter::EncodableValue*) {
          clear_sink();
          return nullptr;
        }));
  };
  set_events(kWindowEvents,
             [plugin_pointer](auto sink) { plugin_pointer->window_event_sink_ = std::move(sink); },
             [plugin_pointer]() { plugin_pointer->window_event_sink_.reset(); });
  set_events(kProcessEvents,
             [plugin_pointer](auto sink) { plugin_pointer->process_event_sink_ = std::move(sink); },
             [plugin_pointer]() { plugin_pointer->process_event_sink_.reset(); });
  set_events(kShortcutEvents,
             [plugin_pointer](auto sink) { plugin_pointer->shortcut_event_sink_ = std::move(sink); },
             [plugin_pointer]() { plugin_pointer->shortcut_event_sink_.reset(); });
  set_events(kClipboardEvents,
             [plugin_pointer](auto sink) { plugin_pointer->clipboard_event_sink_ = std::move(sink); },
             [plugin_pointer]() { plugin_pointer->clipboard_event_sink_.reset(); });

  registrar->AddPlugin(std::move(plugin));
}

LockdownPlugin::LockdownPlugin(flutter::PluginRegistrarWindows* registrar)
    : registrar_(registrar),
      hwnd_(registrar->GetView()->GetNativeWindow()),
      keyboard_hook_(nullptr),
      original_style_(0),
      original_ex_style_(0),
      original_rect_{},
      original_window_state_saved_(false),
      fullscreen_enforced_(false),
      clipboard_listener_registered_(false),
      clipboard_baseline_armed_(false) {
  // [clipboard_blocked_] / [shortcuts_blocked_] are std::atomic<bool>
  // with default initializers in the header — passing them via the
  // member-init list with a bool value works on MSVC, but the explicit
  // store() here keeps the construction site compatible with the
  // overload set we actually call throughout the rest of the plugin.
  clipboard_blocked_.store(false);
  shortcuts_blocked_.store(false);
  instance_ = this;
}

LockdownPlugin::~LockdownPlugin() {
  // Defense-in-depth: if the plugin is being torn down while a lockdown
  // session is still active, restore the window to its original style
  // before unwiring hooks. Without this, the platform could be left with
  // a modified WS_CAPTION-less window after the binder reclaims this
  // object.
  ExitFullscreenForTeardown();
  if (keyboard_hook_) {
    UnhookWindowsHookEx(keyboard_hook_);
    keyboard_hook_ = nullptr;
  }
  shortcuts_blocked_.store(false);
  UnregisterClipboardListener();
  instance_ = nullptr;
}

void LockdownPlugin::ExitFullscreenForTeardown() {
  // Best-effort cleanup — same sequence as ExitFullscreen's success path,
  // but without reporting a result and without short-circuiting when state
  // is missing. Safe to call from the destructor: every SetWindowLong /
  // SetWindowPos failure here is logged-and-ignored, never propagated.
  if (!hwnd_ || !original_window_state_saved_) return;
  SetLastError(ERROR_SUCCESS);
  ::SetWindowLong(hwnd_, GWL_STYLE, original_style_);
  ::SetWindowLong(hwnd_, GWL_EXSTYLE, original_ex_style_);
  ::SetWindowPos(hwnd_, HWND_NOTOPMOST, original_rect_.left, original_rect_.top,
                 original_rect_.right - original_rect_.left,
                 original_rect_.bottom - original_rect_.top,
                 SWP_FRAMECHANGED | SWP_NOACTIVATE);
  fullscreen_enforced_ = false;
  original_window_state_saved_ = false;
}

bool LockdownPlugin::RegisterClipboardListener() {
  if (clipboard_listener_registered_) return true;
  clipboard_listener_registered_ = AddClipboardFormatListener(hwnd_) == TRUE;
  return clipboard_listener_registered_;
}

void LockdownPlugin::UnregisterClipboardListener() {
  if (clipboard_listener_registered_) {
    RemoveClipboardFormatListener(hwnd_);
    clipboard_listener_registered_ = false;
  }
}

bool LockdownPlugin::HandleWindowMessage(UINT message, WPARAM wparam, LPARAM lparam) {
  auto* self = instance_;
  if (!self) return false;
  // Clipboard update path: detect an *external* write to the clipboard
  // while blocking is active. WM_CLIPBOARDUPDATE fires whenever the
  // clipboard contents change — not whenever a paste happens — so we
  // must never mutate the clipboard from here. We additionally compare
  // the current GetClipboardSequenceNumber() against the baseline armed
  // when blockExternalPaste was called; only a delta counts as an
  // external write, so internal app writes (which increment sequence by
  // exactly one and happen to be the source we expect) don't generate
  // false positives.
  if (message == WM_CLIPBOARDUPDATE) {
    if (!self->clipboard_blocked_.load()) return false;
    DWORD current = GetClipboardSequenceNumber();
    DWORD baseline = self->last_clipboard_sequence_.load();
    if (current != baseline) {
      HWND owner = GetClipboardOwner();
      if (owner && owner != self->hwnd_) {
        self->SendViolationEvent("clipboard", "CLIPBOARD_PASTE");
      }
      // Always advance the baseline, even when we ignored the event
      // (internal write), so subsequent external writes remain visible.
      self->last_clipboard_sequence_.store(current);
    }
    // Don't consume the message — Chrome/Flutter itself relies on
    // WM_CLIPBOARDUPDATE reaching the default handler chain for things
    // like the IME clipboard history.
    return false;
  }
  // Window violation detection: fullscreen-escape vectors include both
  // focus loss and the WM_SYSCOMMAND family (Alt+Enter, the restore/
  // maximize/minimize buttons on the window manager, and the
  // SC_KEYMENU alt-menu path). Hook only the relevant subcommands —
  // SC_MOVE is legitimate window dragging, SC_SIZE is legitimate
  // resizing from the system menu, etc. The plugin still reports only;
  // remediation policy lives in the Dart service layer.
  if (self->fullscreen_enforced_) {
    if (message == WM_KILLFOCUS) {
      self->SendViolationEvent("window", "FULLSCREEN_EXIT");
      return false;
    }
    if (message == WM_SYSCOMMAND) {
      int command = static_cast<int>(wparam) & 0xFFF0;
      if (command == SC_RESTORE || command == SC_MAXIMIZE ||
          command == SC_MINIMIZE || command == SC_KEYMENU ||
          command == SC_TASKLIST || command == SC_CLOSE) {
        self->SendViolationEvent("window", "FULLSCREEN_EXIT");
        // Don't consume — let Win32 do its default handling; the Dart
        // service layer decides whether to re-arm.
        return false;
      }
    }
  }
  return false;
}

void LockdownPlugin::EnforceFullscreen(const MethodCall&, std::unique_ptr<MethodResult> result) {
  if (!hwnd_) { result->Error("NO_WINDOW", "Window handle not available"); return; }
  // Capture the original style exactly once. EnforceFullscreen is idempotent
  // by design: subsequent calls must preserve the very first captured state.
  if (!original_window_state_saved_) {
    original_style_ = GetWindowLong(hwnd_, GWL_STYLE);
    original_ex_style_ = GetWindowLong(hwnd_, GWL_EXSTYLE);
    GetWindowRect(hwnd_, &original_rect_);
    original_window_state_saved_ = true;
  }
  // The phase spec calls for a WS_POPUP fullscreen — start from the
  // captured style, strip every caption/thickframe/border hint, and add
  // WS_POPUP so the window has no window-manager decorations at all on
  // Windows 10/11.
  LONG style = (original_style_ & ~(WS_CAPTION | WS_THICKFRAME | WS_MINIMIZE |
                                    WS_MAXIMIZE | WS_SYSMENU)) | WS_POPUP;
  LONG applied_style = SetWindowLong(hwnd_, GWL_STYLE, style);
  if (applied_style == 0) {
    result->Error("SET_WINDOW_STYLE_FAILED", "Failed to set fullscreen window style");
    // Roll back to the captured state — otherwise the user sees a
    // half-stripped window with no recovery path.
    ::SetWindowLong(hwnd_, GWL_STYLE, original_style_);
    ::SetWindowLong(hwnd_, GWL_EXSTYLE, original_ex_style_);
    // Trigger SWP_FRAMECHANGED so the OS recomputes non-client area
    // (re-attaches WS_CAPTION) even though we are restoring to the
    // original position. Without this, the window can remain
    // borderless on some GPU drivers until the next user resize.
    ::SetWindowPos(hwnd_, 0, 0, 0, 0, 0,
                    SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_FRAMECHANGED);
    return;
  }
  MONITORINFO monitor = {sizeof(monitor)};
  if (!GetMonitorInfo(MonitorFromWindow(hwnd_, MONITOR_DEFAULTTOPRIMARY), &monitor)) {
    result->Error("MONITOR_INFO_FAILED", "Failed to get monitor info");
    // Restore style AND trigger SWP_FRAMECHANGED so the original
    // window chrome is re-attached after SetWindowLong restores it.
    ::SetWindowLong(hwnd_, GWL_STYLE, original_style_);
    ::SetWindowLong(hwnd_, GWL_EXSTYLE, original_ex_style_);
    ::SetWindowPos(hwnd_, 0, 0, 0, 0, 0,
                    SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_FRAMECHANGED);
    return;
  }
  if (!SetWindowPos(hwnd_, HWND_TOP, monitor.rcMonitor.left, monitor.rcMonitor.top,
                    monitor.rcMonitor.right - monitor.rcMonitor.left,
                    monitor.rcMonitor.bottom - monitor.rcMonitor.top,
                    SWP_FRAMECHANGED | SWP_SHOWWINDOW)) {
    result->Error("SET_WINDOW_POS_FAILED", "Failed to set fullscreen position");
    // Restore style AND trigger SWP_FRAMECHANGED — the window is
    // still in its original position/size so only the frame change
    // matters here.
    ::SetWindowLong(hwnd_, GWL_STYLE, original_style_);
    ::SetWindowLong(hwnd_, GWL_EXSTYLE, original_ex_style_);
    ::SetWindowPos(hwnd_, 0, 0, 0, 0, 0,
                    SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_FRAMECHANGED);
    return;
  }
  fullscreen_enforced_ = true;
  result->Success();
}

void LockdownPlugin::ExitFullscreen(const MethodCall&, std::unique_ptr<MethodResult> result) {
  if (!hwnd_ || !original_window_state_saved_) { result->Success(); return; }
  SetLastError(ERROR_SUCCESS);
  LONG applied_style = SetWindowLong(hwnd_, GWL_STYLE, original_style_);
  LONG applied_ex_style = SetWindowLong(hwnd_, GWL_EXSTYLE, original_ex_style_);
  bool style_ok = GetLastError() == ERROR_SUCCESS && applied_style == original_style_ &&
                  applied_ex_style == original_ex_style_;
  if (!SetWindowPos(hwnd_, HWND_NOTOPMOST, original_rect_.left, original_rect_.top,
                    original_rect_.right - original_rect_.left,
                    original_rect_.bottom - original_rect_.top,
                    SWP_FRAMECHANGED | SWP_NOACTIVATE)) {
    // Position failure is also a corruption of the captured state —
    // surface it so the upper layer can decide to retry.
    result->Error("RESTORE_WINDOW_FAILED", "Failed to restore window state");
    return;
  }
  if (!style_ok) {
    result->Error("RESTORE_STYLE_FAILED", "Failed to restore window style");
    return;
  }
  fullscreen_enforced_ = false;
  original_window_state_saved_ = false;
  result->Success();
}

void LockdownPlugin::GetRunningProcesses(const MethodCall&, std::unique_ptr<MethodResult> result) {
  flutter::EncodableList processes;
  HANDLE snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if (snapshot == INVALID_HANDLE_VALUE) { result->Error("SNAPSHOT_FAILED", "Failed to create process snapshot"); return; }
  PROCESSENTRY32W entry{sizeof(entry)};
  if (!Process32FirstW(snapshot, &entry)) { CloseHandle(snapshot); result->Error("ENUMERATION_FAILED", "Failed to enumerate processes"); return; }
  do { processes.emplace_back(Narrow(entry.szExeFile)); } while (Process32NextW(snapshot, &entry));
  CloseHandle(snapshot);
  result->Success(flutter::EncodableValue(processes));
}

void LockdownPlugin::TerminateProcess(const MethodCall& call, std::unique_ptr<MethodResult> result) {
  const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
  if (!args) { result->Error("BAD_ARGS", "Arguments must be a map"); return; }
  const auto it = args->find(flutter::EncodableValue("name"));
  const auto* name = it == args->end() ? nullptr : std::get_if<std::string>(&it->second);
  if (!name || name->empty()) { result->Error("BAD_ARGS", "Missing or invalid 'name' argument"); return; }
  HANDLE snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if (snapshot == INVALID_HANDLE_VALUE) { result->Error("SNAPSHOT_FAILED", "Failed to create process snapshot"); return; }
  bool terminated = false;
  PROCESSENTRY32W entry{sizeof(entry)};
  if (Process32FirstW(snapshot, &entry)) {
    do {
      if (_wcsicmp(entry.szExeFile, Widen(*name).c_str()) == 0) {
        HANDLE process = OpenProcess(PROCESS_TERMINATE, FALSE, entry.th32ProcessID);
        if (process) { terminated = ::TerminateProcess(process, 0) == TRUE; CloseHandle(process); }
      }
    } while (!terminated && Process32NextW(snapshot, &entry));
  }
  CloseHandle(snapshot);
  result->Success(flutter::EncodableValue(terminated));
}

void LockdownPlugin::BlockExternalPaste(const MethodCall&, std::unique_ptr<MethodResult> result) {
  if (!RegisterClipboardListener()) { result->Error("CLIPBOARD_LISTENER_FAILED", "Failed to monitor clipboard"); return; }
  // Arm the clipboard sequence-number baseline before flipping the
  // blocking flag, so the very first WM_CLIPBOARDUPDATE that fires
  // (typically the OS notifying us about a clipboard *read* by a
  // different process during the activation window) doesn't immediately
  // trip a false violation.
  last_clipboard_sequence_.store(GetClipboardSequenceNumber());
  clipboard_baseline_armed_ = true;
  clipboard_blocked_.store(true);
  result->Success();
}

void LockdownPlugin::ClearClipboard(const MethodCall&, std::unique_ptr<MethodResult> result) {
  if (!OpenClipboard(hwnd_)) { if (result) result->Error("CLIPBOARD_FAILED", "Failed to open clipboard"); return; }
  const BOOL cleared = EmptyClipboard();
  CloseClipboard();
  if (result) cleared ? result->Success() : result->Error("CLIPBOARD_FAILED", "Failed to clear clipboard");
}

void LockdownPlugin::UnblockClipboard(const MethodCall&, std::unique_ptr<MethodResult> result) {
  clipboard_blocked_.store(false);
  // Drop the baseline so the next activation re-arms fresh — otherwise
  // any drift in the OS sequence number between sessions would
  // mask the first external write of the next attempt.
  clipboard_baseline_armed_ = false;
  last_clipboard_sequence_.store(0);
  UnregisterClipboardListener();
  result->Success();
}

void LockdownPlugin::BlockSystemShortcuts(const MethodCall&, std::unique_ptr<MethodResult> result) {
  if (keyboard_hook_) { result->Error("ALREADY_HOOKED", "Keyboard hook already installed"); return; }
  keyboard_hook_ = SetWindowsHookEx(WH_KEYBOARD_LL, KeyboardHookProc, nullptr, 0);
  if (!keyboard_hook_) { result->Error("HOOK_FAILED", "Failed to install keyboard hook"); return; }
  shortcuts_blocked_.store(true);
  result->Success();
}

void LockdownPlugin::UnblockShortcuts(const MethodCall&, std::unique_ptr<MethodResult> result) {
  if (keyboard_hook_) { UnhookWindowsHookEx(keyboard_hook_); keyboard_hook_ = nullptr; }
  shortcuts_blocked_.store(false);
  if (result) result->Success();
}

LRESULT CALLBACK LockdownPlugin::KeyboardHookProc(int nCode, WPARAM wParam,
                                                  LPARAM lParam) {
  if (nCode == HC_ACTION && instance_ && instance_->shortcuts_blocked_.load()) {
    if (wParam != WM_KEYDOWN && wParam != WM_SYSKEYDOWN &&
        wParam != WM_KEYUP && wParam != WM_SYSKEYUP) {
      // Always forward the original wParam/lParam — passing 0 instead of
      // wParam corrupts the event for every downstream hook.
      return CallNextHookEx(nullptr, nCode, wParam, lParam);
    }
    const auto* key = reinterpret_cast<const KBDLLHOOKSTRUCT*>(lParam);
    const bool alt = (GetAsyncKeyState(VK_MENU) & 0x8000) != 0;
    const bool ctrl = (GetAsyncKeyState(VK_CONTROL) & 0x8000) != 0;
    std::string violation;
    if ((key->vkCode == VK_TAB || key->vkCode == VK_F4) && alt) violation = key->vkCode == VK_TAB ? "ALT_TAB" : "ALT_F4";
    else if (key->vkCode == VK_LWIN || key->vkCode == VK_RWIN) violation = "WIN_KEY";
    else if (key->vkCode == VK_SNAPSHOT) violation = "PRINTSCREEN";
    else if (key->vkCode == VK_ESCAPE && ctrl) violation = "CTRL_ESC";
    if (!violation.empty()) { instance_->SendViolationEvent("shortcuts", violation); return 1; }
  }
  return CallNextHookEx(nullptr, nCode, wParam, lParam);
}

void LockdownPlugin::SendViolationEvent(const std::string& channel, const std::string& violation) {
  auto event = flutter::EncodableValue(violation);
  if (channel == "shortcuts" && shortcut_event_sink_) shortcut_event_sink_->Success(event);
  else if (channel == "window" && window_event_sink_) window_event_sink_->Success(event);
  else if (channel == "process" && process_event_sink_) process_event_sink_->Success(event);
  else if (channel == "clipboard" && clipboard_event_sink_) clipboard_event_sink_->Success(event);
}

}  // namespace lockdown_plugin
