import 'package:flutter_test/flutter_test.dart';
import 'package:time_sync_plugin/time_sync_plugin.dart';
import 'package:time_sync_plugin/time_sync_plugin_platform_interface.dart';
import 'package:time_sync_plugin/time_sync_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// class MockTimeSyncPluginPlatform
//     with MockPlatformInterfaceMixin
//     implements TimeSyncPluginPlatform {
//
//   @override
//   Future<String?> getPlatformVersion() => Future.value('42');
// }

void main() {
  final TimeSyncPluginPlatform initialPlatform = TimeSyncPluginPlatform.instance;

  test('$MethodChannelTimeSyncPlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelTimeSyncPlugin>());
  });

  test('getPlatformVersion', () async {
    //TimeSyncPlugin timeSyncPlugin = TimeSyncPlugin();
    // MockTimeSyncPluginPlatform fakePlatform = MockTimeSyncPluginPlatform();
    // TimeSyncPluginPlatform.instance = fakePlatform;

    expect(await TimeSyncPlugin.getPlatformVersion(), '42');
  });
}
