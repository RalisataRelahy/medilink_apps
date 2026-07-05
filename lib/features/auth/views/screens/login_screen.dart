import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medilink/core/theme/app_colors.dart';
import '../../../../app/router/app_router.dart';
import '../providers/auth_provider.dart';

// NEW: simple RFC-lite email pattern — enough to reject obviously malformed
// input client-side (no request wasted) without being overly strict about
// exotic-but-valid addresses.
final RegExp _emailPattern = RegExp(r'^[\w\.\-\+]+@[\w\-]+\.[a-zA-Z]{2,}$');

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = true;
  bool _obscurePassword = true;

  // NEW: dedicated form key so email/password get real field-level
  // validation instead of a single generic "fill everything" snackbar.
  final _formKey = GlobalKey<FormState>();

  // MediLink brand colors
  static const Color primaryBlue = AppColors.headerBlueDark;
  static const Color headerBlueDark = AppColors.headerBlueDark;
  static const Color headerBlueLight = AppColors.headerBlueLight;
  static const Color linkBlue = AppColors.headerBlueDark;
  static const Color cardBg = AppColors.surface;
  static const Color bgGray = AppColors.background;
  static const Color textDark = AppColors.textDark;
  static const Color textGray = AppColors.textGrey;
  static const Color borderColor = AppColors.inactiveStep;
  static const Color checkboxBlue = AppColors.headerBlueDark;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // NEW: maps whatever the backend/auth SDK throws (Firebase-style error
  // codes, generic exceptions, etc.) into a short, safe French message.
  // Deliberately generic for wrong-password/user-not-found so the app
  // never reveals whether a given email is registered (avoids account
  // enumeration) while still being specific about a malformed email or a
  // connectivity problem.
  String _friendlyAuthError(Object error) {
    final msg = error.toString().toLowerCase();

    if (msg.contains('invalid-email')) {
      return 'Adresse email invalide.';
    }
    if (msg.contains('wrong-password') ||
        msg.contains('user-not-found') ||
        msg.contains('invalid-credential') ||
        msg.contains('invalid credential')) {
      return 'Email ou mot de passe incorrect.';
    }
    if (msg.contains('user-disabled')) {
      return 'Ce compte a été désactivé. Contactez le support.';
    }
    if (msg.contains('too-many-requests')) {
      return 'Trop de tentatives. Veuillez réessayer plus tard.';
    }
    if (msg.contains('network') || msg.contains('socket') || msg.contains('timeout')) {
      return 'Impossible de contacter le serveur. Vérifiez votre connexion internet.';
    }
    return 'Une erreur est survenue. Veuillez réessayer.';
  }

  // NEW: client-side email format validator — rejects malformed emails
  // before any network call is made.
  String? _validateEmail(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Veuillez saisir votre email';
    if (!_emailPattern.hasMatch(trimmed)) return 'Adresse email invalide';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Veuillez saisir votre mot de passe';
    return null;
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();

    // NEW: validate locally first — if the email is malformed or a field
    // is empty, stop here and never touch the network.
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      await ref.read(authProvider.notifier).signIn(email, password);
    } catch (error) {
      // NEW: catch anything the notifier itself doesn't already turn into
      // authState.error, so the user never sees a silent failure.
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(_friendlyAuthError(error)),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final size = MediaQuery.of(context).size;

    // Breakpoints : on gère explicitement les très petits écrans (<360px)
    final isWide = size.width > 600;
    final isNarrow = size.width < 360;

    // Valeurs adaptatives en fonction de la largeur réelle
    final horizontalPagePadding = isWide ? 0.0 : (isNarrow ? 12.0 : 20.0);
    final cardHorizontalPadding = isNarrow ? 18.0 : 28.0;
    final cardTopPadding = isNarrow ? 20.0 : 28.0;
    final cardBottomPadding = isNarrow ? 16.0 : 24.0;
    final titleFontSize = isWide ? 26.0 : (isNarrow ? 19.0 : 22.0);
    final fieldFontSize = isNarrow ? 13.0 : 14.0;
    final fieldVerticalPadding = isNarrow ? 11.0 : 13.0;

    return Scaffold(
      backgroundColor: bgGray,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPagePadding,
              vertical: isNarrow ? 16 : 24,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isWide ? 420 : double.infinity,
              ),
              child: Card(
                color: cardBg,
                elevation: 8,
                shadowColor: Colors.black.withValues(alpha: 0.12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isNarrow ? 16 : 20),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Header gradient band ──
                    _buildHeader(isNarrow: isNarrow),

                    // ── Form body ──
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        cardHorizontalPadding,
                        cardTopPadding,
                        cardHorizontalPadding,
                        cardBottomPadding,
                      ),
                      // NEW: Form wraps the fields so validators run
                      // together on submit and show inline errors.
                      child: Form(
                        key: _formKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title
                            Center(
                              child: Text(
                                'Se connecter',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: titleFontSize,
                                  fontWeight: FontWeight.w700,
                                  color: primaryBlue,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Center(
                              child: Text(
                                'Accédez à votre espace personnel',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: isNarrow ? 12.5 : 14,
                                  color: textGray,
                                ),
                              ),
                            ),
                            SizedBox(height: isNarrow ? 22 : 28),

                            // Email field
                            _buildLabel('Email', isNarrow: isNarrow),
                            const SizedBox(height: 6),
                            _buildTextField(
                              controller: _emailController,
                              hint: 'exemple@medilink.mg',
                              keyboardType: TextInputType.emailAddress,
                              fontSize: fieldFontSize,
                              verticalPadding: fieldVerticalPadding,
                              validator: _validateEmail, // NEW
                            ),
                            SizedBox(height: isNarrow ? 14 : 18),

                            // Password field
                            _buildLabel('Mot de passe', isNarrow: isNarrow),
                            const SizedBox(height: 6),
                            _buildPasswordField(
                              fontSize: fieldFontSize,
                              verticalPadding: fieldVerticalPadding,
                            ),
                            const SizedBox(height: 16),

                            // Remember me + Forgot password
                            _buildRememberRow(isNarrow: isNarrow),
                            SizedBox(height: isNarrow ? 22 : 28),

                            // Login button or loader
                            if (authState.isLoading)
                              const Center(child: CircularProgressIndicator())
                            else
                              _buildLoginButton(isNarrow: isNarrow),

                            // NEW: friendlier error card instead of raw
                            // "Erreur: <exception>" text.
                            if (authState.error != null && !authState.isLoading)
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.error_outline_rounded,
                                          size: 18, color: AppColors.error),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _friendlyAuthError(authState.error!),
                                          style: const TextStyle(
                                            color: AppColors.error, fontSize: 13, height: 1.3,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            SizedBox(height: isNarrow ? 16 : 20),

                            // Sign up link
                            _buildSignupRow(isNarrow: isNarrow),
                          ],
                        ),
                      ),
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

  // ── Header with gradient + logos ──
  // Sur très petit écran : logos plus petits + Flexible/FittedBox pour
  // empêcher tout overflow horizontal du Row.
  Widget _buildHeader({required bool isNarrow}) {
    final logoSize = isNarrow ? 60.0 : 72.0;
    final nlPaddingH = isNarrow ? 7.0 : 9.0;
    final nlPaddingV = isNarrow ? 2.0 : 4.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: isNarrow ? 20 : 28,
        horizontal: isNarrow ? 12 : 20,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [headerBlueDark, headerBlueLight],
        ),
      ),
      child: Column(
        children: [
          // Logos row — Flexible + FittedBox évitent l'overflow sur <360px
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // MediLink globe logo placeholder
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SizedBox(
                    width: logoSize,
                    height: logoSize,
                    child: Center(
                      child: Image.asset('assets/images/logoIspm.png'),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: isNarrow ? 6 : 10),
                child: Text(
                  '×',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: isNarrow ? 18 : 22,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
              //logo placeholder
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: nlPaddingH,
                      vertical: nlPaddingV,
                    ),
                    child: Image.asset('assets/images/logo.png'),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isNarrow ? 12 : 16),
          Text(
            'Bienvenue sur MediLink',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: isNarrow ? 17 : 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, {required bool isNarrow}) {
    return Text(
      text,
      style: TextStyle(
        fontSize: isNarrow ? 12.5 : 13.5,
        fontWeight: FontWeight.w600,
        color: textDark,
      ),
    );
  }

  // NEW: now a TextFormField with a validator, wired through the Form above.
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    required double fontSize,
    required double verticalPadding,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(fontSize: fontSize, color: textDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            color: textGray.withValues(alpha: 0.7), fontSize: fontSize),
        contentPadding: EdgeInsets.symmetric(
            horizontal: 14, vertical: verticalPadding),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderColor, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryBlue, width: 1.8),
        ),
        errorBorder: OutlineInputBorder( // NEW
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error, width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder( // NEW
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error, width: 1.8),
        ),
        errorStyle: const TextStyle(fontSize: 11.5), // NEW: keeps error text compact
      ),
    );
  }

  Widget _buildPasswordField({
    required double fontSize,
    required double verticalPadding,
  }) {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      validator: _validatePassword, // NEW
      style: TextStyle(fontSize: fontSize, color: textDark),
      decoration: InputDecoration(
        hintText: '••••••••',
        hintStyle: TextStyle(
            color: textGray.withValues(alpha: 0.7), fontSize: fontSize),
        contentPadding: EdgeInsets.symmetric(
            horizontal: 14, vertical: verticalPadding),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderColor, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryBlue, width: 1.8),
        ),
        errorBorder: OutlineInputBorder( // NEW
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error, width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder( // NEW
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error, width: 1.8),
        ),
        errorStyle: const TextStyle(fontSize: 11.5), // NEW
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            size: 20,
            color: textGray,
          ),
          onPressed: () =>
              setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
    );
  }

  // "Se souvenir de moi" + "Mot de passe oublié ?" : on utilise Wrap au lieu
  // d'un Row+Spacer. Wrap retourne automatiquement à la ligne dès que la
  // largeur ne suffit plus, ce qui élimine tout risque de RenderFlex
  // overflow, quelle que soit la largeur réelle de l'écran (pas seulement
  // sous le seuil isNarrow).
  Widget _buildRememberRow({required bool isNarrow}) {
    final checkboxItem = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: Checkbox(
            value: _rememberMe,
            onChanged: (val) => setState(() => _rememberMe = val ?? false),
            activeColor: checkboxBlue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            side: const BorderSide(color: borderColor, width: 1.5),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Se souvenir de moi',
          style: TextStyle(
              fontSize: isNarrow ? 12 : 13, color: textDark),
        ),
      ],
    );

    final forgotLink = GestureDetector(
      onTap: () {
        // TODO: forgot password
      },
      child: Text(
        'Mot de passe oublié ?',
        style: TextStyle(
          fontSize: isNarrow ? 12 : 13,
          color: linkBlue,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        checkboxItem,
        forgotLink,
      ],
    );
  }

  Widget _buildLoginButton({required bool isNarrow}) {
    return SizedBox(
      width: double.infinity,
      height: isNarrow ? 44 : 48,
      child: ElevatedButton(
        onPressed: _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: primaryBlue.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Se connecter',
          style: TextStyle(
            fontSize: isNarrow ? 14.5 : 15.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildSignupRow({required bool isNarrow}) {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        children: [
          Text(
            "Vous n'avez pas de compte ? ",
            style: TextStyle(
                fontSize: isNarrow ? 12.5 : 13.5, color: textGray),
          ),
          GestureDetector(
            onTap: () {
              context.push(AppRoutes.register);
            },
            child: Text(
              'Créer un compte',
              style: TextStyle(
                fontSize: isNarrow ? 12.5 : 13.5,
                color: linkBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}