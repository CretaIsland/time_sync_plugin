import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'time_sync_plugin_method_channel.dart';

abstract class TimeSyncPluginPlatform extends PlatformInterface {
  /// Constructs a TimeSyncPluginPlatform.
  TimeSyncPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static TimeSyncPluginPlatform _instance = MethodChannelTimeSyncPlugin();

  /// The default instance of [TimeSyncPluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelTimeSyncPlugin].
  static TimeSyncPluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [TimeSyncPluginPlatform] when
  /// they register themselves.
  static set instance(TimeSyncPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<bool?> setSyncTime(String time) {
    throw UnimplementedError('setSyncTime() has not been implemented.');
  }

  Future<int?> getWifiStrength() {
    throw UnimplementedError('getWifiStrength() has not been implemented.');
  }
}
