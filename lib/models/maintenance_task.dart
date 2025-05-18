class MaintenanceTask {
  final int id;
  final String name;
  final String description;
  final DateTime scheduledDate;
  final String status; // 'pending', 'in_progress', 'completed', 'cancelled'
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
      id: json['id'],
      name: json['name'],
      description: json['description'],
      scheduledDate: DateTime.parse(json['scheduled_date']),
      status: json['status'],
      priority: json['priority'],
      technicianId: json['technician_id'],
      equipmentId: json['equipment_id'],
      location: json['location'],
      attachments: List<String>.from(json['attachments'] ?? []),
      createdAt: DateTime.parse(json['created_at']),
      lastUpdated: DateTime.parse(json['last_updated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'scheduled_date': scheduledDate.toIso8601String(),
      'status': status,
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