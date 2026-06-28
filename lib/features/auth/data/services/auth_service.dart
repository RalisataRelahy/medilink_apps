import 'package:flutter/cupertino.dart';
import 'package:medilink/core/constants/db_constants.dart';
import 'package:medilink/features/auth/data/models/user_model.dart';
import 'package:medilink/features/doctors/data/models/doctor_model.dart';
import 'package:medilink/features/patients/data/models/allergy_model.dart';
import 'package:medilink/features/patients/data/models/disease_model.dart';
import 'package:medilink/features/patients/data/models/patient_model.dart';
import 'package:medilink/shared/enums/user_role.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../patients/data/models/patient_details_models.dart';

class AuthService {
  final supabase = Supabase.instance.client;

  Future<AuthResponse> login(String email, String password) {
    return supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> register({
    PatientDetailsModel? patientData,
    DoctorModel? doctorData,
    required String password,
    required UserRole role,
    String? email, // Nécessaire si c'est un docteur car DoctorModel n'a pas d'email
    required UserModel userRegister
  }) async {
    final registrationEmail = role == UserRole.patient ? patientData!.profile.email : email;

    if (registrationEmail == null) {
      throw Exception("L'email et le nom complet sont obligatoires.");
    }
    debugPrint("Ignit Service register");
    // 1. Inscription Auth
    final res = await supabase.auth.signUp(
      email: registrationEmail,
      password: password,
    );

    final user = res.user;
    if (user == null) throw Exception("Échec de l'inscription.");

    final userId = user.id;

    // 2. Création du profil (UserModel)
    final userModel = UserModel(
      id: userId,
      email: registrationEmail,
      role: role,
      firstName: userRegister.firstName,
      lastName: userRegister.lastName,
      phone: userRegister.phone,
      address: userRegister.address,
      avatarUrl: userRegister.avatarUrl,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await supabase.from(TableNames.profiles).insert(userModel.toJson());
    print("Registred succeffully");
    print(role);
    // 3. Données spécifiques au rôle
    if (role == UserRole.patient && patientData != null) {
      try {
        print("Registered patient started: $userId");

        final patientInsert = await supabase
            .from('patients')
            .insert({
          'id': userId,
          'gender': patientData.patient.gender,
          'date_of_birth': patientData.patient.dateOfBirth.toIso8601String().split('T')[0],
          'blood_type': patientData.patient.bloodType?.name,
          'height': patientData.patient.height,
          'weight': patientData.patient.weight,
          'emergency_contact_name': patientData.patient.emergencyContactName,
          'emergency_contact_phone': patientData.patient.emergencyContactPhone,
          'account_status': patientData.patient.accountStatus.name,
          'created_at': patientData.patient.createdAt?.toIso8601String(),
          'updated_at': patientData.patient.updatedAt.toIso8601String(),
        })
            .select()
            .single();
        print(patientInsert);
        // Enregistrement des maladies
        if (patientData.diseases.isNotEmpty) {
          await registerPatientDiseases(userId, patientData.diseases);
        }
        print("Registred succeffully 3");

        // Enregistrement des allergies
        if (patientData.allergies.isNotEmpty) {
          await registerPatientAllergies(userId, patientData.allergies);
        }
        debugPrint("Registred succeffully 4");
        print("Registered successfully 2");
      } catch (e, stack) {
        print("INSERT ERROR: $e");
        print(stack);
        rethrow;
      }
    } else if (role == UserRole.doctor && doctorData != null) {
      await supabase.from(TableNames.doctors).insert({
        'id': userId,
        ...doctorData.toJson(),
      });
      debugPrint("Registred succeffully 5");
    }

    return res;
  }
  Future<String> getOrCreateDiseaseId(String name) async {
    final existing = await supabase
        .from(TableNames.diseases)
        .select('id')
        .eq('name', name)
        .maybeSingle();

    if (existing != null) {
      return existing['id'];
    }

    final created = await supabase
        .from(TableNames.diseases)
        .insert({'name': name})
        .select('id')
        .single();

    return created['id'];
  }
  Future<void> registerPatientDiseases(
      String userId,
      List<DiseaseModel> diseases,
      ) async {
    try {
      final liaisons = await Future.wait(
        diseases.map((d) async {
          final id = await getOrCreateDiseaseId(d.name);

          return {
            'patient_id': userId,
            'disease_id': id,
          };
        }),
      );

      await supabase.from(TableNames.patientDiseases).insert(liaisons);
    } catch (e) {
      print('Erreur registerPatientDiseases: $e');
      rethrow;
    }
  }

  Future<void> registerPatientAllergies(String userId, List<AllergyModel> allergies) async {
    try {
      final List<dynamic> res = await supabase
          .from(TableNames.allergies)
          .insert(allergies.map((a) => {'name': a.name}).toList())
          .select();

      final liaisons = res.map((all) => {
        'patient_id': userId,
        'allergy_id': all['id'],
      }).toList();

      await supabase.from(TableNames.patientAllergies).insert(liaisons);
    } catch (e) {
      print('Erreur registerPatientAllergies: $e');
      rethrow;
    }
  }

  Future<void> logout() => supabase.auth.signOut();

  User? get currentUser => supabase.auth.currentUser;

  Future<UserModel?> getUserProfile(String userId) async {
    try {
      print("Searching profile: $userId");
      final data = await supabase
          .from(TableNames.profiles)
          .select()
          .eq('id', userId)
          .single();
      return UserModel.fromJson(data);
    } catch (e) {
      print('Erreur getUserProfile: $e');
      return null;
    }
  }
}
