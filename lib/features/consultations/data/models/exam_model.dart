class ExamModel {
  final String? id;
  final String category;
  final String examenName;
  final String medicalIndication;
  final String? specialMention;

  const ExamModel({
    this.id,
    required this.category,
    required this.examenName,
    required this.medicalIndication,
    this.specialMention,
  });

  ExamModel copyWith({
    String? id,
    String? category,
    String? examenName,
    String? medicalIndication,
    String? specialMention,
  }) {
    return ExamModel(
      id: id ?? this.id,
      category: category ?? this.category,
      examenName: examenName ?? this.examenName,
      medicalIndication: medicalIndication ?? this.medicalIndication,
      specialMention: specialMention ?? this.specialMention,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'category': category,
      'examen_name': examenName,
      'medical_indication': medicalIndication,
      'special_mention': specialMention,
    };
  }

  factory ExamModel.fromJson(Map<String, dynamic> json) {
    return ExamModel(
      id: (json['id'] ?? json['uid']) as String?,
      category: (json['category'] ?? '') as String,
      examenName: (json['examen_name'] ?? '') as String,
      medicalIndication: (json['medical_indication'] ?? '') as String,
      specialMention: json['special_mention'] as String?,
    );
  }

  @override
  String toString() {
    return 'ExamModel(id: $id, category: $category, name: $examenName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExamModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
