import 'package:medilink/features/appointments/data/models/appointment_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppointmentsServices {
  final _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchAllAppointmentsFromDoctor(String doctorUId) async {
    final List<dynamic> data = await _supabase
        .from('appointments')
        .select('*, profiles:id_patient(*)')
        .eq('id_doctor', doctorUId)
        .order('date', ascending: true)
        .order('heure', ascending: true);
    return data.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> fetchAllAppointmentsFromPatient(String patientUId) async {
    final List<dynamic> data = await _supabase
        .from('appointments')
        .select('*, profiles:id_doctor(*)')
        .eq('id_patient', patientUId)
        .order('date', ascending: true)
        .order('heure', ascending: true);
    return data.cast<Map<String, dynamic>>();
  }
}
