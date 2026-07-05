import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/features/auth/views/providers/auth_provider.dart';
import 'package:medilink/shared/enums/user_role.dart';
import '../providers/consultation_provider.dart';
import '../../data/models/consultation_details_model.dart';

class ConsultationsScreen extends ConsumerWidget {
  const ConsultationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consultationsAsync = ref.watch(consultationsProvider);
    final userRole = ref.watch(authProvider).user?.role ?? UserRole.patient;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: AppBar(
          automaticallyImplyLeading: false,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryLight],
              ),
            ),
            // Remplacement de Center par Align + Padding
            child: const Align(
              alignment: Alignment.centerLeft, // Centrage vertical, aligné à gauche
              child: Padding(
                padding: EdgeInsets.only(left: 16.0), // Marge de sécurité à gauche
                child: Text(
                  'Historique des Consultations',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 20, // Optionnel : pour adapter à la grande taille de l'AppBar
                  ),
                ),
              ),
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      body: consultationsAsync.when(
        // NEW: short explanatory label instead of a bare spinner.
        loading: () => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text('Chargement de vos consultations…',
                  style: TextStyle(color: AppColors.textGrey, fontSize: 13)),
            ],
          ),
        ),
        // NEW: consistent error treatment (icon in tinted circle, clear
        // title/subtitle, styled retry button) instead of a raw exception.
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
                  'Impossible de charger vos consultations',
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
                  onPressed: () => ref.invalidate(consultationsProvider),
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
        data: (consultations) {
          // NEW: most recent consultation first — users expect a history
          // list to read newest-to-oldest, and nothing guaranteed that
          // ordering upstream.
          final sorted = [...consultations]..sort((a, b) {
            final dateA = a.consultation.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final dateB = b.consultation.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return dateB.compareTo(dateA);
          });

          if (sorted.isEmpty) {
            // NEW: wrapped in a scrollable + RefreshIndicator so the user
            // can still pull-to-refresh from an empty state, e.g. right
            // after their very first consultation was just created.
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async => ref.refresh(consultationsProvider.future),
              child: LayoutBuilder(
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
                              child: const Icon(Icons.history_edu_outlined,
                                  size: 40, color: AppColors.primary),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Aucune consultation trouvée',
                              style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Vos consultations passées apparaîtront ici une fois terminées.',
                              style: TextStyle(fontSize: 13, color: AppColors.textGrey),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => ref.refresh(consultationsProvider.future),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: sorted.length,
              itemBuilder: (context, index) {
                final consultation = sorted[index];
                return _buildConsultationCard(context, consultation, userRole);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildConsultationCard(BuildContext context, ConsultationDetailsModel details, UserRole userRole) {
    final consultation = details.consultation;
    final profile = details.profile;
    final date = consultation.createdAt ?? DateTime.now();
    final hasPrescription = details.prescription != null &&
        (details.medicines.isNotEmpty || details.exams.isNotEmpty); // NEW: avoid "0 médicament(s), 0 examen(s)" clutter

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // Navigation vers le détail de la consultation si nécessaire
            // context.push('/consultations/${consultation.id}');
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, // NEW: small date icon
                            size: 13, color: AppColors.textGrey.withValues(alpha: 0.7)),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('dd MMMM yyyy', 'fr_FR').format(date),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.check_circle_rounded, size: 12, color: AppColors.primary), // NEW
                          SizedBox(width: 4),
                          Text(
                            "TERMINÉ",
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.background,
                      backgroundImage: profile?.avatarUrl != null
                          ? NetworkImage(profile!.avatarUrl!)
                          : null,
                      // NEW: swallow broken/unreachable avatar URLs instead
                      // of letting an unhandled network image exception
                      // surface as a red error box in the UI.
                      onBackgroundImageError: profile?.avatarUrl != null
                          ? (_, __) {}
                          : null,
                      child: profile?.avatarUrl == null
                          ? const Icon(Icons.person, color: AppColors.textLight)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userRole == UserRole.patient
                                ? "Dr. ${profile?.fullName ?? 'Médecin'}"
                                : (profile?.fullName ?? "Patient"),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis, // NEW: guard long names
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.textDark,
                            ),
                          ),
                          Text(
                            consultation.reason,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.textGrey, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, // NEW: affordance hinting the card opens details
                        color: AppColors.textGrey.withValues(alpha: 0.4)),
                  ],
                ),
                if (hasPrescription) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.description_outlined, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "${details.medicines.length} médicament(s), ${details.exams.length} examen(s)",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}