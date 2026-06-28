import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/db_constants.dart';
import '../../data/models/patient_details_models.dart';
import '../../data/models/patient_model.dart';
import '../../data/models/allergy_model.dart';
import '../../data/models/disease_model.dart';
import '../../../auth/data/models/user_model.dart';

class PatientService {
  final _supabase = Supabase.instance.client;

  Future<PatientDetailsModel?> getPatientDetails(String userId) async {
    try {
      // Fetch profile
      final profileData = await _supabase
          .from(TableNames.profiles)
          .select()
          .eq('id', userId)
          .single();
      final profile = UserModel.fromJson(profileData);

      // Fetch patient info
      final patientData = await _supabase
          .from(TableNames.patients)
          .select()
          .eq('id', userId)
          .single();
      final patient = PatientModel.fromJson(patientData);

      // Fetch allergies
      final allergiesData = await _supabase
          .from(TableNames.patientAllergies)
          .select('allergy(*)')
          .eq('patient_id', userId);
      
      final allergies = (allergiesData as List)
          .map((item) => AllergyModel.fromJson(item['allergy'] as Map<String, dynamic>))
          .toList();

      // Fetch diseases
      final diseasesData = await _supabase
          .from(TableNames.patientDiseases)
          .select('diseases(*)')
          .eq('patient_id', userId);

      final diseases = (diseasesData as List)
          .map((item) => DiseaseModel.fromJson(item['diseases'] as Map<String, dynamic>))
          .toList();

      return PatientDetailsModel(
        profile: profile,
        patient: patient,
        allergies: allergies,
        diseases: diseases,
      );
    } catch (e) {
      print('Error fetching patient details: $e');
      return null;
    }
  }

  Future<void> updatePatientProfile(UserModel user) async {
    await _supabase
        .from(TableNames.profiles)
        .update(user.toJson())
        .eq('id', user.id);
  }

  Future<void> updatePatientDetails(PatientModel patient) async {
    await _supabase
        .from(TableNames.patients)
        .update(patient.toJson())
        .eq('id', patient.id!);
  }
}
