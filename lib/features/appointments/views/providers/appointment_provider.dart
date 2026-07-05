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
