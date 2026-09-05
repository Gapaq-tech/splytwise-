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
import '../features/settings/settings_screen.dart';
import '../features/shell/app_shell.dart';
import '../features/splash/splash_screen.dart';
import '../providers/add_income_provider.dart';
import '../providers/app_providers.dart';

final _rootKey = GlobalKey<NavigatorState>();
final unlockedProvider = StateProvider<bool>((ref) => false);

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/splash',
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
      GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
    ],
    redirect: (context, state) {
      final boot = ref.read(appBootstrapProvider);
      if (boot.isLoading) return state.matchedLocation == '/splash' ? null : '/splash';
      final settings = ref.read(settingsProvider).valueOrNull;
      if (settings == null) return '/splash';
      final loc = state.matchedLocation;
      if (!settings.onboardingComplete && loc != '/onboarding') return '/onboarding';
      if (settings.onboardingComplete && loc == '/onboarding') return '/home';
      if (settings.pinEnabled &&
          !ref.read(unlockedProvider) &&
          loc != '/lock' &&
          loc != '/splash' &&
          loc != '/onboarding') {
        return '/lock';
      }
      return null;
    },
  );
});
