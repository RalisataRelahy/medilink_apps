class AllergyModel {
  final String? id;
  final String name;

  const AllergyModel({
    this.id,
    required this.name,
  });

  factory AllergyModel.fromJson(Map<String, dynamic> json) {
    return AllergyModel(
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

  AllergyModel copyWith({
    String? id,
    String? name,
  }) {
    return AllergyModel(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AllergyModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'AllergyModel(id: $id, name: $name)';
}
