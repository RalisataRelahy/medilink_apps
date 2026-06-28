import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/views/providers/auth_provider.dart';
import '../widgets/app_bottom_nav_bar.dart';
import 'package:go_router/go_router.dart';

class MainLayout extends ConsumerWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final user = authState.user;
    if (user == null) {
      // Normalement géré par le router redirect, mais au cas où
      return const Scaffold(
        body: Center(child: Text("Utilisateur non connecté")),
      );
    }

    final location = GoRouterState.of(context).uri.toString();

    return Scaffold(
      body: child,
      bottomNavigationBar: AppBottomNav(
        role: user.role,
        currentLocation: location,
      ),
    );
  }
}
