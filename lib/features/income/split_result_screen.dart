import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/add_income_provider.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../utils/format.dart';
import '../../widgets/celebration_burst.dart';
import '../../widgets/ui_kit.dart';

class SplitResultScreen extends ConsumerWidget {
  const SplitResultScreen({super.key, required this.commit});

  final SplitCommit commit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buckets = ref.watch(allBucketsProvider).valueOrNull ?? [];
    final byId = {for (final c in buckets) c.id: c};
    final user = ref.watch(userProvider).valueOrNull;
    final currency = user?.currency ?? 'GHS';
    final celebrated = commit.completedGoalIds.isNotEmpty;

    return Scaffold(
      body: CelebrationBurst(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(celebrated ? 'Goal unlocked' : 'Split complete',
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text('${commit.source} · ${formatPesewas(commit.amountPesewas, currency: currency)}',
                    style: const TextStyle(color: SplytPalette.mute)),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    children: [
                      for (final line in commit.settled)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GlowCard(
                            child: Row(
                              children: [
                                GlyphBadge(
                                  iconKey: byId[line.categoryId]?.icon ?? 'wallet',
                                  color: Color(byId[line.categoryId]?.color ?? SplytPalette.mint.value),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        byId[line.categoryId]?.name ?? 'Bucket',
                                        style: const TextStyle(fontWeight: FontWeight.w800),
                                      ),
                                      Text(formatPercent(line.percent),
                                          style: const TextStyle(color: SplytPalette.mute)),
                                    ],
                                  ),
                                ),
                                MoneyText(
                                  formatPesewas(line.amountPesewas, currency: currency),
                                  fontSize: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (celebrated)
                        GlowCard(
                          color: SplytPalette.gold.withOpacity(0.16),
                          child: Text(
                            commit.completedGoalIds
                                .map((id) => '${byId[id]?.name ?? 'A goal'} is fully funded. You did that.')
                                .join('\n'),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: SplytPalette.mint,
                      foregroundColor: SplytPalette.deep,
                    ),
                    onPressed: () => context.go('/home'),
                    child: const Text('Back to dashboard'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
