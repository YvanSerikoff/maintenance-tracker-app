// Flutter/Dart - Encoder Basic Auth et appels API
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

// Fonction simple pour encoder Basic Auth
String encodeBasicAuth(String username, String password) {
  String credentials = '$username:$password';
  Codec<String, String> stringToBase64 = utf8.fuse(base64);
  String encoded = stringToBase64.encode(credentials);
  return encoded;
}

// Fonction pour obtenir l'header complet
String getAuthHeader(String username, String password) {
  String encoded = encodeBasicAuth(username, password);
  return 'Basic $encoded';
}

// Classe pour gérer l'API CMMS
class CMMSApiService {
  final String baseUrl;
  final String username;
  final String password;
  late String authHeader;

  CMMSApiService({
    required this.baseUrl,
    required this.username,
    required this.password,
  }) {
    authHeader = getAuthHeader(username, password);
  }

  // Headers par défaut
  Map<String, String> get defaultHeaders => {
    'Authorization': authHeader,
    'Content-Type': 'application/json',
  };

  Future<Map<String, dynamic>?> getUser() async{
    try{
      final response = await http.get(
        Uri.parse('$baseUrl/api/flutter/user/profile'),
        headers: defaultHeaders,
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Erreur: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception: $e');
      return null;
    }
  }

  // Récupérer le dashboard complet
  Future<Map<String, dynamic>?> getDashboard() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/flutter/maintenance/dashboard'),
        headers: defaultHeaders,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        // Affiche le message d'erreur retourné par l'API si disponible
        try {
          final body = json.decode(response.body);
          print('Erreur: ${response.statusCode} - ${body['message'] ?? response.body}');
        } catch (_) {
          print('Erreur: ${response.statusCode} - ${response.body}');
        }
        return null;
      }
    } catch (e) {
      print('Exception: $e');
      return null;
    }
  }

  // Récupérer les demandes de maintenance
  Future<Map<String, dynamic>?> getMaintenanceRequests({
    int limit = 100,
    int offset = 0,
    String? status,
    int? equipmentId,
  }) async {
    try {
      String url = '$baseUrl/api/flutter/maintenance/requests?limit=$limit&offset=$offset';
      
      if (status != null) url += '&status=$status';
      if (equipmentId != null) url += '&equipment_id=$equipmentId';

      final response = await http.get(
        Uri.parse(url),
        headers: defaultHeaders,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Erreur: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception: $e');
      return null;
    }
  }

  // Récupérer les équipements avec modèles 3D
  Future<Map<String, dynamic>?> getEquipment({
    int limit = 100,
    int offset = 0,
    bool? has3dModel,
    int? categoryId,
  }) async {
    try {
      String url = '$baseUrl/api/flutter/maintenance/equipment?limit=$limit&offset=$offset';
      
      if (has3dModel != null) url += '&has_3d_model=${has3dModel.toString()}';
      if (categoryId != null) url += '&category_id=$categoryId';

      final response = await http.get(
        Uri.parse(url),
        headers: defaultHeaders,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Erreur: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception: $e');
      return null;
    }
  }

  // Créer une nouvelle demande de maintenance
  Future<Map<String, dynamic>?> createMaintenanceRequest({
    required String name,
    required String description,
    String maintenanceType = 'corrective',
    String priority = 'medium',
    int? equipmentId,
    String? scheduleDate,
  }) async {
    try {
      Map<String, dynamic> requestData = {
        'name': name,
        'description': description,
        'maintenance_type': maintenanceType,
        'priority': priority,
      };

      if (equipmentId != null) requestData['equipment_id'] = equipmentId;
      if (scheduleDate != null) requestData['schedule_date'] = scheduleDate;

      final response = await http.post(
        Uri.parse('$baseUrl/api/flutter/maintenance/requests'),
        headers: defaultHeaders,
        body: json.encode(requestData),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        print('Erreur: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception: $e');
      return null;
    }
  }

  // Mettre à jour une demande
  Future<Map<String, dynamic>?> updateMaintenanceRequest(
    int requestId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/flutter/maintenance/requests/$requestId'),
        headers: defaultHeaders,
        body: json.encode(updates),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Erreur: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception: $e');
      return null;
    }
  }

  getEquipmentById(int equipmentId) async {
    try {
      print(defaultHeaders); // Affiche les headers envoyés
      final response = await http.get(
        Uri.parse('$baseUrl/api/flutter/maintenance/equipment/$equipmentId'),
        headers: defaultHeaders,

      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Erreur: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> updateUserEmail(String email) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/flutter/user/profile/update'),
        headers: defaultHeaders,
        body: json.encode({'email': email}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Erreur: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception: $e');
      return null;
    }
  }
}

