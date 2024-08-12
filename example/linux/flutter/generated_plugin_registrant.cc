//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <time_sync_plugin/time_sync_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) time_sync_plugin_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "TimeSyncPlugin");
  time_sync_plugin_register_with_registrar(time_sync_plugin_registrar);
}
