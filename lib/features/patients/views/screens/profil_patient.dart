import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../shared/enums/user_role.dart';
import '../providers/patient_provider.dart';
import '../../../auth/views/providers/auth_provider.dart';
import '../../../../shared/enums/blood_type.dart';

class PatientProfileScreen extends ConsumerWidget {
  const PatientProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final patientAsync = ref.watch(patientProvider);

    if (authState.user?.role == UserRole.doctor) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profil Docteur')),
        body: const Center(child: Text('Profil docteur en cours de développement.')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Mon Profil Médical', 
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF0A6E8A),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: patientAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
        data: (details) {
          if (details == null) {
            return const Center(child: Text('Aucune donnée de profil trouvée.'));
          }

          final profile = details.profile;
          final patient = details.patient;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildHeader(profile),
                const SizedBox(height: 24),
                _buildSectionTitle('Informations Personnelles'),
                _buildInfoCard([
                  _buildInfoRow(Icons.email_outlined, 'Email', profile.email),
                  _buildInfoRow(Icons.phone_outlined, 'Téléphone', profile.phone),
                  _buildInfoRow(Icons.location_on_outlined, 'Adresse', profile.address),
                ]),
                const SizedBox(height: 24),
                _buildSectionTitle('Données Médicales'),
                _buildInfoCard([
                  Row(
                    children: [
                      Expanded(child: _buildMedicalStat('Genre', patient.gender == 'male' ? 'Homme' : 'Femme')),
                      Expanded(child: _buildMedicalStat('Âge', _calculateAge(patient.dateOfBirth))),
                      Expanded(child: _buildMedicalStat('Groupe', patient.bloodType?.label ?? 'N/A')),
                    ],
                  ),
                  const Divider(height: 32),
                  Row(
                    children: [
                      Expanded(child: _buildMedicalStat('Taille', '${patient.height ?? "--"} cm')),
                      Expanded(child: _buildMedicalStat('Poids', '${patient.weight ?? "--"} kg')),
                      Expanded(child: _buildMedicalStat('IMC', _calculateBMI(patient.height, patient.weight))),
                    ],
                  ),
                ]),
                const SizedBox(height: 24),
                _buildSectionTitle('Pathologies & Allergies'),
                _buildMedicalTags('Maladies Chroniques', details.diseases.map((e) => e.name).toList(), Colors.blue),
                const SizedBox(height: 12),
                _buildMedicalTags('Allergies', details.allergies.map((e) => e.name).toList(), Colors.orange),
                const SizedBox(height: 24),
                _buildSectionTitle('Contact d\'Urgence'),
                _buildInfoCard([
                  _buildInfoRow(Icons.contact_phone_outlined, 'Nom', patient.emergencyContactName),
                  _buildInfoRow(Icons.phone_callback_rounded, 'Numéro', patient.emergencyContactPhone),
                ]),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(dynamic profile) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: const Color(0xFF0A6E8A).withOpacity(0.1),
          child: Text(
            profile.firstName[0].toUpperCase(),
            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFF0A6E8A)),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '${profile.firstName} ${profile.lastName}',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        Text(
          'Patient MediLink',
          style: TextStyle(fontSize: 14, color: Colors.grey[600], letterSpacing: 1),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 1.2),
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF0A6E8A)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
      ],
    );
  }

  Widget _buildMedicalTags(String title, List<String> tags, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 12),
          if (tags.isEmpty)
            const Text('Aucune information renseignée', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags.map((tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(tag, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
              )).toList(),
            ),
        ],
      ),
    );
  }

  String _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return '$age ans';
  }

  String _calculateBMI(double? heightCm, double? weightKg) {
    if (heightCm == null || weightKg == null || heightCm == 0) return 'N/A';
    final heightM = heightCm / 100;
    final bmi = weightKg / (heightM * heightM);
    return bmi.toStringAsFixed(1);
  }
}
