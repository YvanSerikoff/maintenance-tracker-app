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
      id: json['id'],
      name: json['name'],
      serialNumber: json['serial_number'],
      category: json['category'],
      location: json['location'],
      installationDate: DateTime.parse(json['installation_date']),
      status: json['status'],
      imageUrl: json['image_url'] ?? '',
      specifications: json['specifications'] ?? {},
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
}