import 'package:medilink/features/appointments/data/models/appointment_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppointmentsServices {
  final _supabase=Supabase.instance.client;
  Future<List<AppointmentModel>> fetchAllAppointmentsFromDoctor(String doctorUId)async{
    final List<dynamic> data=await _supabase
        .from('appointments')
        .select()
        .eq('id_doctor',doctorUId )
        .order('date',ascending: true)
        .order('heure',ascending: true);
    return data.map((json)=>AppointmentModel.fromJson(json as Map<String,dynamic>)).toList();
  }
}