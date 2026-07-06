import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medilink/features/appointments/data/services/appointments_services.dart';
import 'package:medilink/features/auth/views/providers/auth_provider.dart';
import 'package:medilink/shared/enums/user_role.dart';

import '../../data/models/appointment_models.dart';

final appointmentServiceProvider = Provider((ref) => AppointmentsServices());

// Provider dynamique pour les rendez-vous (dépend du rôle de l'utilisateur)
final appointmentsProvider = FutureProvider<List<AppointmentModel>>((ref) async {
  final service = ref.watch(appointmentServiceProvider);
  final authState = ref.watch(authProvider);
  final user = authState.user;

  if (user == null) return [];

  final List<Map<String, dynamic>> rawData;

  if (user.role == UserRole.doctor) {
    rawData = await service.fetchAllAppointmentsFromDoctor(user.id);
  } else {
    rawData = await service.fetchAllAppointmentsFromPatient(user.id);
  }

  return rawData.map((json) => AppointmentModel.fromJson(json)).toList();
});

// NOUVEAU : Provider pour gérer l'état d'insertion d'un rendez-vous
final createAppointmentProvider = AsyncNotifierProvider<
    CreateAppointmentNotifier,
    void>(() {
  return CreateAppointmentNotifier();
});

class CreateAppointmentNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // État initial vide (Idle)
  }

  Future<bool> addAppointment({
    required String doctorId,
    required String patientId,
    required DateTime date,
    required String time,
    String? localization,
  }) async {
    // 1. Passe l'état en mode chargement (utile pour afficher un spinner sur le bouton)
    state = const AsyncValue.loading();

    final service = ref.read(appointmentServiceProvider);

    final authState = ref.read(authProvider);
    final userRole = authState.user!.role;
    // 2. Exécute l'insertion de manière sécurisée avec AsyncValue.guard
    if (userRole == UserRole.doctor) {
      state = await AsyncValue.guard(() async {
        await service.createAppointmentByDoctor(
          doctorId: doctorId,
          patientId: patientId,
          date: date,
          time: time,
          localization: localization ?? "Undefinied",
        );
      });
    } else {
      state = await AsyncValue.guard(() async {
        await service.createAppointmentByPatient(
          doctorId: doctorId,
          patientId: patientId,
          date: date,
          time: time,
        );
      });
    }
    // 3. Si l'insertion a réussi, on rafraîchit automatiquement la liste globale
    if (!state.hasError) {
      ref.invalidate(appointmentsProvider);
      return true;
    }

    return false;
  }
}
