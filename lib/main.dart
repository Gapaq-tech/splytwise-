import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/app_providers.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: SplytwiseApp()));
}

class SplytwiseApp extends ConsumerWidget {
  const SplytwiseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appBootstrapProvider);
    final router = ref.watch(routerProvider);
    final settings = ref.watch(settingsProvider).valueOrNull;
    final themeMode = switch (settings?.themeMode) {
      'dark' => ThemeMode.light,
      'light' => ThemeMode.light,
      'system' => ThemeMode.light,
      _ => ThemeMode.light,
    };

    return MaterialApp.router(
      title: 'Splytwise',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
