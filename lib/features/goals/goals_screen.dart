import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../utils/format.dart';
import '../../widgets/celebration_burst.dart';
import '../../widgets/ui_kit.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsProvider).valueOrNull ?? [];
    final user = ref.watch(userProvider).valueOrNull;
    final currency = user?.currency ?? 'GHS';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 12),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Goals', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
                  ),
                  FilledButton.icon(
                    onPressed: () => context.push('/goals/new'),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('New goal'),
                    style: FilledButton.styleFrom(
                      backgroundColor: SplytPalette.mint,
                      foregroundColor: SplytPalette.deep,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (goals.isEmpty)
            const SliverFillRemaining(
              child: Center(child: Text('A laptop, a trip, a buffer — give it a target.')),
            )
          else
            SliverList.builder(
              itemCount: goals.length,
              itemBuilder: (context, i) {
                final goal = goals[i];
                final p = (goal.targetAmount == null || goal.targetAmount == 0)
                    ? 0.0
                    : goal.currentAmount / goal.targetAmount!;
                final done = goal.completedAt != null;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: GlowCard(
                    onTap: () => context.push('/category/${goal.id}'),
                    color: done ? SplytPalette.gold.withOpacity(0.12) : null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (done)
                              const CelebrationBurst(
                                child: SizedBox(width: 56, height: 56),
                              )
                            else
                              ProgressRing(
                                progress: p,
                                color: Color(goal.color),
                                child: Text('${(p * 100).clamp(0, 999).round()}%',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                              ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(goal.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                                  Text(
                                    '${formatPesewas(goal.currentAmount, currency: currency)} of ${formatPesewas(goal.targetAmount ?? 0, currency: currency)}',
                                    style: const TextStyle(color: SplytPalette.mute),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            minHeight: 8,
                            value: p.clamp(0, 1),
                            color: done ? SplytPalette.gold : Color(goal.color),
                            backgroundColor: Colors.white12,
                          ),
                        ),
                        if (done)
                          const Padding(
                            padding: EdgeInsets.only(top: 10),
                            child: Text('Funded. That’s a win.',
                                style: TextStyle(color: SplytPalette.gold, fontWeight: FontWeight.w700)),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}
