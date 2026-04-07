#ifndef FLUTTER_PLUGIN_GOOX_TERMINAL_PLUGIN_H_
#define FLUTTER_PLUGIN_GOOX_TERMINAL_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace goox_terminal {

class GooxTerminalPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  GooxTerminalPlugin();

  virtual ~GooxTerminalPlugin();

  // Disallow copy and assign.
  GooxTerminalPlugin(const GooxTerminalPlugin&) = delete;
  GooxTerminalPlugin& operator=(const GooxTerminalPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace goox_terminal

#endif  // FLUTTER_PLUGIN_GOOX_TERMINAL_PLUGIN_H_
