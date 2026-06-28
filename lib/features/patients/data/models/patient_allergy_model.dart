class PatientAllergyModel {
  final String patientId;
  final String allergyId;

  const PatientAllergyModel({
    required this.patientId,
    required this.allergyId,
  });

  factory PatientAllergyModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return PatientAllergyModel(
      patientId: json['patient_id'],
      allergyId: json['allergy_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patient_id': patientId,
      'allergy_id': allergyId,
    };
  }
}