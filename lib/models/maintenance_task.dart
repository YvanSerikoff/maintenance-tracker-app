class MaintenanceTask {
  final int id;
  final String name;
  final String description;
  final DateTime scheduledDate;
  final int status;
  final int priority; // 0-3 (low to high)
  final int technicianId;
  final int equipmentId;
  final String location;
  final List<String> attachments;
  final DateTime createdAt;
  final DateTime lastUpdated;

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
  });

  factory MaintenanceTask.fromJson(Map<String, dynamic> json) {
    return MaintenanceTask(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      scheduledDate: json['scheduled_date'] != null
          ? DateTime.tryParse(json['scheduled_date'].toString()) ?? DateTime(1970)
          : DateTime(1970),
      // CORRECTION CRITIQUE: Gestion sécurisée de stage_id
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
    );
  }

  // NOUVELLE MÉTHODE: Extraction sécurisée du status
  static int _extractStatusFromJson(Map<String, dynamic> json) {
    try {
      // Cas 1: status direct
      if (json['status'] != null) {
        if (json['status'] is int) {
          return json['status'];
        }
        if (json['status'] is String) {
          return int.tryParse(json['status']) ?? 1;
        }
      }

      // Cas 2: stage_id comme object
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

      // Fallback
      return 1; // Status par défaut: pending
    } catch (e) {
      print('Error extracting status from JSON: $e');
      return 1;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'scheduled_date': scheduledDate.toIso8601String(),
      'status': status,
      'stage_id': {'id': status}, // Format compatible avec l'API
      'priority': priority,
      'technician_id': technicianId,
      'equipment_id': equipmentId,
      'location': location,
      'attachments': attachments,
      'created_at': createdAt.toIso8601String(),
      'last_updated': lastUpdated.toIso8601String(),
    };
  }
}