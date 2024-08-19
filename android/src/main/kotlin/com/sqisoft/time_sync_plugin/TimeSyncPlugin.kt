package com.sqisoft.time_sync_plugin

import androidx.annotation.NonNull

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** TimeSyncPlugin */
class TimeSyncPlugin: FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "time_sync_plugin")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    if (call.method == "getPlatformVersion") {
      result.success("Android ${android.os.Build.VERSION.RELEASE}")
    } else if (call.method == "setSyncTime") {
      val time = call.argument<String>("syncTime")
      _syncTime(time)
      result.success(true)
    } else if (call.method == "getWifiStrength") {
      //
      // android native code
      // or using flutter:package:wifi_iot
      //
      // return value : 0 ~ -100 (higher is better, lower is worst)
      //
      result.success(0)
    } else {
      result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  fun _syncTime(time: String?) {
    //
    // time : ex)2024-08-10T12:34:56.789012Z
    //
    // android native code for sync-time...
    //
  }
}
