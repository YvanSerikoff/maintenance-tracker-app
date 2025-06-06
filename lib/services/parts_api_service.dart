import 'dart:convert';
import 'package:http/http.dart' as http;

class PartsApiService {
  final String baseUrl;
  final Map<String, String> headers;

  PartsApiService({
    required this.baseUrl,
    required this.headers,
  });

  // ✨ HELPER : Conversion sécurisée de String vers int
  static int _safeParseInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed ?? defaultValue;
    }
    if (value is double) return value.toInt();
    return defaultValue;
  }

  /// Obtenir le détail d'une pièce spécifique
  Future<Map<String, dynamic>?> getPartDetails(int taskId, int partId) async {
    try {
      final url = '$baseUrl/api/flutter/maintenance/requests/$taskId/part/$partId';
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // ✨ Normaliser les IDs pour éviter les erreurs de type
        if (data['data'] != null) {
          data['data']['id'] = _safeParseInt(data['data']['id']);

          // Normaliser les IDs dans les sous-objets
          if (data['data']['submodel'] != null) {
            data['data']['submodel']['id'] = _safeParseInt(data['data']['submodel']['id']);
            data['data']['submodel']['relative_id'] = _safeParseInt(data['data']['submodel']['relative_id']);
          }

          if (data['data']['parent_model3d'] != null) {
            data['data']['parent_model3d']['id'] = _safeParseInt(data['data']['parent_model3d']['id']);
          }
        }

        return data;
      } else {
        print('Failed to get part details: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error getting part details: $e');
      return null;
    }
  }

  /// Mettre à jour le statut "done" d'une pièce
  Future<bool> updatePartStatus(int taskId, int partId, bool isDone) async {
    try {
      final url = '$baseUrl/api/flutter/maintenance/requests/$taskId/part/$partId';
      final response = await http.put(
        Uri.parse(url),
        headers: {
          ...headers,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'done': isDone,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else {
        print('Failed to update part status: ${response.statusCode}');
        print('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error updating part status: $e');
      return false;
    }
  }

  /// Mettre à jour plusieurs pièces en batch
  Future<Map<int, bool>> updateMultiplePartsStatus(
      int taskId,
      Map<int, bool> partsStatus
      ) async {
    Map<int, bool> results = {};

    for (var entry in partsStatus.entries) {
      final partId = entry.key;
      final isDone = entry.value;

      final success = await updatePartStatus(taskId, partId, isDone);
      results[partId] = success;

      // Petit délai pour éviter de surcharger l'API
      await Future.delayed(Duration(milliseconds: 100));
    }

    return results;
  }
}