import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medilink/core/theme/app_colors.dart';
import '../enums/user_role.dart';
import 'package:go_router/go_router.dart';
import '../navigations/nav_config.dart';

// ── iOS-style tokens ─────────────────────────────────────────────────────
// Matches Apple's system tab bar look: translucent blur, hairline separator,
// system blue accent, small bold-on-select labels.
class _IOSNavColors {
  static const activeBlue = Color(0xFF007AFF); // iOS system blue
  static const inactiveGray = Color(0xFF2D2D32); // iOS system gray
  static const hairline = Color(0xFF000000);
}

class AppBottomNav extends StatelessWidget {
  final UserRole role;
  final String currentLocation;

  const AppBottomNav({
    super.key,
    required this.role,
    required this.currentLocation,
  });

  List<String> _routesFor(UserRole role) =>
      role == UserRole.doctor ? NavConfig.doctorTabs : NavConfig.patientTabs;

  // Matches the current location against each tab's route as a prefix, not
  // an exact string, so nested/sub-routes still highlight the right tab.
  int _resolveIndex(List<String> routes) {
    final exact = routes.indexOf(currentLocation);
    if (exact >= 0) return exact;

    final candidates = List<MapEntry<int, String>>.generate(
      routes.length, (i) => MapEntry(i, routes[i]),
    )..sort((a, b) => b.value.length.compareTo(a.value.length));

    for (final c in candidates) {
      if (currentLocation.startsWith(c.value)) return c.key;
    }
    return 0;
  }

  void _onTap(BuildContext context, int i, List<String> routes) {
    if (i < 0 || i >= routes.length) return;
    final currentIndex = _resolveIndex(routes);
    if (i == currentIndex) return;
    HapticFeedback.selectionClick();
    context.go(routes[i]);
  }

  @override
  Widget build(BuildContext context) {
    final routes = _routesFor(role);
    final isDoctor = role == UserRole.doctor;
    final index = _resolveIndex(routes);
    final bottomInset = MediaQuery.of(context).padding.bottom; // home indicator area

    final items = [
      _NavItemData(
        icon: isDoctor ? Icons.medical_services_outlined : Icons.home_outlined,
        selectedIcon: isDoctor ? Icons.medical_services_rounded : Icons.home_rounded,
        label: 'Accueil',
      ),
      const _NavItemData(
        icon: Icons.calendar_month_outlined,
        selectedIcon: Icons.calendar_month_rounded,
        label: 'Rendez-vous',
      ),
      _NavItemData(
        icon: Icons.folder_outlined,
        selectedIcon: Icons.folder_rounded,
        label: isDoctor ? 'Dossiers patients' : 'Mon dossier',
      ),
      const _NavItemData(
        icon: Icons.person_outline_rounded,
        selectedIcon: Icons.person_rounded,
        label: 'Profil',
      ),
    ];

    // ClipRect + BackdropFilter = the frosted-glass effect used by every
    // native iOS tab bar / nav bar.
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: EdgeInsets.only(bottom: bottomInset > 0 ? bottomInset : 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(
              top: BorderSide(color: _IOSNavColors.hairline, width: 0.3), // iOS hairline
            ),
          ),
          child: SizedBox(
            height: 80, // standard iOS tab bar content height
            child: Row(
              children: List.generate(items.length, (i) {
                return Expanded(
                  child: _NavItem(
                    data: items[i],
                    isSelected: i == index,
                    onTap: () => _onTap(context, i, routes),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const _NavItemData({required this.icon, required this.selectedIcon, required this.label});
}

// Stateful so we can give each tab a small "press" bounce, matching the
// tactile feel of native iOS controls (which never use Material ripples).
class _NavItem extends StatefulWidget {
  final _NavItemData data;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.data,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isSelected
        ? _IOSNavColors.activeBlue
        : _IOSNavColors.inactiveGray;

    return GestureDetector(
      behavior: HitTestBehavior.opaque, // no Material splash/ripple, iOS has none
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.88 : 1.0, // subtle bounce, like native iOS tabs
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: Icon(
                widget.isSelected ? widget.data.selectedIcon : widget.data.icon,
                key: ValueKey(widget.isSelected),
                size: 25,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.data.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                height: 1.1,
                letterSpacing: -0.1,
                fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}