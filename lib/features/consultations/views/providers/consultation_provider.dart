import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medilink/features/consultations/data/models/consultation_details_model.dart';
import 'package:medilink/features/consultations/data/services/consultations_services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final consultationServiceProvider = Provider<ConsultationsServices>((ref) {
  return ConsultationsServices();
});

final pastConsultationsProviderFromPatient = FutureProvider<List<ConsultationDetailsModel>>((ref) {
  final service = ref.watch(consultationServiceProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;
  
  if (userId == null) return [];
  
  return service.fetchPastConsultationsFromPatient(userId);
});

final pastConsultationsProviderFromDoctor = FutureProvider<List<ConsultationDetailsModel>>((ref) {
  final service = ref.watch(consultationServiceProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;

  if (userId == null) return [];

  return service.fetchPastConsultationsFromDoctor(userId);
});
