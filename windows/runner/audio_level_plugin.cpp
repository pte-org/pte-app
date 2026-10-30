#include "audio_level_plugin.h"

#include <windows.h>
#include <audiopolicy.h>
#include <endpointvolume.h>
#include <mmdeviceapi.h>
#include <wrl/client.h>

#include <flutter/standard_method_codec.h>

#include <algorithm>
#include <cmath>

namespace audio_level_plugin {
namespace {

using Microsoft::WRL::ComPtr;

class ScopedComInitialization {
 public:
  ScopedComInitialization()
      : result_(CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED)) {}

  ~ScopedComInitialization() {
    // S_FALSE also increments COM's initialization count. A different existing
    // apartment (RPC_E_CHANGED_MODE) is usable, but is not ours to uninitialize.
    if (SUCCEEDED(result_)) {
      CoUninitialize();
    }
  }

  ScopedComInitialization(const ScopedComInitialization&) = delete;
  ScopedComInitialization& operator=(const ScopedComInitialization&) = delete;

  bool usable() const {
    return SUCCEEDED(result_) || result_ == RPC_E_CHANGED_MODE;
  }

 private:
  HRESULT result_;
};

double GetPlaybackLevel() {
  // Declare the guard first so all COM interfaces are released before it.
  ScopedComInitialization com;
  if (!com.usable()) {
    return 0.0;
  }

  ComPtr<IMMDeviceEnumerator> devices;
  if (FAILED(CoCreateInstance(__uuidof(MMDeviceEnumerator), nullptr,
                              CLSCTX_INPROC_SERVER,
                              IID_PPV_ARGS(devices.GetAddressOf())))) {
    return 0.0;
  }

  // Refresh every poll and include every active render endpoint: an existing
  // stream can remain on its previous device after the default device changes.
  // Never activate an endpoint-wide peak meter.
  ComPtr<IMMDeviceCollection> endpoints;
  if (FAILED(devices->EnumAudioEndpoints(eRender, DEVICE_STATE_ACTIVE,
                                         endpoints.GetAddressOf()))) {
    return 0.0;
  }

  UINT endpoint_count = 0;
  if (FAILED(endpoints->GetCount(&endpoint_count))) {
    return 0.0;
  }

  const DWORD current_process_id = GetCurrentProcessId();
  double level = 0.0;
  for (UINT endpoint_index = 0; endpoint_index < endpoint_count;
       ++endpoint_index) {
    ComPtr<IMMDevice> device;
    if (FAILED(endpoints->Item(endpoint_index, device.GetAddressOf()))) {
      continue;
    }

    ComPtr<IAudioSessionManager2> manager;
    if (FAILED(device->Activate(
            __uuidof(IAudioSessionManager2), CLSCTX_ALL, nullptr,
            reinterpret_cast<void**>(manager.GetAddressOf())))) {
      continue;
    }

    ComPtr<IAudioSessionEnumerator> sessions;
    if (FAILED(manager->GetSessionEnumerator(sessions.GetAddressOf()))) {
      continue;
    }

    int count = 0;
    if (FAILED(sessions->GetCount(&count))) {
      continue;
    }

    for (int index = 0; index < count; ++index) {
      ComPtr<IAudioSessionControl> session;
      if (FAILED(sessions->GetSession(index, session.GetAddressOf()))) {
        continue;
      }

      ComPtr<IAudioSessionControl2> control;
      if (FAILED(session.As(&control))) {
        continue;
      }

      DWORD process_id = 0;
      // Require S_OK: AUDCLNT_S_NO_SINGLE_PROCESS reports only the creator PID
      // for a cross-process session and cannot isolate this process's playback.
      if (control->GetProcessId(&process_id) != S_OK ||
          process_id != current_process_id) {
        continue;
      }

      ComPtr<IAudioMeterInformation> meter;
      if (FAILED(session.As(&meter))) {
        continue;
      }

      float peak = 0.0f;
      if (SUCCEEDED(meter->GetPeakValue(&peak)) && std::isfinite(peak)) {
        level = std::max(level, std::clamp(static_cast<double>(peak), 0.0, 1.0));
      }
    }
  }
  return level;
}

}  // namespace

void AudioLevelPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  registrar->AddPlugin(std::make_unique<AudioLevelPlugin>(registrar));
}

AudioLevelPlugin::AudioLevelPlugin(flutter::PluginRegistrarWindows* registrar)
    : channel_(std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "pte/audio_levels",
          &flutter::StandardMethodCodec::GetInstance())) {
  channel_->SetMethodCallHandler([](const auto& call, auto result) {
    if (call.method_name() == "getPlaybackLevel") {
      result->Success(flutter::EncodableValue(GetPlaybackLevel()));
    } else {
      result->NotImplemented();
    }
  });
}

AudioLevelPlugin::~AudioLevelPlugin() {
  channel_->SetMethodCallHandler(nullptr);
}

}  // namespace audio_level_plugin
