import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medilink/features/doctors/views/screens/profil_doctor.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/enums/user_role.dart';
import '../providers/patient_provider.dart';
import '../../../auth/views/providers/auth_provider.dart';

class PatientProfileScreen extends ConsumerWidget {
  const PatientProfileScreen({super.key});

  // ── NEW: confirmation dialog before logging out ───────────────────────────
  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.logout_rounded, color: AppColors.error),
          SizedBox(width: 10),
          Text('Se déconnecter ?'),
        ]),
        content: const Text(
          'Vous devrez vous reconnecter pour accéder à votre dossier médical.',
          style: TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      // ignore: use_build_context_synchronously
      ref.read(authProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final patientAsync = ref.watch(patientProvider);

    if (authState.user?.role == UserRole.doctor) {
      return DoctorProfileScreen();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: patientAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        // NEW: friendlier error state with an icon + retry button instead of
        // a raw exception dump.
        error: (err, stack) => Center(
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
                  child: const Icon(Icons.cloud_off_rounded,
                      size: 40, color: AppColors.error),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Impossible de charger votre profil',
                  style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
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
                  onPressed: () => ref.invalidate(patientProvider),
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
        data: (details) {
          // NEW: friendlier empty state (also actionable)
          if (details == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.folder_off_outlined,
                        size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    const Text(
                      'Aucune donnée de profil trouvée',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: () => ref.invalidate(patientProvider),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Actualiser'),
                    ),
                  ],
                ),
              ),
            );
          }

          final profile = details.profile;
          final patient = details.patient;

          // NEW: pull-to-refresh so the patient can manually sync their data
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => ref.invalidate(patientProvider),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(), // NEW: works even if content is short
              padding: const EdgeInsets.all(16),
              child: Stack(
                children: [
                  Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(profile),
                    const SizedBox(height: 28),
                    _buildSectionTitle('Informations Personnelles', Icons.badge_outlined),
                    _buildInfoCard([
                      _buildInfoRow(Icons.email_outlined, 'Email', _fallback(profile.email)),
                      _buildInfoRow(Icons.phone_outlined, 'Téléphone', _fallback(profile.phone)),
                      _buildInfoRow(Icons.location_on_outlined, 'Adresse', _fallback(profile.address),
                          isLast: true),
                    ]),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Données Médicales', Icons.favorite_border_rounded),
                    _buildInfoCard([
                      Row(
                        children: [
                          Expanded(child: _buildMedicalStat(
                            Icons.wc_rounded, 'Genre', _genderLabel(patient.gender),
                          )),
                          Expanded(child: _buildMedicalStat(
                            Icons.cake_outlined, 'Âge', _calculateAge(patient.dateOfBirth),
                          )),
                          Expanded(child: _buildMedicalStat(
                            Icons.bloodtype_outlined, 'Groupe',
                            patient.bloodType?.label ?? 'N/A',
                            valueColor: patient.bloodType != null ? AppColors.error : null,
                          )),
                        ],
                      ),
                      const Divider(height: 32),
                      Row(
                        children: [
                          Expanded(child: _buildMedicalStat(
                            Icons.height_rounded, 'Taille',
                            patient.height != null ? '${patient.height} cm' : '--',
                          )),
                          Expanded(child: _buildMedicalStat(
                            Icons.monitor_weight_outlined, 'Poids',
                            patient.weight != null ? '${patient.weight} kg' : '--',
                          )),
                          Expanded(child: _buildBMIStat(patient.height, patient.weight)),
                        ],
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Pathologies & Allergies', Icons.medical_information_outlined),
                    _buildMedicalTags(
                      'Maladies Chroniques',
                      Icons.vaccines_outlined,
                      details.diseases.map((e) => e.name).toList(),
                      const Color(0xFF1A6FD6),
                    ),
                    const SizedBox(height: 12),
                    _buildMedicalTags(
                      'Allergies',
                      Icons.warning_amber_rounded,
                      details.allergies.map((e) => e.name).toList(),
                      const Color(0xFFB84000),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Contact d\'Urgence', Icons.emergency_share_rounded),
                    _buildInfoCard([
                      _buildInfoRow(Icons.contact_phone_outlined, 'Nom',
                          _fallback(patient.emergencyContactName)),
                      _buildInfoRow(Icons.phone_callback_rounded, 'Numéro',
                          _fallback(patient.emergencyContactPhone), isLast: true),
                    ]),
                    const SizedBox(height: 40),
                  ],
                ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      // Retirez la propriété 'color' directe si vous utilisez 'decoration'
                      decoration: const BoxDecoration(
                        color: AppColors.background,
                        shape: BoxShape.circle, // Rend le container parfaitement rond
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2), // Ajoute un léger effet flottant
                          ),
                        ],
                      ),
                      child: IconButton(
                        tooltip: 'Se déconnecter',
                        icon: const Icon(Icons.logout_rounded, color: AppColors.primary),
                        onPressed: () => _confirmLogout(context, ref),
                      ),
                    ),
                  ),
                ]
              ),
            ),
          );
        },
      ),
    );
  }

  // ── NEW: small helper so a null/empty field never crashes or shows "null"
  String _fallback(String? value) {
    if (value == null || value.trim().isEmpty) return 'Non renseigné';
    return value;
  }

  // ── NEW: robust gender label (handles unexpected/missing values gracefully)
  String _genderLabel(String? gender) {
    switch (gender) {
      case 'male': return 'Homme';
      case 'female': return 'Femme';
      case 'other': return 'Autre';
      default: return 'Non renseigné';
    }
  }

  Widget _buildHeader(dynamic profile) {
    // NEW: safe initial even if firstName is empty/null, avoids RangeError
    final firstName = (profile.firstName as String?)?.trim() ?? '';
    final lastName = (profile.lastName as String?)?.trim() ?? '';
    final initial = firstName.isNotEmpty ? firstName[0].toUpperCase() : '?';
    final fullName = [firstName, lastName].where((s) => s.isNotEmpty).join(' ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [AppColors.headerBlueDark, AppColors.headerBlueLight],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.headerBlueDark.withValues(alpha: 0.25),
            blurRadius: 16, offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2),
            ),
            child: CircleAvatar(
              radius: 46,
              backgroundColor: Colors.white,
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 38, fontWeight: FontWeight.bold, color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            fullName.isNotEmpty ? fullName : 'Nom non renseigné',
            style: const TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'PATIENT MEDILINK',
              style: TextStyle(
                fontSize: 11, color: Colors.white.withValues(alpha: 0.9),
                letterSpacing: 1.2, fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textGrey), // NEW: icon per section
          const SizedBox(width: 6),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.bold,
              color: AppColors.textGrey, letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {bool isLast = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark),
                      overflow: TextOverflow.ellipsis, // NEW: avoid overflow on long addresses/emails
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // NEW: subtle divider between rows instead of one dense block
        if (!isLast) const Divider(height: 1),
      ],
    );
  }

  Widget _buildMedicalStat(IconData icon, String label, String value, {Color? valueColor}) {
    return Column(
      children: [
        Icon(icon, size: 18, color: AppColors.textGrey), // NEW: icon per stat
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold,
            color: valueColor ?? AppColors.textDark,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ── NEW: BMI now shows a colour-coded category, not just the raw number
  Widget _buildBMIStat(double? heightCm, double? weightKg) {
    final bmi = _calculateBMIValue(heightCm, weightKg);
    if (bmi == null) {
      return _buildMedicalStat(Icons.monitor_heart_outlined, 'IMC', '--');
    }
    final (label, color) = _bmiCategory(bmi);
    return Column(
      children: [
        const Icon(Icons.monitor_heart_outlined, size: 18, color: AppColors.textGrey),
        const SizedBox(height: 6),
        const Text('IMC', style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
        const SizedBox(height: 4),
        Text(
          bmi.toStringAsFixed(1),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: color),
          ),
        ),
      ],
    );
  }

  (String, Color) _bmiCategory(double bmi) {
    if (bmi < 18.5) return ('Insuffisance', Colors.orange);
    if (bmi < 25) return ('Normal', Colors.green);
    if (bmi < 30) return ('Surpoids', Colors.orange);
    return ('Obésité', AppColors.error);
  }

  Widget _buildMedicalTags(String title, IconData icon, List<String> tags, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)), // NEW: slightly more visible border
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 15, color: color), // NEW: icon matching section
            const SizedBox(width: 6),
            Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
            const Spacer(),
            if (tags.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${tags.length}', // NEW: quick count badge
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
              ),
          ]),
          const SizedBox(height: 12),
          if (tags.isEmpty)
            Row(children: [
              Icon(Icons.check_circle_outline, size: 14, color: Colors.grey[400]),
              const SizedBox(width: 6),
              const Text('Aucune information renseignée',
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey)),
            ])
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags.map((tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.25)),
                ),
                child: Text(tag, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
              )).toList(),
            ),
        ],
      ),
    );
  }

  String _calculateAge(DateTime? birthDate) {
    if (birthDate == null) return 'N/A'; // NEW: guard against null date
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return '$age ans';
  }

  double? _calculateBMIValue(double? heightCm, double? weightKg) {
    if (heightCm == null || weightKg == null || heightCm == 0) return null;
    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }
}