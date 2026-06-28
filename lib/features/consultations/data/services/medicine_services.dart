import 'package:medilink/features/consultations/data/models/medicine_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MedicineService {
  final _supabase = Supabase.instance.client;

  /// Récupère tous les médicaments (utilisé pour les dropdowns de prescription)
  Future<List<MedicineModel>> fetchAllMedicines() async {
    try {
      final List<dynamic> data = await _supabase
          .from('medicine')
          .select('id, name, dosage, unit, type');
      
      return data
          .map((json) => MedicineModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (err) {
      print('Erreur MedicineService.fetchAllMedicines: $err');
      return [];
    }
  }

  /// Ajoute un nouveau médicament à la base de données
  Future<void> addMedicine(MedicineModel newMedicine) async {
    try {
      await _supabase.from('medicine').insert(newMedicine.toJson());
    } catch (err) {
      print('Erreur MedicineService.addMedicine: $err');
      rethrow; // On rethrow pour permettre à l'UI de gérer l'erreur (ex: Snackbar)
    }
  }
}

