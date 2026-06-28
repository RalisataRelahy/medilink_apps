import 'package:medilink/shared/enums/account_status.dart';
import 'package:medilink/shared/enums/blood_type.dart';

class PatientModel {
  final String? id;
  final String gender;
  final DateTime dateOfBirth;
  final BloodType? bloodType;
  final double? height;
  final double? weight;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final AccountStatus accountStatus;
  final DateTime? createdAt;
  final DateTime updatedAt;

  PatientModel({
    this.id,
    required this.gender,
    required this.dateOfBirth,
    this.bloodType,
    this.height,
    this.weight,
    required this.emergencyContactName,
    required this.emergencyContactPhone,
    required this.accountStatus,
    required this.updatedAt,
    this.createdAt,
  });

  PatientModel copyWith({
    String? id,
    String? gender,
    DateTime? dateOfBirth,
    BloodType? bloodType,
    double? height,
    double? weight,
    String? emergencyContactName,
    String? emergencyContactPhone,
    AccountStatus? accountStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PatientModel(
      id: id ?? this.id,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      bloodType: bloodType ?? this.bloodType,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      accountStatus: accountStatus ?? this.accountStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gender': gender,
      'date_of_birth': dateOfBirth.toIso8601String(),
      'blood_type': bloodType?.name,
      'height': height,
      'weight': weight,
      'emergency_contact_name': emergencyContactName,
      'emergency_contact_phone': emergencyContactPhone,
      'account_status': accountStatus.name,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel(
      id: (json['id'] ?? json['uid']) as String?,
      gender: json['gender'] as String,
      dateOfBirth: DateTime.parse(json['date_of_birth'] as String),
      bloodType: json['blood_type'] != null
          ? BloodType.values.firstWhere(
              (e) => e.name == json['blood_type'],
            )
          : null,
      height: (json['height'] as num?)?.toDouble(),
      weight: (json['weight'] as num?)?.toDouble(),
      emergencyContactName: json['emergency_contact_name'] as String,
      emergencyContactPhone: json['emergency_contact_phone'] as String,
      accountStatus: AccountStatus.values.firstWhere(
        (e) => e.name == json['account_status'],
      ),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
