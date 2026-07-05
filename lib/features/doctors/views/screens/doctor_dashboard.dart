import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medilink/core/theme/app_colors.dart';
import '../providers/doctor_provider.dart';

class DoctorDashboardScreen extends ConsumerStatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  ConsumerState<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends ConsumerState<DoctorDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final doctorAsync = ref.watch(doctorDetailsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(doctorAsync),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsGrid(),
                  const SizedBox(height: 32),
                  _buildSectionHeader("Aujourd'hui", () => context.push('/appointments')),
                  const SizedBox(height: 16),
                  _buildTodaySchedule(),
                  const SizedBox(height: 32),
                  _buildSectionHeader("Actions rapides", () {}),
                  const SizedBox(height: 16),
                  _buildQuickActions(),
                  const SizedBox(height: 32),
                  _buildSectionHeader("Nouveaux patients", () => context.push('/patients')),
                  const SizedBox(height: 16),
                  _buildRecentPatients(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(AsyncValue doctorAsync) {
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    final isSmallScreen = screenWidth < 400;

    return SliverAppBar(
      expandedHeight: 150,
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
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 25),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              doctorAsync.when(
                data: (details) => Text(
                  "Dr. ${details?.profile.lastName ?? 'Médecin'}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                loading: () => const SizedBox(height: 30, width: 180, child: LinearProgressIndicator(color: Colors.white30)),
                error: (_, __) => const Text("Tableau de bord", style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "En ligne",
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Vous avez 8 consultations aujourd'hui",
                    style: TextStyle(color: Colors.white.withOpacity(0.9),
                        fontSize: isSmallScreen ? 10 : 13),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        _statCard("RDV du jour", "8", Icons.calendar_today_rounded, Colors.blue),
        const SizedBox(width: 16),
        _statCard("Patients", "124", Icons.people_alt_rounded, Colors.orange),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.textGrey, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onSeeAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        TextButton(
          onPressed: onSeeAll,
          child: const Text("Voir tout", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildTodaySchedule() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15)],
      ),
      child: Column(
        children: [
          _appointmentItem("10:30", "Jean Dupont", "Consultation générale", true),
          const Divider(height: 1, indent: 70),
          _appointmentItem("11:15", "Marie Curie", "Suivi post-op", false),
          const Divider(height: 1, indent: 70),
          _appointmentItem("14:00", "Paul Belmondo", "Première visite", false),
        ],
      ),
    );
  }

  Widget _appointmentItem(String time, String name, String type, bool isActive) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Text(
            time,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isActive ? AppColors.primary : AppColors.textGrey,
              fontSize: 15,
            ),
          ),
          const SizedBox(width: 20),
          Container(
            width: 2,
            height: 30,
            color: isActive ? AppColors.primary : AppColors.inactiveStep,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                ),
                Text(
                  type,
                  style: const TextStyle(color: AppColors.textGrey, fontSize: 13),
                ),
              ],
            ),
          ),
          if (isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                "En cours",
                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _actionItem("Ordonnance", Icons.description_rounded, Colors.teal),
        _actionItem("Consultation", Icons.add_box_rounded, Colors.blue),
        _actionItem("Planning", Icons.schedule_rounded, Colors.orange),
      ],
    );
  }

  Widget _actionItem(String label, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color, size: 26),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textDark),
        ),
      ],
    );
  }

  Widget _buildRecentPatients() {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          return Column(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 29,
                  backgroundImage: NetworkImage(
                    'https://i.pravatar.cc/150?u=$index',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text("Patient ${index + 1}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          );
        },
      ),
    );
  }
}
