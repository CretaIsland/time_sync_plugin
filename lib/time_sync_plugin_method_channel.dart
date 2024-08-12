import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'time_sync_plugin_platform_interface.dart';

/// An implementation of [TimeSyncPluginPlatform] that uses method channels.
class MethodChannelTimeSyncPlugin extends TimeSyncPluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('time_sync_plugin');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<bool?> setSyncTime(String time) async {
    final result = await methodChannel.invokeMethod<bool>('setSyncTime', { 'syncTime': time });
    return result;
  }

  @override
  Future<int?> getWifiStrength() async {
    final result = await methodChannel.invokeMethod<int>('getWifiStrength');
    debugPrint('MethodChannelTimeSyncPlugin.getWifiStrength=$result');
    return result;
  }
}
