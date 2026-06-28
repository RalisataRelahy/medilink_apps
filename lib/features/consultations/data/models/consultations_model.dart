import 'package:medilink/shared/enums/status.dart';

class ConsultationsModel {
  final String? id;
  final String patientId;
  final String doctorId;
  final String reason;
  final Status status;
  final DateTime? createdAt;

  const ConsultationsModel({
    this.id,
    required this.patientId,
    required this.doctorId,
    required this.reason,
    required this.status,
    this.createdAt,
  });

  ConsultationsModel copyWith({
    String? id,
    String? patientId,
    String? doctorId,
    String? reason,
    Status? status,
    DateTime? createdAt,
  }) {
    return ConsultationsModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'patient_id': patientId,
      'doctor_id': doctorId,
      'reason': reason,
      'status': status.name,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory ConsultationsModel.fromJson(Map<String, dynamic> json) {
    return ConsultationsModel(
      id: (json['id'] ?? json['uid']) as String?,
      patientId: (json['patient_id'] ?? '') as String,
      doctorId: (json['doctor_id'] ?? '') as String,
      reason: (json['reason'] ?? '') as String,
      status: Status.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => Status.pending,
      ),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  @override
  String toString() {
    return 'ConsultationsModel(id: $id, reason: $reason, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConsultationsModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
