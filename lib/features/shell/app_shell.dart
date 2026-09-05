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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/income'),
        backgroundColor: SplytPalette.mint,
        foregroundColor: SplytPalette.deep,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add income', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: shell.goBranch,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.pie_chart_rounded), label: 'Budget'),
          NavigationDestination(icon: Icon(Icons.history_rounded), label: 'History'),
          NavigationDestination(icon: Icon(Icons.flag_rounded), label: 'Goals'),
        ],
      ),
    );
  }
}
