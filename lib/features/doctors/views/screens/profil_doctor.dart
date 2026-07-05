import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/features/auth/views/providers/auth_provider.dart';
import '../providers/doctor_provider.dart';
import '../../data/models/doctor_details_model.dart';

class DoctorProfileScreen extends ConsumerWidget {
  const DoctorProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(doctorDetailsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: detailsAsync.when(
        data: (details) {
          if (details == null) {
            return const Center(child: Text("Impossible de charger le profil"));
          }
          return CustomScrollView(
            slivers: [
              _buildAppBar(details),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildQuickStats(details),
                      const SizedBox(height: 24),
                      _buildSectionTitle("Bio Professionnelle"),
                      const SizedBox(height: 8),
                      _buildBioCard(details.doctor.bio),
                      const SizedBox(height: 24),
                      _buildSectionTitle("Spécialités"),
                      const SizedBox(height: 12),
                      _buildTagCloud(details.specialities.map((e) => e.name).toList(), AppColors.primary),
                      const SizedBox(height: 24),
                      _buildSectionTitle("Diplômes & Certifications"),
                      const SizedBox(height: 12),
                      _buildTagCloud(details.diplomas.map((e) => e.name).toList(), AppColors.headerBlueLight),
                      const SizedBox(height: 24),
                      _buildSectionTitle("Langues parlées"),
                      const SizedBox(height: 12),
                      _buildTagCloud(details.languages.map((e) => e.name).toList(), Colors.blue.shade700),
                      const SizedBox(height: 24),
                      _buildSectionTitle("Informations de contact"),
                      const SizedBox(height: 12),
                      _buildContactInfo(details),
                      const SizedBox(height: 40),
                      _buildLogoutButton(ref),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, stack) => Center(child: Text("Erreur: $err")),
      ),
    );
  }

  Widget _buildAppBar(DoctorDetailsModel details) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.headerBlueDark, AppColors.headerBlueLight],
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: details.profile.avatarUrl != null
                      ? ClipOval(child: Image.network(details.profile.avatarUrl!, fit: BoxFit.cover, width: 95, height: 95))
                      : const Icon(Icons.person, size: 60, color: AppColors.primary),
                ),
                const SizedBox(height: 12),
                Text(
                  "Dr. ${details.profile.fullName}",
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Text(
                  details.specialities.isNotEmpty ? details.specialities.first.name : "Médecin",
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 16),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Licence: ${details.doctor.licenseNumber}",
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(DoctorDetailsModel details) {
    return Row(
      children: [
        _statItem(Icons.star, details.doctor.rating.toString(), "Note"),
        _statItem(Icons.history, "${details.doctor.yearsOfExperience} ans", "Exp."),
        _statItem(Icons.business, details.doctor.clinicName ?? "N/A", "Clinique"),
      ],
    );
  }

  Widget _statItem(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark)),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
    );
  }

  Widget _buildBioCard(String bio) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        bio,
        style: const TextStyle(color: AppColors.textGrey, height: 1.5, fontSize: 14.5),
      ),
    );
  }

  Widget _buildTagCloud(List<String> tags, Color color) {
    if (tags.isEmpty) return const Text("Non renseigné", style: TextStyle(fontStyle: FontStyle.italic, color: AppColors.textGrey));
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags.map((tag) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(tag, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
      )).toList(),
    );
  }

  Widget _buildContactInfo(DoctorDetailsModel details) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _contactItem(Icons.email_outlined, details.profile.email),
          const Divider(height: 24),
          _contactItem(Icons.phone_outlined, details.profile.phone),
          const Divider(height: 24),
          _contactItem(Icons.location_on_outlined, details.profile.address),
        ],
      ),
    );
  }

  Widget _contactItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14.5, color: AppColors.textDark))),
      ],
    );
  }

  Widget _buildLogoutButton(WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => ref.read(authProvider.notifier).logout(),
        icon: const Icon(Icons.logout),
        label: const Text("Se déconnecter"),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
