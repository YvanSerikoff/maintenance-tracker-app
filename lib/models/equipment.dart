class Equipment {
  final int id;
  final String name;
  final String category;
  final String location;
  final String? model3dViewerUrl;

  Equipment({
    required this.id,
    required this.name,
    required this.category,
    required this.location,
    this.model3dViewerUrl,
  });

  factory Equipment.fromJson(Map<String, dynamic> json) {
    return Equipment(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      model3dViewerUrl: json['model_3d_viewer_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'location': location,
      'model_3d_viewer_url': model3dViewerUrl,
    };
  }

  factory Equipment.empty() {
    return Equipment(
      id: 0,
      name: '',
      category: '',
      location: '',
      model3dViewerUrl: null,
    );
  }
}