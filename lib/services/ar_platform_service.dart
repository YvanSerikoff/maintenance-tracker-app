import 'package:flutter/services.dart';
import 'dart:typed_data';

class ARPlatformService {
  static const MethodChannel _channel = MethodChannel('maintenance_app/ar');

  /// Vérifier si ARCore est supporté sur l'appareil
  static Future<bool> isARCoreSupported() async {
    try {
      final bool result = await _channel.invokeMethod('isARCoreSupported');
      return result;
    } on PlatformException catch (e) {
      print('Erreur vérification ARCore: ${e.message}');
      return false;
    }
  }

  /// Démarrer la session AR avec un modèle 3D
  static Future<bool> startARSession({
    required String equipmentId,
    required String equipmentName,
    String? model3dUrl,
    String? model3dPath,
  }) async {
    try {
      final Map<String, dynamic> params = {
        'equipmentId': equipmentId,
        'equipmentName': equipmentName,
        'model3dUrl': model3dUrl,
        'model3dPath': model3dPath,
      };

      final bool result = await _channel.invokeMethod('startARSession', params);
      return result;
    } on PlatformException catch (e) {
      print('Erreur démarrage AR: ${e.message}');
      return false;
    }
  }

  /// Placer un modèle 3D dans l'espace AR
  static Future<bool> placeModel({
    required double x,
    required double y,
    required double z,
    double scale = 1.0,
  }) async {
    try {
      final Map<String, dynamic> params = {
        'x': x,
        'y': y,
        'z': z,
        'scale': scale,
      };

      final bool result = await _channel.invokeMethod('placeModel', params);
      return result;
    } on PlatformException catch (e) {
      print('Erreur placement modèle: ${e.message}');
      return false;
    }
  }

  /// Capturer une image de la session AR
  static Future<Uint8List?> captureARImage() async {
    try {
      final Uint8List? result = await _channel.invokeMethod('captureARImage');
      return result;
    } on PlatformException catch (e) {
      print('Erreur capture AR: ${e.message}');
      return null;
    }
  }

  /// Arrêter la session AR
  static Future<void> stopARSession() async {
    try {
      await _channel.invokeMethod('stopARSession');
    } on PlatformException catch (e) {
      print('Erreur arrêt AR: ${e.message}');
    }
  }

  /// Télécharger un modèle 3D
  static Future<String?> downloadModel(String url) async {
    try {
      final String? localPath = await _channel.invokeMethod('downloadModel', {
        'url': url,
      });
      return localPath;
    } on PlatformException catch (e) {
      print('Erreur téléchargement modèle: ${e.message}');
      return null;
    }
  }
}