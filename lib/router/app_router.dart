import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/budget/budget_screen.dart';
import '../features/budget/category_detail_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/expense/add_expense_screen.dart';
import '../features/goals/edit_goal_screen.dart';
import '../features/goals/goals_screen.dart';
import '../features/history/history_screen.dart';
import '../features/income/add_income_flow.dart';
import '../features/income/split_result_screen.dart';
import '../features/lock/pin_lock_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/recap/monthly_recap_screen.dart';
import '../features/settings/settings_page.dart';
import '../features/shell/app_shell.dart';
import '../features/splash/splash_screen.dart';
import '../providers/add_income_provider.dart';
import '../providers/app_providers.dart';

final _rootKey = GlobalKey<NavigatorState>();
final unlockedProvider = StateProvider<bool>((ref) => false);

class _RouterRefresh extends ChangeNotifier {
  void ping() => notifyListeners();
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh();
  ref.onDispose(refresh.dispose);
  ref.listen(appBootstrapProvider, (_, __) => refresh.ping());
  ref.listen(settingsProvider, (_, __) => refresh.ping());
  ref.listen(unlockedProvider, (_, __) => refresh.ping());

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/splash',
    refreshListenable: refresh,
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: '/lock', builder: (context, state) => const PinLockScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(shell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/home', builder: (context, state) => const DashboardScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/budget', builder: (context, state) => const BudgetScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/history', builder: (context, state) => const HistoryScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/goals', builder: (context, state) => const GoalsScreen()),
          ]),
        ],
      ),
      GoRoute(path: '/income', builder: (context, state) => const AddIncomeFlow()),
      GoRoute(
        path: '/income/result',
        builder: (context, state) => SplitResultScreen(commit: state.extra as SplitCommit),
      ),
      GoRoute(path: '/expense', builder: (context, state) => const AddExpenseScreen()),
      GoRoute(
        path: '/category/:id',
        builder: (context, state) => CategoryDetailScreen(
          id: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(path: '/goals/new', builder: (context, state) => const EditGoalScreen()),
      GoRoute(path: '/recap', builder: (context, state) => const MonthlyRecapScreen()),
      GoRoute(path: '/settings', builder: (context, state) => const SettingsPage()),
    ],
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final boot = ref.read(appBootstrapProvider);
      if (boot.isLoading || boot.hasError) {
        if (loc == '/splash' || loc == '/lock' || loc == '/settings' || loc == '/onboarding') {
          return null;
        }
        return '/splash';
      }

      final settings = ref.read(settingsProvider).valueOrNull;
      if (settings == null) {
        if (loc == '/splash' || loc == '/settings' || loc == '/lock' || loc == '/onboarding') {
          return null;
        }
        return '/splash';
      }

      if (!settings.onboardingComplete && loc != '/onboarding') return '/onboarding';
      if (settings.onboardingComplete && loc == '/onboarding') return '/home';
      if (settings.pinEnabled &&
          !ref.read(unlockedProvider) &&
          loc != '/lock' &&
          loc != '/splash' &&
          loc != '/onboarding' &&
          // Settings must always be reachable — it's the only screen that can
          // turn PIN lock off. Without this exemption, a broken or forgotten
          // PIN permanently locks the person out of the one screen that can
          // fix it, and any issue on the lock screen itself then looks
          // exactly like "Settings is blank" from the outside.
          loc != '/settings') {
        return '/lock';
      }
      return null;
    },
  );
});