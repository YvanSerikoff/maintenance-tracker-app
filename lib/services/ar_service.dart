import 'package:flutter/services.dart';

class ArService {
  static const MethodChannel _channel = MethodChannel('com.example.maintenance_tracker/ar_viewer');

  /// Launch the AR model viewer with the specified model path
  static Future<void> launchArViewer(String modelPath) async {
    try {
      await _channel.invokeMethod('launchArViewer', {
        'modelPath': modelPath,
      });
    } on PlatformException catch (e) {
      print("Failed to launch AR viewer: '${e.message}'.");
      rethrow;
    }
  }

  /// Check if AR is supported on this device
  static Future<bool> checkArSupport() async {
    try {
      final bool isSupported = await _channel.invokeMethod('checkArSupport');
      return isSupported;
    } on PlatformException catch (e) {
      print("Failed to check AR support: '${e.message}'.");
      return false;
    }
  }
}