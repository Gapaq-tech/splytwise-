import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_providers.dart';
import '../../providers/dashboard_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../utils/format.dart';
import '../../widgets/celebration_burst.dart';
import '../../widgets/ui_kit.dart';

class CategoryDetailScreen extends ConsumerWidget {
  const CategoryDetailScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buckets = ref.watch(allBucketsProvider).valueOrNull ?? [];
    final cat = buckets.where((c) => c.id == id).firstOrNull;
    final history = ref.watch(historyProvider).valueOrNull ?? [];
    final user = ref.watch(userProvider).valueOrNull;
    if (cat == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final related = history.where((h) => h.kind == 'expense' && h.categoryId == cat.id).toList();
    final currency = user?.currency ?? 'GHS';
    final done = cat.isGoal && cat.completedAt != null;

    return Scaffold(
      appBar: AppBar(title: Text(cat.name)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          GlowCard(
            child: Column(
              children: [
                if (done) const CelebrationBurst(child: SizedBox(height: 80, width: double.infinity)),
                GlyphBadge(iconKey: cat.icon, color: Color(cat.color), size: 64),
                const SizedBox(height: 12),
                MoneyText(formatPesewas(cat.currentAmount, currency: currency)),
                if (cat.isGoal && cat.targetAmount != null)
                  Text('of ${formatPesewas(cat.targetAmount!, currency: currency)}'),
                if (done)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('Goal complete — celebrate that.',
                        style: TextStyle(color: SplytPalette.gold, fontWeight: FontWeight.w800)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Look & feel', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final color in SplytPalette.categorySwatches)
                GestureDetector(
                  onTap: () =>
                      ref.read(databaseProvider).updateCategoryLook(cat.id, color: color),
                  child: CircleAvatar(
                    backgroundColor: Color(color),
                    child: cat.color == color ? const Icon(Icons.check, size: 16) : null,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final glyph in categoryGlyphs)
                ActionChip(
                  avatar: Icon(glyph.icon),
                  label: Text(glyph.label),
                  onPressed: () =>
                      ref.read(databaseProvider).updateCategoryLook(cat.id, icon: glyph.key),
                ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Activity', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          if (related.isEmpty) const Text('No expenses on this bucket yet.'),
          for (final item in related)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(item.title),
              subtitle: Text(dayLabel(item.date)),
              trailing: MoneyText(
                '-${formatPesewas(item.amountPesewas, currency: currency)}',
                fontSize: 16,
                color: SplytPalette.coral,
              ),
            ),
        ],
      ),
    );
  }
}
