import 'package:medilink/features/consultations/data/models/consultation_details_model.dart';
import 'package:medilink/features/doctors/data/models/doctor_model.dart';
import 'package:medilink/features/patients/data/models/patient_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ConsultationsServices {
  ConsultationsServices();

  final SupabaseClient _supabase = Supabase.instance.client;

  //--------------------------------------
  // PRIVATE
  //--------------------------------------

  Future<List<ConsultationDetailsModel>> _fetchConsultations({
    required String filterColumn,
    required String profileRelation,
    required String id,
  }) async {
    final List<dynamic> data = await _supabase
        .from('consultations')
        .select('''
          *,
          profiles:$profileRelation(*),
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
        .eq(filterColumn, id)
        .order('created_at', ascending: false);

    return data
        .map((e) => ConsultationDetailsModel.fromJson(e))
        .toList();
  }

  //--------------------------------------
  // CONSULTATIONS
  //--------------------------------------

  /// Historique d'un patient
  Future<List<ConsultationDetailsModel>> getPatientHistory(
      String patientId) async {
    return _fetchConsultations(
      filterColumn: 'patient_id',
      profileRelation: 'doctor_id',
      id: patientId,
    );
  }

  /// Historique d'un docteur
  Future<List<ConsultationDetailsModel>> getDoctorHistory(
      String doctorId) async {
    return _fetchConsultations(
      filterColumn: 'doctor_id',
      profileRelation: 'patient_id',
      id: doctorId,
    );
  }

  //--------------------------------------
  // DOCTEURS CONSULTÉS PAR UN PATIENT
  //--------------------------------------

  Future<List<DoctorModel>> getPatientDoctors(String patientId) async {
    final data = await _supabase
        .from('consultations')
        .select('''
          profiles:doctor_id(*)
        ''')
        .eq('patient_id', patientId);

    final doctors = <DoctorModel>[];
    final ids = <String>{};

    for (final row in data) {
      final profile = row['profiles'];

      if (profile == null) continue;

      if (ids.add(profile['id'])) {
        doctors.add(DoctorModel.fromJson(profile));
      }
    }

    return doctors;
  }

  //--------------------------------------
  // PATIENTS DÉJÀ CONSULTÉS PAR UN DOCTEUR
  //--------------------------------------

  Future<List<PatientModel>> getDoctorPatients(String doctorId) async {
    final data = await _supabase
        .from('consultations')
        .select('''
          profiles:patient_id(*)
        ''')
        .eq('doctor_id', doctorId);

    final patients = <PatientModel>[];
    final ids = <String>{};

    for (final row in data) {
      final profile = row['profiles'];

      if (profile == null) continue;

      if (ids.add(profile['id'])) {
        patients.add(PatientModel.fromJson(profile));
      }
    }

    return patients;
  }
}