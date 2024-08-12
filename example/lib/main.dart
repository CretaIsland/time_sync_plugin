import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:time_sync_plugin/time_sync_plugin.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  //bool _setSyncTime = false;
  //final _timeSyncPlugin = TimeSyncPlugin();

  @override
  void initState() {
    super.initState();
    initPlatformState();
    initSyncTime();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion = await TimeSyncPlugin.getPlatformVersion() ?? 'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  Future<void> initSyncTime() async {
    debugPrint('initSyncTime');

    if (kDebugMode) {
      TimeSyncPlugin.startTimeSync('TEST-123456');
    } else {
      TimeSyncPlugin.startTimeSync('SQI-001642');
    }

    Timer.periodic(const Duration(seconds: 3), (timer) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    DateTime? syncTime;
    try {
      syncTime = DateTime.parse(TimeSyncPlugin.getCurrentSyncDevice.lastSyncTime).toLocal();
    } catch (e) {
      debugPrint('EXCEPTION(2):${e.toString()}');
    }
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Time-Sync-Plugin example app'),
        ),
        body: Center(
          child: Column(
            children: [
              Text('Running on: $_platformVersion\n'),
              Text('Sync Device ID : ${TimeSyncPlugin.getCurrentSyncDevice.deviceId}'),
              Text('Sync Wifi Strength : ${TimeSyncPlugin.getCurrentSyncDevice.maxWifiStrength}'),
              Text('Sync Time : ${syncTime?.toString()}'),
            ],
          ),
        ),
      ),
    );
  }
}
