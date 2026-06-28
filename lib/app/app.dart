import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medilink/app/router/app_router.dart';
import 'package:medilink/app/theme/theme_data.dart';
import 'package:medilink/core/providers/theme_provider.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final ThemeMode currentThemeMode=ref.watch(themeProvider);
    return MaterialApp.router(
      routerConfig: router,
      title: 'MediLink',
      debugShowCheckedModeBanner: false,
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: currentThemeMode,
    );
  }
}
