import 'package:medilink/features/auth/data/models/user_model.dart';
import 'package:medilink/features/patients/data/models/patient_model.dart';
import 'allergy_model.dart';
import 'disease_model.dart';

class PatientDetailsModel {
  final UserModel profile;
  final PatientModel patient;
  final List<AllergyModel> allergies;
  final List<DiseaseModel> diseases;

  const PatientDetailsModel({
    required this.profile,
    required this.patient,
    required this.allergies,
    required this.diseases,
  });

  /// Crée une copie de l'objet avec des champs modifiés (utile pour Riverpod)
  PatientDetailsModel copyWith({
    UserModel? profile,
    PatientModel? patient,
    List<AllergyModel>? allergies,
    List<DiseaseModel>? diseases,
  }) {
    return PatientDetailsModel(
      profile: profile ?? this.profile,
      patient: patient ?? this.patient,
      allergies: allergies ?? this.allergies,
      diseases: diseases ?? this.diseases,
    );
  }

  /// Conversion depuis Map (JSON) venant de Supabase
  /// Gère les jointures complexes (profile, allergies, diseases)
  factory PatientDetailsModel.fromJson(Map<String, dynamic> json) {
    // Extraction du profil (soit directement, soit via une jointure 'profiles')
    final profileData = json['profile'] ?? json['profiles'] ?? {};
    
    // Extraction des allergies (gestion de la table de jointure patient_allergies)
    var allergiesList = <AllergyModel>[];
    if (json['allergies'] != null) {
      allergiesList = (json['allergies'] as List).map((e) => AllergyModel.fromJson(e)).toList();
    } else if (json['patient_allergies'] != null) {
      // Cas où Supabase renvoie via la table de jointure
      allergiesList = (json['patient_allergies'] as List)
          .where((e) => e['allergies'] != null)
          .map((e) => AllergyModel.fromJson(e['allergies']))
          .toList();
    }

    // Extraction des maladies (gestion de la table de jointure patient_diseases)
    var diseasesList = <DiseaseModel>[];
    if (json['diseases'] != null) {
      diseasesList = (json['diseases'] as List).map((e) => DiseaseModel.fromJson(e)).toList();
    } else if (json['patient_diseases'] != null) {
      // Cas où Supabase renvoie via la table de jointure
      diseasesList = (json['patient_diseases'] as List)
          .where((e) => e['diseases'] != null)
          .map((e) => DiseaseModel.fromJson(e['diseases']))
          .toList();
    }

    return PatientDetailsModel(
      profile:UserModel.fromJson(profileData),
      patient: PatientModel.fromJson(json), // Le JSON racine contient souvent les champs de patient
      allergies: allergiesList,
      diseases: diseasesList,
    );
  }

  /// Conversion vers Map (JSON)
  Map<String, dynamic> toJson() {
    return {
      'profile': profile.toJson(),
      'patient': patient.toJson(),
      'allergies': allergies.map((e) => e.toJson()).toList(),
      'diseases': diseases.map((e) => e.toJson()).toList(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PatientDetailsModel &&
        other.profile == profile &&
        other.patient == patient;
  }

  @override
  int get hashCode => profile.hashCode ^ patient.hashCode;

  @override
  String toString() {
    return 'PatientDetailsModel(name: ${profile.fullName}, allergies: ${allergies.length}, diseases: ${diseases.length})';
  }
}
