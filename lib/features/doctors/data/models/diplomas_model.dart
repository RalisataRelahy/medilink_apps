class DiplomasModel {
  final String? id;
  final String name;

  const DiplomasModel({
    this.id,
    required this.name,
  });

  DiplomasModel copyWith({
    String? id,
    String? name,
  }) {
    return DiplomasModel(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  factory DiplomasModel.fromJson(Map<String, dynamic> json) {
    return DiplomasModel(
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
    return other is DiplomasModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'DiplomasModel(id: $id, name: $name)';
}
