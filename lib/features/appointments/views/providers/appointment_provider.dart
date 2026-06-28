import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medilink/features/appointments/data/services/appointments_services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/appointment_models.dart';

final appointmentServiceProvider = Provider((ref) => AppointmentsServices());

// Le FutureProvider que le tableau de bord du docteur va écouter
final doctorAppointmentsProvider = FutureProvider<List<AppointmentModel>>((ref) async {
  final service = ref.watch(appointmentServiceProvider);
  final doctorId = Supabase.instance.client.auth.currentUser?.id;

  if (doctorId == null) return [];

  final rawData = await service.fetchAllAppointmentsFromDoctor(doctorId);
  return rawData.map((json) => AppointmentModel.fromJson(json as Map<String,dynamic>)).toList();
});
