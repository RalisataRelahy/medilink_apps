import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/enums/status.dart';
import '../providers/appointment_provider.dart';
import '../widgets/build_appointment_list.dart';

class AppointmentsScreen extends ConsumerWidget {
  const AppointmentsScreen({super.key});



  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(doctorAppointmentsProvider);

    return DefaultTabController(
      length: 2, // 2 onglets : À venir / Historique
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mes Rendez-vous'),
          backgroundColor: Colors.teal,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'À traiter', icon: Icon(Icons.calendar_today)),
              Tab(text: 'Historique', icon: Icon(Icons.history)),
            ],
          ),
        ),
        body: appointmentsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, __) => Center(child: Text('Erreur : $err')),
          data: (appointments) {
            if (appointments.isEmpty) {
              return const Center(child: Text('Aucun rendez-vous planifié.'));
            }

            // Filtrage des rendez-vous selon le statut pour alimenter les deux onglets
            final activeAppointments = appointments.where((a) =>
            a.status == Status.pending ||
                a.status == Status.confirmed ||
                a.status == Status.progress
            ).toList();

            final pastAppointments = appointments.where((a) =>
            a.status == Status.finished ||
                a.status == Status.canceled
            ).toList();

            return TabBarView(
              children: [
                // ONGLET 1 : Liste active
                buildAppointmentList(activeAppointments),
                // ONGLET 2 : Liste passée
                buildAppointmentList(pastAppointments),
              ],
            );
          },
        ),
      ),
    );
  }

  // Widget générique pour construire une liste sous forme de cartes graphiques (Cards)

}
