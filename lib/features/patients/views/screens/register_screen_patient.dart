import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/features/auth/data/models/user_model.dart';
import 'package:medilink/features/patients/data/models/allergy_model.dart';
import 'package:medilink/features/patients/data/models/disease_model.dart';
import 'package:medilink/features/patients/data/models/patient_details_models.dart';
import 'package:medilink/features/patients/data/models/patient_model.dart';

import '../../../../shared/enums/account_status.dart';
import '../../../../shared/enums/blood_type.dart';
import '../../../auth/views/providers/auth_provider.dart';

extension BloodTypeLabel on BloodType {
  String get label {
    switch (this) {
      case BloodType.aPositive:  return 'A+';
      case BloodType.aNegative:  return 'A−';
      case BloodType.bPositive:  return 'B+';
      case BloodType.bNegative:  return 'B−';
      case BloodType.abPositive: return 'AB+';
      case BloodType.abNegative: return 'AB−';
      case BloodType.oPositive:  return 'O+';
      case BloodType.oNegative:  return 'O−';
    }
  }
}

// ─── Design tokens ───────────────────────────────────────────────────────────

class MedilinkColors {
  static const primary      = AppColors.primary;
  static const primaryLight = AppColors.primaryLight;
  static const accent       = AppColors.accent;
  static const surface      = AppColors.background;
  static const card         = AppColors.surface;
  static const textMain     = AppColors.textDark;
  static const textSub      = AppColors.textGrey;
  static const error        = AppColors.error;
  static const stepDone     = AppColors.stepDone;
  static const stepActive   = AppColors.primary;
  static const stepIdle     = AppColors.inactiveStep;

  // Tag colours
  static const diseaseTag   = Color(0xFF1A6FD6); // blue — chronic, manageable
  static const diseaseBg    = Color(0xFFEBF3FF);
  static const allergyTag   = Color(0xFFB84000); // amber-red — danger
  static const allergyBg    = Color(0xFFFFF0E6);
}

// ─── Quick-suggest data ───────────────────────────────────────────────────────

const _diseaseSuggestions = [
  'Diabète type 2', 'Hypertension', 'Asthme', 'Insuffisance cardiaque',
  'Hypothyroïdie', 'Arthrite', 'Épilepsie', 'Dépression', 'Migraine',
  'Insuffisance rénale',
];

const _allergySuggestions = [
  'Pénicilline', 'Arachides', 'Latex', 'Aspirine', 'Sulfamides',
  'Fruits de mer', 'Gluten', 'Lait', 'Pollen', 'Œufs',
];

// ─── Page principale ─────────────────────────────────────────────────────────

class RegisterPagePatient extends ConsumerStatefulWidget {
  final UserModel user;
  final String password;
  const RegisterPagePatient({super.key, required this.user, required this.password});

  @override
  ConsumerState<RegisterPagePatient> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPagePatient>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  final int _totalSteps = 4;

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  // Step 2
  String _gender = 'male';
  DateTime? _dateOfBirth;

  // Step 3 – NEW: tag-based
  BloodType? _bloodType;
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();

  final List<String> _diseases  = [];
  final List<String> _allergies = [];

  final _diseaseInputCtrl  = TextEditingController();
  final _allergyInputCtrl  = TextEditingController();

  // Step 4
  final _emergencyNameCtrl  = TextEditingController();
  final _emergencyPhoneCtrl = TextEditingController();

  // Form keys
  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();
  final _step3Key = GlobalKey<FormState>();
  final _step4Key = GlobalKey<FormState>();

  // ── NEW: submission / error state ─────────────────────────────────────────
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 350),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1, 0), end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _diseaseInputCtrl.dispose();
    _allergyInputCtrl.dispose();
    _emergencyNameCtrl.dispose();
    _emergencyPhoneCtrl.dispose();
    super.dispose();
  }

  GlobalKey<FormState> get _currentFormKey {
    switch (_currentStep) {
      case 0: return _step1Key;
      case 1: return _step2Key;
      case 2: return _step3Key;
      default: return _step4Key;
    }
  }

  // ── NEW: whether the user has entered anything worth not losing ───────────
  bool get _hasEnteredData {
    return _dateOfBirth != null ||
        _bloodType != null ||
        _heightCtrl.text.trim().isNotEmpty ||
        _weightCtrl.text.trim().isNotEmpty ||
        _diseases.isNotEmpty ||
        _allergies.isNotEmpty ||
        _emergencyNameCtrl.text.trim().isNotEmpty ||
        _emergencyPhoneCtrl.text.trim().isNotEmpty;
  }

  bool _validateCurrentStep() {
    if (!(_currentFormKey.currentState?.validate() ?? false)) return false;
    if (_currentStep == 1 && _dateOfBirth == null) {
      _showError('Veuillez sélectionner votre date de naissance.');
      return false;
    }
    return true;
  }

  void _nextStep() {
    if (_isSubmitting) return;
    if (!_validateCurrentStep()) return;
    FocusScope.of(context).unfocus();
    if (_currentStep < _totalSteps - 1) _animateToStep(_currentStep + 1);
  }

  void _prevStep() {
    if (_isSubmitting) return;
    if (_currentStep > 0) {
      FocusScope.of(context).unfocus();
      _animateToStep(_currentStep - 1);
    }
  }

  void _animateToStep(int step) {
    _slideController.reset();
    setState(() => _currentStep = step);
    _slideController.forward();
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(msg)),
        ]),
        backgroundColor: MedilinkColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
  }

  // ── NEW: dedicated error dialog for submission failures ────────────────────
  Future<void> _showSubmitErrorDialog(Object error) async {
    if (!mounted) return;

    // Try to give a slightly more useful message without leaking raw
    // exception internals to the user.
    String message = 'Une erreur est survenue lors de la création de votre '
        'compte. Veuillez vérifier votre connexion internet et réessayer.';
    final errString = error.toString().toLowerCase();
    if (errString.contains('email') &&
        (errString.contains('exist') || errString.contains('use') || errString.contains('utilis'))) {
      message = 'Cette adresse e-mail est déjà utilisée par un autre compte.';
    } else if (errString.contains('network') ||
        errString.contains('socket') ||
        errString.contains('timeout')) {
      message = 'Impossible de contacter le serveur. Vérifiez votre connexion '
          'internet et réessayez.';
    }

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.error_outline_rounded, color: MedilinkColors.error),
          SizedBox(width: 10),
          Text('Échec de l\'inscription'),
        ]),
        content: Text(message, style: const TextStyle(height: 1.4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer',
                style: TextStyle(color: MedilinkColors.textSub)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _submit();
            },
            style: FilledButton.styleFrom(backgroundColor: MedilinkColors.primary),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  // ── NEW: confirm before leaving the page if data was entered ───────────────
  Future<bool> _confirmDiscard() async {
    if (!_hasEnteredData || _isSubmitting) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Abandonner l\'inscription ?'),
        content: const Text(
          'Les informations que vous avez saisies seront perdues. '
              'Voulez-vous vraiment quitter ?',
          style: TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Continuer l\'inscription'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Quitter', style: TextStyle(color: MedilinkColors.error)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _submit() async {
    if (_isSubmitting) return; // NEW: prevent double submission
    if (!_validateCurrentStep()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);

    try {
      final patientData = PatientModel(
        gender: _gender,
        weight: double.tryParse(_weightCtrl.text.trim()),
        height: double.tryParse(_heightCtrl.text.trim()),
        bloodType: _bloodType,
        dateOfBirth: _dateOfBirth!,
        emergencyContactName: _emergencyNameCtrl.text.trim(),
        emergencyContactPhone: _emergencyPhoneCtrl.text.trim(),
        accountStatus: AccountStatus.pending,
        updatedAt: DateTime.now(),
      );
      final allergyModel = _allergies
          .map((e) => AllergyModel(name: e))
          .toList();

      final diseases = _diseases
          .map((e) => DiseaseModel(name: e))
          .toList();

      final patientDataComplete = PatientDetailsModel(
        profile: widget.user,
        patient: patientData,
        allergies: allergyModel,
        diseases: diseases,
      );

      await ref.read(authProvider.notifier).register(
        email: widget.user.email,
        password: widget.password,
        role: widget.user.role,
        userRegister: widget.user,
        patientData: patientDataComplete,
      );

      if (!mounted) return; // NEW: guard after await

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(children: [
            Icon(Icons.check_circle_rounded, color: MedilinkColors.accent),
            SizedBox(width: 10),
            Text('Inscription réussie'),
          ]),
          content: const Text(
            'Votre dossier médical a été créé.\nVous recevrez un email de confirmation.',
          ),
          actions: [
            TextButton(
              onPressed: () => context.push('/login'),
              child: const Text('OK', style: TextStyle(color: MedilinkColors.primary)),
            ),
          ],
        ),
      );
    } catch (error) {
      // NEW: never silently swallow — surface a clear, actionable error.
      if (!mounted) return;
      await _showSubmitErrorDialog(error);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ─── BUILD ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasEnteredData && !_isSubmitting,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _confirmDiscard();
        if (shouldPop && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: GestureDetector(
        // NEW: dismiss keyboard when tapping outside a field
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: MedilinkColors.surface,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildStepIndicator(),
                Expanded(
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                      child: _buildCurrentStep(),
                    ),
                  ),
                ),
                _buildBottomNav(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  //// ─── Header ──────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    const titles    = ['Compte', 'Identité', 'Santé', 'Contact d\'urgence'];
    const subtitles = [
      'Créez vos identifiants de connexion',
      'Informations personnelles',
      'Votre profil médical',
      'En cas d\'urgence médicale',
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.headerBlueDark, AppColors.headerBlueLight],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.medical_services_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 10),
          const Text('MEDILINK',
              style: TextStyle(
                color: Colors.white, fontSize: 20,
                fontWeight: FontWeight.w800, letterSpacing: 1.5,
              )),
          const Spacer(),
          Text('Étape ${_currentStep + 1}/$_totalSteps',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 12, fontWeight: FontWeight.w600,
              )),
        ]),
        const SizedBox(height: 20),
        Text(titles[_currentStep],
            style: const TextStyle(
              color: Colors.white, fontSize: 26,
              fontWeight: FontWeight.w700, height: 1.1,
            )),
        const SizedBox(height: 4),
        Text(subtitles[_currentStep],
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
      ]),
    );
  }

  Widget _buildStepIndicator() {
    const icons = [
      Icons.lock_rounded, Icons.person_rounded,
      Icons.favorite_rounded, Icons.emergency_rounded,
    ];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Row(
        children: List.generate(_totalSteps, (i) {
          final isDone   = i < _currentStep;
          final isActive = i == _currentStep;
          return Expanded(
            child: Row(children: [
              Expanded(child: Column(children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: isDone
                        ? AppColors.stepDone
                        : isActive
                        ? AppColors.primary
                        : AppColors.inactiveStep,
                    shape: BoxShape.circle,
                    boxShadow: isActive ? [BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 8, offset: const Offset(0, 3),
                    )] : null,
                  ),
                  child: Icon(
                    isDone ? Icons.check_rounded : icons[i],
                    color: (isDone || isActive) ? Colors.white : AppColors.textGrey,
                    size: 18,
                  ),
                ),
              ])),
              if (i < _totalSteps - 1)
                Expanded(child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 2,
                  color: i < _currentStep
                      ? AppColors.stepDone
                      : AppColors.inactiveStep,
                )),
            ]),
          );
        }),
      ),
    );
  }

  // ─── Steps ────────────────────────────────────────────────────────────────

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0: return _buildStep1();
      case 1: return _buildStep2();
      case 2: return _buildStep3();
      case 3: return _buildStep4();
      default: return const SizedBox();
    }
  }

  // ── Step 1 ───────────────────────────────────────────────────────────────

  Widget _buildStep1() {
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 600;
    return Form(
      key: _step1Key,
      child: Column(children: [
        Center(child: Container(
          width: isSmall ? size.width * 0.9 : 520,
          margin: const EdgeInsets.all(20),
          child: Card(
            elevation: 8,
            shadowColor: Colors.blue.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Color(0xFFEBF8FF), Color(0xFFF0F9FF)],
                ),
              ),
              padding: const EdgeInsets.all(32),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle,
                    boxShadow: [BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.15),
                      blurRadius: 20, spreadRadius: 5,
                    )],
                  ),
                  child: const Icon(Icons.medical_information_rounded,
                      size: 64, color: Color(0xFF1E88E5)),
                ),
                const SizedBox(height: 24),
                Text('Complétez maintenant',
                    style: TextStyle(
                      fontSize: isSmall ? 22 : 26, fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E3A8A), letterSpacing: -0.5,
                    ), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Text('le reste de vos informations.',
                    style: TextStyle(
                      fontSize: isSmall ? 18 : 20, fontWeight: FontWeight.w500,
                      color: const Color(0xFF334155), height: 1.4,
                    ), textAlign: TextAlign.center),
                const SizedBox(height: 32),
                const SizedBox(height: 16),
                Text('Cela ne prendra que quelques minutes',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600],
                        fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center),
              ]),
            ),
          ),
        )),
        _infoTip(Icons.shield_outlined,
            'Vos données médicales sont chiffrées et protégées selon les normes HIPAA.'),
      ]),
    );
  }

  // ── Step 2 ───────────────────────────────────────────────────────────────

  Widget _buildStep2() {
    return Form(
      key: _step2Key,
      child: Column(children: [
        const SizedBox(height: 16),
        _card([
          _sectionLabel('Genre', Icons.wc_rounded),
          const SizedBox(height: 12),
          Row(children: [
            _genderChip('male',   'Homme', Icons.male_rounded),
            const SizedBox(width: 10),
            _genderChip('female', 'Femme', Icons.female_rounded),
            const SizedBox(width: 10),
            _genderChip('other',  'Autre', Icons.transgender_rounded),
          ]),
        ]),
        const SizedBox(height: 16),
        _card([
          _sectionLabel('Date de naissance', Icons.cake_outlined),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime(1990),
                firstDate: DateTime(1900),
                lastDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
                builder: (ctx, child) => Theme(
                  data: Theme.of(ctx).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: MedilinkColors.primary,
                      onPrimary: Colors.white,
                      surface: Colors.white,
                    ),
                  ),
                  child: child!,
                ),
              );
              if (picked != null && mounted) setState(() => _dateOfBirth = picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: MedilinkColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _dateOfBirth != null
                      ? MedilinkColors.primary
                      : MedilinkColors.stepIdle,
                  width: 1.5,
                ),
              ),
              child: Row(children: [
                const Icon(Icons.calendar_today_rounded,
                    color: MedilinkColors.primary, size: 20),
                const SizedBox(width: 12),
                Text(
                  _dateOfBirth == null
                      ? 'Sélectionner une date'
                      : DateFormat('dd MMMM yyyy', 'fr_FR').format(_dateOfBirth!),
                  style: TextStyle(
                    color: _dateOfBirth == null
                        ? MedilinkColors.textSub
                        : MedilinkColors.textMain,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right_rounded, color: MedilinkColors.textSub),
              ]),
            ),
          ),
          // NEW: inline hint so the user knows why the field matters and
          // that a red border below means a missing required value.
          if (_dateOfBirth == null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Requis pour valider votre profil médical.',
                style: TextStyle(
                  fontSize: 11.5,
                  color: MedilinkColors.textSub.withValues(alpha: 0.8),
                ),
              ),
            ),
        ]),
      ]),
    );
  }

  // ── Step 3 : Santé ────────────────────────────────────────────────────────

  Widget _buildStep3() {
    return Form(
      key: _step3Key,
      child: Column(children: [

        // Blood type
        _card([
          _sectionLabel('Groupe sanguin', Icons.bloodtype_outlined),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: BloodType.values.map((bt) {
              final isSelected = _bloodType == bt;
              return GestureDetector(
                onTap: () => setState(() => _bloodType = bt),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? MedilinkColors.error.withValues(alpha: 0.12)
                        : MedilinkColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? MedilinkColors.error : MedilinkColors.stepIdle,
                      width: isSelected ? 2 : 1.5,
                    ),
                  ),
                  child: Text(bt.label,
                      style: TextStyle(
                        color: isSelected ? MedilinkColors.error : MedilinkColors.textSub,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 14,
                      )),
                ),
              );
            }).toList(),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('Optionnel',
                style: TextStyle(
                  color: MedilinkColors.textSub.withValues(alpha: 0.7), fontSize: 11,
                )),
          ),
        ]),
        const SizedBox(height: 16),

        // Height / Weight
        _card([
          _sectionLabel('Mensurations', Icons.straighten_rounded),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _inputField(
              controller: _heightCtrl,
              label: 'Taille (cm)', hint: '175',
              icon: Icons.height_rounded,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final h = double.tryParse(v.trim());
                if (h == null) return 'Nombre invalide';
                if (h < 50 || h > 250) return 'Entre 50 et 250 cm';
                return null;
              },
              optional: true,
            )),
            const SizedBox(width: 12),
            Expanded(child: _inputField(
              controller: _weightCtrl,
              label: 'Poids (kg)', hint: '70',
              icon: Icons.monitor_weight_outlined,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final w = double.tryParse(v.trim());
                if (w == null) return 'Nombre invalide';
                if (w < 1 || w > 500) return 'Entre 1 et 500 kg';
                return null;
              },
              optional: true,
            )),
          ]),
        ]),
        const SizedBox(height: 16),

        // ── DISEASES — tag input ─────────────────────────────────────────
        _TagInputCard(
          title: 'Maladies chroniques',
          icon: Icons.vaccines_outlined,
          subtitle: 'Conditions médicales que vous gérez au long terme',
          emptyHint: 'Aucune maladie chronique renseignée',
          placeholder: 'Ex : Diabète type 2',
          suggestions: _diseaseSuggestions,
          tags: _diseases,
          tagColor: MedilinkColors.diseaseTag,
          tagBg: MedilinkColors.diseaseBg,
          controller: _diseaseInputCtrl,
          onAdd: (v) { if (!_diseases.contains(v)) setState(() => _diseases.add(v)); },
          onRemove: (v) => setState(() => _diseases.remove(v)),
        ),
        const SizedBox(height: 16),

        // ── ALLERGIES — tag input ────────────────────────────────────────
        _TagInputCard(
          title: 'Allergies',
          icon: Icons.warning_amber_rounded,
          subtitle: 'Substances provoquant une réaction allergique',
          emptyHint: 'Aucune allergie renseignée',
          placeholder: 'Ex : Pénicilline',
          suggestions: _allergySuggestions,
          tags: _allergies,
          tagColor: MedilinkColors.allergyTag,
          tagBg: MedilinkColors.allergyBg,
          controller: _allergyInputCtrl,
          onAdd: (v) { if (!_allergies.contains(v)) setState(() => _allergies.add(v)); },
          onRemove: (v) => setState(() => _allergies.remove(v)),
          isDanger: true,
        ),
      ]),
    );
  }

  // ── Step 4 ────────────────────────────────────────────────────────────────

  Widget _buildStep4() {
    return Form(
      key: _step4Key,
      child: Column(children: [
        _infoTip(Icons.info_outline_rounded,
            'Ces informations seront utilisées uniquement en cas d\'urgence médicale.'),
        const SizedBox(height: 16),
        _card([
          _sectionLabel('Contact d\'urgence', Icons.emergency_share_rounded),
          const SizedBox(height: 16),
          _inputField(
            controller: _emergencyNameCtrl,
            label: 'Nom du contact', hint: 'Marie Dupont',
            icon: Icons.person_pin_rounded,
            validator: (v) {
              final trimmed = v?.trim() ?? '';
              if (trimmed.isEmpty) return 'Nom requis';
              if (trimmed.length < 2) return 'Nom trop court';
              return null;
            },
          ),
          const SizedBox(height: 16),
          _inputField(
            controller: _emergencyPhoneCtrl,
            label: 'Numéro de téléphone', hint: '+261 34 00 000 00',
            icon: Icons.phone_rounded,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[+\d\s]'))],
            validator: (v) {
              final trimmed = v?.trim() ?? '';
              if (trimmed.isEmpty) return 'Téléphone requis';
              final cleaned = trimmed.replaceAll(RegExp(r'\s'), '');
              if (!RegExp(r'^\+?[\d]{8,15}$').hasMatch(cleaned)) {
                return 'Numéro invalide (8 à 15 chiffres)';
              }
              return null;
            },
          ),
        ]),
        const SizedBox(height: 16),
        _card([
          Row(children: [
            const Icon(Icons.check_circle_outline_rounded,
                color: MedilinkColors.accent, size: 20),
            const SizedBox(width: 8),
            const Expanded(child: Text(
              'En vous inscrivant, vous acceptez nos Conditions d\'utilisation et notre Politique de confidentialité.',
              style: TextStyle(
                fontSize: 12, color: MedilinkColors.textSub, height: 1.4,
              ),
            )),
          ]),
        ]),
      ]),
    );
  }

  Widget _buildBottomNav() {
    final isLast = _currentStep == _totalSteps - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 12, offset: const Offset(0, -4),
        )],
      ),
      child: Row(children: [
        if (_currentStep > 0)
          OutlinedButton.icon(
            onPressed: _isSubmitting ? null : _prevStep, // NEW: disabled while submitting
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: const Text('Retour'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        const Spacer(),
        FilledButton.icon(
          onPressed: _isSubmitting ? null : (isLast ? _submit : _nextStep), // NEW
          icon: _isSubmitting
              ? const SizedBox(
            width: 16, height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2, color: Colors.white,
            ),
          )
              : Icon(
            isLast ? Icons.check_rounded : Icons.arrow_forward_rounded,
            size: 18,
          ),
          label: Text(_isSubmitting
              ? 'Création en cours…'
              : (isLast ? 'Créer mon compte' : 'Suivant')),
          style: FilledButton.styleFrom(
            backgroundColor: isLast ? AppColors.accent : AppColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: (isLast ? AppColors.accent : AppColors.primary)
                .withValues(alpha: 0.6),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
          ),
        ),
      ]),
    );
  }

  // ─── Shared utility widgets ───────────────────────────────────────────────

  Widget _card(List<Widget> children) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: MedilinkColors.card,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 10, offset: const Offset(0, 4),
      )],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );

  Widget _sectionLabel(String label, IconData icon) => Row(children: [
    Icon(icon, size: 18, color: MedilinkColors.primary),
    const SizedBox(width: 8),
    Text(label, style: const TextStyle(
      fontSize: 14, fontWeight: FontWeight.w700,
      color: MedilinkColors.primary, letterSpacing: 0.3,
    )),
  ]);

  Widget _inputField({
    required TextEditingController controller,
    required String label, required String hint, required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    int maxLines = 1,
    bool optional = false,
  }) => TextFormField(
    controller: controller,
    obscureText: obscureText,
    keyboardType: keyboardType,
    inputFormatters: inputFormatters,
    maxLines: maxLines,
    validator: validator,
    autovalidateMode: AutovalidateMode.onUserInteraction, // NEW: live feedback
    style: const TextStyle(color: MedilinkColors.textMain, fontSize: 15),
    decoration: InputDecoration(
      labelText: optional ? '$label (optionnel)' : label,
      hintText: hint,
      prefixIcon: Icon(icon, color: MedilinkColors.primary, size: 20),
      suffixIcon: suffixIcon,
      filled: true, fillColor: MedilinkColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: const TextStyle(color: MedilinkColors.textSub, fontSize: 13),
      hintStyle: TextStyle(color: MedilinkColors.textSub.withValues(alpha: 0.6), fontSize: 13),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: MedilinkColors.stepIdle, width: 1.5)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: MedilinkColors.stepIdle, width: 1.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: MedilinkColors.primary, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: MedilinkColors.error, width: 1.5)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: MedilinkColors.error, width: 2)),
    ),
  );

  Widget _genderChip(String value, String label, IconData icon) {
    final isSelected = _gender == value;
    return Expanded(child: GestureDetector(
      onTap: () => setState(() => _gender = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? MedilinkColors.primary.withValues(alpha: 0.1)
              : MedilinkColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? MedilinkColors.primary : MedilinkColors.stepIdle,
            width: isSelected ? 2 : 1.5,
          ),
        ),
        child: Column(children: [
          Icon(icon,
            color: isSelected ? MedilinkColors.primary : MedilinkColors.textSub,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(
            fontSize: 12,
            color: isSelected ? MedilinkColors.primary : MedilinkColors.textSub,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          )),
        ]),
      ),
    ));
  }

  Widget _infoTip(IconData icon, String text) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: MedilinkColors.primaryLight.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: MedilinkColors.primary.withValues(alpha: 0.2)),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 18, color: MedilinkColors.primary),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: const TextStyle(
        fontSize: 12, color: MedilinkColors.primary, height: 1.5,
      ))),
    ]),
  );
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
  final bool isDanger;

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
    this.isDanger = false,
  });

  @override
  State<_TagInputCard> createState() => _TagInputCardState();
}

class _TagInputCardState extends State<_TagInputCard> {
  bool _showSuggestions = false;
  String _query = '';

  // NEW: max tags to avoid an unbounded, unusable list of entries
  static const int _maxTags = 20;
  static const int _maxTagLength = 60;

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

    // NEW: basic guardrails with visible feedback instead of failing silently
    if (widget.tags.length >= _maxTags) {
      _showFieldError('Maximum $_maxTags éléments atteint.');
      return;
    }
    if (trimmed.length > _maxTagLength) {
      _showFieldError('Ce texte est trop long (max $_maxTagLength caractères).');
      return;
    }
    if (widget.tags.any((t) => t.toLowerCase() == trimmed.toLowerCase())) {
      _showFieldError('« $trimmed » est déjà dans la liste.');
      widget.controller.clear();
      setState(() { _query = ''; _showSuggestions = false; });
      return;
    }

    widget.onAdd(trimmed);
    widget.controller.clear();
    setState(() { _query = ''; _showSuggestions = false; });
  }

  void _showFieldError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: widget.tagColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
  }

  @override
  Widget build(BuildContext context) {
    // Card border colour: danger uses allergyTag tint, else primary tint
    final borderColor = widget.isDanger
        ? MedilinkColors.allergyTag.withValues(alpha: 0.25)
        : MedilinkColors.primary.withValues(alpha: 0.15);
    final headerIconColor = widget.isDanger
        ? MedilinkColors.allergyTag
        : MedilinkColors.primary;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: MedilinkColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10, offset: const Offset(0, 4),
        )],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Header ──────────────────────────────────────────────────────
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
                fontSize: 11.5, color: MedilinkColors.textSub,
              )),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: MedilinkColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Optionnel', style: TextStyle(
                fontSize: 10, color: MedilinkColors.accent, fontWeight: FontWeight.w600,
              )),
            ),
          ]),
        ),

        // ── Tags display ─────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: widget.tags.isEmpty
              ? Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: MedilinkColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: MedilinkColors.stepIdle, style: BorderStyle.solid),
            ),
            child: Column(children: [
              Icon(widget.icon,
                  size: 22, color: MedilinkColors.textSub.withValues(alpha: 0.4)),
              const SizedBox(height: 6),
              Text(widget.emptyHint, style: TextStyle(
                fontSize: 12.5,
                color: MedilinkColors.textSub.withValues(alpha: 0.6),
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

        // ── Input row ────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: widget.controller,
                style: const TextStyle(
                    color: MedilinkColors.textMain, fontSize: 14),
                textInputAction: TextInputAction.done, // NEW: clearer keyboard action
                decoration: InputDecoration(
                  hintText: widget.placeholder,
                  hintStyle: TextStyle(
                      color: MedilinkColors.textSub.withValues(alpha: 0.6),
                      fontSize: 13),
                  prefixIcon: Icon(Icons.add_circle_outline,
                      size: 18, color: MedilinkColors.primary),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                  filled: true,
                  fillColor: MedilinkColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: MedilinkColors.stepIdle, width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: MedilinkColors.stepIdle, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                        color: widget.tagColor, width: 2),
                  ),
                ),
                onChanged: (v) => setState(() {
                  _query = v;
                  _showSuggestions = v.isNotEmpty;
                }),
                onSubmitted: _addTag,
                onTap: () => setState(() => _showSuggestions = true),
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

        // ── Suggestions chips ─────────────────────────────────────────────
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
                      color: MedilinkColors.textSub.withValues(alpha: 0.7),
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
                                color: widget.tagColor.withValues(alpha: 0.3)),
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

        // ── Footer: count ─────────────────────────────────────────────────
        if (widget.tags.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              color: widget.tagBg,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(children: [
              Icon(Icons.check_circle_outline, size: 14, color: widget.tagColor),
              const SizedBox(width: 6),
              Text(
                '${widget.tags.length} élément${widget.tags.length > 1 ? 's' : ''} renseigné${widget.tags.length > 1 ? 's' : ''}'
                    '${widget.tags.length >= _maxTags ? ' (maximum atteint)' : ''}',
                style: TextStyle(
                  fontSize: 12, color: widget.tagColor, fontWeight: FontWeight.w600,
                ),
              ),
            ]),
          ),
      ]),
    );
  }
}

// ─── Individual medical tag ───────────────────────────────────────────────────

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
        border: Border.all(color: color.withValues(alpha: 0.4)),
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
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.close, size: 11, color: color),
          ),
        ),
      ]),
    );
  }
}