import '../screens/dashboard/flutter_dashboard_widget.dart';
import 'equipment.dart';

class MaintenanceTask {
  final int id;
  final String name;
  final String description;
  final DateTime scheduledDate;
  final int status;
  final int priority;
  final int technicianId;
  final int equipmentId;
  final String location;
  final List<String> attachments;
  final DateTime createdAt;
  final DateTime lastUpdated;

  // ✨ NOUVEAU : Stockage direct des infos équipement
  final Equipment? equipment;
  final Map<String, dynamic>? additionalData;

  MaintenanceTask({
    required this.id,
    required this.name,
    required this.description,
    required this.scheduledDate,
    required this.status,
    required this.priority,
    required this.technicianId,
    required this.equipmentId,
    required this.location,
    this.attachments = const [],
    required this.createdAt,
    required this.lastUpdated,
    this.equipment,
    this.additionalData,
  });

  factory MaintenanceTask.fromJson(Map<String, dynamic> json) {
    return MaintenanceTask(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      scheduledDate: json['scheduled_date'] != null
          ? DateTime.tryParse(json['scheduled_date'].toString()) ?? DateTime(1970)
          : DateTime(1970),
      status: _extractStatusFromJson(json),
      priority: json['priority'] is int
          ? json['priority']
          : int.tryParse(json['priority']?.toString() ?? '0') ?? 0,
      technicianId: json['technician_id'] is int
          ? json['technician_id']
          : int.tryParse(json['technician_id']?.toString() ?? '0') ?? 0,
      equipmentId: json['equipment_id'] is int
          ? json['equipment_id']
          : (json['equipment_id'] is Map && json['equipment_id']['id'] != null
          ? json['equipment_id']['id']
          : 0),
      location: json['location']?.toString() ?? '',
      attachments: (json['attachments'] as List?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime(1970)
          : DateTime(1970),
      lastUpdated: json['last_updated'] != null
          ? DateTime.tryParse(json['last_updated'].toString()) ?? DateTime(1970)
          : DateTime(1970),
      // ✨ NOUVEAU : Parsing des données étendues
      equipment: json['equipment'] != null
          ? Equipment.fromJson(json['equipment'])
          : null,
      additionalData: json['additional_data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'scheduled_date': scheduledDate.toIso8601String(),
      'status': status,
      'stage_id': {'id': status},
      'priority': priority,
      'technician_id': technicianId,
      'equipment_id': equipmentId,
      'location': location,
      'attachments': attachments,
      'created_at': createdAt.toIso8601String(),
      'last_updated': lastUpdated.toIso8601String(),
      // ✨ NOUVEAU : Sérialisation des données étendues
      'equipment': equipment?.toJson(),
      'additional_data': additionalData,
    };
  }

  static int _extractStatusFromJson(Map<String, dynamic> json) {
    try {
      if (json['status'] != null) {
        if (json['status'] is int) {
          return json['status'];
        }
        if (json['status'] is String) {
          return int.tryParse(json['status']) ?? 1;
        }
      }

      if (json['stage_id'] != null) {
        if (json['stage_id'] is Map && json['stage_id']['id'] != null) {
          return json['stage_id']['id'];
        }
        if (json['stage_id'] is int) {
          return json['stage_id'];
        }
        if (json['stage_id'] is String) {
          return int.tryParse(json['stage_id']) ?? 1;
        }
      }

      return 1;
    } catch (e) {
      print('Error extracting status from JSON: $e');
      return 1;
    }
  }
}