import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:maintenance_app/models/maintenance_task.dart';

class OdooService {
  final String baseUrl;
  final String database;
  String? sessionId;
  int? uid;

  OdooService({
    required this.baseUrl,
    required this.database,
  });

  Future<bool> authenticate(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/jsonrpc'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'jsonrpc': '2.0',
          'params': {
            'db': database,
            'login': username,
            'password': password,
          }
        }),
      );

      final responseData = jsonDecode(response.body);
      print ("Authentication response: $responseData['result']");
      if (responseData['result'] != null) {
        sessionId = responseData['result']['session_id'];
        uid = responseData['result']['uid'];
        return true;
      }
      return false;
    } catch (e) {
      print('Authentication error: $e');
      return false;
    }
  }

  Future<bool> logout() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/web/session/destroy'),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'session_id=$sessionId',
        },
        body: jsonEncode({
          'jsonrpc': '2.0',
          'params': {},
        }),
      );

      final responseData = jsonDecode(response.body);
      return responseData['result'] != null;
    } catch (e) {
      print('Logout error: $e');
      return false;
    }
  }

  Future<dynamic> callKw({
    required String model,
    required String method,
    List<dynamic>? args,
    Map<String, dynamic>? kwargs,
  }) async {
    try {
      args ??= [];
      kwargs ??= {};
      
      final response = await http.post(
        Uri.parse('$baseUrl/web/dataset/call_kw'),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'session_id=$sessionId',
        },
        body: jsonEncode({
          'jsonrpc': '2.0',
          'method': 'call',
          'params': {
            'model': model,
            'method': method,
            'args': args,
            'kwargs': kwargs,
          }
        }),
      );

      final responseData = jsonDecode(response.body);
      if (responseData.containsKey('error')) {
        throw Exception(responseData['error']['data']['message'] ?? 'Unknown error');
      }
      return responseData['result'];
    } catch (e) {
      print('callKw error: $e');
      rethrow;
    }
  }

  Future<List<MaintenanceTask>> getTasks({String status = ''}) async {
    try {
      var domain = [['technician_id', '=', uid]];
      if (status.isNotEmpty) {
        domain.add(['status', '=', status]);
      }

      final result = await callKw(
        model: 'maintenance.request',
        method: 'search_read',
        args: [],
        kwargs: {
          'fields': [
            'name', 'description', 'schedule_date', 'stage_id', 
            'priority', 'technician_id', 'equipment_id', 
            'location', 'create_date', 'write_date'
          ],
          'domain': domain,
        },
      );

      if (result != null) {
        List<dynamic> records = result;
        return records.map((record) {
          // Convert Odoo record to MaintenanceTask
          return MaintenanceTask(
            id: record['id'],
            name: record['name'],
            description: record['description'] ?? '',
            scheduledDate: DateTime.parse(record['schedule_date'] ?? DateTime.now().toIso8601String()),
            status: _mapStageToStatus(record['stage_id'][0]),
            priority: record['priority'] ?? 0,
            technicianId: record['technician_id'][0],
            equipmentId: record['equipment_id'][0],
            location: record['location'] ?? '',
            createdAt: DateTime.parse(record['create_date']),
            lastUpdated: DateTime.parse(record['write_date']),
          );
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching tasks: $e');
      return [];
    }
  }

  // Keep the rest of the methods the same...
  // (updateTaskStatus, getEquipment, helper methods, etc.)
  
  // Helper methods to map between Odoo stages and app statuses
  String _mapStageToStatus(int stageId) {
    switch (stageId) {
      case 1: return 'pending';       // New
      case 2: return 'in_progress';   // In Progress
      case 3: return 'completed';     // Repaired
      case 4: return 'cancelled';     // Scrap
      default: return 'pending';
    }
  }

  int _mapStatusToStage(String status) {
    switch (status) {
      case 'pending': return 1;      // New
      case 'in_progress': return 2;  // In Progress
      case 'completed': return 3;    // Repaired
      case 'cancelled': return 4;    // Scrap
      default: return 1;
    }
  }

  updateTaskStatus(int id, String newStatus) {
    try {
      final stageId = _mapStatusToStage(newStatus);
      return callKw(
        model: 'maintenance.request',
        method: 'write',
        args: [
          [id],
          {'stage_id': stageId}
        ],
      );
    } catch (e) {
      print('Error updating task status: $e');
    }
  }

  getEquipment(int equipmentId) {
    try {
      return callKw(
        model: 'maintenance.equipment',
        method: 'read',
        args: [
          [equipmentId],
          ['name', 'serial_number', 'category_id', 'location_id', 'installation_date', 'status']
        ],
      );
    } catch (e) {
      print('Error fetching equipment: $e');
    }
  }
}