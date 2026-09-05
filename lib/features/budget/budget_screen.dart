import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../utils/format.dart';
import '../../widgets/ui_kit.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats = ref.watch(categoriesProvider).valueOrNull ?? [];
    final goals = ref.watch(goalsProvider).valueOrNull ?? [];
    final user = ref.watch(userProvider).valueOrNull;
    final currency = user?.currency ?? 'GHS';

    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 56, 20, 8),
            child: Text('Budget', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
          ),
        ),
        SliverList.builder(
          itemCount: cats.length,
          itemBuilder: (context, i) {
            final cat = cats[i];
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: GlowCard(
                onTap: () => context.push('/category/${cat.id}'),
                child: Row(
                  children: [
                    GlyphBadge(iconKey: cat.icon, color: Color(cat.color)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                          if (cat.protected)
                            const Text('Protected', style: TextStyle(color: SplytPalette.gold, fontSize: 12)),
                          if (cat.isSystem)
                            const Text('Built-in bucket', style: TextStyle(color: SplytPalette.mute, fontSize: 12)),
                        ],
                      ),
                    ),
                    MoneyText(formatPesewas(cat.currentAmount, currency: currency), fontSize: 18),
                  ],
                ),
              ),
            );
          },
        ),
        if (goals.isNotEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Text('Goals live here too', style: TextStyle(color: SplytPalette.mute)),
            ),
          ),
        SliverList.builder(
          itemCount: goals.length,
          itemBuilder: (context, i) {
            final cat = goals[i];
            final p = cat.targetAmount == null || cat.targetAmount == 0
                ? 0.0
                : cat.currentAmount / cat.targetAmount!;
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: GlowCard(
                onTap: () => context.push('/category/${cat.id}'),
                child: Row(
                  children: [
                    ProgressRing(
                      progress: p,
                      color: Color(cat.color),
                      size: 52,
                      child: Icon(iconForKey(cat.icon), size: 18, color: Color(cat.color)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                    MoneyText(formatPesewas(cat.currentAmount, currency: currency), fontSize: 16),
                  ],
                ),
              ),
            );
          },
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}
