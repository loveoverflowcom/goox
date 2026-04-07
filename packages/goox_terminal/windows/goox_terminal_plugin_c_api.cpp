#include "include/goox_terminal/goox_terminal_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "goox_terminal_plugin.h"

void GooxTerminalPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  goox_terminal::GooxTerminalPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
