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
  final List<Map<String, dynamic>>? parts;

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
    this.parts,
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

  // ✨ HELPER : Conversion sécurisée pour DateTime
  static DateTime _safeParseDateTime(dynamic value, {DateTime? defaultValue}) {
    defaultValue ??= DateTime.now();
    if (value == null) return defaultValue;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      final parsed = DateTime.tryParse(value);
      return parsed ?? defaultValue;
    }
    return defaultValue;
  }

  factory MaintenanceTask.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> additional = {};

    if (json['detailed_info'] != null) {
      additional = Map<String, dynamic>.from(json['detailed_info']);
    }

    return MaintenanceTask(
      id: _safeParseInt(json['id']),
      name: json['name']?.toString() ?? json['request_object']?.toString() ?? 'Sans nom',
      description: json['description']?.toString() ?? json['request_reason']?.toString() ?? '',
      scheduledDate: _safeParseDateTime(json['scheduled_date']),
      status: _extractStatus(json),
      priority: _safeParseInt(json['priority']),
      technicianId: _safeParseInt(json['technician_id']),
      equipmentId: _safeParseInt(json['equipment_id']),
      location: json['location']?.toString() ?? 'Non spécifié',
      attachments: json['attachments'] != null
          ? List<String>.from(json['attachments'])
          : [],
      createdAt: _safeParseDateTime(json['created_at']),
      lastUpdated: json['last_updated'] != null
          ? _safeParseDateTime(json['last_updated'])
          : (json['detailed_info'] != null && json['detailed_info']['last_update'] != null
          ? _safeParseDateTime(json['detailed_info']['last_update'], defaultValue: DateTime(1970))
          : DateTime(1970)),
      equipment: json['equipment'] != null
          ? Equipment.fromJson(json['equipment'])
          : null,
      additionalData: additional.isNotEmpty ? additional : null,
      parts: (json['parts'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList(),
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
      'equipment': equipment?.toJson(),
      'additional_data': additionalData,
      'parts': parts,
    };
  }

  // ✨ NOUVEAU : Méthodes pour gérer l'état des pièces basé sur le champ "done"
  bool get areAllPartsChecked {
    if (parts == null || parts!.isEmpty) return false;

    for (var part in parts!) {
      if (part['done'] != true) {
        return false;
      }
    }
    return true;
  }

  // ✨ NOUVEAU : Compter les pièces cochées
  int get checkedPartsCount {
    if (parts == null) return 0;
    return parts!.where((part) => part['done'] == true).length;
  }

  // ✨ NOUVEAU : Total des pièces
  int get totalPartsCount {
    return parts?.length ?? 0;
  }

  // ✨ NOUVEAU : Obtenir le statut des pièces sous forme de Map
  Map<int, bool> get partsCheckedStatus {
    Map<int, bool> status = {};
    if (parts != null) {
      for (var part in parts!) {
        final partId = _safeParseInt(part['id']); // ✨ Conversion sécurisée
        if (partId > 0) { // Vérifier que l'ID est valide
          status[partId] = part['done'] == true;
        }
      }
    }
    return status;
  }

  // ✨ NOUVEAU : Créer une copie avec des pièces mises à jour
  MaintenanceTask copyWithUpdatedParts(List<Map<String, dynamic>> updatedParts) {
    return MaintenanceTask(
      id: id,
      name: name,
      description: description,
      scheduledDate: scheduledDate,
      status: status,
      priority: priority,
      technicianId: technicianId,
      equipmentId: equipmentId,
      location: location,
      attachments: attachments,
      createdAt: createdAt,
      lastUpdated: DateTime.now(),
      equipment: equipment,
      additionalData: additionalData,
      parts: updatedParts,
    );
  }

  static int _extractStatus(Map<String, dynamic> json) {
    try {
      // ✨ Conversion sécurisée pour tous les cas
      if (json['stage_id'] != null && json['stage_id'] is int) {
        return json['stage_id'];
      }
      if (json['stage_id'] != null && json['stage_id'] is String) {
        return _safeParseInt(json['stage_id'], defaultValue: 1);
      }
      if (json['stage_id'] != null && json['stage_id'] is Map && json['stage_id']['id'] != null) {
        return _safeParseInt(json['stage_id']['id'], defaultValue: 1);
      }
      if (json['stage'] != null && json['stage'] is Map && json['stage']['id'] != null) {
        return _safeParseInt(json['stage']['id'], defaultValue: 1);
      }
      if (json['status'] != null) {
        return _safeParseInt(json['status'], defaultValue: 1);
      }
      return 1;
    } catch (e) {
      print('Error extracting status from JSON: $e');
      return 1;
    }
  }
}