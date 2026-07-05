import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medilink/features/auth/views/providers/auth_provider.dart';
import 'package:medilink/features/consultations/data/models/consultation_details_model.dart';
import 'package:medilink/features/consultations/data/services/consultations_services.dart';
import 'package:medilink/features/doctors/data/models/doctor_model.dart';
import 'package:medilink/features/patients/data/models/patient_model.dart';
import 'package:medilink/shared/enums/user_role.dart';

final consultationServiceProvider = Provider((ref) => ConsultationsServices());

final patientConsultationsProvider =
FutureProvider.family<List<ConsultationDetailsModel>, String>(
      (ref, patientId) {
    return ref
        .read(consultationServiceProvider)
        .getPatientHistory(patientId);
  },
);

final doctorConsultationsProvider =
FutureProvider.family<List<ConsultationDetailsModel>, String>(
      (ref, doctorId) {
    return ref
        .read(consultationServiceProvider)
        .getDoctorHistory(doctorId);
  },
);

final consultationsProvider =
FutureProvider<List<ConsultationDetailsModel>>((ref) async {
  final authState = ref.watch(authProvider);

  final user = authState.user;

  if (user == null) return [];

  final service = ref.read(consultationServiceProvider);

  switch (user.role) {
    case UserRole.doctor:
      return service.getDoctorHistory(user.id);

    case UserRole.patient:
      return service.getPatientHistory(user.id);

    default:
      return [];
  }
});

final doctorPatientsProvider =
FutureProvider.family<List<PatientModel>, String>((ref, doctorId) {
  return ref
      .read(consultationServiceProvider)
      .getDoctorPatients(doctorId);
});

final patientDoctorsProvider =
FutureProvider.family<List<DoctorModel>, String>((ref, patientId) {
  return ref
      .read(consultationServiceProvider)
      .getPatientDoctors(patientId);
});
