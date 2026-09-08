#ifndef LOCKDOWN_PLUGIN_H_
#define LOCKDOWN_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <flutter/event_channel.h>
#include <flutter/event_stream_handler_functions.h>

#include <windows.h>
#include <tlhelp32.h>
#include <memory>
#include <string>

namespace lockdown_plugin {

class LockdownPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  LockdownPlugin(flutter::PluginRegistrarWindows *registrar);
  virtual ~LockdownPlugin();

  // Disallow copy and assign.
  LockdownPlugin(const LockdownPlugin&) = delete;
  LockdownPlugin& operator=(const LockdownPlugin&) = delete;

 private:
  // Window management
  void EnforceFullscreen(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  
  void ExitFullscreen(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  // Process management
  void GetRunningProcesses(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  
  void TerminateProcess(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  // Clipboard
  void BlockExternalPaste(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  
  void ClearClipboard(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  
  void UnblockClipboard(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  // Shortcuts
  void BlockSystemShortcuts(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  
  void UnblockShortcuts(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  // Keyboard hook callback
  static LRESULT CALLBACK KeyboardHookProc(int nCode, WPARAM wParam, LPARAM lParam);
  
  // Event sinks for violation streams
  void SendViolationEvent(const std::string& channel, const std::string& violation);

  flutter::PluginRegistrarWindows *registrar_;
  HWND hwnd_;
  HHOOK keyboard_hook_;
  bool fullscreen_enforced_;
  bool shortcuts_blocked_;
  
  std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> window_event_sink_;
  std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> shortcut_event_sink_;
  
  static LockdownPlugin* instance_;
};

}  // namespace lockdown_plugin

#endif  // LOCKDOWN_PLUGIN_H_
