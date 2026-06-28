class LanguageModel {
  final String? id;
  final String name;

  const LanguageModel({
    this.id,
    required this.name,
  });

  LanguageModel copyWith({
    String? id,
    String? name,
  }) {
    return LanguageModel(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  factory LanguageModel.fromJson(Map<String, dynamic> json) {
    return LanguageModel(
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
    return other is LanguageModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'LanguageModel(id: $id, name: $name)';
}
