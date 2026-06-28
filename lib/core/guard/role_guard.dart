import '../../app/router/app_router.dart';
import '../../shared/enums/user_role.dart';

class RoleGuard {
  static bool canAccess(String path, UserRole role) {
    final doctorOnly = {
      AppRoutes.dashboard,
      AppRoutes.patients,
      AppRoutes.consultations,
    };

    if (role == UserRole.doctor) {
      return true;
    }

    if (role == UserRole.patient) {
      return !doctorOnly.contains(path);
    }

    return false;
  }
}