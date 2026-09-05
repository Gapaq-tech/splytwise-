import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_providers.dart';
import '../../providers/dashboard_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../utils/format.dart';
import '../../widgets/ui_kit.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dash = ref.watch(dashboardProvider);
    final user = ref.watch(userProvider).valueOrNull;
    final currency = user?.currency ?? 'GHS';

    return dash.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (snap) {
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 56, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hey ${user?.name ?? 'there'}',
                              style: TextStyle(color: Colors.white.withOpacity(0.6))),
                          const Text('Every cedi, on purpose',
                              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => context.push('/settings'),
                      icon: const Icon(Icons.tune_rounded),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GlowCard(
                  color: SplytPalette.surfaceHigh,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total in buckets', style: TextStyle(color: SplytPalette.mute)),
                      const SizedBox(height: 6),
                      MoneyText(formatPesewas(snap.totalBalance, currency: currency), fontSize: 36),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _MiniStat(
                              label: 'Free money',
                              value: formatPesewas(snap.freeMoney?.currentAmount ?? 0, currency: currency),
                              color: SplytPalette.mint,
                            ),
                          ),
                          Expanded(
                            child: _MiniStat(
                              label: 'Toward goals',
                              value: formatPesewas(snap.goalSaved, currency: currency),
                              color: SplytPalette.gold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: GlowCard(
                        child: Row(
                          children: [
                            const Icon(Icons.local_fire_department_rounded, color: SplytPalette.coral),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                snap.weeksOnTrack == 0
                                    ? 'Log income to start a streak'
                                    : '${snap.weeksOnTrack} week${snap.weeksOnTrack == 1 ? '' : 's'} on track',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GlowCard(
                      onTap: () => context.push('/recap'),
                      child: const Icon(Icons.auto_graph_rounded, color: SplytPalette.mint),
                    ),
                  ],
                ),
              ),
            ),
            if (snap.protectedWarnings.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: GlowCard(
                    color: SplytPalette.coral.withOpacity(0.16),
                    child: Text(
                      snap.protectedWarnings
                          .map((c) => '${c.name} is running low (${formatPesewas(c.currentAmount, currency: currency)})')
                          .join('\n'),
                    ),
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: GlowCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Spending this month', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 180,
                        child: snap.spendByBucket.isEmpty
                            ? const Center(child: Text('No spend yet — that’s a kind of win.'))
                            : PieChart(
                                PieChartData(
                                  sectionsSpace: 3,
                                  centerSpaceRadius: 48,
                                  sections: [
                                    for (final row in snap.spendByBucket.take(6))
                                      PieChartSectionData(
                                        value: row.spent.toDouble(),
                                        color: Color(row.category.color),
                                        title: '',
                                        radius: 28,
                                      ),
                                  ],
                                ),
                              ),
                      ),
                      MoneyText(formatPesewas(snap.spentThisMonth, currency: currency), fontSize: 22),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final row in snap.spendByBucket.take(6))
                            Chip(
                              avatar: CircleAvatar(backgroundColor: Color(row.category.color)),
                              label: Text(row.category.name),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonal(
                        onPressed: () => context.push('/expense'),
                        child: const Text('Add expense'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: SplytPalette.coral),
                        onPressed: () => context.push('/income'),
                        child: const Text('Split income'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: SplytPalette.mute, fontSize: 12)),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16)),
      ],
    );
  }
}
