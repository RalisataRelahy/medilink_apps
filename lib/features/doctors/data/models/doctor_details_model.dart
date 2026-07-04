import 'package:medilink/features/auth/data/models/user_model.dart';
import 'package:medilink/features/doctors/data/models/doctor_model.dart';
import 'speciality_model.dart';
import 'language_model.dart';
import 'diplomas_model.dart';

class DoctorDetailsModel {
  final UserModel profile;
  final DoctorModel doctor;
  final List<SpecialityModel> specialities;
  final List<LanguageModel> languages;
  final List<DiplomasModel> diplomas;

  const DoctorDetailsModel({
    required this.profile,
    required this.doctor,
    required this.specialities,
    required this.languages,
    required this.diplomas,
  });

  DoctorDetailsModel copyWith({
    UserModel? profile,
    DoctorModel? doctor,
    List<SpecialityModel>? specialities,
    List<LanguageModel>? languages,
    List<DiplomasModel>? diplomas,
  }) {
    return DoctorDetailsModel(
      profile: profile ?? this.profile,
      doctor: doctor ?? this.doctor,
      specialities: specialities ?? this.specialities,
      languages: languages ?? this.languages,
      diplomas: diplomas ?? this.diplomas,
    );
  }

  factory DoctorDetailsModel.fromJson(Map<String, dynamic> json) {
    final profileData = json['profile'] ?? json['profiles'] ?? {};
    
    var specialitiesList = <SpecialityModel>[];
    if (json['specialities'] != null) {
      specialitiesList = (json['specialities'] as List).map((e) => SpecialityModel.fromJson(e)).toList();
    }

    var languagesList = <LanguageModel>[];
    if (json['languages'] != null) {
      languagesList = (json['languages'] as List).map((e) => LanguageModel.fromJson(e)).toList();
    }

    var diplomasList = <DiplomasModel>[];
    if (json['diplomas'] != null) {
      diplomasList = (json['diplomas'] as List).map((e) => DiplomasModel.fromJson(e)).toList();
    }

    return DoctorDetailsModel(
      profile: UserModel.fromJson(profileData),
      doctor: DoctorModel.fromJson(json),
      specialities: specialitiesList,
      languages: languagesList,
      diplomas: diplomasList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profile': profile.toJson(),
      'doctor': doctor.toJson(),
      'specialities': specialities.map((e) => e.toJson()).toList(),
      'languages': languages.map((e) => e.toJson()).toList(),
      'diplomas': diplomas.map((e) => e.toJson()).toList(),
    };
  }
}
