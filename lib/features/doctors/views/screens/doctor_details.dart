import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medilink/core/theme/app_colors.dart';
import '../providers/doctor_provider.dart';
import '../../data/models/doctor_details_model.dart';

class DoctorDetailsScreen extends ConsumerWidget {
  final String doctorId;

  const DoctorDetailsScreen({super.key, required this.doctorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doctorAsync = ref.watch(doctorByIdProvider(doctorId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: doctorAsync.when(
        data: (doctor) {
          if (doctor == null) {
            return const Center(child: Text("Médecin introuvable"));
          }
          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  _buildAppBar(context, doctor),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildQuickStats(doctor),
                          const SizedBox(height: 32),
                          _buildSectionTitle("À propos"),
                          const SizedBox(height: 12),
                          Text(
                            doctor.doctor.bio,
                            style: const TextStyle(
                              color: AppColors.textGrey,
                              fontSize: 15,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 32),
                          _buildSectionTitle("Spécialités"),
                          const SizedBox(height: 12),
                          _buildTagCloud(
                            doctor.specialities.map((e) => e.name).toList(),
                            AppColors.primary,
                          ),
                          const SizedBox(height: 32),
                          _buildSectionTitle("Diplômes et Formations"),
                          const SizedBox(height: 12),
                          _buildTagCloud(
                            doctor.diplomas.map((e) => e.name).toList(),
                            AppColors.headerBlueLight,
                          ),
                          const SizedBox(height: 32),
                          _buildSectionTitle("Langues parlées"),
                          const SizedBox(height: 12),
                          _buildTagCloud(
                            doctor.languages.map((e) => e.name).toList(),
                            Colors.blue.shade700,
                          ),
                          const SizedBox(height: 32),
                          _buildSectionTitle("Lieu de consultation"),
                          const SizedBox(height: 12),
                          _buildLocationCard(doctor),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              _buildBottomAction(context),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, _) => Center(child: Text("Erreur: $err")),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, DoctorDetailsModel doctor) {
    return SliverAppBar(
      expandedHeight: 340,
      pinned: true,
      backgroundColor: AppColors.primary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Header Image/Gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.headerBlueDark, AppColors.headerBlueLight],
                ),
              ),
            ),
            // Doctor Info overlay
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Hero(
                  tag: 'doctor_avatar_${doctor.profile.id}',
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white,
                      backgroundImage: doctor.profile.avatarUrl != null
                          ? NetworkImage(doctor.profile.avatarUrl!)
                          : null,
                      child: doctor.profile.avatarUrl == null
                          ? const Icon(
                              Icons.person,
                              size: 70,
                              color: AppColors.textLight,
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Dr. ${doctor.profile.fullName}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  doctor.specialities.isNotEmpty
                      ? doctor.specialities.first.name
                      : "Médecin",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.verified_rounded,
                        color: AppColors.accent,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Licence: ${doctor.doctor.licenseNumber}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(DoctorDetailsModel doctor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statItem(
            Icons.star_rounded,
            doctor.doctor.rating.toStringAsFixed(1),
            "Note",
            Colors.amber,
          ),
          _statItem(
            Icons.history_rounded,
            "${doctor.doctor.yearsOfExperience} ans",
            "Expérience",
            Colors.blue,
          ),
          _statItem(Icons.people_alt_rounded, "500+", "Patients", Colors.green),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
      ),
    );
  }

  Widget _buildTagCloud(List<String> tags, Color color) {
    if (tags.isEmpty)
      return const Text(
        "Non renseigné",
        style: TextStyle(
          fontStyle: FontStyle.italic,
          color: AppColors.textGrey,
        ),
      );
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags
          .map(
            (tag) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Text(
                tag,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildLocationCard(DoctorDetailsModel doctor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.inactiveStep.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctor.doctor.clinicName ?? "Cabinet Médical",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  doctor.profile.address,
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () {
            // Logique pour prendre RDV
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: const Text(
            "Prendre un rendez-vous",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
