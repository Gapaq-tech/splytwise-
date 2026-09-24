import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../../providers/app_providers.dart';
import '../../providers/dashboard_provider.dart';
import '../../theme/tokens.dart';
import '../../utils/format.dart';

class CategoryDetailScreen extends ConsumerWidget {
  const CategoryDetailScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buckets = ref.watch(allBucketsProvider).valueOrNull ?? [];
    final category = buckets.where((item) => item.id == id).firstOrNull;
    if (category == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final history = ref.watch(historyProvider).valueOrNull ?? [];
    final user = ref.watch(userProvider).valueOrNull;
    final currency = user?.currency ?? 'GHS';
    final related = history.where((item) => item.kind == 'expense' && item.categoryId == id).toList();
    final allocations = ref.watch(allocationsProvider).valueOrNull ?? [];
    final incomes = ref.watch(incomesProvider).valueOrNull ?? [];
    final inflows = [
      for (final split in allocations.where((item) => item.categoryId == id))
        if (incomes.where((item) => item.id == split.incomeId).firstOrNull != null)
          (income: incomes.firstWhere((item) => item.id == split.incomeId), split: split),
    ];
    final isFreeMoney = category.systemKey == freeMoneyKey;
    final displayAmount = isFreeMoney && category.currentAmount < 0 ? 0 : category.currentAmount;
    final title = isFreeMoney ? 'Free money' : category.name;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: Text(title, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 32),
        children: [
          _AccountSummary(
            icon: isFreeMoney ? Icons.account_balance_wallet_outlined : iconForKey(category.icon),
            amount: formatPesewas(displayAmount, currency: currency),
            target: category.isGoal && category.targetAmount != null
                ? 'of ${formatPesewas(category.targetAmount ?? 0, currency: currency)}'
                : null,
          ),
          const SizedBox(height: 26),
          const Text('Activity', style: TextStyle(color: Colors.black, fontSize: 19, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (inflows.isEmpty && related.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Text('No movement on this bucket yet.', style: TextStyle(color: Colors.black54)),
            ),
          for (final row in inflows)
            _ActivityRow(
              title: row.income.source,
              subtitle: 'Income · ${dayLabel(row.income.date)}',
              amount: '+${formatPesewas(row.split.amount, currency: currency)}',
            ),
          for (final item in related)
            _ActivityRow(
              title: item.title,
              subtitle: 'Expense · ${dayLabel(item.date)}',
              amount: '-${formatPesewas(item.amountPesewas, currency: currency)}',
              expense: true,
            ),
          const SizedBox(height: 18),
          _CustomizeBucket(
            category: category,
            onColorChanged: (color) => ref.read(databaseProvider).updateCategoryLook(category.id, color: color),
            onIconChanged: (icon) => ref.read(databaseProvider).updateCategoryLook(category.id, icon: icon),
          ),
        ],
      ),
    );
  }
}

class _AccountSummary extends StatelessWidget {
  const _AccountSummary({required this.icon, required this.amount, this.target});

  final IconData icon;
  final String amount;
  final String? target;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: SplytPalette.cream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SplytPalette.gold.withValues(alpha: 0.55)),
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(color: SplytPalette.gold, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.black, size: 27),
          ),
          const SizedBox(height: 14),
          Text(amount, style: const TextStyle(color: Colors.black, fontSize: 34, fontWeight: FontWeight.w700)),
          if (target != null) ...[
            const SizedBox(height: 4),
            Text(target!, style: const TextStyle(color: Colors.black54)),
          ],
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.title, required this.subtitle, required this.amount, this.expense = false});

  final String title;
  final String subtitle;
  final String amount;
  final bool expense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: SplytPalette.cream))),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(color: SplytPalette.cream, shape: BoxShape.circle),
            child: Icon(expense ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, color: Colors.black, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 12)),
              ],
            ),
          ),
          Text(amount, style: TextStyle(color: expense ? Colors.black : SplytPalette.gold, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _CustomizeBucket extends StatelessWidget {
  const _CustomizeBucket({required this.category, required this.onColorChanged, required this.onIconChanged});

  final Category category;
  final ValueChanged<int> onColorChanged;
  final ValueChanged<String> onIconChanged;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 8),
      title: const Text('Customize bucket', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
      subtitle: const Text('Change its icon', style: TextStyle(color: Colors.black54, fontSize: 12)),
      iconColor: Colors.black,
      collapsedIconColor: Colors.black,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final glyph in categoryGlyphs)
                InkWell(
                  onTap: () => onIconChanged(glyph.key),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 52,
                    height: 42,
                    decoration: BoxDecoration(
                      color: category.icon == glyph.key ? SplytPalette.goldSoft : SplytPalette.cream,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: category.icon == glyph.key ? SplytPalette.gold : Colors.black12),
                    ),
                    child: Icon(glyph.icon, color: Colors.black, size: 20),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
