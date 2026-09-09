#ifndef RUNNER_LOCKDOWN_PLUGIN_H_
#define RUNNER_LOCKDOWN_PLUGIN_H_

#include <flutter/event_channel.h>
#include <flutter/event_stream_handler_functions.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <windows.h>
#include <tlhelp32.h>

#include <atomic>
#include <memory>
#include <string>

namespace lockdown_plugin {

class LockdownPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  explicit LockdownPlugin(flutter::PluginRegistrarWindows* registrar);
  ~LockdownPlugin() override;

  LockdownPlugin(const LockdownPlugin&) = delete;
  LockdownPlugin& operator=(const LockdownPlugin&) = delete;

  // Called by the runner for window messages that belong to this plugin.
  // Returns true to indicate the message was handled (the runner then
  // returns 0); false to let the runner fall through. The runner passes
  // the full message triple so plugins can react to focus/activation
  // events, not just the message id.
  static bool HandleWindowMessage(UINT message, WPARAM wparam, LPARAM lparam);

 private:
  using MethodResult = flutter::MethodResult<flutter::EncodableValue>;
  using MethodCall = flutter::MethodCall<flutter::EncodableValue>;

  void EnforceFullscreen(const MethodCall& call,
                         std::unique_ptr<MethodResult> result);
  void ExitFullscreen(const MethodCall& call,
                      std::unique_ptr<MethodResult> result);
  void GetRunningProcesses(const MethodCall& call,
                           std::unique_ptr<MethodResult> result);
  void TerminateProcess(const MethodCall& call,
                        std::unique_ptr<MethodResult> result);
  void BlockExternalPaste(const MethodCall& call,
                          std::unique_ptr<MethodResult> result);
  void ClearClipboard(const MethodCall& call,
                      std::unique_ptr<MethodResult> result);
  void UnblockClipboard(const MethodCall& call,
                        std::unique_ptr<MethodResult> result);
  void BlockSystemShortcuts(const MethodCall& call,
                            std::unique_ptr<MethodResult> result);
  void UnblockShortcuts(const MethodCall& call,
                        std::unique_ptr<MethodResult> result);

  void SendViolationEvent(const std::string& channel,
                          const std::string& violation);
  bool RegisterClipboardListener();
  void UnregisterClipboardListener();
  // Best-effort cleanup called from the destructor. Same style/rect
  // restoration as ExitFullscreen, but never reports a result and never
  // short-circuits when state is missing — required so the platform isn't
  // left holding a half-restyled window when the plugin is torn down while
  // a lockdown session is still active.
  void ExitFullscreenForTeardown();

  static LRESULT CALLBACK KeyboardHookProc(int nCode, WPARAM wParam,
                                            LPARAM lParam);

  flutter::PluginRegistrarWindows* registrar_;
  HWND hwnd_;
  HHOOK keyboard_hook_;
  LONG original_style_;
  LONG original_ex_style_;
  RECT original_rect_;
  bool original_window_state_saved_;
  bool fullscreen_enforced_;
  // True once registration finishes, and the keyboard hook must consult
  // [shortcuts_blocked_] before forwarding events. Accessed from the
  // hook callback (arbitrary thread) and from method-channel handlers
  // (UI thread), so it is stored as std::atomic<bool>.
  std::atomic<bool> shortcuts_blocked_{false};
  // Same threading story — window-message handler fires on the UI thread,
  // but the plugin's destruction runs from a different teardown path, and
  // [instance_] itself can briefly outlive a still-pending window message.
  std::atomic<bool> clipboard_blocked_{false};
  // Last observed clipboard sequence number while blocking was active.
  // SetClipboardData increments this counter the moment an external
  // caller *writes* to the clipboard; comparing the value before/after a
  // WM_CLIPBOARDUPDATE tells us whether a non-app process actually
  // mutated clipboard contents since we last observed it. Stored as
  // atomic so the read on the UI thread pairs with the update path
  // without a dedicated lock.
  std::atomic<DWORD> last_clipboard_sequence_{0};

  // Listener state is owned by the UI thread (RegisterClipboardListener/
  // UnregisterClipboardListener call SetWindowsHookEx peers), so a plain
  // bool is fine — kept separate so the flag is meaningful at all times
  // even when [clipboard_blocked_] is false.
  bool clipboard_listener_registered_;
  // Set true once the sequence baseline has been armed. Reset by
  // UnblockClipboard so the next activation re-baselines on a clean
  // slate rather than carrying stale sequence numbers across attempts.
  bool clipboard_baseline_armed_;

  std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> window_event_sink_;
  std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> process_event_sink_;
  std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> shortcut_event_sink_;
  // Distinct channel for clipboard violations — Dart's ClipboardMonitorChannel
  // must expose its own EventChannel receiver, not share the process stream.
  std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> clipboard_event_sink_;

  static LockdownPlugin* instance_;
};

}  // namespace lockdown_plugin

#endif  // RUNNER_LOCKDOWN_PLUGIN_H_
