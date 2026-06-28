class DiseaseModel {
  final String? id;
  final String name;

  const DiseaseModel({
    this.id,
    required this.name,
  });

  factory DiseaseModel.fromJson(Map<String, dynamic> json) {
    return DiseaseModel(
      id: (json['id'] ?? json['uid']) as String?,
      name: (json['name'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
    };
  }

  DiseaseModel copyWith({
    String? id,
    String? name,
  }) {
    return DiseaseModel(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DiseaseModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'DiseaseModel(id: $id, name: $name)';
}
