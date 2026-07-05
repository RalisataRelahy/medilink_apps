import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medilink/features/auth/views/providers/auth_provider.dart';
import '../../data/models/doctor_details_model.dart';

final doctorDetailsProvider = FutureProvider<DoctorDetailsModel?>((ref) async {
  final authState = ref.watch(authProvider);
  final userId = authState.user?.id;
  
  if (userId == null) return null;
  
  final authService = ref.read(authServiceProvider);
  return authService.getDoctorDetails(userId);
});

final allDoctorsProvider = FutureProvider<List<DoctorDetailsModel>>((
    ref) async {
  final authService = ref.read(authServiceProvider);
  return authService.getAllDoctors();
});

final doctorByIdProvider = FutureProvider.family<DoctorDetailsModel?, String>((
    ref, id) async {
  final authService = ref.read(authServiceProvider);
  return authService.getDoctorDetails(id);
});
