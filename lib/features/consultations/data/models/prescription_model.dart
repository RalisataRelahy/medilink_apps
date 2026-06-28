class PrescriptionModel {
  final String? id;
  final String consultationId;
  final String? note;
  final String? fileUrl;
  final DateTime? createdAt;

  const PrescriptionModel({
    this.id,
    required this.consultationId,
    this.note,
    this.fileUrl,
    this.createdAt,
  });

  PrescriptionModel copyWith({
    String? id,
    String? consultationId,
    String? note,
    String? fileUrl,
    DateTime? createdAt,
  }) {
    return PrescriptionModel(
      id: id ?? this.id,
      consultationId: consultationId ?? this.consultationId,
      note: note ?? this.note,
      fileUrl: fileUrl ?? this.fileUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'consultation_id': consultationId,
      'note': note,
      'file_url': fileUrl,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory PrescriptionModel.fromJson(Map<String, dynamic> json) {
    return PrescriptionModel(
      id: (json['id'] ?? json['uid']) as String?,
      consultationId: (json['consultation_id'] ?? '') as String,
      note: json['note'] as String?,
      fileUrl: json['file_url'] as String?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : null,
    );
  }

  @override
  String toString() => 'PrescriptionModel(id: $id, consultationId: $consultationId)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PrescriptionModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
