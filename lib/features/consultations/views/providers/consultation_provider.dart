import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medilink/features/auth/views/providers/auth_provider.dart';
import 'package:medilink/features/consultations/data/models/consultation_details_model.dart';
import 'package:medilink/features/consultations/data/services/consultations_services.dart';
import 'package:medilink/shared/enums/user_role.dart';

final consultationServiceProvider = Provider<ConsultationsServices>((ref) {
  return ConsultationsServices();
});

final consultationsProvider = FutureProvider<List<ConsultationDetailsModel>>((ref) async {
  final service = ref.watch(consultationServiceProvider);
  final authState = ref.watch(authProvider);
  final user = authState.user;
  
  if (user == null) return [];
  
  if (user.role == UserRole.doctor) {
    return service.fetchPastConsultationsFromDoctor(user.id);
  } else {
    return service.fetchPastConsultationsFromPatient(user.id);
  }
});
