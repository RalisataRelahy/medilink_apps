import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/shared/enums/user_role.dart';
import '../../../auth/views/providers/auth_provider.dart';
import '../../../../shared/enums/status.dart';
import '../providers/appointment_provider.dart';
import '../widgets/build_appointment_list.dart';

class AppointmentsScreen extends ConsumerWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(appointmentsProvider);
    final userRole = ref.watch(authProvider).user?.role ?? UserRole.patient;

    // NEW: compute tab counts from whatever data is currently available (or
    // 0 while loading/erroring) so the tab labels can show live badges.
    final appointments = appointmentsAsync.mapOrNull() ?? const [];
    final activeCount = appointments.where((a) =>
    a.status == Status.pending ||
        a.status == Status.confirmed ||
        a.status == Status.progress
    ).length;
    final pastCount = appointments.where((a) =>
    a.status == Status.finished ||
        a.status == Status.canceled
    ).length;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          // NEW: subtle gradient instead of a flat fill, matching the rest
          // of the app's header treatment.
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryLight],
              ),
            ),
          ),
          title: const Text(
            'Mes Rendez-vous',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(52),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Container(
                // NEW: pill-shaped container behind the tabs, closer to a
                // Material 3 segmented control than a bare underline.
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TabBar(
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding: const EdgeInsets.all(4),
                  dividerColor: Colors.transparent, // NEW: removes default divider line
                  splashBorderRadius: BorderRadius.circular(12),
                  labelColor: AppColors.primary,
                  unselectedLabelColor: Colors.white,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                  tabs: [
                    _buildTab(Icons.upcoming_rounded, 'À venir', activeCount),
                    _buildTab(Icons.history_rounded, 'Historique', pastCount),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: appointmentsAsync.when(
          // NEW: loading state with a short explanatory label instead of a
          // bare spinner floating in empty space.
          loading: () => const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                SizedBox(height: 16),
                Text('Chargement de vos rendez-vous…',
                    style: TextStyle(color: AppColors.textGrey, fontSize: 13)),
              ],
            ),
          ),
          // NEW: consistent error treatment (icon in a tinted circle, clear
          // title/subtitle, styled retry button) instead of a raw message.
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.cloud_off_rounded, size: 40, color: AppColors.error),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Impossible de charger vos rendez-vous',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Vérifiez votre connexion internet, puis réessayez.',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => ref.invalidate(appointmentsProvider),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Réessayer'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          data: (appointments) {
            final active = appointments.where((a) =>
            a.status == Status.pending ||
                a.status == Status.confirmed ||
                a.status == Status.progress
            ).toList();

            final past = appointments.where((a) =>
            a.status == Status.finished ||
                a.status == Status.canceled
            ).toList();

            return TabBarView(
              children: [
                RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async => ref.refresh(appointmentsProvider.future),
                  child: active.isEmpty
                  // NEW: friendly empty state per tab instead of an
                  // ambiguous blank screen (still scrollable so
                  // pull-to-refresh keeps working when the list is empty).
                      ? _buildEmptyState(
                    icon: Icons.add_alarm_rounded,
                    callback: () => context.push('/addappointment'),
                    title: 'Aucun rendez-vous à venir',
                    subtitle: 'Vos prochains rendez-vous apparaîtront ici.',
                  )
                      : buildAppointmentList(active, userRole),
                ),
                RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async => ref.refresh(appointmentsProvider.future),
                  child: past.isEmpty
                      ? _buildEmptyState(
                    icon: Icons.history_toggle_off_rounded,
                    title: 'Aucun historique',
                    subtitle: 'Vos rendez-vous passés ou annulés apparaîtront ici.',
                  )
                      : buildAppointmentList(past, userRole),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // NEW: tab with icon + label + live count badge.
  Widget _buildTab(IconData icon, String label, int count) {
    return Tab(
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // NEW: reusable empty-state, wrapped in a scrollable so RefreshIndicator
  // still works when there's nothing to show.
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    VoidCallback? callback,
    required String subtitle,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(onPressed: callback,
                        icon: Icon(icon),
                        iconSize: 40,
                        color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 13, color: AppColors.textGrey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}