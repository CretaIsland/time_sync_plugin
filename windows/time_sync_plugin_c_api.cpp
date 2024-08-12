#include "include/time_sync_plugin/time_sync_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "time_sync_plugin.h"

void TimeSyncPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  time_sync_plugin::TimeSyncPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
