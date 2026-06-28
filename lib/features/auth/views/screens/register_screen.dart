import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/enums/user_role.dart';
import '../../data/models/user_model.dart';
import '../providers/auth_provider.dart';

// ── MediLink Design Tokens ──────────────────────────────────────────────────
const _navy      = Color(0xFF0F172A);
const _blue      = Color(0xFF2563EB);
const _mint      = Color(0xFF10B981);  // vitality accent
const _surface   = Color(0xFFFFFFFF);
const _bgSlate   = Color(0xFFF1F5F9);
const _slate400  = Color(0xFF94A3B8);
const _slate600  = Color(0xFF475569);
const _slate200  = Color(0xFFE2E8F0);
const _errorRed  = Color(0xFFEF4444);
const _warningAmber = Color(0xFFF59E0B);

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl  = TextEditingController();
  final _lastNameCtrl   = TextEditingController();
  final _phoneCtrl      = TextEditingController();
  final _addressCtrl    = TextEditingController();
  final _emailCtrl      = TextEditingController();
  final _passCtrl       = TextEditingController();
  final _confirmCtrl    = TextEditingController();

  bool _hidePass    = true;
  bool _hideConfirm = true;
  UserRole _role    = UserRole.patient;
  int _passStrength = 0; // 0-4
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    _passCtrl.addListener(_updatePasswordStrength);
  }

  void _updatePasswordStrength() {
    final p = _passCtrl.text;
    int score = 0;
    if (p.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(p)) score++;
    if (RegExp(r'[0-9]').hasMatch(p)) score++;
    if (RegExp(r'[!@#\$&*~%^()_\-+=\[\]{}|;:,.<>?]').hasMatch(p)) score++;
    setState(() => _passStrength = score);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final newUser = UserModel(
      id: '',
      email: _emailCtrl.text.trim(),
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      role: _role,
    );
    context.push('/registerPatient', extra: {
      'user': newUser.toJson(),
      'password': _passCtrl.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final size      = MediaQuery.of(context).size;
    final isWide    = size.width >= 800;

    return Scaffold(
      backgroundColor: _bgSlate,
      body: isWide
          ? _WideLayout(
        fadeAnim : _fadeAnim,
        role     : _role,
        onRoleTap: (r) => setState(() => _role = r),
        formKey  : _formKey,
        firstNameCtrl : _firstNameCtrl,
        lastNameCtrl  : _lastNameCtrl,
        phoneCtrl     : _phoneCtrl,
        addressCtrl   : _addressCtrl,
        emailCtrl     : _emailCtrl,
        passCtrl      : _passCtrl,
        confirmCtrl   : _confirmCtrl,
        hidePass      : _hidePass,
        hideConfirm   : _hideConfirm,
        passStrength  : _passStrength,
        isLoading     : authState.isLoading,
        onTogglePass  : () => setState(() => _hidePass = !_hidePass),
        onToggleConfirm: () => setState(() => _hideConfirm = !_hideConfirm),
        onSubmit      : _submit,
      )
          : _NarrowLayout(
        fadeAnim : _fadeAnim,
        role     : _role,
        onRoleTap: (r) => setState(() => _role = r),
        formKey  : _formKey,
        firstNameCtrl : _firstNameCtrl,
        lastNameCtrl  : _lastNameCtrl,
        phoneCtrl     : _phoneCtrl,
        addressCtrl   : _addressCtrl,
        emailCtrl     : _emailCtrl,
        passCtrl      : _passCtrl,
        confirmCtrl   : _confirmCtrl,
        hidePass      : _hidePass,
        hideConfirm   : _hideConfirm,
        passStrength  : _passStrength,
        isLoading     : authState.isLoading,
        onTogglePass  : () => setState(() => _hidePass = !_hidePass),
        onToggleConfirm: () => setState(() => _hideConfirm = !_hideConfirm),
        onSubmit      : _submit,
      ),
    );
  }
}

// ── SHARED FORM CONTENT ─────────────────────────────────────────────────────
class _FormContent extends StatelessWidget {
  final UserRole role;
  final ValueChanged<UserRole> onRoleTap;
  final GlobalKey<FormState> formKey;
  final TextEditingController firstNameCtrl, lastNameCtrl, phoneCtrl,
      addressCtrl, emailCtrl, passCtrl, confirmCtrl;
  final bool hidePass, hideConfirm, isLoading;
  final int passStrength;
  final VoidCallback onTogglePass, onToggleConfirm, onSubmit;

  const _FormContent({
    required this.role,
    required this.onRoleTap,
    required this.formKey,
    required this.firstNameCtrl,
    required this.lastNameCtrl,
    required this.phoneCtrl,
    required this.addressCtrl,
    required this.emailCtrl,
    required this.passCtrl,
    required this.confirmCtrl,
    required this.hidePass,
    required this.hideConfirm,
    required this.passStrength,
    required this.isLoading,
    required this.onTogglePass,
    required this.onToggleConfirm,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Role selector
          const _SectionLabel('Je m\'inscris en tant que'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _RoleChip(
                label: 'Patient',
                icon: Icons.person_outline_rounded,
                description: 'Consulter des médecins',
                selected: role == UserRole.patient,
                onTap: () => onRoleTap(UserRole.patient),
              )),
              const SizedBox(width: 12),
              Expanded(child: _RoleChip(
                label: 'Médecin',
                icon: Icons.medical_services_outlined,
                description: 'Gérer mes consultations',
                selected: role == UserRole.doctor,
                onTap: () => onRoleTap(UserRole.doctor),
              )),
            ],
          ),
          const SizedBox(height: 22),

          // Name row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _Field(
                controller: firstNameCtrl,
                label: 'Prénom',
                hint: 'Jean',
                icon: Icons.badge_outlined,
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Requis' : null,
              )),
              const SizedBox(width: 12),
              Expanded(child: _Field(
                controller: lastNameCtrl,
                label: 'Nom',
                hint: 'Dupont',
                icon: Icons.badge_outlined,
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Requis' : null,
              )),
            ],
          ),
          const SizedBox(height: 16),

          _Field(
            controller: phoneCtrl,
            label: 'Téléphone',
            hint: '+261 34 00 000 00',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'Numéro requis' : null,
          ),
          const SizedBox(height: 16),

          _Field(
            controller: addressCtrl,
            label: 'Adresse',
            hint: 'Lot II M 40 Antananarivo',
            icon: Icons.location_on_outlined,
            keyboardType: TextInputType.streetAddress,
            validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'Adresse requise' : null,
          ),
          const SizedBox(height: 16),

          _Field(
            controller: emailCtrl,
            label: 'Email',
            hint: 'jean.dupont@exemple.mg',
            icon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email requis';
              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) {
                return 'Format invalide';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          _Field(
            controller: passCtrl,
            label: 'Mot de passe',
            hint: '••••••••',
            icon: Icons.lock_outline_rounded,
            obscure: hidePass,
            onToggle: onTogglePass,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Mot de passe requis';
              if (v.length < 6) return 'Minimum 6 caractères';
              return null;
            },
          ),
          const SizedBox(height: 8),
          _PasswordStrengthBar(strength: passStrength),
          const SizedBox(height: 16),

          _Field(
            controller: confirmCtrl,
            label: 'Confirmer le mot de passe',
            hint: '••••••••',
            icon: Icons.lock_outline_rounded,
            obscure: hideConfirm,
            onToggle: onToggleConfirm,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Confirmation requise';
              if (v != passCtrl.text) return 'Les mots de passe diffèrent';
              return null;
            },
          ),
          const SizedBox(height: 28),

          // Submit
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              onPressed: isLoading ? null : onSubmit,
              child: isLoading
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
                  : const Text(
                'Créer mon compte',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Login link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Déjà inscrit ? ',
                style: TextStyle(fontSize: 14, color: _slate600),
              ),
              GestureDetector(
                onTap: () => context.go('/login'),
                child: const Text(
                  'Se connecter',
                  style: TextStyle(
                    fontSize: 14,
                    color: _blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── WIDE LAYOUT (≥800 px) ────────────────────────────────────────────────────
class _WideLayout extends StatelessWidget {
  final Animation<double> fadeAnim;
  final UserRole role;
  final ValueChanged<UserRole> onRoleTap;
  final GlobalKey<FormState> formKey;
  final TextEditingController firstNameCtrl, lastNameCtrl, phoneCtrl,
      addressCtrl, emailCtrl, passCtrl, confirmCtrl;
  final bool hidePass, hideConfirm, isLoading;
  final int passStrength;
  final VoidCallback onTogglePass, onToggleConfirm, onSubmit;

  const _WideLayout({
    required this.fadeAnim,
    required this.role,
    required this.onRoleTap,
    required this.formKey,
    required this.firstNameCtrl,
    required this.lastNameCtrl,
    required this.phoneCtrl,
    required this.addressCtrl,
    required this.emailCtrl,
    required this.passCtrl,
    required this.confirmCtrl,
    required this.hidePass,
    required this.hideConfirm,
    required this.passStrength,
    required this.isLoading,
    required this.onTogglePass,
    required this.onToggleConfirm,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left brand panel
        Expanded(
          flex: 5,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF1D4ED8), Color(0xFF0EA5E9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.3), width: 1),
                          ),
                          child: const Icon(Icons.local_hospital_rounded,
                              color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'MediLink',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Headline
                    const Text(
                      'Votre santé,\nnos priorités.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Rejoignez des milliers de patients et médecins qui font confiance à MediLink pour simplifier leurs soins.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.80),
                        fontSize: 15,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Trust badges
                    ...[
                      (Icons.verified_outlined,   'Données sécurisées et chiffrées'),
                      (Icons.schedule_outlined,   'Rendez-vous en quelques clics'),
                      (Icons.support_agent_outlined, 'Support disponible 24 h / 7 j'),
                    ].map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: _mint.withOpacity(0.20),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(e.$1,
                                color: const Color(0xFF6EE7B7), size: 16),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            e.$2,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.88),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )),
                    const Spacer(),
                    Text(
                      '© 2025 MediLink Madagascar',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.40),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Right form panel
        Expanded(
          flex: 6,
          child: FadeTransition(
            opacity: fadeAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
              child: SafeArea(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Créer un compte',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: _navy,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Quelques informations pour commencer.',
                        style: TextStyle(fontSize: 15, color: _slate600),
                      ),
                      const SizedBox(height: 32),
                      _FormContent(
                        role: role,
                        onRoleTap: onRoleTap,
                        formKey: formKey,
                        firstNameCtrl: firstNameCtrl,
                        lastNameCtrl: lastNameCtrl,
                        phoneCtrl: phoneCtrl,
                        addressCtrl: addressCtrl,
                        emailCtrl: emailCtrl,
                        passCtrl: passCtrl,
                        confirmCtrl: confirmCtrl,
                        hidePass: hidePass,
                        hideConfirm: hideConfirm,
                        passStrength: passStrength,
                        isLoading: isLoading,
                        onTogglePass: onTogglePass,
                        onToggleConfirm: onToggleConfirm,
                        onSubmit: onSubmit,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── NARROW LAYOUT (<800 px) ──────────────────────────────────────────────────
class _NarrowLayout extends StatelessWidget {
  final Animation<double> fadeAnim;
  final UserRole role;
  final ValueChanged<UserRole> onRoleTap;
  final GlobalKey<FormState> formKey;
  final TextEditingController firstNameCtrl, lastNameCtrl, phoneCtrl,
      addressCtrl, emailCtrl, passCtrl, confirmCtrl;
  final bool hidePass, hideConfirm, isLoading;
  final int passStrength;
  final VoidCallback onTogglePass, onToggleConfirm, onSubmit;

  const _NarrowLayout({
    required this.fadeAnim,
    required this.role,
    required this.onRoleTap,
    required this.formKey,
    required this.firstNameCtrl,
    required this.lastNameCtrl,
    required this.phoneCtrl,
    required this.addressCtrl,
    required this.emailCtrl,
    required this.passCtrl,
    required this.confirmCtrl,
    required this.hidePass,
    required this.hideConfirm,
    required this.passStrength,
    required this.isLoading,
    required this.onTogglePass,
    required this.onToggleConfirm,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnim,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              height: 160,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF38BDF8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.3), width: 1.5),
                      ),
                      child: const Icon(Icons.local_hospital_rounded,
                          color: Colors.white, size: 26),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'MediLink',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Votre santé, nos priorités.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Créer un compte',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: _navy,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Quelques informations pour commencer.',
                    style: TextStyle(fontSize: 14, color: _slate600),
                  ),
                  const SizedBox(height: 24),
                  _FormContent(
                    role: role,
                    onRoleTap: onRoleTap,
                    formKey: formKey,
                    firstNameCtrl: firstNameCtrl,
                    lastNameCtrl: lastNameCtrl,
                    phoneCtrl: phoneCtrl,
                    addressCtrl: addressCtrl,
                    emailCtrl: emailCtrl,
                    passCtrl: passCtrl,
                    confirmCtrl: confirmCtrl,
                    hidePass: hidePass,
                    hideConfirm: hideConfirm,
                    passStrength: passStrength,
                    isLoading: isLoading,
                    onTogglePass: onTogglePass,
                    onToggleConfirm: onToggleConfirm,
                    onSubmit: onSubmit,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── ROLE CHIP ────────────────────────────────────────────────────────────────
class _RoleChip extends StatelessWidget {
  final String label, description;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RoleChip({
    required this.label,
    required this.description,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEFF6FF) : _surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _blue : _slate200,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
            BoxShadow(
              color: _blue.withOpacity(0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: selected
                        ? _blue.withOpacity(0.12)
                        : _slate200.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon,
                      color: selected ? _blue : _slate600, size: 17),
                ),
                const Spacer(),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: selected ? 1 : 0,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: _blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check,
                        color: Colors.white, size: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: selected ? _blue : _navy,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              description,
              style: const TextStyle(fontSize: 11.5, color: _slate600),
            ),
          ],
        ),
      ),
    );
  }
}

// ── FIELD ────────────────────────────────────────────────────────────────────
class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint;
  final IconData icon;
  final TextInputType keyboardType;
  final bool obscure;
  final VoidCallback? onToggle;
  final String? Function(String?) validator;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.obscure = false,
    this.onToggle,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _navy,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscure,
          validator: validator,
          style: const TextStyle(fontSize: 14, color: _navy),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: _slate400, fontSize: 14),
            prefixIcon: Icon(icon, color: _slate400, size: 19),
            suffixIcon: onToggle != null
                ? IconButton(
              icon: Icon(
                obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: _slate400,
                size: 19,
              ),
              onPressed: onToggle,
            )
                : null,
            contentPadding:
            const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _slate200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _slate200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _blue, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _errorRed),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _errorRed, width: 1.5),
            ),
            errorStyle: const TextStyle(fontSize: 12, color: _errorRed),
          ),
        ),
      ],
    );
  }
}

// ── PASSWORD STRENGTH BAR ────────────────────────────────────────────────────
class _PasswordStrengthBar extends StatelessWidget {
  final int strength; // 0–4

  const _PasswordStrengthBar({required this.strength});

  Color get _barColor {
    if (strength <= 1) return _errorRed;
    if (strength == 2) return _warningAmber;
    if (strength == 3) return const Color(0xFF84CC16); // lime
    return _mint;
  }

  String get _label {
    if (strength == 0) return '';
    if (strength == 1) return 'Très faible';
    if (strength == 2) return 'Faible';
    if (strength == 3) return 'Bon';
    return 'Excellent';
  }

  @override
  Widget build(BuildContext context) {
    if (strength == 0) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (i) {
            final filled = i < strength;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i < 3 ? 4 : 0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 4,
                  decoration: BoxDecoration(
                    color: filled ? _barColor : _slate200,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 5),
        Text(
          _label,
          style: TextStyle(fontSize: 11.5, color: _barColor, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

// ── SECTION LABEL ────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: _navy,
      ),
    );
  }
}