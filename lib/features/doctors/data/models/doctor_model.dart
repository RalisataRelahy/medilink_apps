import 'package:medilink/shared/enums/account_status.dart';

class DoctorModel {
  final String? id;
  final String licenseNumber;
  final int yearsOfExperience;
  final String bio;
  final double rating;
  final String clinicName;
  final AccountStatus accountStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DoctorModel({
    this.id,
    required this.licenseNumber,
    required this.yearsOfExperience,
    required this.bio,
    required this.rating,
    required this.clinicName,
    required this.accountStatus,
    this.createdAt,
    this.updatedAt,
  });

  /// Crée une copie de l'objet avec des champs modifiés
  DoctorModel copyWith({
    String? id,
    String? licenseNumber,
    int? yearsOfExperience,
    String? bio,
    double? rating,
    String? clinicName,
    AccountStatus? accountStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DoctorModel(
      id: id ?? this.id,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      bio: bio ?? this.bio,
      rating: rating ?? this.rating,
      clinicName: clinicName ?? this.clinicName,
      accountStatus: accountStatus ?? this.accountStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Conversion vers Map (JSON) pour Supabase
  Map<String, dynamic> toJson() {
    return {
      if(id!=null)'id': id,
      'license_number': licenseNumber,
      'years_of_experience': yearsOfExperience,
      'bio': bio,
      'rating': rating,
      'clinic_name': clinicName,
      'account_status': accountStatus.name,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Conversion depuis Map (JSON)
  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    return DoctorModel(
      id: (json['id'] ?? json['uid'] ?? '') as String,
      licenseNumber: (json['license_number'] ?? '') as String,
      yearsOfExperience: (json['years_of_experience'] ?? 0) as int,
      bio: (json['bio'] ?? '') as String,
      rating: (json['rating'] as num? ?? 0.0).toDouble(),
      clinicName: (json['clinic_name'] ?? '') as String,
      accountStatus: AccountStatus.values.firstWhere(
        (e) => e.name == json['account_status'],
        orElse: () => AccountStatus.pending,
      ),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  @override
  String toString() {
    return 'DoctorModel(id: $id, clinic: $clinicName, rating: $rating)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DoctorModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
