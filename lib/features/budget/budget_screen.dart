import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/db/app_database.dart';
import '../../providers/app_providers.dart';
import '../../theme/tokens.dart';
import '../../utils/format.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
    final goals = ref.watch(goalsProvider).valueOrNull ?? [];
    final user = ref.watch(userProvider).valueOrNull;
    final currency = user?.currency ?? 'GHS';
    final total = categories.fold<int>(0, (sum, category) => sum + category.currentAmount);
    final protectedCount = categories.where((category) => category.protected).length;

    return ColoredBox(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 12),
              child: _BudgetHeader(
                total: formatPesewas(total, currency: currency),
                categoryCount: categories.length,
                protectedCount: protectedCount,
                onAdd: () => _addCategory(context, ref, categories.length),
                onProfile: () => context.push('/settings'),
                onNotifications: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('You are all caught up.')),
                  );
                },
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 100),
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(22, 4, 22, 8),
                    child: Text(
                      'Money buckets',
                      style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                  for (final category in categories)
                    _BudgetRow(
                      name: _displayCategoryName(category.name, category.systemKey),
                      amount: formatPesewas(
                        category.systemKey == freeMoneyKey && category.currentAmount < 0
                            ? 0
                            : category.currentAmount,
                        currency: currency,
                      ),
                      icon: category.systemKey == freeMoneyKey
                          ? Icons.account_balance_wallet_outlined
                          : iconForKey(category.icon),
                      isProtected: category.protected,
                      isSystem: category.isSystem,
                      onTap: () => context.push('/category/${category.id}'),
                    ),
                  if (goals.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(22, 0, 22, 8),
                      child: Text(
                        'Goals',
                        style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ),
                    for (final goal in goals)
                      _GoalRow(
                        name: _displayCategoryName(goal.name, goal.systemKey),
                        amount: formatPesewas(goal.currentAmount, currency: currency),
                        progress: () {
                          final targetAmount = goal.targetAmount;
                          if (targetAmount == null || targetAmount == 0) return 0.0;
                          return (goal.currentAmount / targetAmount).clamp(0.0, 1.0);
                        }(),
                        onTap: () => context.push('/category/${goal.id}'),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _displayCategoryName(String name, String? systemKey) {
    if (systemKey == freeMoneyKey) return 'Free money';
    return name
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  Future<void> _addCategory(BuildContext context, WidgetRef ref, int count) async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => const _AddBucketDialog(),
    );
    if (name != null && name.trim().isNotEmpty) {
      await ref.read(databaseProvider).createCategory(
            name: name.trim(),
            icon: 'wallet',
            color: 0xFFD9A441,
          );
    }
  }
}

class _AddBucketDialog extends StatefulWidget {
  const _AddBucketDialog();

  @override
  State<_AddBucketDialog> createState() => _AddBucketDialogState();
}

class _AddBucketDialogState extends State<_AddBucketDialog> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: const Text(
        'Add money bucket',
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
      ),
      content: TextField(
        controller: _name,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        style: const TextStyle(color: Colors.black, fontSize: 18),
        decoration: const InputDecoration(
          labelText: 'Bucket name',
          labelStyle: TextStyle(color: Colors.black54),
          floatingLabelStyle: TextStyle(color: Colors.black),
          hintStyle: TextStyle(color: Colors.black38),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.black26),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: SplytPalette.gold, width: 2),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _name.text),
          style: FilledButton.styleFrom(
            backgroundColor: SplytPalette.gold,
            foregroundColor: Colors.black,
          ),
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class _BudgetHeader extends StatelessWidget {
  const _BudgetHeader({required this.total, required this.categoryCount, required this.protectedCount, required this.onAdd, required this.onProfile, required this.onNotifications});

  final String total;
  final int categoryCount;
  final int protectedCount;
  final VoidCallback onAdd;
  final VoidCallback onProfile;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _BudgetIcon(icon: Icons.person_outline_rounded, tooltip: 'Profile', onTap: onProfile),
            const SizedBox(width: 12),
            const Expanded(child: Center(child: Text('Budget', style: TextStyle(color: Colors.black, fontSize: 27, fontWeight: FontWeight.w700)))),
            const SizedBox(width: 12),
            _BudgetIcon(icon: Icons.notifications_none_rounded, tooltip: 'Notifications', onTap: onNotifications),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
          decoration: BoxDecoration(
            color: SplytPalette.cream,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: SplytPalette.gold.withValues(alpha: 0.55)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TOTAL IN BUCKETS', style: TextStyle(color: Colors.black54, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
                    const SizedBox(height: 5),
                    Text(total, style: const TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              _HeaderStat(value: '$categoryCount', label: 'buckets'),
              const SizedBox(width: 20),
              _HeaderStat(value: '$protectedCount', label: 'protected'),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, size: 17),
            label: const Text('Bucket'),
            style: FilledButton.styleFrom(
              backgroundColor: SplytPalette.gold,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ),
      ],
    );
  }
}

class _BudgetIcon extends StatelessWidget {
  const _BudgetIcon({required this.icon, required this.tooltip, required this.onTap});

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

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(value, style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w700)),
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 11)),
      ],
    );
  }
}

class _BudgetRow extends StatelessWidget {
  const _BudgetRow({required this.name, required this.amount, required this.icon, required this.isProtected, required this.isSystem, required this.onTap});

  final String name;
  final String amount;
  final IconData icon;
  final bool isProtected;
  final bool isSystem;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 7, 22, 7),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: SplytPalette.cream),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: SplytPalette.gold, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
                    if (isProtected || isSystem)
                      Text(
                        isProtected ? 'Protected' : 'Built-in bucket',
                        style: const TextStyle(color: Colors.black54, fontSize: 11),
                      ),
                  ],
                ),
              ),
              Text(amount, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, color: Colors.black54, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  const _GoalRow({required this.name, required this.amount, required this.progress, required this.onTap});

  final String name;
  final String amount;
  final double progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 7, 22, 7),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: SplytPalette.cream,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.star_outline_rounded, color: SplytPalette.gold, size: 21),
                  const SizedBox(width: 10),
                  Expanded(child: Text(name, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600))),
                  Text(amount, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 9),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: Colors.white,
                  valueColor: const AlwaysStoppedAnimation<Color>(SplytPalette.gold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
