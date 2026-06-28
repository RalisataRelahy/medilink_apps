import 'package:flutter/material.dart';
import '../enums/user_role.dart';
import 'package:go_router/go_router.dart';
import '../navigations/nav_config.dart';

class AppBottomNav extends StatelessWidget {
  final UserRole role;
  final String currentLocation;

  const AppBottomNav({
    super.key,
    required this.role,
    required this.currentLocation,
  });

  void _onTap(BuildContext context, int i) {
    final routes = role == UserRole.doctor
        ? NavConfig.doctorTabs
        : NavConfig.patientTabs;

    context.go(routes[i]);
  }

  @override
  Widget build(BuildContext context) {
    final routes = role == UserRole.doctor
        ? NavConfig.doctorTabs
        : NavConfig.patientTabs;

    final index = routes.indexOf(currentLocation);

    final isDoctor = role == UserRole.doctor;

    return NavigationBar(
      height: 70,
      selectedIndex: index < 0 ? 0 : index,
      onDestinationSelected: (i) => _onTap(context, i),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      animationDuration: const Duration(milliseconds: 400),

      destinations: [
        NavigationDestination(
          icon: Icon(isDoctor ? Icons.medical_services_outlined : Icons.home_outlined),
          selectedIcon: Icon(isDoctor ? Icons.medical_services : Icons.home),
          label: 'Accueil',
        ),

        NavigationDestination(
          icon: const Icon(Icons.calendar_month_outlined),
          selectedIcon: const Icon(Icons.calendar_month),
          label: 'Rendez-vous',
        ),

        NavigationDestination(
          icon: const Icon(Icons.folder_outlined),
          selectedIcon: const Icon(Icons.folder),
          label: isDoctor ? 'Dossiers patients' : 'Mon dossier',
        ),

        NavigationDestination(
          icon: const Icon(Icons.person_outline),
          selectedIcon: const Icon(Icons.person),
          label: 'Profil',
        ),
      ],
    );
  }
}