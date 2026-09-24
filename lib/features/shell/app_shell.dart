import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/tokens.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: 86,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE5E0D6))),
          ),
          child: Row(
            children: [
              _NavItem(
                  icon: Icons.home_outlined,
                  label: 'Home',
                  selected: shell.currentIndex == 0,
                  onTap: () => shell.goBranch(0)),
              _NavItem(
                  icon: Icons.pie_chart_outline_rounded,
                  label: 'Budget',
                  selected: shell.currentIndex == 1,
                  onTap: () => shell.goBranch(1)),
              Expanded(
                child: Center(
                  child: FloatingActionButton(
                    onPressed: () => _showAddMenu(context),
                    backgroundColor: SplytPalette.gold,
                    foregroundColor: Colors.black,
                    elevation: 6,
                    shape: const CircleBorder(),
                    child: const Icon(Icons.add_rounded, size: 34),
                  ),
                ),
              ),
              _NavItem(
                  icon: Icons.show_chart_rounded,
                  label: 'History',
                  selected: shell.currentIndex == 2,
                  onTap: () => shell.goBranch(2)),
              _NavItem(
                  icon: Icons.star_border_rounded,
                  label: 'Goals',
                  selected: shell.currentIndex == 3,
                  onTap: () => shell.goBranch(3)),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add to Splytwise',
                style: TextStyle(
                  color: SplytPalette.deepTeal,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _AddChoice(
                      icon: Icons.arrow_downward_rounded,
                      label: 'Income',
                      color: SplytPalette.gold,
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/income');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AddChoice(
                      icon: Icons.arrow_upward_rounded,
                      label: 'Expense',
                      color: Colors.black,
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/expense');
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddChoice extends StatelessWidget {
  const _AddChoice({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem(
      {required this.icon,
      required this.label,
      required this.selected,
      required this.onTap});

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.black : Colors.black54;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 29),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
