class DoctorDiplomaModel{
  final String doctorId;
  final String diplomaId;

  const DoctorDiplomaModel({
    required this.doctorId,
    required this.diplomaId,
  });

  DoctorDiplomaModel copyWith({
    String? doctorId,
    String? diplomaId,
  }) {
    return DoctorDiplomaModel(
      doctorId: doctorId ?? this.doctorId,
      diplomaId: diplomaId ?? this.diplomaId,
    );
  }

  factory DoctorDiplomaModel.fromJson(Map<String, dynamic> json) {
    return DoctorDiplomaModel(

      doctorId: (json['doctor_id'] ?? '') as String,
      diplomaId: (json['diploma_id'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {

      'doctor_id': doctorId,
      'diploma_id': diplomaId,
    };
  }
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DoctorDiplomaModel &&

        other.doctorId == doctorId &&
        other.diplomaId == diplomaId;
  }



  @override
  String toString() =>
      'DoctorDiplomaModel( doctorId: $doctorId, diplomaId: $diplomaId)';
}
