import 'dart:convert';
import 'dart:isolate';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:udp/udp.dart';

import 'time_sync_const.dart';
import 'time_sync_data.dart';
import '../time_sync_plugin.dart';
import '../time_sync_plugin_platform_interface.dart';

class TimeSync {
  String _deviceId = '';
  RootIsolateToken? _rootIsolateToken;
  Isolate? _timeSyncIsolate;
  SyncDevice _currentSyncDevice = SyncDevice.init();

  SyncDevice get getCurrentSyncDevice => _currentSyncDevice;

  void init(String deviceId, RootIsolateToken rootIsolateToken) {
    _deviceId = deviceId;
    _rootIsolateToken = rootIsolateToken;
  }

  Future<bool> startSync() async {
    if (_timeSyncIsolate != null) {
      // already started ==> pass
      return true;
    }
    if (_rootIsolateToken == null || _deviceId.isEmpty) {
      return false;
    }

    ReceivePort receivePort = ReceivePort();
    receivePort.listen((data) {
      if (data is String) {
        // data is sync-time-string
        TimeSyncPluginPlatform.instance.setSyncTime(data);
      }
      else if (data is SyncDevice) {
        _currentSyncDevice = data;
      }
    });

    debugPrint('Isolate.spawn(_syncIsolate)');
    _timeSyncIsolate = await Isolate.spawn(_syncIsolate, [
      receivePort.sendPort,
      _deviceId,
      _rootIsolateToken,
    ]);
    return true;
  }

  Future<bool> stopSync() async {
    _timeSyncIsolate?.kill();
    return true;
  }

  void _syncIsolate(dynamic datas) async {
    SendPort sendPort = datas[0] as SendPort;
    String thisDeviceId = datas[1] as String;
    RootIsolateToken rootIsolateToken = datas[2] as RootIsolateToken;

    BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);

    debugPrint('start _syncIsolate');

    // start wifi-strenth
    // 1.a 기동후 1분동안 3초마다 wifi감도 값을 수집하여 그중 최고값 산출
    // 1.b 1분이후에도, 현재로부터 이전1분동안 최고값을 지속적으로 산출
    // 1.c 새로 산출된 최고값이 이전 최고값보다 높을 경우 해당 값으로 갱신
    // 1.d 새로 산출된 최고값이 이전 최고값보다 일정치(10) 이하일 경우 새로 산출된 최고값으로 대체
    //
    // 2. 기동후 1분이 지난 시점(1.b)부터 특정 UDP 포트(9999)로 5초 마다
    //   [인증키ID] + [Wifi감도최고평균값(소수점3자리까지)] + [자신의 시간(milli초까지 포함)]
    //   패킷 발송

    // start sync
    // 3. 패킷 수신
    // 4a. 2항목의 데이터 수집하며 wifi감도가 제일 높은 단말 검색
    // 4b. wifi감도가 같은 경우 인증키ID가 제일 낮은 단말기가 우선순위
    // 5. 1분 이후부터, 동일 단말기에 대해 연속으로 3번이상 시간차(100ms) 발생시 해당 시간으로 동기화

    SyncDataSet syncDataSet = SyncDataSet();
    syncDataSet.init(sendPort, thisDeviceId);
    int loopCount = 0;

    var udpSocket = await UDP.bind(Endpoint.any(port: const Port(TimeSyncConst.udpBroadcastPort)));

    // receiving\listening
    udpSocket.asStream().listen((datagram) {
      if (datagram == null) return;
      try {
        // InternetAddress inetAddr = datagram.address;
        // String ipAddr = inetAddr.address;
        String recvJson = utf8.decode(datagram.data);
        debugPrint('[${DateTime.now().toString()}] recvJson=$recvJson');
        Map<String, dynamic> udpPacket = jsonDecode(recvJson);
        String recvDeviceId = udpPacket['deviceId'] ?? '';
        double recvWifiStrength = ((udpPacket['wifi'] ?? TimeSyncConst.minWifiStrength) as num).toDouble();
        String recvSyncTime = udpPacket['time'] ?? '';
        debugPrint('[${DateTime.now().toString()}] recvDeviceId=$recvDeviceId');
        debugPrint('[${DateTime.now().toString()}] recvWifiStrength=$recvWifiStrength');
        debugPrint('[${DateTime.now().toString()}] recvSyncTime=$recvSyncTime');
        if (recvDeviceId.isEmpty || recvSyncTime.isEmpty) {
          // invalid packet ==> PASS !!!
          return;
        }
        SyncData recvSyncData = SyncData(recvWifiStrength, recvSyncTime);
        syncDataSet.syncTime(recvDeviceId, recvSyncData, (loopCount > 20));
        sendPort.send(syncDataSet.getCurrentSyncDevice);
      } catch (e) {
        // something error
        debugPrint('EXCEPTION(1) : ${e.toString()}');
      }
    });

    while (true) {
      await Future.delayed(const Duration(seconds: 3));
      loopCount++;
      debugPrint('[${DateTime.now().toString()}] loopCount=$loopCount');
      //
      int? ws = await TimeSyncPlugin.getWifiStrength();
      double currentWifiStrength = ws?.toDouble() ?? TimeSyncConst.minWifiStrength;
      debugPrint('[${DateTime.now().toString()}] currentWifiStrength=$currentWifiStrength');
      DateTime nowUtc = DateTime.now().toUtc();
      // 1분동안은 wifi 값만 수집
      if (loopCount < 20) {
        // 현재 단말기값 갱신
        syncDataSet.syncTime(thisDeviceId, SyncData(currentWifiStrength, nowUtc.toIso8601String()), (loopCount > 20));
        continue;
      }
      // 1분 이후부터는 udp 브로드캐스트 (현재 단말기값도 udp로 갱신)
      syncDataSet.increaseNoReceivingCount();
      String packet = '{"deviceId":"$thisDeviceId","wifi":$currentWifiStrength,"time":"${nowUtc.toIso8601String()}"}';
      debugPrint('[${DateTime.now().toString()}] sendPacket=$packet');
      try {
        udpSocket.send(packet.codeUnits, Endpoint.broadcast(port: const Port(TimeSyncConst.udpBroadcastPort)));
      } catch (e) {
        // something error
      }
    }
  }
}
