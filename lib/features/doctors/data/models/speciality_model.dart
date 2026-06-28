class SpecialityModel {
  final String? id;
  final String name;

  const SpecialityModel({
    this.id,
    required this.name,
  });

  SpecialityModel copyWith({
    String? id,
    String? name,
  }) {
    return SpecialityModel(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  factory SpecialityModel.fromJson(Map<String, dynamic> json) {
    return SpecialityModel(
      id: (json['id'] ?? json['uid'] ?? '') as String,
      name: (json['name'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if(id!=null)'id': id,
      'name': name,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SpecialityModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'SpecialityModel(id: $id, name: $name)';
}
