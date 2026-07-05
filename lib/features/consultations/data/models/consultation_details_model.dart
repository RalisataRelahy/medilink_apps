import 'package:medilink/features/auth/data/models/user_model.dart';
import 'consultations_model.dart';
import 'prescription_model.dart';
import 'prescriptions_medicine_models.dart';
import 'prescription_exams_model.dart';
import 'medicine_model.dart';
import 'exam_model.dart';

class ConsultationDetailsModel {
  final ConsultationsModel consultation;
  final PrescriptionModel? prescription;
  final List<MedicineWithDetails> medicines;
  final List<ExamWithDetails> exams;
  final UserModel? profile;

  const ConsultationDetailsModel({
    required this.consultation,
    this.prescription,
    this.medicines = const [],
    this.exams = const [],
    this.profile,
  });

  factory ConsultationDetailsModel.fromJson(Map<String, dynamic> json) {
    // On récupère la consultation de base
    final consultation = ConsultationsModel.fromJson(json);
    final profile = json['profiles'] != null ? UserModel.fromJson(json['profiles']) : null;

    // On cherche la prescription (souvent une liste d'une seule prescription dans le retour Supabase)
    final prescriptionsList = json['prescriptions'] as List?;
    final Map<String, dynamic>? prescriptionJson = 
        (prescriptionsList != null && prescriptionsList.isNotEmpty) 
        ? prescriptionsList.first 
        : null;
    
    final prescription = prescriptionJson != null 
        ? PrescriptionModel.fromJson(prescriptionJson) 
        : null;

    // Parsing des médicaments avec leurs détails (via prescription_medicine)
    List<MedicineWithDetails> medicines = [];
    if (prescriptionJson != null && prescriptionJson['prescription_medicine'] != null) {
      medicines = (prescriptionJson['prescription_medicine'] as List).map((pm) {
        return MedicineWithDetails(
          prescriptionMedicine: PrescriptionsMedicineModels.fromJson(pm),
          medicine: pm['medicine'] != null 
              ? MedicineModel.fromJson(pm['medicine']) 
              : null,
        );
      }).toList();
    }

    // Parsing des examens avec leurs détails (via prescription_exams)
    List<ExamWithDetails> exams = [];
    if (prescriptionJson != null && prescriptionJson['prescription_exams'] != null) {
      exams = (prescriptionJson['prescription_exams'] as List).map((pe) {
        return ExamWithDetails(
          prescriptionExam: PrescriptionExamsModel.fromJson(pe),
          exam: pe['examen'] != null 
              ? ExamModel.fromJson(pe['examen']) 
              : null,
        );
      }).toList();
    }

    return ConsultationDetailsModel(
      consultation: consultation,
      prescription: prescription,
      medicines: medicines,
      exams: exams,
      profile: profile,
    );
  }
}

/// Classe utilitaire pour grouper un médicament et sa posologie spécifique à l'ordonnance
class MedicineWithDetails {
  final PrescriptionsMedicineModels prescriptionMedicine; // La posologie (fréquence, durée)
  final MedicineModel? medicine; // Les infos du médicament (nom, dosage de base)

  const MedicineWithDetails({
    required this.prescriptionMedicine,
    this.medicine,
  });
}

/// Classe utilitaire pour grouper un examen et ses détails spécifiques
class ExamWithDetails {
  final PrescriptionExamsModel prescriptionExam; // Le lien prescription-examen
  final ExamModel? exam; // Les détails de l'examen (nom, catégorie)

  const ExamWithDetails({
    required this.prescriptionExam,
    this.exam,
  });
}
