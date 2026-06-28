// lib/core/constants/db_constants.dart

class TableNames {
  // Auth & Profiles
  static const String profiles = 'profiles';

  // Patients
  static const String patients = 'patients';
  static const  String allergies = 'allergy';
  static const String diseases = 'diseases';
  static const String patientAllergies = 'patient_allergy';
  static const String patientDiseases = 'patient_diseases';

  // Doctors
  static const String doctors = 'doctors';
  static const String specialities = 'specialities';
  static const String doctorSpecialites='doctor_specialties';
  static const String doctorLanguages='doctor_languages';
  static const String doctorDiplomas='doctor_diplomas';
  static const String languages = 'languages';
  static const String diplomas = 'diplomas';

  // Consultations
  static const String consultations = 'consultations';
  static const String prescriptions = 'prescriptions';
  static const String medicines = 'medicines';
  static const String exams = 'exams';
  static const String prescriptionMedicines = 'prescription_medicines';
  static const String prescriptionExams = 'prescription_exams';
}