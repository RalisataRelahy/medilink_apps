import 'package:medilink/shared/enums/days_type.dart';

class PrescriptionsMedicineModels {
  final String? id;
  final String prescriptionsId;
  final String medocId;
  final String frequency; // like-1-0-1
  final int duration;
  final DaysType typeOfDuration;

  const PrescriptionsMedicineModels({
    this.id,
    required this.prescriptionsId,
    required this.medocId,
    required this.frequency,
    required this.duration,
    required this.typeOfDuration,
  });

  PrescriptionsMedicineModels copyWith({
    String? id,
    String? prescriptionsId,
    String? medocId,
    String? frequency,
    int? duration,
    DaysType? typeOfDuration,
  }) {
    return PrescriptionsMedicineModels(
      id: id ?? this.id,
      prescriptionsId: prescriptionsId ?? this.prescriptionsId,
      medocId: medocId ?? this.medocId,
      frequency: frequency ?? this.frequency,
      duration: duration ?? this.duration,
      typeOfDuration: typeOfDuration ?? this.typeOfDuration,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'prescriptions_id': prescriptionsId,
      'medoc_id': medocId,
      'frequency': frequency,
      'duration': duration,
      'type_of_duration': typeOfDuration.name,
    };
  }

  factory PrescriptionsMedicineModels.fromJson(Map<String, dynamic> json) {
    return PrescriptionsMedicineModels(
      id: (json['id'] ?? json['uid']) as String?,
      prescriptionsId: (json['prescriptions_id'] ?? '') as String,
      medocId: (json['medoc_id'] ?? '') as String,
      frequency: (json['frequency'] ?? '') as String,
      duration: (json['duration'] ?? 0) as int,
      typeOfDuration: DaysType.values.firstWhere(
        (e) => e.name == json['type_of_duration'],
        orElse: () => DaysType.day,
      ),
    );
  }

  @override
  String toString() {
    return 'PrescriptionsMedicineModels(id: $id, frequency: $frequency, duration: $duration ${typeOfDuration.labelFr})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PrescriptionsMedicineModels && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
