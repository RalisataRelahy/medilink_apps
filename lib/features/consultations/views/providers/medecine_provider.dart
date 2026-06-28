import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medilink/features/consultations/data/models/medicine_model.dart';

import '../../data/services/medicine_services.dart';

final medicineServiceProvider = Provider((ref) => MedicineService());

// Ce provider fournit la liste brute des médicaments
final medicinesListProvider = FutureProvider<List<MedicineModel>>((ref) async {
  final service = ref.watch(medicineServiceProvider);
  return service.fetchAllMedicines();
});
