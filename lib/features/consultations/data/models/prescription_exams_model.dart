class PrescriptionExamsModel {
  final String? id;
  final String prescriptionId;
  final String examenId;

  const PrescriptionExamsModel({
    this.id,
    required this.prescriptionId,
    required this.examenId,
  });

  PrescriptionExamsModel copyWith({
    String? id,
    String? prescriptionId,
    String? examenId,
  }) {
    return PrescriptionExamsModel(
      id: id ?? this.id,
      prescriptionId: prescriptionId ?? this.prescriptionId,
      examenId: examenId ?? this.examenId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'prescription_id': prescriptionId,
      'examen_id': examenId,
    };
  }

  factory PrescriptionExamsModel.fromJson(Map<String, dynamic> json) {
    return PrescriptionExamsModel(
      id: (json['id'] ?? json['uid']) as String?,
      prescriptionId: (json['prescription_id'] ?? '') as String,
      examenId: (json['examen_id'] ?? '') as String,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PrescriptionExamsModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
