import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medilink/features/auth/data/models/user_model.dart';
import 'package:medilink/features/patients/views/screens/profil_patient.dart';
import 'package:medilink/features/patients/views/screens/register_screen_patient.dart';
import '../../features/auth/views/providers/auth_provider.dart';
import '../../shared/enums/user_role.dart';
import '../../shared/layout/main_layout.dart';
import '../../features/auth/views/screens/login_screen.dart';
import '../../features/auth/views/screens/register_screen.dart';

class AppRoutes {
  static const login = '/login';
  static const register = '/register';
  static const registerPatient = '/registerPatient';
  static const home = '/home';
  static const dossierMedicale='/dossierMedicale';
  static const dashboard = '/dashboard';
  static const patients = '/patients';
  static const patientDetails = '/patients/:id';
  static const doctors = '/doctors';
  static const doctorDetails = '/doctors/:id';
  static const appointments = '/appointments';
  static const appointmentDetails = '/appointments/:id';
  static const consultations = '/consultations';
  static const consultationDetails = '/consultations/:id';
  static const profile = '/profile';
}

// ✅ Un ValueNotifier pour dire au routeur quand se recharger
class RouterRefreshNotifier extends ChangeNotifier {
  RouterRefreshNotifier(Ref ref) {
    ref.listen(authProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  // On utilise read au lieu de watch pour ne pas détruire le routeur
  final notifier = RouterRefreshNotifier(ref);

  return GoRouter(
    initialLocation: AppRoutes.home,
    //  On donne le notifier à GoRouter pour écouter les changements
    refreshListenable: notifier,
    redirect: (context, state) {
      //  On lit l'état actuel pour prendre les décisions de redirection
      final authState = ref.read(authProvider);

      if (authState.isLoading) return null;

      final location = state.matchedLocation;
      final user = authState.user;
      final isAuthRoute = location == AppRoutes.login || location == AppRoutes.register||location==AppRoutes.registerPatient;

      // 1. Non connecté
      if (user == null) {
        return isAuthRoute ? null : AppRoutes.login;
      }

      // 2. Connecté mais sur Login/Register
      if (isAuthRoute) {
        return user.role == UserRole.doctor ? AppRoutes.dashboard : AppRoutes.home;
      }

      // 3. Sécurité des rôles
      if (user.role == UserRole.patient) {
        final isDoctorPage = location == AppRoutes.dashboard ||
            location == AppRoutes.patients ||
            location == AppRoutes.patientDetails ||
            location == AppRoutes.consultations;

        if (isDoctorPage) return AppRoutes.patients;
      }

      if (user.role == UserRole.doctor && location == AppRoutes.home) {
        return AppRoutes.dashboard;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.registerPatient,
        builder: (context, state) {

          final data = state.extra as Map<String, dynamic>;

          final user = UserModel.fromJson(data['user'],);
          final password = data['password'] as String;

          return RegisterPage(
            user: user,
            password: password,
          );
        },
      ),
      ShellRoute(
        builder: (context, state, child) => MainLayout(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (_, __) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (_, __) => const DoctorDashboard(),
          ),
          GoRoute(
            path: AppRoutes.patients,
            builder: (_, __) => const PatientsScreen(),
          ),
          GoRoute(
            path: AppRoutes.patientDetails,
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return PatientDetailsScreen(patientId: id);
            },
          ),
          GoRoute(
            path: AppRoutes.doctors,
            builder: (_, __) => const DoctorsScreen(),
          ),
          GoRoute(
            path: AppRoutes.doctorDetails,
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return DoctorDetailsScreen(doctorId: id);
            },
          ),
          GoRoute(
            path: AppRoutes.appointments,
            builder: (_, __) => const AppointmentsScreen(),
          ),
          GoRoute(
            path: AppRoutes.dossierMedicale,
            builder: (_, __) => const DossierScreen(),
          ),
          GoRoute(
            path: AppRoutes.appointmentDetails,
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return AppointmentDetailsScreen(appointmentId: id);
            },
          ),
          GoRoute(
            path: AppRoutes.consultations,
            builder: (_, __) => const ConsultationsScreen(),
          ),
          GoRoute(
            path: AppRoutes.consultationDetails,
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return ConsultationDetailsScreen(consultationId: id);
            },
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (_, __) => const PatientProfileScreen(),
          ),
        ],
      ),
    ],
  );
});

// Placeholders (à déplacer dans des fichiers séparés plus tard)
class HomeScreen extends StatelessWidget { const HomeScreen({super.key}); @override Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Home'))); }
class PatientsScreen extends StatelessWidget { const PatientsScreen({super.key}); @override Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Patients'))); }
class PatientDetailsScreen extends StatelessWidget { final String patientId; const PatientDetailsScreen({super.key, required this.patientId}); @override Widget build(BuildContext context) => Scaffold(body: Center(child: Text('Patient $patientId'))); }
class DoctorsScreen extends StatelessWidget { const DoctorsScreen({super.key}); @override Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Doctors'))); }
class DoctorDetailsScreen extends StatelessWidget { final String doctorId; const DoctorDetailsScreen({super.key, required this.doctorId}); @override Widget build(BuildContext context) => Scaffold(body: Center(child: Text('Doctor $doctorId'))); }
class AppointmentsScreen extends StatelessWidget { const AppointmentsScreen({super.key}); @override Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Appointments'))); }
class AppointmentDetailsScreen extends StatelessWidget { final String appointmentId; const AppointmentDetailsScreen({super.key, required this.appointmentId}); @override Widget build(BuildContext context) => Scaffold(body: Center(child: Text('Appointment $appointmentId'))); }
class ConsultationsScreen extends StatelessWidget { const ConsultationsScreen({super.key}); @override Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Consultations'))); }
class ConsultationDetailsScreen extends StatelessWidget { final String consultationId; const ConsultationDetailsScreen({super.key, required this.consultationId}); @override Widget build(BuildContext context) => Scaffold(body: Center(child: Text('Consultation $consultationId'))); }
class DoctorDashboard extends StatelessWidget { const DoctorDashboard({super.key}); @override Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Doctor Dashboard'))); }
class DossierScreen extends StatelessWidget {const DossierScreen({super.key});@override Widget build(BuildContext context) {    return Center(child: Text("Dossier"),);  }}