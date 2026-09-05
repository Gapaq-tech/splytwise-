import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/app_providers.dart';
import '../router/app_router.dart';
import '../theme/tokens.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(appBootstrapProvider, (prev, next) async {
      if (!next.hasValue) return;
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      final settings = ref.read(settingsProvider).valueOrNull;
      if (settings == null) return;
      if (!settings.onboardingComplete) {
        context.go('/onboarding');
      } else if (settings.pinEnabled && !ref.read(unlockedProvider)) {
        context.go('/lock');
      } else {
        context.go('/home');
      }
    });

    return Scaffold(
      backgroundColor: SplytPalette.deep,
      body: Center(
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _c, curve: Curves.easeOut),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: SplytPalette.mint,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(Icons.bolt_rounded, size: 44, color: SplytPalette.deep),
              ),
              const SizedBox(height: 20),
              const Text(
                'Splytwise',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.8),
              ),
              const SizedBox(height: 8),
              Text(
                'Give every cedi a purpose',
                style: TextStyle(color: SplytPalette.mint.withOpacity(0.9), fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
