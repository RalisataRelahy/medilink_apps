import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:medilink/shared/enums/status.dart';

class AppointmentsServices {
  final _supabase = Supabase.instance.client;

  // Le docteur voit les infos du patient
  Future<List<Map<String, dynamic>>> fetchAllAppointmentsFromDoctor(String doctorUId) async {
    final List<dynamic> data = await _supabase
        .from('appointments')
        .select('*, profiles:id_patient(profiles(*))')
        .eq('id_doctor', doctorUId)
        .order('date', ascending: true)
        .order('heure', ascending: true);
    return data.cast<Map<String, dynamic>>();
  }

  // Le patient voit les infos du docteur
  Future<List<Map<String, dynamic>>> fetchAllAppointmentsFromPatient(String patientUId) async {
    final List<dynamic> data = await _supabase
        .from('appointments')
        .select('*, profiles:id_doctor(profiles(*))')
        .eq('id_patient', patientUId)
        .order('date', ascending: true)
        .order('heure', ascending: true);
    return data.cast<Map<String, dynamic>>();
  }

  Future<void> createAppointmentByDoctor({
    required String doctorId,
    required String patientId,
    required DateTime date,
    required String time,
    required String localization,
  }) async {
    await _supabase.from('appointments').insert({
      'id_doctor': doctorId,
      'id_patient': patientId,
      'date': date.toIso8601String().split('T')[0],
      'heure': time,
      'localization': localization,
      'status': 'confirmed',
    });
  }

  Future<void> createAppointmentByPatient({
    required String doctorId,
    required String patientId,
    required DateTime date,
    required String time,
  }) async {
    await _supabase.from('appointments').insert({
      'id_doctor': doctorId,
      'id_patient': patientId,
      'date': date.toIso8601String().split('T')[0],
      'heure': time,
      'status': Status.pending.name,
    });
  }
}
