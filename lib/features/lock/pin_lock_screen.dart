import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_providers.dart';
import '../../router/app_router.dart';
import '../../services/pin_service.dart';
import '../../theme/tokens.dart';

class PinLockScreen extends ConsumerStatefulWidget {
  const PinLockScreen({super.key});

  @override
  ConsumerState<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends ConsumerState<PinLockScreen> {
  String _pin = '';
  String? _error;

  Future<void> _tap(String d) async {
    if (_pin.length >= 4) return;
    setState(() => _pin += d);
    if (_pin.length == 4) {
      final settings = ref.read(settingsProvider).valueOrNull;
      if (settings?.pinHash == hashPin(_pin)) {
        ref.read(unlockedProvider.notifier).state = true;
        if (mounted) context.go('/home');
      } else {
        setState(() {
          _error = 'Wrong PIN';
          _pin = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            const Icon(Icons.lock_rounded, color: SplytPalette.mint, size: 40),
            const SizedBox(height: 12),
            const Text('Unlock Splytwise', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < _pin.length ? SplytPalette.mint : SplytPalette.mute,
                  ),
                );
              }),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: SplytPalette.coral)),
            ],
            const Spacer(),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              childAspectRatio: 1.6,
              padding: const EdgeInsets.all(24),
              children: [
                for (final n in ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', '⌫'])
                  TextButton(
                    onPressed: n.isEmpty
                        ? null
                        : () {
                            if (n == '⌫') {
                              if (_pin.isNotEmpty) setState(() => _pin = _pin.substring(0, _pin.length - 1));
                            } else {
                              _tap(n);
                            }
                          },
                    child: Text(n, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
