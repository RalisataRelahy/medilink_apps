import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/models/patient_details_models.dart';
import '../../data/services/patient_service.dart';
import '../../../auth/views/providers/auth_provider.dart';

final patientServiceProvider = Provider<PatientService>((ref) {
  return PatientService();
});

final patientDetailsProvider = FutureProvider<PatientDetailsModel?>((ref) async {
  final authState = ref.watch(authProvider);
  final user = authState.user;

  if (user == null) return null;

  return ref.read(patientServiceProvider).getPatientDetails(user.id);
});

class PatientNotifier extends StateNotifier<AsyncValue<PatientDetailsModel?>> {
  final PatientService _service;
  final String? _userId;

  PatientNotifier(this._service, this._userId) : super(const AsyncValue.loading()) {
    if (_userId != null) {
      loadPatientDetails();
    } else {
      state = const AsyncValue.data(null);
    }
  }

  Future<void> loadPatientDetails() async {
    if (_userId == null) return;
    state = const AsyncValue.loading();
    try {
      final details = await _service.getPatientDetails(_userId);
      state = AsyncValue.data(details);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final patientProvider = StateNotifierProvider<PatientNotifier, AsyncValue<PatientDetailsModel?>>((ref) {
  final authState = ref.watch(authProvider);
  final service = ref.read(patientServiceProvider);
  return PatientNotifier(service, authState.user?.id);
});
