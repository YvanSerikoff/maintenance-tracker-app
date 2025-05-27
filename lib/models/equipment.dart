class Equipment {
  final int id;
  final String name;
  final String category;
  final String location;
  final String? model3dViewerUrl;
  final String? categoryName;

  Equipment({
    required this.id,
    required this.name,
    required this.category,
    required this.location,
    this.model3dViewerUrl,
    this.categoryName,
  });

  factory Equipment.fromJson(Map<String, dynamic> json) {
    // Gestion de la catégorie (objet ou string)
    String categoryName = '';
    if (json['category'] is Map && json['category'] != null) {
      categoryName = json['category']['name']?.toString() ?? '';
    } else if (json['category'] != null) {
      categoryName = json['category'].toString();
    }
    // Gestion du modèle 3D (objet ou string)
    String? model3dViewerUrl;
    if (json['model_3d'] is Map && json['model_3d'] != null) {
      model3dViewerUrl = json['model_3d']['viewer_url']?.toString();
    } else if (json['model_3d_viewer_url'] != null) {
      model3dViewerUrl = json['model_3d_viewer_url'].toString();
    }
    return Equipment(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? '',
      category: categoryName,
      location: json['location']?.toString() ?? '',
      model3dViewerUrl: model3dViewerUrl,
      categoryName: categoryName,
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

