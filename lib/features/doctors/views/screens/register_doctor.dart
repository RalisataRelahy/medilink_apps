import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medilink/features/auth/views/providers/auth_provider.dart';

// ⚠️ Adaptez ces imports au chemin réel de votre projet :
import '../../../auth/data/models/user_model.dart';
import '../../data/models/doctor_model.dart';
import '../../data/models/doctor_details_model.dart';
import '../../data/models/speciality_model.dart';
import '../../data/models/language_model.dart';
import '../../data/models/diplomas_model.dart';
import '../../../../shared/enums/account_status.dart';

/// ============================================================
/// COULEURS & STYLE "MediLink"
/// ============================================================
class MedilinkColors {
  static const Color primary = Color(0xFF0F7A82); // teal médical (header)
  static const Color primaryDark = Color(0xFF0B5C63);
  static const Color background = Color(0xFFF4F7F8);
  static const Color cardBg = Color(0xFFEFF5F6);
  static const Color textDark = Color(0xFF17313B);
  static const Color textGrey = Color(0xFF6B7B80);
  static const Color inactiveStep = Color(0xFFD7E3E5);
  static const Color accent = Color(0xFF00C9A7);
}

const _specialitySuggestions = [
  'Cardiologie', 'Dermatologie', 'Pédiatrie', 'Gynécologie', 'Ophtalmologie',
  'Neurologie', 'Psychiatrie', 'Médecine Générale', 'Chirurgie', 'Radiologie',
];

const _languageSuggestions = [
  'Français', 'Anglais', 'Malgache', 'Espagnol', 'Allemand', 'Italien', 'Chinois',
];

const _diplomaSuggestions = [
  'Doctorat en Médecine', 'Master en Santé Publique', 'Diplôme de Spécialisation',
  'DU en Échographie', 'Certification en Télémédecine',
];

/// ============================================================
/// ECRAN D'INSCRIPTION MEDECIN — STEP BY STEP
/// ============================================================
class RegisterDoctorScreen extends ConsumerStatefulWidget {
  final UserModel user;
  final String password;
  const RegisterDoctorScreen({super.key, required this.user,required this.password});

  @override
  ConsumerState<RegisterDoctorScreen> createState() =>_RegisterDoctorScreenState();
}

class _RegisterDoctorScreenState extends ConsumerState<RegisterDoctorScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 4;
  bool _isSubmitting = false;

  // Form keys par étape
  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();
  final _step3Key = GlobalKey<FormState>();

  // Controllers correspondant STRICTEMENT aux champs saisissables
  final _licenseNumberCtrl = TextEditingController();
  final _yearsExperienceCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _clinicNameCtrl = TextEditingController();

  // Nouveaux controllers pour les tags
  final _specialityInputCtrl = TextEditingController();
  final _diplomaInputCtrl = TextEditingController();
  final _languageInputCtrl = TextEditingController();

  final List<String> _specialities = [];
  final List<String> _diplomas = [];
  final List<String> _languages = [];

  final List<_StepInfo> _steps = const [
    _StepInfo(icon: Icons.badge_outlined, label: 'Licence'),
    _StepInfo(icon: Icons.school_outlined, label: 'Expertise'),
    _StepInfo(icon: Icons.language_outlined, label: 'Langues'),
    _StepInfo(icon: Icons.fact_check_outlined, label: 'Vérification'),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _licenseNumberCtrl.dispose();
    _yearsExperienceCtrl.dispose();
    _bioCtrl.dispose();
    _clinicNameCtrl.dispose();
    _specialityInputCtrl.dispose();
    _diplomaInputCtrl.dispose();
    _languageInputCtrl.dispose();
    super.dispose();
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _step1Key.currentState?.validate() ?? false;
      case 1:
        if (_specialities.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Veuillez ajouter au moins une spécialité')),
          );
          return false;
        }
        return _step2Key.currentState?.validate() ?? false;
      case 2:
        return _step3Key.currentState?.validate() ?? false;
      default:
        return true;
    }
  }

  void _goNext() {
    if (_currentStep < _totalSteps - 1) {
      if (!_validateCurrentStep()) return;
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut,
      );
    } else {
      _openFinalVerificationDialog();
    }
  }

  void _goBack() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut,
      );
    }
  }

  void _jumpToStep(int step) {
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOut,
    );
  }

  /// Vérification finale : montre un récapitulatif ; si le médecin
  /// a modifié un champ depuis l'ouverture de la boîte, on lui
  /// redemande confirmation avant l'envoi définitif.
  Future<void> _openFinalVerificationDialog() async {
    // Snapshot des valeurs au moment de l'ouverture du dialogue
    final snapshot = _FormSnapshot(
      license: _licenseNumberCtrl.text,
      years: _yearsExperienceCtrl.text,
      bio: _bioCtrl.text,
      clinic: _clinicNameCtrl.text,
      specialities: List.from(_specialities),
      diplomas: List.from(_diplomas),
      languages: List.from(_languages),
    );

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setDialogState) {
          final current = _FormSnapshot(
            license: _licenseNumberCtrl.text,
            years: _yearsExperienceCtrl.text,
            bio: _bioCtrl.text,
            clinic: _clinicNameCtrl.text,
            specialities: List.from(_specialities),
            diplomas: List.from(_diplomas),
            languages: List.from(_languages),
          );
          final hasChanges = current != snapshot;

          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.verified_user_outlined,
                    color: MedilinkColors.primary),
                SizedBox(width: 8),
                Text('Vérification finale'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Merci de confirmer que ces informations sont exactes '
                        'avant l\'envoi de votre demande d\'inscription.',
                    style: TextStyle(color: MedilinkColors.textGrey),
                  ),
                  const SizedBox(height: 12),
                  _summaryLine('Numéro de licence', current.license),
                  _summaryLine(
                      'Années d\'expérience', '${current.years} an(s)'),
                  _summaryLine('Spécialités', current.specialities.join(', ')),
                  _summaryLine('Diplômes', current.diplomas.join(', ')),
                  _summaryLine('Langues', current.languages.join(', ')),
                  _summaryLine('Bio', current.bio, maxLines: 3),
                  _summaryLine('Clinique', current.clinic.isEmpty
                      ? 'Non renseignée'
                      : current.clinic),
                  if (hasChanges) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 18, color: Colors.orange.shade700),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Des modifications ont été détectées. '
                                  'Vérifiez-les avant de confirmer.',
                              style: TextStyle(fontSize: 12.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Modifier',
                    style: TextStyle(color: MedilinkColors.textGrey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: MedilinkColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Confirmer et envoyer'),
              ),
            ],
          );
        });
      },
    );

    if (confirmed == true) {
      await _submit();
    }
  }

  Widget _summaryLine(String label, String value, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: MedilinkColors.textGrey)),
          const SizedBox(height: 2),
          Text(
            value.isEmpty ? '—' : value,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 14.5,
                color: MedilinkColors.textDark,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      final doctorData = DoctorModel(
        licenseNumber: _licenseNumberCtrl.text.trim(),
        yearsOfExperience: int.tryParse(_yearsExperienceCtrl.text.trim()) ?? 0,
        bio: _bioCtrl.text.trim(),
        clinicName: _clinicNameCtrl.text.trim().isEmpty ? null : _clinicNameCtrl.text.trim(),
        rating: 0,
        accountStatus: AccountStatus.pending,
      );

      final doctorDetails = DoctorDetailsModel(
        profile: widget.user,
        doctor: doctorData,
        specialities: _specialities.map((s) => SpecialityModel(name: s)).toList(),
        languages: _languages.map((l) => LanguageModel(name: l)).toList(),
        diplomas: _diplomas.map((d) => DiplomasModel(name: d)).toList(),
      );

      await ref.read(authProvider.notifier).register(
        email: widget.user.email,
        password: widget.password,
        role: widget.user.role,
        userRegister: widget.user,
        doctorData: doctorDetails,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Demande d\'inscription envoyée avec succès !'),
          backgroundColor: MedilinkColors.primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: Colors.red.shade400,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MedilinkColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildStepper(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStep1(),
                    _buildStep2(),
                    _buildStep3(),
                    _buildStep4Review(),
                  ],
                ),
              ),
            ),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  /// ---------------- HEADER ----------------
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 26),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [MedilinkColors.primary, MedilinkColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.local_hospital, color: Colors.white),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'MEDILINK',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Étape ${_currentStep + 1}/$_totalSteps',
              style: const TextStyle(color: Colors.white, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }

  /// ---------------- STEPPER (cercles) ----------------
  Widget _buildStepper() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            final leftDone = (i - 1) ~/ 2 < _currentStep;
            return Container(
              width: 34,
              height: 2,
              color: leftDone
                  ? MedilinkColors.primary
                  : MedilinkColors.inactiveStep,
            );
          }
          final index = i ~/ 2;
          final isActive = index == _currentStep;
          final isDone = index < _currentStep;
          return GestureDetector(
            onTap: isDone ? () => _jumpToStep(index) : null,
            child: CircleAvatar(
              radius: 20,
              backgroundColor: (isActive || isDone)
                  ? MedilinkColors.primary
                  : MedilinkColors.inactiveStep,
              child: isDone
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : Icon(
                _steps[index].icon,
                color: isActive ? Colors.white : MedilinkColors.textGrey,
                size: 18,
              ),
            ),
          );
        }),
      ),
    );
  }

  /// ---------------- ETAPE 1 : Licence & Expérience ----------------
  Widget _buildStep1() {
    return Form(
      key: _step1Key,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _stepTitle('Informations professionnelles',
                'Renseignez votre licence et votre expérience.'),
            const SizedBox(height: 24),
            _label('Numéro de licence médicale'),
            _textField(
              controller: _licenseNumberCtrl,
              hint: 'Ex : MD-2025-00123',
              icon: Icons.badge_outlined,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Le numéro de licence est requis';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            _label('Années d\'expérience'),
            _textField(
              controller: _yearsExperienceCtrl,
              hint: 'Ex : 5',
              icon: Icons.timeline_outlined,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Ce champ est requis';
                }
                final n = int.tryParse(v.trim());
                if (n == null || n < 0) {
                  return 'Entrez un nombre valide';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            _infoBanner(
              'Vos données médicales sont chiffrées et protégées '
                  'selon les normes HIPAA.',
              icon: Icons.shield_outlined,
            ),
          ],
        ),
      ),
    );
  }

  /// ---------------- ETAPE 2 : Expertise (Spécialités & Diplômes) ----------------
  Widget _buildStep2() {
    return Form(
      key: _step2Key,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _stepTitle('Votre expertise',
                'Quelles sont vos spécialités et vos diplômes ?'),
            const SizedBox(height: 24),
            _TagInputCard(
              title: 'Spécialités',
              subtitle: 'Vos domaines d\'expertise médicale',
              emptyHint: 'Aucune spécialité renseignée',
              placeholder: 'Ex : Cardiologie',
              icon: Icons.local_hospital_outlined,
              tags: _specialities,
              suggestions: _specialitySuggestions,
              tagColor: MedilinkColors.primary,
              tagBg: MedilinkColors.cardBg,
              controller: _specialityInputCtrl,
              onAdd: (v) { if (!_specialities.contains(v)) setState(() => _specialities.add(v)); },
              onRemove: (v) => setState(() => _specialities.remove(v)),
            ),
            const SizedBox(height: 16),
            _TagInputCard(
              title: 'Diplômes',
              subtitle: 'Vos titres et certifications',
              emptyHint: 'Aucun diplôme renseigné',
              placeholder: 'Ex : Doctorat en Médecine',
              icon: Icons.school_outlined,
              tags: _diplomas,
              suggestions: _diplomaSuggestions,
              tagColor: MedilinkColors.accent,
              tagBg: MedilinkColors.accent.withOpacity(0.1),
              controller: _diplomaInputCtrl,
              onAdd: (v) { if (!_diplomas.contains(v)) setState(() => _diplomas.add(v)); },
              onRemove: (v) => setState(() => _diplomas.remove(v)),
            ),
          ],
        ),
      ),
    );
  }

  /// ---------------- ETAPE 3 : Communication & Bio ----------------
  Widget _buildStep3() {
    return Form(
      key: _step3Key,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _stepTitle('Communication & Bio',
                'Quelles langues parlez-vous ? Dites-nous en plus sur vous.'),
            const SizedBox(height: 24),
            _TagInputCard(
              title: 'Langues',
              subtitle: 'Langues utilisées lors des consultations',
              emptyHint: 'Aucune langue renseignée',
              placeholder: 'Ex : Français',
              icon: Icons.language_outlined,
              tags: _languages,
              suggestions: _languageSuggestions,
              tagColor: Colors.blue.shade700,
              tagBg: Colors.blue.shade50,
              controller: _languageInputCtrl,
              onAdd: (v) { if (!_languages.contains(v)) setState(() => _languages.add(v)); },
              onRemove: (v) => setState(() => _languages.remove(v)),
            ),
            const SizedBox(height: 24),
            _label('Bio professionnelle'),
            _textField(
              controller: _bioCtrl,
              hint: 'Décrivez votre spécialité, votre approche...',
              icon: Icons.description_outlined,
              maxLines: 4,
              validator: (v) {
                if (v == null || v.trim().length < 20) {
                  return 'Minimum 20 caractères';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  /// ---------------- ETAPE 4 : Clinique & Récapitulatif ----------------
  Widget _buildStep4Review() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepTitle('Finalisation',
              'Vérifiez vos informations et renseignez votre clinique.'),
          const SizedBox(height: 24),
          _label('Nom de la clinique (optionnel)'),
          _textField(
            controller: _clinicNameCtrl,
            hint: 'Ex : Clinique Andrainarivo',
            icon: Icons.local_hospital_outlined,
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),
          const Text('Récapitulatif',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: MedilinkColors.textDark)),
          const SizedBox(height: 12),
          _reviewCard(
            title: 'Numéro de licence',
            value: _licenseNumberCtrl.text,
            icon: Icons.badge_outlined,
            onEdit: () => _jumpToStep(0),
          ),
          _reviewCard(
            title: 'Spécialités',
            value: _specialities.isEmpty ? '—' : _specialities.join(', '),
            icon: Icons.local_hospital_outlined,
            onEdit: () => _jumpToStep(1),
          ),
          _reviewCard(
            title: 'Diplômes',
            value: _diplomas.isEmpty ? '—' : _diplomas.join(', '),
            icon: Icons.school_outlined,
            onEdit: () => _jumpToStep(1),
          ),
          _reviewCard(
            title: 'Langues',
            value: _languages.isEmpty ? '—' : _languages.join(', '),
            icon: Icons.language_outlined,
            onEdit: () => _jumpToStep(2),
          ),
          const SizedBox(height: 12),
          _infoBanner(
            'Votre compte sera validé par notre équipe sous 24h à 48h.',
            icon: Icons.hourglass_top_outlined,
          ),
        ],
      ),
    );
  }

  /// ---------------- WIDGETS UTILITAIRES ----------------
  Widget _stepTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: MedilinkColors.textDark)),
        const SizedBox(height: 6),
        Text(subtitle,
            style: const TextStyle(
                fontSize: 14, color: MedilinkColors.textGrey)),
      ],
    );
  }

  Widget _iconCircle(IconData icon) {
    return Center(
      child: Container(
        width: 84,
        height: 84,
        decoration: const BoxDecoration(
          color: MedilinkColors.cardBg,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 36, color: MedilinkColors.primary),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: MedilinkColors.textDark)),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(color: MedilinkColors.textDark),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: maxLines == 1
            ? Icon(icon, color: MedilinkColors.primary, size: 20)
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: MedilinkColors.inactiveStep),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: MedilinkColors.inactiveStep),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: MedilinkColors.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red.shade300),
        ),
      ),
    );
  }

  Widget _infoBanner(String text, {required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MedilinkColors.cardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: MedilinkColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 12.5, color: MedilinkColors.textGrey)),
          ),
        ],
      ),
    );
  }

  Widget _reviewCard({
    required String title,
    required String value,
    required IconData icon,
    required VoidCallback onEdit,
    int maxLines = 1,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MedilinkColors.inactiveStep),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: MedilinkColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: MedilinkColors.textGrey)),
                const SizedBox(height: 3),
                Text(
                  value.isEmpty ? '—' : value,
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 14.5,
                      color: MedilinkColors.textDark,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                size: 18, color: MedilinkColors.primary),
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }

  /// ---------------- NAVIGATION BAS ----------------
  Widget _buildBottomNav() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _isSubmitting ? null : _goBack,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: MedilinkColors.inactiveStep),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Retour',
                    style: TextStyle(color: MedilinkColors.textGrey)),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _goNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: MedilinkColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: _isSubmitting
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
                  : Icon(_currentStep == _totalSteps - 1
                  ? Icons.check
                  : Icons.arrow_forward),
              label: Text(_currentStep == _totalSteps - 1
                  ? 'Confirmer et envoyer'
                  : 'Suivant'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepInfo {
  final IconData icon;
  final String label;
  const _StepInfo({required this.icon, required this.label});
}

class _FormSnapshot {
  final String license;
  final String years;
  final String bio;
  final String clinic;
  final List<String> specialities;
  final List<String> diplomas;
  final List<String> languages;

  const _FormSnapshot({
    required this.license,
    required this.years,
    required this.bio,
    required this.clinic,
    required this.specialities,
    required this.diplomas,
    required this.languages,
  });

  @override
  bool operator ==(Object other) =>
      other is _FormSnapshot &&
          other.license == license &&
          other.years == years &&
          other.bio == bio &&
          other.clinic == clinic &&
          other.specialities.toString() == specialities.toString() &&
          other.diplomas.toString() == diplomas.toString() &&
          other.languages.toString() == languages.toString();

  @override
  int get hashCode => Object.hash(license, years, bio, clinic, specialities, diplomas, languages);
}

// ─── Tag Input Card (stateless, driven by parent setState) ────────────────────

class _TagInputCard extends StatefulWidget {
  final String title, subtitle, emptyHint, placeholder;
  final IconData icon;
  final List<String> tags;
  final List<String> suggestions;
  final Color tagColor, tagBg;
  final TextEditingController controller;
  final void Function(String) onAdd;
  final void Function(String) onRemove;
  final bool isOptional;

  const _TagInputCard({
    required this.title,
    required this.subtitle,
    required this.emptyHint,
    required this.placeholder,
    required this.icon,
    required this.tags,
    required this.suggestions,
    required this.tagColor,
    required this.tagBg,
    required this.controller,
    required this.onAdd,
    required this.onRemove,
    this.isOptional = false,
  });

  @override
  State<_TagInputCard> createState() => _TagInputCardState();
}

class _TagInputCardState extends State<_TagInputCard> {
  String _query = '';

  List<String> get _filteredSuggestions {
    final q = _query.toLowerCase();
    return widget.suggestions
        .where((s) =>
    !widget.tags.contains(s) &&
        (q.isEmpty || s.toLowerCase().contains(q)))
        .toList();
  }

  void _addTag(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    widget.onAdd(trimmed);
    widget.controller.clear();
    setState(() { _query = ''; });
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.tagColor.withOpacity(0.15);
    final headerIconColor = widget.tagColor;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10, offset: const Offset(0, 4),
        )],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: widget.tagBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(widget.icon, size: 18, color: headerIconColor),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.title, style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700,
                color: headerIconColor, letterSpacing: 0.2,
              )),
              Text(widget.subtitle, style: const TextStyle(
                fontSize: 11.5, color: MedilinkColors.textGrey,
              )),
            ])),
            if (widget.isOptional)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: MedilinkColors.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Optionnel', style: TextStyle(
                  fontSize: 10, color: MedilinkColors.accent, fontWeight: FontWeight.w600,
                )),
              ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: widget.tags.isEmpty
              ? Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: MedilinkColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: MedilinkColors.inactiveStep, style: BorderStyle.solid),
            ),
            child: Column(children: [
              Icon(widget.icon,
                  size: 22, color: MedilinkColors.textGrey.withOpacity(0.4)),
              const SizedBox(height: 6),
              Text(widget.emptyHint, style: TextStyle(
                fontSize: 12.5,
                color: MedilinkColors.textGrey.withOpacity(0.6),
              )),
            ]),
          )
              : Wrap(
            spacing: 8, runSpacing: 8,
            children: widget.tags.map((tag) => _MedicalTag(
              label: tag,
              color: widget.tagColor,
              bg: widget.tagBg,
              onRemove: () => widget.onRemove(tag),
            )).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: widget.controller,
                style: const TextStyle(
                    color: MedilinkColors.textDark, fontSize: 14),
                decoration: InputDecoration(
                  hintText: widget.placeholder,
                  hintStyle: TextStyle(
                      color: MedilinkColors.textGrey.withOpacity(0.6),
                      fontSize: 13),
                  prefixIcon: const Icon(Icons.add_circle_outline,
                      size: 18, color: MedilinkColors.primary),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                  filled: true,
                  fillColor: MedilinkColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: MedilinkColors.inactiveStep, width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: MedilinkColors.inactiveStep, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                        color: widget.tagColor, width: 2),
                  ),
                ),
                onChanged: (v) => setState(() {
                  _query = v;
                }),
                onSubmitted: _addTag,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _addTag(widget.controller.text),
              child: Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: widget.tagColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 22),
              ),
            ),
          ]),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: _filteredSuggestions.isEmpty
              ? const SizedBox.shrink()
              : Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Suggestions rapides',
                    style: TextStyle(
                      fontSize: 11,
                      color: MedilinkColors.textGrey.withOpacity(0.7),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    )),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: _filteredSuggestions.take(6).map((s) =>
                      GestureDetector(
                        onTap: () => _addTag(s),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: widget.tagBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: widget.tagColor.withOpacity(0.3)),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.add, size: 12, color: widget.tagColor),
                            const SizedBox(width: 4),
                            Text(s, style: TextStyle(
                              fontSize: 12, color: widget.tagColor,
                              fontWeight: FontWeight.w500,
                            )),
                          ]),
                        ),
                      ),
                  ).toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
      ]),
    );
  }
}

class _MedicalTag extends StatelessWidget {
  final String label;
  final Color color, bg;
  final VoidCallback onRemove;

  const _MedicalTag({
    required this.label,
    required this.color,
    required this.bg,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 4, top: 6, bottom: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: TextStyle(
          fontSize: 13, color: color, fontWeight: FontWeight.w600,
        )),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: onRemove,
          child: Container(
            width: 18, height: 18,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.close, size: 11, color: color),
          ),
        ),
      ]),
    );
  }
}
