import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_router.dart';
import '../providers/auth_provider.dart';

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

  // MediLink brand colors
  static const Color primaryBlue = Color(0xFF2B7DE9);
  static const Color headerBlueDark = Color(0xFF1A5DC8);
  static const Color headerBlueLight = Color(0xFF4CA3F5);
  static const Color linkBlue = Color(0xFF2B7DE9);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color bgGray = Color(0xFFF0F4FA);
  static const Color textDark = Color(0xFF1A1A2E);
  static const Color textGray = Color(0xFF6B7280);
  static const Color borderColor = Color(0xFFD1D5DB);
  static const Color checkboxBlue = Color(0xFF2B7DE9);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    await ref.read(authProvider.notifier).signIn(email, password);
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
                shadowColor: Colors.black.withOpacity(0.12),
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

                          if (authState.error != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Text(
                                'Erreur: ${authState.error}',
                                style: const TextStyle(
                                    color: Colors.red, fontSize: 13),
                              ),
                            ),

                          SizedBox(height: isNarrow ? 16 : 20),

                          // Sign up link
                          _buildSignupRow(isNarrow: isNarrow),
                        ],
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
    final logoSize = isNarrow ? 40.0 : 52.0;
    final iconSize = isNarrow ? 22.0 : 28.0;
    final nlFontSize = isNarrow ? 15.0 : 18.0;
    final nlPaddingH = isNarrow ? 9.0 : 12.0;
    final nlPaddingV = isNarrow ? 4.0 : 6.0;

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
                  child: Container(
                    width: logoSize,
                    height: logoSize,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Icon(Icons.public,
                          color: Colors.white, size: iconSize),
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
                    color: Colors.white.withOpacity(0.85),
                    fontSize: isNarrow ? 18 : 22,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
              // NL logo placeholder
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: nlPaddingH,
                      vertical: nlPaddingV,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      'NL',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: nlFontSize,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    required double fontSize,
    required double verticalPadding,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(fontSize: fontSize, color: textDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            color: textGray.withOpacity(0.7), fontSize: fontSize),
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
      ),
    );
  }

  Widget _buildPasswordField({
    required double fontSize,
    required double verticalPadding,
  }) {
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: TextStyle(fontSize: fontSize, color: textDark),
      decoration: InputDecoration(
        hintText: '••••••••',
        hintStyle: TextStyle(
            color: textGray.withOpacity(0.7), fontSize: fontSize),
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
          shadowColor: primaryBlue.withOpacity(0.4),
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