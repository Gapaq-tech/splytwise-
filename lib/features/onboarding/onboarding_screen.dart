import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_providers.dart';
import '../../theme/tokens.dart';
import '../../widgets/ui_kit.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _page = PageController();
  final _name = TextEditingController();
  int _index = 0;
  final _picked = <String>{'food', 'bus', 'home'};

  static const _starters = [
    (key: 'food', name: 'Chop', icon: 'food', color: 0xFFFF5A36),
    (key: 'bus', name: 'Move around', icon: 'bus', color: 0xFF4D9FFF),
    (key: 'home', name: 'Home', icon: 'home', color: 0xFFFFC857),
    (key: 'fun', name: 'Vibe', icon: 'music', color: 0xFFB388FF),
    (key: 'save', name: 'Save first', icon: 'save', color: 0xFF00E5A8),
  ];

  @override
  void dispose() {
    _page.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final name = _name.text.trim().isEmpty ? 'You' : _name.text.trim();
    await ref.read(databaseProvider).completeOnboarding(
          name: name,
          starterCategories: [
            for (final item in _starters)
              if (_picked.contains(item.key))
                (name: item.name, icon: item.icon, color: item.color),
          ],
        );
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _page,
                onPageChanged: (i) => setState(() => _index = i),
                children: [
                  _Story(
                    title: 'Give every cedi a purpose',
                    body: 'Money lands. You decide where it goes — not a rigid template, not later. Right now.',
                    icon: Icons.bolt_rounded,
                  ),
                  _Story(
                    title: 'Split it your way',
                    body: 'Pick the categories and goals that matter for this inflow. Leftovers become Free money you can actually spend.',
                    icon: Icons.call_split_rounded,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: ListView(
                      children: [
                        const Text('What should we call you?',
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, height: 1.1)),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _name,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            hintText: 'Your name',
                            filled: true,
                            fillColor: SplytPalette.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        const Text('Start with a few buckets (optional)',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (final item in _starters)
                              ChoiceChip(
                                label: Text(item.name),
                                selected: _picked.contains(item.key),
                                onSelected: (_) => setState(() {
                                  if (_picked.contains(item.key)) {
                                    _picked.remove(item.key);
                                  } else {
                                    _picked.add(item.key);
                                  }
                                }),
                                selectedColor: SplytPalette.mint.withOpacity(0.25),
                                avatar: Icon(iconForKey(item.icon), size: 18),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _index == i ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _index == i ? SplytPalette.mint : SplytPalette.mute,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: SplytPalette.mint,
                        foregroundColor: SplytPalette.deep,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      onPressed: () {
                        if (_index < 2) {
                          _page.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
                        } else {
                          _finish();
                        }
                      },
                      child: Text(_index < 2 ? 'Continue' : "Let's split"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Story extends StatelessWidget {
  const _Story({required this.title, required this.body, required this.icon});

  final String title;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          GlyphBadge(iconKey: 'spark', color: SplytPalette.mint, size: 72),
          const SizedBox(height: 28),
          Text(title, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, height: 1.05)),
          const SizedBox(height: 16),
          Text(body, style: TextStyle(fontSize: 18, color: Colors.white.withOpacity(0.72), height: 1.4)),
          const Spacer(flex: 2),
          Icon(icon, color: SplytPalette.coral, size: 36),
        ],
      ),
    );
  }
}
