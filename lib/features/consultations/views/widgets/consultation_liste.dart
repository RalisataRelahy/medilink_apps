import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:medilink/features/consultations/views/providers/consultation_provider.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/guard/role_guard.dart';
import '../../../../shared/enums/user_role.dart';
import '../../../auth/views/providers/auth_provider.dart';

class ConsultationHistoryScreen extends ConsumerWidget {
  const ConsultationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    // 1. Gestion du chargement de l'authentification
    if (authState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 2. Gestion des erreurs d'authentification
    if (authState.error != null) {
      return Scaffold(body: Center(child: Text('Erreur : ${authState.error}')));
    }

    final user = authState.user;
    if (user == null) {
      return const Scaffold(body: Center(child: Text("Utilisateur non connecté")));
    }

    // 3. Vérification des droits d'accès
    final canAccess = RoleGuard.canAccess(AppRoutes.consultations, user.role);
    if (!canAccess) {
      return const Scaffold(body: Center(child: Text("Accès refusé")));
    }

    // 4. Choix du provider de données selon le rôle
    final historyAsync = user.role == UserRole.doctor
        ? ref.watch(pastConsultationsProviderFromDoctor)
        : ref.watch(pastConsultationsProviderFromPatient);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique médical'),
        centerTitle: true,
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, __) => Center(child: Text('Erreur lors du chargement : $err')),
        data: (consultations) {
          if (consultations.isEmpty) {
            return const Center(child: Text('Aucune consultation trouvée.'));
          }

          return ListView.builder(
            itemCount: consultations.length,
            padding: const EdgeInsets.all(8),
            itemBuilder: (context, index) {
              final item = consultations[index];
              final date = item.consultation.createdAt != null
                  ? DateFormat('dd/MM/yyyy HH:mm').format(item.consultation.createdAt!)
                  : 'Date inconnue';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.medical_information),
                  ),
                  title: Text(
                    item.consultation.reason,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Le $date - Statut: ${item.consultation.status.labelFr}'),
                  children: [
                    if (item.medicines.isEmpty && item.exams.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('Aucune prescription pour cette consultation.'),
                      ),

                    if (item.medicines.isNotEmpty) ...[
                      const Divider(),
                      const ListTile(
                        dense: true,
                        title: Text('MÉDICAMENTS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue)),
                      ),
                      ...item.medicines.map((medDetails) => ListTile(
                        leading: const Icon(Icons.medication, color: Colors.green),
                        title: Text(medDetails.medicine?.name ?? 'Médicament inconnu'),
                        subtitle: Text(
                            '${medDetails.prescriptionMedicine.frequency} pendant ${medDetails.prescriptionMedicine.duration} ${medDetails.prescriptionMedicine.typeOfDuration.labelFr}'),
                      )),
                    ],

                    if (item.exams.isNotEmpty) ...[
                      const Divider(),
                      const ListTile(
                        dense: true,
                        title: Text('EXAMENS À FAIRE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.orange)),
                      ),
                      ...item.exams.map((examDetails) => ListTile(
                        leading: const Icon(Icons.science, color: Colors.deepPurple),
                        title: Text(examDetails.exam?.examenName ?? 'Examen inconnu'),
                        subtitle: Text(examDetails.exam?.category ?? ''),
                      )),
                    ],

                    if (item.prescription?.note != null) ...[
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Note du médecin :', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(item.prescription!.note!),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}