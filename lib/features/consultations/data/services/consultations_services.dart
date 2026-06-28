import 'package:medilink/features/consultations/data/models/consultation_details_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ConsultationsServices {
  final _supabase = Supabase.instance.client;

  Future<List<ConsultationDetailsModel>> fetchPastConsultationsFromPatient(String patientId) async {
    final List<dynamic> data = await _supabase
        .from('consultations')
        .select('''
          *,
          prescriptions(
            *,
            prescription_medicine(
              *,
              medicine(*)
            ),
            prescription_exams(
              *,
              examen(*)
            )
          )
        ''')
        .eq('patient_id', patientId)
        .order('created_at', ascending: false);

    return data.map((json) => ConsultationDetailsModel.fromJson(json as Map<String, dynamic>)).toList();
  }
  Future<List<ConsultationDetailsModel>> fetchPastConsultationsFromDoctor(String doctorId) async {
    final List<dynamic> data = await _supabase
        .from('consultations')
        .select('''
          *,
          prescriptions(
            *,
            prescription_medicine(
              *,
              medicine(*)
            ),
            prescription_exams(
              *,
              examen(*)
            )
          )
        ''')
        .eq('doctor_id', doctorId)
        .order('created_at', ascending: false);

    return data.map((json) => ConsultationDetailsModel.fromJson(json as Map<String, dynamic>)).toList();
  }
}
