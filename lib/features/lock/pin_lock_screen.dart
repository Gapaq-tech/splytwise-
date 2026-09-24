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
  String _entered = '';
  bool _shake = false;

  void _onDigit(String digit) {
    if (_entered.length >= 4) return;
    setState(() => _entered += digit);
    if (_entered.length == 4) _verify();
  }

  void _onBackspace() {
    if (_entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  Future<void> _verify() async {
    final settings = ref.read(settingsProvider).valueOrNull;
    final storedHash = settings?.pinHash;
    final matches = storedHash != null && hashPin(_entered) == storedHash;

    if (matches) {
      ref.read(unlockedProvider.notifier).state = true;
      if (mounted) context.go('/home');
      return;
    }

    setState(() => _shake = true);
    await Future.delayed(const Duration(milliseconds: 320));
    if (!mounted) return;
    setState(() {
      _shake = false;
      _entered = '';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Wrong PIN, try again')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SplytPalette.lightBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),
              const Icon(Icons.lock_outline_rounded, color: SplytPalette.gold, size: 40),
              const SizedBox(height: 18),
              const Text(
                'Enter your PIN',
                style: TextStyle(color: SplytPalette.lightInk, fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 28),
              AnimatedSlide(
                offset: _shake ? const Offset(0.02, 0) : Offset.zero,
                duration: const Duration(milliseconds: 60),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (i) {
                      final filled = i < _entered.length;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: filled ? SplytPalette.gold : Colors.transparent,
                        border: Border.all(color: SplytPalette.gold, width: 1.5),
                      ),
                    );
                  }),
                ),
              ),
              const Spacer(flex: 3),
              _Keypad(onDigit: _onDigit, onBackspace: _onBackspace),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({required this.onDigit, required this.onBackspace});

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
    ];
    return Column(
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [for (final d in row) _KeypadButton(label: d, onTap: () => onDigit(d))],
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 68, height: 68),
              _KeypadButton(label: '0', onTap: () => onDigit('0')),
              SizedBox(
                width: 68,
                height: 68,
                child: IconButton(
                  onPressed: onBackspace,
                  icon: const Icon(Icons.backspace_outlined, color: SplytPalette.mute, size: 22),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _KeypadButton extends StatelessWidget {
  const _KeypadButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.06),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 68,
          height: 68,
          child: Center(
            child: Text(
              label,
              style: const TextStyle(color: SplytPalette.lightInk, fontSize: 24, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}