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
    (key: 'food', name: 'Chop', icon: 'food', color: 0xFFF5D6A6),
    (key: 'bus', name: 'Move around', icon: 'bus', color: 0xFFE9E4D6),
    (key: 'home', name: 'Home', icon: 'home', color: 0xFFF4E3B8),
    (key: 'fun', name: 'Vibe', icon: 'music', color: 0xFFEAEAEA),
    (key: 'save', name: 'Save first', icon: 'save', color: 0xFFE7E2D6),
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
      backgroundColor: const Color(0xFF0B3B3E),
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 20, 0),
                child: TextButton(
                  onPressed: _finish,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white70,
                  ),
                  child: const Text('Skip'),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _page,
                onPageChanged: (i) => setState(() => _index = i),
                children: [
                  _Story(
                    title: 'Give every money a purpose',
                    body:
                        'When money comes in, decide where it goes now. No guessing later and no letting it disappear.',
                    icon: Icons.bolt_rounded,
                  ),
                  _Story(
                    title: 'Split your money with clarity',
                    body:
                        'Use buckets, goals, and everyday categories so your money has a job before it gets spent.',
                    icon: Icons.call_split_rounded,
                  ),
                  _Story(
                    title: 'Keep momentum simple',
                    body:
                        'Track what is coming in, what is going out, and what you are building next without the stress.',
                    icon: Icons.timeline_rounded,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                    child: ListView(
                      children: [
                        const SizedBox(height: 24),
                        const Text('What should we call you?',
                            style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.1)),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _name,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.06),
                            hintText: 'Your name',
                            labelText: 'Your name',
                            labelStyle: const TextStyle(color: Colors.white70),
                            hintStyle: const TextStyle(color: Colors.white38),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Colors.white12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: SplytPalette.gold),
                            ),
                          ),
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 28),
                        const Text('Start with a few buckets (optional)',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                fontSize: 16)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (final item in _starters)
                              ChoiceChip(
                                label: Text(
                                  item.name,
                                  style: const TextStyle(
                                    color: Colors.black,
                                  ),
                                ),
                                selected: _picked.contains(item.key),
                                selectedColor: SplytPalette.gold,
                                backgroundColor: Colors.white.withOpacity(0.06),
                                onSelected: (_) => setState(() {
                                  if (_picked.contains(item.key)) {
                                    _picked.remove(item.key);
                                  } else {
                                    _picked.add(item.key);
                                  }
                                }),
                                avatar: Icon(
                                  iconForKey(item.icon),
                                  size: 18,
                                  color: Colors.black,
                                ),
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
                    children: List.generate(4, (i) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _index == i ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _index == i ? SplytPalette.gold : Colors.white24,
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
                        backgroundColor: SplytPalette.gold,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        if (_index < 3) {
                          _page.nextPage(
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeOut);
                        } else {
                          _finish();
                        }
                      },
                      child: Text(_index < 3 ? 'Continue' : "Let's split"),
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
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          Center(
            child: Container(
              width: 170,
              height: 170,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFE7E2D6),
                borderRadius: BorderRadius.circular(42),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F3EE),
                  borderRadius: BorderRadius.circular(32),
                ),
                padding: const EdgeInsets.all(18),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Image.asset(
                    'assets/app_icon.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(title,
              style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  height: 1.08,
                  color: Colors.white)),
          const SizedBox(height: 14),
          Text(body,
              style: const TextStyle(
                  fontSize: 18, color: SplytPalette.gold, height: 1.5)),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}
