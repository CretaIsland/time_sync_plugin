import 'dart:isolate';

import 'time_sync_const.dart';

class SyncData {
  const SyncData(this.wifiStrength, this.syncTime);

  SyncData.makeClone(SyncData syncData) : this(syncData.wifiStrength, syncData.syncTime);

  final double wifiStrength;
  final String syncTime;
}

class SyncDevice {
  String deviceId = '';
  double maxWifiStrength = TimeSyncConst.minWifiStrength;
  String lastSyncTime = '';
  bool isThisDevice = false;
  int noReceivingCount = 0;
  final List<SyncData> _syncDataList = [];

  SyncDevice.init();

  SyncDevice(this.deviceId, this.maxWifiStrength, this.lastSyncTime, {bool? isThisDevice}) {
    if (isThisDevice != null) this.isThisDevice = isThisDevice;
    _syncDataList.add(SyncData(maxWifiStrength, lastSyncTime));
  }

  SyncDevice.makeClone(SyncDevice source, {bool copyDataList = false}) {
    deviceId = source.deviceId;
    maxWifiStrength = source.maxWifiStrength;
    lastSyncTime = source.lastSyncTime;
    isThisDevice = source.isThisDevice;
    if (copyDataList) {
      for (var syncData in source._syncDataList) {
        _syncDataList.add(SyncData(syncData.wifiStrength, syncData.syncTime));
      }
    }
  }

  void addSyncData(SyncData syncData) {
    if (lastSyncTime.compareTo(syncData.syncTime) == 0) {
      // equal time ==> equal packet ==> PASS !!!
      return;
    }
    noReceivingCount = 0;
    if (_syncDataList.length >= 20) {
      _syncDataList.removeAt(0);
    }
    double newMaxWifiStrength = TimeSyncConst.minWifiStrength;
    _syncDataList
      ..add(syncData)
      ..forEach((value) {
        if (newMaxWifiStrength > value.wifiStrength) return;
        newMaxWifiStrength = value.wifiStrength;
      });
    lastSyncTime = syncData.syncTime;
    // 최근 wifi가 1분이전의 wifi보다 큼
    // ==> wifi감도가 최근에 좋아짐
    // ==> wifi를 최근값으로 갱신
    if (newMaxWifiStrength > maxWifiStrength) maxWifiStrength = newMaxWifiStrength;
    // 최근 wifi가 1분이전의 wifi보다 오차범위 이하값
    // ==> wifi감도가 최근에 떨어짐
    // ==> wifi를 최근값으로 갱신
    if ((maxWifiStrength - TimeSyncConst.wifiStrengthGap) > newMaxWifiStrength) maxWifiStrength = newMaxWifiStrength;
  }
}

class SyncDataSet {
  SyncDevice _currentSyncDevice = SyncDevice.init();
  String thisDeviceId = '';
  SendPort? sendPort;
  int _syncDiffCount = 0;
  final Map<String, SyncDevice> _syncDeviceMap = {}; // <DeviceId, SyncDevice>

  SyncDevice get getCurrentSyncDevice => _currentSyncDevice;

  void init(SendPort sendPort, String deviceId) {
    this.sendPort = sendPort;
    thisDeviceId = deviceId;
  }

  void increaseNoReceivingCount() {
    _syncDeviceMap.forEach((key, value) => value.noReceivingCount++);
  }

  bool syncTime(String deviceId, SyncData syncData, bool doSyncTime) {
    _addSyncData(deviceId, syncData);
    _checkBestDevice(deviceId, syncData);
    if (doSyncTime) return _syncTime(deviceId, syncData);
    return false;
  }

  void _addSyncData(String deviceId, SyncData syncData) {
    SyncDevice? device = _syncDeviceMap[deviceId];
    if (device == null) {
      device = SyncDevice(deviceId, syncData.wifiStrength, syncData.syncTime, isThisDevice: (thisDeviceId == deviceId));
      _syncDeviceMap[deviceId] = device;
    } else {
      device.addSyncData(syncData);
    }
  }

  void _checkBestDevice(String deviceId, SyncData syncData) {
    String beforeSyncDevieId = _currentSyncDevice.deviceId;
    if (_currentSyncDevice.noReceivingCount > 20) {
      // 현재 단말기가 1분 이상 데이터 없음 ==> 동기화 단말기 취소
      _currentSyncDevice = SyncDevice.init();
    }
    _syncDeviceMap.forEach((key, value) {
      if (_currentSyncDevice.maxWifiStrength == value.maxWifiStrength) {
        // 동일 wifi감도에 인증ID가 크면 ==> 패스
        if (_currentSyncDevice.deviceId.compareTo(value.deviceId) < 0) return;
      } else if (_currentSyncDevice.maxWifiStrength > value.maxWifiStrength) {
        return;
      }
      // (_currentSyncDevice.wifiStrength < value.wifiStrength)
      // ==> change best-device
      _currentSyncDevice = value;
    });
    if (beforeSyncDevieId != _currentSyncDevice.deviceId) {
      // best-device is changed ==> reset count
      _syncDiffCount = 0;
    }
  }

  bool _syncTime(String deviceId, SyncData syncData) {
    // (_currentSyncDevice == this-machine)
    // ==> PASS
    if (_currentSyncDevice.isThisDevice) return false;
    // (syncDevice.deviceId != _currentSyncDevice.deviceId)
    // ==> NOT BEST DEVICE !!! ==> DO NOT TIME-SYNC !!!
    if (deviceId != _currentSyncDevice.deviceId) return false;
    // (syncDevice.deviceId == _currentSyncDevice.deviceId)
    // ==> best deivce ==> do time-sync
    final DateTime newTime = DateTime.parse(syncData.syncTime);
    final DateTime nowUtc = DateTime.now().toUtc();
    final timeDelay = newTime.difference(nowUtc);
    if (timeDelay.inMilliseconds > 100 || timeDelay.inMilliseconds < -100) {
      _syncDiffCount++;
    } else {
      _syncDiffCount = 0;
    }
    if (_syncDiffCount >= 3) {
      // 3번 연속으로 시간 차이 발생 ==> 시간 동기화
      _syncDiffCount = 0;
      sendPort?.send(syncData.syncTime);
    }
    return true;
  }
}

class DoubleListEx {
  final List<double> _list = [];

  int get length => _list.length;

  void add(double val) => _list.add(val);
  void removeHead() => _list.removeAt(0);

  double getAverage() {
    double sum = 0.0;
    for(var val in _list) {
      sum += val;
    }
    return (sum / _list.length.toDouble());
  }
}
