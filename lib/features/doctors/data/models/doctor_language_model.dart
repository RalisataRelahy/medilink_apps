class DoctorLanguageModel {
  final String doctorId;
  final String languageId;

  const DoctorLanguageModel({

    required this.doctorId,
    required this.languageId,
  });

  DoctorLanguageModel copyWith({

    String? doctorId,
    String? languageId,
  }) {
    return DoctorLanguageModel(
      doctorId: doctorId ?? this.doctorId,
      languageId: languageId ?? this.languageId,
    );
  }

  factory DoctorLanguageModel.fromJson(Map<String, dynamic> json) {
    return DoctorLanguageModel(
      doctorId: (json['doctor_id'] ?? '') as String,
      languageId: (json['language_id'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {

      'doctor_id': doctorId,
      'language_id': languageId,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DoctorLanguageModel &&
        other.doctorId == doctorId &&
        other.languageId == languageId;
  }

  @override
  String toString() =>
      'DoctorLanguageModel(doctorId: $doctorId, languageId: $languageId)';
}
