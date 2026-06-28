//   -- 🌟 AJOUT DU STATUT
//   -- 'en_attente' : réservé par le patient mais pas encore validé par le docteur
//   -- 'confirme'  : validé par le docteur
//   -- 'en_cours'  : le patient est actuellement dans le cabinet
//   -- 'termine'   : la consultation est finie
//   -- 'annule'    : rendez-vous annulé

import 'package:flutter/foundation.dart';
import 'package:medilink/shared/enums/status.dart';

@immutable
class AppointmentModel {
  final String? id;
  final String heure; // Format: "14:30:00"
  final DateTime date;
  final String localization;
  final String idPatient;
  final String? idConsultation; // Optionnel car NULL au début
  final String idDoctor;
  final Status status;
  final DateTime createdAt;

  const AppointmentModel({
    this.id,
    required this.heure,
    required this.date,
    required this.localization,
    required this.idPatient,
    this.idConsultation,
    required this.idDoctor,
    required this.status,
    required this.createdAt,
  });

  // Convertit le JSON brut reçu de Supabase en un objet typé et sécurisé
  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: (json['id'] ?? json['uid']) as String?,
      heure: (json['heure'] ?? '') as String,
      // Supabase renvoie les dates en chaînes de caractères, on les transforme en DateTime
      date: DateTime.parse(json['date'] as String),
      localization: (json['localization'] ?? '') as String,
      idPatient: (json['id_patient'] ?? '') as String,
      idConsultation: json['id_consultation'] as String?,
      idDoctor: (json['id_doctor'] ?? '') as String,
      // Transformation du texte de la BDD vers notre Enum sécurisé
      status: Status.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => Status.pending,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  // Conversion vers Map (JSON) pour Supabase
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'heure': heure,
      'date': date.toIso8601String(),
      'localization': localization,
      'id_patient': idPatient,
      'id_consultation': idConsultation,
      'id_doctor': idDoctor,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Permet de cloner l'objet en modifiant seulement quelques variables (Recommandé avec Riverpod)
  AppointmentModel copyWith({
    String? id,
    String? heure,
    DateTime? date,
    String? localization,
    String? idPatient,
    String? idConsultation,
    String? idDoctor,
    Status? status,
    DateTime? createdAt,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      heure: heure ?? this.heure,
      date: date ?? this.date,
      localization: localization ?? this.localization,
      idPatient: idPatient ?? this.idPatient,
      idConsultation: idConsultation ?? this.idConsultation,
      idDoctor: idDoctor ?? this.idDoctor,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'AppointmentModel(id: $id, date: $date, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppointmentModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
