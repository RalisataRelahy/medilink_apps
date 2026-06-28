class DoctorSpecialityModel {
  final String doctorId;
  final String specialityId;

  const DoctorSpecialityModel({
    required this.doctorId,
    required this.specialityId,
  });

  DoctorSpecialityModel copyWith({
    String? id,
    String? doctorId,
    String? specialityId,
  }) {
    return DoctorSpecialityModel(

      doctorId: doctorId ?? this.doctorId,
      specialityId: specialityId ?? this.specialityId,
    );
  }

  factory DoctorSpecialityModel.fromJson(Map<String, dynamic> json) {
    return DoctorSpecialityModel(
      doctorId: (json['doctor_id'] ?? '') as String,
      specialityId: (json['speciality_id'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {

      'doctor_id': doctorId,
      'speciality_id': specialityId,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DoctorSpecialityModel &&

        other.doctorId == doctorId &&
        other.specialityId == specialityId;
  }


  @override
  String toString() =>
      'DoctorSpecialityModel(doctorId: $doctorId, specialityId: $specialityId)';
}
