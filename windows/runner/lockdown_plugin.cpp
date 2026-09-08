#include "lockdown_plugin.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <sstream>

namespace lockdown_plugin {

// Static instance for keyboard hook callback
LockdownPlugin* LockdownPlugin::instance_ = nullptr;

// Register plugin channels
void LockdownPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto plugin = std::make_unique<LockdownPlugin>(registrar);

  // Window management channel
  auto window_channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "com.pte.lockdown/window",
          &flutter::StandardMethodCodec::GetInstance());

  window_channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        if (call.method_name().compare("enforceFullscreen") == 0) {
          plugin_pointer->EnforceFullscreen(call, std::move(result));
        } else if (call.method_name().compare("exitFullscreen") == 0) {
          plugin_pointer->ExitFullscreen(call, std::move(result));
        } else {
          result->NotImplemented();
        }
      });

  // Process management channel
  auto process_channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "com.pte.lockdown/process",
          &flutter::StandardMethodCodec::GetInstance());

  process_channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        if (call.method_name().compare("getRunningProcesses") == 0) {
          plugin_pointer->GetRunningProcesses(call, std::move(result));
        } else if (call.method_name().compare("terminateProcess") == 0) {
          plugin_pointer->TerminateProcess(call, std::move(result));
        } else {
          result->NotImplemented();
        }
      });

  // Clipboard channel
  auto clipboard_channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "com.pte.lockdown/clipboard",
          &flutter::StandardMethodCodec::GetInstance());

  clipboard_channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        if (call.method_name().compare("blockExternalPaste") == 0) {
          plugin_pointer->BlockExternalPaste(call, std::move(result));
        } else if (call.method_name().compare("clearClipboard") == 0) {
          plugin_pointer->ClearClipboard(call, std::move(result));
        } else if (call.method_name().compare("unblock") == 0) {
          plugin_pointer->UnblockClipboard(call, std::move(result));
        } else {
          result->NotImplemented();
        }
      });

  // Shortcuts channel
  auto shortcut_channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "com.pte.lockdown/shortcuts",
          &flutter::StandardMethodCodec::GetInstance());

  shortcut_channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        if (call.method_name().compare("blockSystemShortcuts") == 0) {
          plugin_pointer->BlockSystemShortcuts(call, std::move(result));
        } else if (call.method_name().compare("unblock") == 0) {
          plugin_pointer->UnblockShortcuts(call, std::move(result));
        } else {
          result->NotImplemented();
        }
      });

  registrar->AddPlugin(std::move(plugin));
}

LockdownPlugin::LockdownPlugin(flutter::PluginRegistrarWindows *registrar)
    : registrar_(registrar),
      hwnd_(nullptr),
      keyboard_hook_(nullptr),
      fullscreen_enforced_(false),
      shortcuts_blocked_(false) {
  instance_ = this;
  
  // Get window handle
  hwnd_ = registrar_->GetView()->GetNativeWindow();
}

LockdownPlugin::~LockdownPlugin() {
  if (keyboard_hook_) {
    UnhookWindowsHookEx(keyboard_hook_);
    keyboard_hook_ = nullptr;
  }
  instance_ = nullptr;
}

void LockdownPlugin::EnforceFullscreen(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  
  if (!hwnd_) {
    result->Error("NO_WINDOW", "Window handle not available");
    return;
  }

  // Remove window decorations and menu
  LONG style = GetWindowLong(hwnd_, GWL_STYLE);
  style &= ~(WS_CAPTION | WS_THICKFRAME | WS_MINIMIZE | WS_MAXIMIZE | WS_SYSMENU);
  SetWindowLong(hwnd_, GWL_STYLE, style);

  // Get monitor info for fullscreen dimensions
  MONITORINFO mi = { sizeof(mi) };
  if (!GetMonitorInfo(MonitorFromWindow(hwnd_, MONITOR_DEFAULTTOPRIMARY), &mi)) {
    result->Error("MONITOR_INFO_FAILED", "Failed to get monitor info");
    return;
  }

  // Set window to cover entire screen
  if (!SetWindowPos(hwnd_, HWND_TOP,
               mi.rcMonitor.left, mi.rcMonitor.top,
               mi.rcMonitor.right - mi.rcMonitor.left,
               mi.rcMonitor.bottom - mi.rcMonitor.top,
               SWP_NOZORDER | SWP_NOACTIVATE | SWP_FRAMECHANGED)) {
    result->Error("SET_WINDOW_POS_FAILED", "Failed to set fullscreen position");
    return;
  }

  fullscreen_enforced_ = true;
  result->Success();
}

void LockdownPlugin::ExitFullscreen(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  
  if (!hwnd_) {
    result->Error("NO_WINDOW", "Window handle not available");
    return;
  }

  // Restore window style
  LONG style = GetWindowLong(hwnd_, GWL_STYLE);
  style |= (WS_CAPTION | WS_THICKFRAME | WS_MINIMIZE | WS_MAXIMIZE | WS_SYSMENU);
  SetWindowLong(hwnd_, GWL_STYLE, style);

  // Restore normal window position
  SetWindowPos(hwnd_, HWND_TOP, 100, 100, 1280, 720,
               SWP_NOZORDER | SWP_NOACTIVATE | SWP_FRAMECHANGED);

  fullscreen_enforced_ = false;
  result->Success();
}

void LockdownPlugin::GetRunningProcesses(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  
  flutter::EncodableList process_list;
  HANDLE snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  
  if (snapshot == INVALID_HANDLE_VALUE) {
    result->Error("SNAPSHOT_FAILED", "Failed to create process snapshot");
    return;
  }

  PROCESSENTRY32W entry;
  entry.dwSize = sizeof(PROCESSENTRY32W);

  if (Process32FirstW(snapshot, &entry)) {
    do {
      std::wstring wname(entry.szExeFile);
      std::string name(wname.begin(), wname.end());
      process_list.push_back(flutter::EncodableValue(name));
    } while (Process32NextW(snapshot, &entry));
  }

  CloseHandle(snapshot);
  result->Success(flutter::EncodableValue(process_list));
}

void LockdownPlugin::TerminateProcess(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  
  const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
  if (!arguments) {
    result->Error("BAD_ARGS", "Arguments must be a map");
    return;
  }

  auto name_it = arguments->find(flutter::EncodableValue("name"));
  if (name_it == arguments->end()) {
    result->Error("BAD_ARGS", "Missing 'name' argument");
    return;
  }

  std::string target_name = std::get<std::string>(name_it->second);
  std::wstring wtarget_name(target_name.begin(), target_name.end());
  
  bool terminated = false;
  HANDLE snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  
  if (snapshot != INVALID_HANDLE_VALUE) {
    PROCESSENTRY32W entry;
    entry.dwSize = sizeof(PROCESSENTRY32W);

    if (Process32FirstW(snapshot, &entry)) {
      do {
        if (_wcsicmp(entry.szExeFile, wtarget_name.c_str()) == 0) {
          HANDLE hProcess = OpenProcess(PROCESS_TERMINATE, FALSE, entry.th32ProcessID);
          if (hProcess) {
            if (::TerminateProcess(hProcess, 0)) {
              terminated = true;
            }
            CloseHandle(hProcess);
          }
        }
      } while (Process32NextW(snapshot, &entry) && !terminated);
    }
    CloseHandle(snapshot);
  }

  result->Success(flutter::EncodableValue(terminated));
}

void LockdownPlugin::BlockExternalPaste(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  // Note: Full clipboard blocking requires deeper OS integration
  // For MVP, we clear clipboard on activation
  ClearClipboard(method_call, std::move(result));
}

void LockdownPlugin::ClearClipboard(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  
  if (OpenClipboard(hwnd_)) {
    EmptyClipboard();
    CloseClipboard();
    result->Success();
  } else {
    result->Error("CLIPBOARD_FAILED", "Failed to open clipboard");
  }
}

void LockdownPlugin::UnblockClipboard(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  // No-op for now (clipboard is not actively blocked, just cleared)
  result->Success();
}

void LockdownPlugin::BlockSystemShortcuts(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  
  if (keyboard_hook_) {
    result->Error("ALREADY_HOOKED", "Keyboard hook already installed");
    return;
  }

  keyboard_hook_ = SetWindowsHookEx(WH_KEYBOARD_LL, KeyboardHookProc, NULL, 0);
  
  if (!keyboard_hook_) {
    result->Error("HOOK_FAILED", "Failed to install keyboard hook");
    return;
  }

  shortcuts_blocked_ = true;
  result->Success();
}

void LockdownPlugin::UnblockShortcuts(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  
  if (keyboard_hook_) {
    UnhookWindowsHookEx(keyboard_hook_);
    keyboard_hook_ = nullptr;
  }

  shortcuts_blocked_ = false;
  result->Success();
}

LRESULT CALLBACK LockdownPlugin::KeyboardHookProc(int nCode, WPARAM wParam, LPARAM lParam) {
  if (nCode == HC_ACTION && instance_ && instance_->shortcuts_blocked_) {
    KBDLLHOOKSTRUCT* kb = (KBDLLHOOKSTRUCT*)lParam;
    
    // Block: Alt+Tab, Alt+F4, Win key, PrintScreen, Ctrl+Esc
    bool block = false;
    std::string violation_type;

    if (kb->vkCode == VK_TAB && (GetAsyncKeyState(VK_MENU) & 0x8000)) {
      block = true;
      violation_type = "ALT_TAB";
    } else if (kb->vkCode == VK_F4 && (GetAsyncKeyState(VK_MENU) & 0x8000)) {
      block = true;
      violation_type = "ALT_F4";
    } else if (kb->vkCode == VK_LWIN || kb->vkCode == VK_RWIN) {
      block = true;
      violation_type = "WIN_KEY";
    } else if (kb->vkCode == VK_SNAPSHOT) {
      block = true;
      violation_type = "PRINTSCREEN";
    } else if (kb->vkCode == VK_ESCAPE && (GetAsyncKeyState(VK_CONTROL) & 0x8000)) {
      block = true;
      violation_type = "CTRL_ESC";
    }

    if (block) {
      instance_->SendViolationEvent("shortcuts", violation_type);
      return 1; // Block the key
    }
  }

  return CallNextHookEx(NULL, nCode, wParam, lParam);
}

void LockdownPlugin::SendViolationEvent(const std::string& channel, const std::string& violation) {
  // Event sink implementation would go here
  // For now, log to debug output
  OutputDebugStringA(("Violation detected on " + channel + ": " + violation + "\n").c_str());
}

}  // namespace lockdown_plugin
