import 'dart:io' show Platform;
import 'dart:ui';

import 'package:flutter/cupertino.dart';

import 'time_sync_plugin_platform_interface.dart';
import 'data/time_sync_data.dart';
import 'data/time_sync_object.dart';


class TimeSyncPlugin {
  static final TimeSync _timeSync = TimeSync();
  static final RootIsolateToken _rootIsolateToken = RootIsolateToken.instance!;

  static SyncDevice get getCurrentSyncDevice => _timeSync.getCurrentSyncDevice;

  static Future<String?> getPlatformVersion() {
    return TimeSyncPluginPlatform.instance.getPlatformVersion();
  }

  static Future<bool?> setSyncTime(String time) {
    return TimeSyncPluginPlatform.instance.setSyncTime(time);
  }

  static Future<int?> getWifiStrength() {
    if (Platform.isAndroid) {
      //
      // call from wifi_iot
      // or native-function
      //
    } else if (Platform.isIOS) {
      //
      // not yet...
      //
    } else if (Platform.isLinux) {
      //
      // not yet...
      //
    } else if (Platform.isMacOS) {
      //
      // not yet...
      //
    } else if (Platform.isWindows) {
      // call native-function
    }
    return TimeSyncPluginPlatform.instance.getWifiStrength();
  }

  static void startTimeSync(String deviceId) {
    debugPrint('startTimeSync');
    _timeSync.init(deviceId, _rootIsolateToken);
    _timeSync.startSync();
  }

  static void stopTimeSync() {
    _timeSync.stopSync();
  }

}
