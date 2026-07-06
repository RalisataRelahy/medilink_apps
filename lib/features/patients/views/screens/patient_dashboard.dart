import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/features/appointments/views/providers/appointment_provider.dart';
import 'package:medilink/features/auth/views/providers/auth_provider.dart';
import 'package:medilink/shared/enums/status.dart';
import 'package:medilink/features/doctors/data/models/doctor_details_model.dart';
import 'package:medilink/features/doctors/views/providers/doctor_provider.dart';
import '../providers/patient_provider.dart';


class PatientDashboardScreen extends ConsumerStatefulWidget {
  const PatientDashboardScreen({super.key});

  @override
  ConsumerState<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends ConsumerState<PatientDashboardScreen> {

  void _navigateToSearch() {
    context.push('/doctorslist');
  }

  void showNotificationPopUp({
    required BuildContext context,
    required String message,
    required String title,
    IconData icon = Icons.info_outline,
    Color backgroundColor = const Color(0xFF1E1E24),
  }) {
    // 1. Trouver l'état de l'overlay actuel
    final overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    // 2. Créer le widget de la notification
    overlayEntry = OverlayEntry(
      builder: (context) =>
          Positioned(
            top: MediaQuery
                .of(context)
                .padding
                .top + 10, // Juste en dessous de la barre de statut
            left: 16,
            right: 16,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(icon, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            message,
                            style: const TextStyle(color: Colors.white70,
                                fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                          Icons.close, color: Colors.white60, size: 18),
                      onPressed: () =>
                          overlayEntry
                              .remove(), // Permet de fermer manuellement
                    ),
                  ],
                ),
              ),
            ),
          ),
    );

    // 3. Insérer dans l'écran
    overlayState.insert(overlayEntry);

    // 4. Supprimer automatiquement après 3 secondes
    Future.delayed(const Duration(seconds: 3), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final patientAsync = ref.watch(patientProvider);
    final appointmentsAsync = ref.watch(appointmentsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(patientAsync),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchBar(),
                  const SizedBox(height: 28),
                  _buildQuickActions(),
                  const SizedBox(height: 32),
                  _buildSectionHeader("Prochains rendez-vous", () => context.push('/appointments')),
                  const SizedBox(height: 16),
                  _buildUpcomingAppointment(appointmentsAsync),
                  const SizedBox(height: 32),
                  _buildSectionHeader("Spécialités populaires", () {}),
                  const SizedBox(height: 16),
                  _buildSpecialtiesGrid(),
                  const SizedBox(height: 32),
                  _buildSectionHeader("Médecins recommandés", () =>
                      context.push('/doctorslist/q=''')),
                  const SizedBox(height: 16),
                  _buildRecommendedDoctors(ref),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(AsyncValue patientAsync) {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.headerBlueDark, AppColors.headerBlueLight],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              patientAsync.when(
                data: (details) => Text(
                  "Bonjour, ${details?.profile.firstName ?? 'Patient'}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                loading: () => const SizedBox(height: 28, width: 150, child: LinearProgressIndicator(color: Colors.white30)),
                error: (_, __) => const Text("Bienvenue", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 4),
              Text(
                "Comment vous sentez-vous aujourd'hui ?",
                style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            showNotificationPopUp(
              context: context,
              title: "Rendez-vous validé",
              message: "Votre demande a été transmise au Dr. Dupont.",
              icon: Icons.check_circle_outline,
              backgroundColor: Colors.green.shade800,
            );
          },
          icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: () => _navigateToSearch(),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: "Rechercher un médecin, une spécialité...",
            hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 14),
            prefixIcon: const Icon(
                Icons.search_rounded, color: AppColors.primary),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 16),
          ),
          enabled: false,
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _quickActionItem(
          icon: Icons.calendar_today_rounded,
          label: "Prendre RDV",
          color: const Color(0xFF6366F1),
          onTap: () => context.push('/doctorslist'),
        ),
        SizedBox(width: 30),
        _quickActionItem(
          icon: Icons.folder_shared_rounded,
          label: "Mon Dossier",
          color: const Color(0xFF10B981),
          onTap: () => context.push('/dossierMedicale'),
        ),
      ],
    );
  }

  Widget _quickActionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onSeeAll) {
    double screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    double screenHeight = MediaQuery
        .of(context)
        .size
        .height;
    bool isSmallScreen = screenWidth < 400;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark),
        ),
        TextButton(
          onPressed: onSeeAll,
          child: const Icon(Icons.arrow_forward_outlined, color: AppColors.primary, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildUpcomingAppointment(AsyncValue appointmentsAsync) {
    return appointmentsAsync.when(
      data: (appointments) {
        final upcoming = appointments.where((a) =>
            a.status == Status.pending ||
            a.status == Status.confirmed ||
            a.status == Status.progress
        ).toList();

        if (upcoming.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.inactiveStep.withOpacity(0.5)),
            ),
            child: Column(
              children: [
                Icon(Icons.calendar_today_outlined, color: AppColors.textGrey.withOpacity(0.4), size: 32),
                const SizedBox(height: 12),
                const Text(
                  "Aucun rendez-vous à venir",
                  style: TextStyle(color: AppColors.textGrey, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          );
        }

        final next = upcoming.first;
        final profile = next.profile;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white24,
                    backgroundImage: profile?.avatarUrl != null ? NetworkImage(profile!.avatarUrl!) : null,
                    child: profile?.avatarUrl == null ? const Icon(Icons.person, color: Colors.white) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Dr. ${profile?.lastName ?? 'Médecin'}",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          next.localization,
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  if (next.status == Status.confirmed)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.videocam_rounded, color: Colors.white, size: 20),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      "${DateFormat('dd MMMM', 'fr_FR').format(next.date)}, ${next.heure.substring(0, 5)}",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        next.status.labelFr.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (err, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildSpecialtiesGrid() {
    final specialties = [
      {"icon": Icons.favorite_rounded, "name": "Cardio", "color": Colors.red},
      {"icon": Icons.visibility_rounded, "name": "Ophtalmo", "color": Colors.blue},
      {"icon": Icons.child_care_rounded, "name": "Pédiatrie", "color": Colors.orange},
      {"icon": Icons.psychology_rounded, "name": "Neuro", "color": Colors.purple},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: specialties.map((s) => _specialtyItem(s)).toList(),
    );
  }

  Widget _specialtyItem(Map<String, dynamic> specialty) {
    return Container(
      width: 75,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inactiveStep.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Icon(specialty["icon"] as IconData, color: specialty["color"] as Color, size: 28),
          const SizedBox(height: 8),
          Text(
            specialty["name"] as String,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedDoctors(WidgetRef ref) {
    final doctorsAsync = ref.watch(allDoctorsProvider);

    return doctorsAsync.when(
      data: (doctors) {
        if (doctors.isEmpty) {
          return const Center(child: Text("Aucun médecin disponible"));
        }
        // Take top 3 for dashboard
        final recommended = doctors.take(3).toList();
        return Column(
          children: recommended.map((d) => _doctorCard(d)).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => const SizedBox.shrink(),
    );
  }

  Widget _doctorCard(DoctorDetailsModel doctor) {
    final profile = doctor.profile;
    final spec = doctor.specialities.isNotEmpty
        ? doctor.specialities.first.name
        : 'Médecin';

    return GestureDetector(
      onTap: () => context.push('/doctors/${profile.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Hero(
              tag: 'doctor_avatar_${profile.id}',
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  image: profile.avatarUrl != null
                      ? DecorationImage(image: NetworkImage(profile.avatarUrl!),
                      fit: BoxFit.cover)
                      : null,
                ),
                child: profile.avatarUrl == null
                    ? const Icon(
                    Icons.person, color: AppColors.textLight, size: 40)
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Dr. ${profile.fullName}",
                    style: const TextStyle(fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.textDark),
                  ),
                  Text(
                    "$spec • ${doctor.doctor.yearsOfExperience} ans exp.",
                    style: const TextStyle(
                        color: AppColors.textGrey, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                          Icons.star_rounded, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(doctor.doctor.rating.toStringAsFixed(1),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(width: 12),
                      Icon(Icons.location_on_rounded,
                          color: Colors.red.withOpacity(0.6), size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          profile.address,
                          style: const TextStyle(color: AppColors.textGrey,
                              fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
