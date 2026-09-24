import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_providers.dart';
import '../../theme/tokens.dart';
import '../../utils/format.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsProvider);
    final user = ref.watch(userProvider).valueOrNull;
    final currency = user?.currency ?? 'GHS';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 12),
              child: _GoalsHeader(
                onNotifications: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('You are all caught up.')),
                ),
                onProfile: () => context.push('/settings'),
                onAdd: () => context.push('/goals/new'),
              ),
            ),
            Expanded(
              child: goalsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: SplytPalette.gold)),
                error: (error, _) => _GoalsError(
                  message: error.toString(),
                  onRetry: () => ref.invalidate(goalsProvider),
                ),
                data: (goals) => goals.isEmpty
                    ? _EmptyGoals(onCreate: () => context.push('/goals/new'))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(22, 4, 22, 100),
                        itemCount: goals.length,
                        itemBuilder: (context, index) {
                          final goal = goals[index];
                          final targetAmount = goal.targetAmount;
                          final progress = targetAmount == null || targetAmount == 0
                              ? 0.0
                              : (goal.currentAmount / targetAmount).clamp(0.0, 1.0);
                          final done = goal.completedAt != null;
                          return _GoalRow(
                            name: goal.name,
                            amount: '${formatPesewas(goal.currentAmount, currency: currency)} of ${formatPesewas(goal.targetAmount ?? 0, currency: currency)}',
                            progress: progress,
                            done: done,
                            onTap: () => context.push('/category/${goal.id}'),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalsHeader extends StatelessWidget {
  const _GoalsHeader({required this.onNotifications, required this.onProfile, required this.onAdd});

  final VoidCallback onNotifications;
  final VoidCallback onProfile;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _HeaderIcon(icon: Icons.notifications_none_rounded, tooltip: 'Notifications', onTap: onNotifications),
        const SizedBox(width: 12),
        const Expanded(child: Center(child: Text('Goals', style: TextStyle(color: Colors.black, fontSize: 27, fontWeight: FontWeight.w700)))),
        const SizedBox(width: 12),
        _HeaderIcon(icon: Icons.person_outline_rounded, tooltip: 'Profile', onTap: onProfile),
        const SizedBox(width: 8),
        IconButton(
          onPressed: onAdd,
          tooltip: 'New goal',
          icon: const Icon(Icons.add_rounded, color: Colors.black, size: 22),
          style: IconButton.styleFrom(
            backgroundColor: SplytPalette.gold,
            fixedSize: const Size(42, 42),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          ),
        ),
      ],
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({required this.icon, required this.tooltip, required this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      icon: Icon(icon, color: Colors.black, size: 22),
      style: IconButton.styleFrom(
        backgroundColor: SplytPalette.cream,
        fixedSize: const Size(42, 42),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
    );
  }
}

class _EmptyGoals extends StatelessWidget {
  const _EmptyGoals({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(color: SplytPalette.goldSoft, shape: BoxShape.circle),
              child: const Icon(Icons.star_outline_rounded, color: Colors.black, size: 36),
            ),
            const SizedBox(height: 18),
            const Text('No goals yet', style: TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text(
              'Give something important a clear target and watch your progress grow.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, height: 1.4),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create a goal'),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(SplytPalette.gold),
                foregroundColor: WidgetStateProperty.all(Colors.black),
                minimumSize: WidgetStateProperty.all(const Size(0, 48)),
                padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalsError extends StatelessWidget {
  const _GoalsError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Goals could not load', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 14),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  const _GoalRow({required this.name, required this.amount, required this.progress, required this.done, required this.onTap});

  final String name;
  final String amount;
  final double progress;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: done ? SplytPalette.goldSoft : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: done ? SplytPalette.gold : SplytPalette.cream),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(done ? Icons.check_circle_outline_rounded : Icons.star_outline_rounded, color: Colors.black, size: 24),
                  const SizedBox(width: 10),
                  Expanded(child: Text(name, style: const TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.w700))),
                  Text('${(progress * 100).round()}%', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 7),
              Text(amount, style: const TextStyle(color: Colors.black54, fontSize: 12)),
              const SizedBox(height: 9),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: SplytPalette.cream,
                  valueColor: const AlwaysStoppedAnimation<Color>(SplytPalette.gold),
                ),
              ),
              if (done)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('Funded', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
