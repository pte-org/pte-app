#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include <algorithm>

#include "flutter_window.h"
#include "utils.h"

namespace {
constexpr unsigned int kLoginWindowMaxWidth = 1280;
constexpr unsigned int kLoginWindowMaxHeight = 720;

Win32Window::Point CenterWindowOnPrimaryWorkArea(
    const Win32Window::Size& size) {
  MONITORINFO monitor_info{sizeof(monitor_info)};
  const POINT origin{0, 0};
  const HMONITOR monitor =
      MonitorFromPoint(origin, MONITOR_DEFAULTTOPRIMARY);
  if (!GetMonitorInfo(monitor, &monitor_info)) {
    return Win32Window::Point(0, 0);
  }

  const RECT& work_area = monitor_info.rcWork;
  const LONG work_width = work_area.right - work_area.left;
  const LONG work_height = work_area.bottom - work_area.top;
  const LONG window_width = static_cast<LONG>(size.width);
  const LONG window_height = static_cast<LONG>(size.height);
  const LONG x = work_area.left +
                 std::max<LONG>(0, (work_width - window_width) / 2);
  const LONG y = work_area.top +
                 std::max<LONG>(0, (work_height - window_height) / 2);
  return Win32Window::Point(static_cast<int>(x), static_cast<int>(y));
}
}  // namespace

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Size size(kLoginWindowMaxWidth, kLoginWindowMaxHeight);
  Win32Window::Point origin = CenterWindowOnPrimaryWorkArea(size);
  if (!window.Create(L"pte_app", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
