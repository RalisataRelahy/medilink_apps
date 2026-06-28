import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../patients/data/models/patient_details_models.dart';
import '../../data/models/user_model.dart';
import '../../data/services/auth_service.dart';
import '../../../../shared/enums/user_role.dart';
import '../../../doctors/data/models/doctor_model.dart';
import 'auth_state.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// 1. Utilisez le nouveau NotifierProvider
final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

// 2. Changez la classe parente pour Notifier
class AuthNotifier extends Notifier<AuthState> {

  //  3. Créez une méthode build pour définir l'état initial
  @override
  AuthState build() {
    // Lance la session après la création du Notifier
    Future.microtask(() => initSession());
    return const AuthState();
  }

  // Plus besoin de stocker 'this.ref', la variable 'ref' est déjà accessible partout !
  AuthService get _service => ref.read(authServiceProvider);

  // AUTO SESSION CHECK
  Future<void> initSession() async {
    final user = _service.currentUser;

    if (user != null) {
      state = state.copyWith(isLoading: true);
      final profile = await _service.getUserProfile(user.id);

      if (profile != null) {
        state = state.copyWith(
          isLoading: false,
          user: profile,
          role: profile.role,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  // SIGN IN / LOGIN
  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final res = await _service.login(email, password);
      final user = res.user;

      if (user == null) {
        throw Exception("Échec de la connexion");
      }

      final profile = await _service.getUserProfile(user.id);

      if (profile == null) {
        throw Exception("Impossible de récupérer le profil utilisateur");
      }

      state = state.copyWith(
        isLoading: false,
        user: profile,
        role: profile.role,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // REGISTER
  Future<void> register({
    required String password,
    required UserRole role,
    PatientDetailsModel? patientData,
    DoctorModel? doctorData,
    String? email,
    required UserModel userRegister,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      print("authProvider: ignit registrer");
      final res = await _service.register(
        password: password,
        role: role,
        patientData: patientData,
        doctorData: doctorData,
        email: email,
        userRegister: userRegister,
      );
      print("FINISH Provider register-1");
      final user = res.user;

      if (user == null) {
        throw Exception("Échec de l'inscription");
      }

      final profile = await _service.getUserProfile(user.id);
      print("FINISH Provider register");
      state = state.copyWith(
        isLoading: false,
        user: profile,
        role: role,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // LOGOUT
  Future<void> logout() async {
    await _service.logout();
    state = const AuthState();
  }
}
