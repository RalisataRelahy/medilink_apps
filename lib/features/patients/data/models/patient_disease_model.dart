class PatientDiseaseModel {
  final String patientId;
  final String diseaseId;

  const PatientDiseaseModel({
    required this.patientId,
    required this.diseaseId,
  });

  factory PatientDiseaseModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return PatientDiseaseModel(
      patientId: json['patient_id'],
      diseaseId: json['disease_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patient_id': patientId,
      'disease_id': diseaseId,
    };
  }
}