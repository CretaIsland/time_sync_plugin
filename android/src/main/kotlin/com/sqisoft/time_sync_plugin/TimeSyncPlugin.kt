package com.sqisoft.time_sync_plugin

import android.app.AlarmManager
import android.content.Context
import android.content.Context.WIFI_SERVICE
import android.net.wifi.WifiManager
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.TimeZone


/** TimeSyncPlugin */
class TimeSyncPlugin: FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private lateinit var context: Context

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "time_sync_plugin")
    channel.setMethodCallHandler(this)
    context = flutterPluginBinding.applicationContext // Context를 멤버 변수로 저장
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    if (call.method == "getPlatformVersion") {
      result.success("Android ${android.os.Build.VERSION.RELEASE}")
    } else if (call.method == "setSyncTime") {
      val time = call.argument<String>("syncTime")
      val resultValue = _syncTime(time)
      if(resultValue){
        result.success(true)
      }else{
        result.error("ERROR", "Fail to set sync time", null)
      }

    } else if (call.method == "getWifiStrength") {
      //
      // android native code
      // or using flutter:package:wifi_iot
      //
      // return value : 0 ~ -100 (higher is better, lower is worst)
      //
      val resultValue = _getWifiStrength()
      if(resultValue != null){
        result.success(resultValue)
      }else{
        result.error("ERROR", "Fail to get wifi strength", null)
      }

    } else {
      result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  private fun _getWifiStrength():Int?{
    try {
      val wifiManager =
        context.applicationContext.getSystemService(WIFI_SERVICE) as WifiManager
      val connectionInfo = wifiManager.connectionInfo;
      Log.d("TimeSyncPlugin", "_getWifiStrength:${connectionInfo.rssi}")
      return connectionInfo.rssi
    }catch (e:Exception){
      e.printStackTrace()
      return null
    }
  }

  private fun _syncTime(time: String?):Boolean {
    //
    // time : ex)2024-08-10T12:34:56.789012Z
    //
    // android native code for sync-time...
    //
    //ISO 8601


    val isoFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSSSSX")
    isoFormat.timeZone = TimeZone.getTimeZone("UTC")

    return try {
      // 주어진 시간 문자열을 Date로 파싱
      val calendar = Calendar.getInstance()
      calendar.time = isoFormat.parse(time)

      // 밀리초 단위의 UTC 시간으로 변환
      val timeInMillis = calendar.timeInMillis

      // AlarmManager 인스턴스 가져오기
      val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

      // 지정된 시간으로 시스템 시간 설정 (주의: 루트 권한이 필요할 수 있음)
      alarmManager.setTime(timeInMillis)
      true // 성공적으로 시간 설정
    } catch (e: Exception) {
      e.printStackTrace()
      false // 시간 설정 실패
    }
  }
}
