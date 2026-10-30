#ifndef RUNNER_AUDIO_LEVEL_PLUGIN_H_
#define RUNNER_AUDIO_LEVEL_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace audio_level_plugin {

class AudioLevelPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  explicit AudioLevelPlugin(flutter::PluginRegistrarWindows* registrar);
  ~AudioLevelPlugin() override;

  AudioLevelPlugin(const AudioLevelPlugin&) = delete;
  AudioLevelPlugin& operator=(const AudioLevelPlugin&) = delete;

 private:
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
};

}  // namespace audio_level_plugin

#endif  // RUNNER_AUDIO_LEVEL_PLUGIN_H_
