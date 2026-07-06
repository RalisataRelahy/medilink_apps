import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:medilink/core/constants/db_constants.dart';
import 'package:medilink/features/doctors/data/models/doctor_details_model.dart';
import 'package:medilink/features/doctors/data/models/doctor_model.dart';
import 'package:medilink/features/doctors/data/models/speciality_model.dart';
import 'package:medilink/features/doctors/data/models/language_model.dart';
import 'package:medilink/features/doctors/data/models/diplomas_model.dart';
import 'package:medilink/features/patients/data/models/allergy_model.dart';
import 'package:medilink/features/patients/data/models/disease_model.dart';
import 'package:medilink/shared/enums/user_role.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../patients/data/models/patient_details_models.dart';
import '../models/user_model.dart';

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
    DoctorDetailsModel? doctorData,
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
    final existing = await supabase
        .from(TableNames.profiles)
        .select('id')
        .eq('id', userId)
        .maybeSingle();
    if (existing == null) {
      await supabase.from(TableNames.profiles).insert(userModel.toJson());
    } else {
      await supabase.from(TableNames.profiles).update(userModel.toJson()).eq('id', userId);
    }
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
      print("Doctor registration beguin from auth_servivces :$userId");
      try{
      await supabase.from(TableNames.doctors).insert({
        'id': userId,
        ...doctorData.doctor.toJson(),
      });}catch(e){
        print("INSERT ERROR: $e");
        rethrow;
      }

      if (doctorData.specialities.isNotEmpty) {
        await registerDoctorSpecialities(userId, doctorData.specialities);
      }
      if (doctorData.languages.isNotEmpty) {
        await registerDoctorLanguages(userId, doctorData.languages);
      }
      if (doctorData.diplomas.isNotEmpty) {
        await registerDoctorDiplomas(userId, doctorData.diplomas);
      }
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
      final uniqueDiseases = {
        for (var d in diseases) d.name.toLowerCase().trim(): d
      }.values.toList();

      if (uniqueDiseases.isEmpty) return;

      final liaisons = await Future.wait(
        uniqueDiseases.map((d) async {
          final id = await getOrCreateDiseaseId(d.name.trim());

          return {
            'patient_id': userId,
            'disease_id': id,
          };
        }),
      );

      await supabase
          .from(TableNames.patientDiseases)
          .upsert(liaisons);

    } catch (e, stack) {
      debugPrint("❌ registerPatientDiseases: $e");
      debugPrintStack(stackTrace: stack);
      rethrow;
    }
  }

  Future<void> registerPatientAllergies(
      String userId,
      List<AllergyModel> allergies,
      ) async {
    try {
      final uniqueAllergies = {
        for (var a in allergies) a.name.toLowerCase().trim(): a
      }.values.toList();

      if (uniqueAllergies.isEmpty) return;

      final allergyIds = await Future.wait(
        uniqueAllergies.map((a) async {
          final name = a.name.trim();

          final existing = await supabase
              .from(TableNames.allergies)
              .select('id')
              .eq('name', name)
              .maybeSingle();

          if (existing != null) {
            return existing['id'];
          }

          final inserted = await supabase
              .from(TableNames.allergies)
              .insert({'name': name})
              .select('id')
              .single();

          return inserted['id'];
        }),
      );

      final liaisons = allergyIds.map((id) {
        return {
          'patient_id': userId,
          'allergy_id': id,
        };
      }).toList();

      await supabase
          .from(TableNames.patientAllergies)
          .upsert(liaisons);

    } catch (e, stack) {
      debugPrint("registerPatientAllergies: $e");
      debugPrintStack(stackTrace: stack);
      rethrow;
    }
  }

  Future<void> registerDoctorSpecialities(String userId, List<SpecialityModel> specialities) async {
    final liaisons = await Future.wait(specialities.map((s) async {
      final existing = await supabase.from(TableNames.specialities).select('id').eq('name', s.name.trim()).maybeSingle();
      final specialityId = existing != null ? existing['id'] : (await supabase.from(TableNames.specialities).insert({'name': s.name.trim()}).select('id').single())['id'];
      return {'doctor_id': userId, 'specialty_id': specialityId};
    }));
    await supabase.from(TableNames.doctorSpecialites).upsert(liaisons);
  }

  Future<void> registerDoctorLanguages(String userId, List<LanguageModel> languages) async {
    final liaisons = await Future.wait(languages.map((l) async {
      final existing = await supabase.from(TableNames.languages).select('id').eq('name', l.name.trim()).maybeSingle();
      final languageId = existing != null ? existing['id'] : (await supabase.from(TableNames.languages).insert({'name': l.name.trim()}).select('id').single())['id'];
      return {'doctor_id': userId, 'language_id': languageId};
    }));
    await supabase.from(TableNames.doctorLanguages).upsert(liaisons);
  }

  Future<void> registerDoctorDiplomas(String userId, List<DiplomasModel> diplomas) async {
    final liaisons = await Future.wait(diplomas.map((d) async {
      final existing = await supabase.from(TableNames.diplomas).select('id').eq('name', d.name.trim()).maybeSingle();
      final diplomaId = existing != null ? existing['id'] : (await supabase.from(TableNames.diplomas).insert({'name': d.name.trim()}).select('id').single())['id'];
      return {'doctor_id': userId, 'diploma_id': diplomaId};
    }));
    await supabase.from(TableNames.doctorDiplomas).upsert(liaisons);
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

  Future<DoctorDetailsModel?> getDoctorDetails(String userId) async {
    try {
      final data = await supabase
          .from(TableNames.doctors)
          .select('''
            *,
            profiles:profiles!doctors_id_fkey (*),
            specialities:doctor_specialties!doctor_specialties_doctor_id_fkey (specialties (*)),
            languages:doctor_languages!doctor_languages_doctor_id_fkey (languages (*)),
            diplomas:doctor_diplomas!doctor_diplomas_doctor_id_fkey (diplomas (*))
          ''')
          .eq('id', userId)
          .single();

      final profile = data['profiles'];
      final specialities = (data['specialities'] as List)
          .map((s) => s['specialties'])
          .where((s) => s != null)
          .toList();
      final languages = (data['languages'] as List)
          .map((l) => l['languages'])
          .where((l) => l != null)
          .toList();
      final diplomas = (data['diplomas'] as List)
          .map((d) => d['diplomas'])
          .where((d) => d != null)
          .toList();

      return DoctorDetailsModel(
        profile: UserModel.fromJson(profile),
        doctor: DoctorModel.fromJson(data),
        specialities: specialities.map((e) => SpecialityModel.fromJson(e)).toList(),
        languages: languages.map((e) => LanguageModel.fromJson(e)).toList(),
        diplomas: diplomas.map((e) => DiplomasModel.fromJson(e)).toList(),
      );
    } catch (e) {
      debugPrint('Erreur getDoctorDetails: $e');
      return null;
    }
  }

  Future<List<DoctorDetailsModel>> getAllDoctors() async {
    try {
      final List<dynamic> data = await supabase
          .from(TableNames.doctors)
          .select('''
            *,
            profiles:profiles!doctors_id_fkey (*),
            specialities:doctor_specialties!doctor_specialties_doctor_id_fkey (specialties (*)),
            languages:doctor_languages!doctor_languages_doctor_id_fkey (languages (*)),
            diplomas:doctor_diplomas!doctor_diplomas_doctor_id_fkey (diplomas (*))
          ''');

      final doctors = <DoctorDetailsModel>[];

      for (final d in data) {
        try {
          // Extraction sécurisée du profil
          final profileData = d['profiles'];
          final profileMap = (profileData is List && profileData.isNotEmpty)
              ? profileData.first
              : (profileData is Map<String, dynamic> ? profileData : null);

          if (profileMap == null) continue;

          // Extraction sécurisée des listes
          List<SpecialityModel> specs = [];
          if (d['specialities'] != null) {
            specs = (d['specialities'] as List)
                .map((s) => s['specialties'])
                .where((s) => s != null)
                .map((e) => SpecialityModel.fromJson(e))
                .toList();
          }

          List<LanguageModel> langs = [];
          if (d['languages'] != null) {
            langs = (d['languages'] as List)
                .map((l) => l['languages'])
                .where((l) => l != null)
                .map((e) => LanguageModel.fromJson(e))
                .toList();
          }

          List<DiplomasModel> dipls = [];
          if (d['diplomas'] != null) {
            dipls = (d['diplomas'] as List)
                .map((d) => d['diplomas'])
                .where((d) => d != null)
                .map((e) => DiplomasModel.fromJson(e))
                .toList();
          }

          doctors.add(DoctorDetailsModel(
            profile: UserModel.fromJson(profileMap),
            doctor: DoctorModel.fromJson(d),
            specialities: specs,
            languages: langs,
            diplomas: dipls,
          ));
        } catch (e) {
          debugPrint("Erreur lors du parsing d'un docteur : $e");
        }
      }
      return doctors;
    } catch (e) {
      debugPrint('Erreur getAllDoctors: $e');
      return [];
    }
  }
}
