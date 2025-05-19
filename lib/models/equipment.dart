class Equipment {
  final int id;
  final String name;
  final String serialNumber;
  final String category;
  final String location;
  final DateTime installationDate;
  final String status;
  final String imageUrl;
  final Map<String, dynamic> specifications;

  Equipment({
    required this.id,
    required this.name,
    required this.serialNumber,
    required this.category,
    required this.location,
    required this.installationDate,
    required this.status,
    this.imageUrl = '',
    this.specifications = const {},
  });

  factory Equipment.fromJson(Map<String, dynamic> json) {
    return Equipment(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? '',
      serialNumber: json['serial_number']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      installationDate: json['installation_date'] != null
          ? DateTime.tryParse(json['installation_date'].toString()) ?? DateTime(1970)
          : DateTime(1970),
      status: json['status']?.toString() ?? '',
      imageUrl: json['image_url']?.toString() ?? '',
      specifications: json['specifications'] ?? const {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'serial_number': serialNumber,
      'category': category,
      'location': location,
      'installation_date': installationDate.toIso8601String(),
      'status': status,
      'image_url': imageUrl,
      'specifications': specifications,
    };
  }

  factory Equipment.empty() {
    return Equipment(
      id: 0,
      name: '',
      serialNumber: '',
      category: '',
      location: '',
      installationDate: DateTime(1970),
      status: '',
      imageUrl: '',
      specifications: const {},
    );
  }
}
