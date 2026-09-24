import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/db/app_database.dart';
import '../../providers/app_providers.dart';
import '../../providers/dashboard_provider.dart';
import '../../theme/tokens.dart';
import '../../utils/format.dart';
import '../../utils/money.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  int? _filterId;
  final _searchController = TextEditingController();
  String _search = '';
  String _analyticsPeriod = 'Monthly';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(historyProvider).valueOrNull ?? [];
    final buckets = ref.watch(allBucketsProvider).valueOrNull ?? [];
    final allocations = ref.watch(allocationsProvider).valueOrNull ?? [];
    final user = ref.watch(userProvider).valueOrNull;
    final currency = user?.currency ?? 'GHS';
    final free =
        buckets.where((item) => item.systemKey == freeMoneyKey).firstOrNull;
    final filtered = history.where((item) {
      if (_filterId == null) return true;
      if (item.kind == 'expense') return item.categoryId == _filterId;
      return allocations.any((allocation) =>
          allocation.incomeId == item.id && allocation.categoryId == _filterId);
    }).where((item) {
      if (_search.trim().isEmpty) return true;
      final query = _search.trim().toLowerCase();
      return item.title.toLowerCase().contains(query) ||
          (item.categoryName?.toLowerCase().contains(query) ?? false);
    }).toList();

    return ColoredBox(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 10),
              child: _HistoryHeader(
                onNotifications: () =>
                    ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('You are all caught up.')),
                ),
                onProfile: () => context.push('/settings'),
              ),
            ),
            if (free != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 10),
                child: _FreeMoneyNotice(
                  amount: formatPesewas(
                      free.currentAmount < 0 ? 0 : free.currentAmount,
                      currency: currency),
                  onTap: () => _markFreeSpent(free),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 10),
              child: Row(
                children: [
                  _Filter(
                    label: 'All',
                    selected: _filterId == null,
                    onTap: () => setState(() => _filterId = null),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _search = value),
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        hintText: 'Search history',
                        hintStyle: const TextStyle(color: Colors.black54),
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: Colors.black54),
                        suffixIcon: _search.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _search = '');
                                },
                                icon: const Icon(Icons.close_rounded,
                                    color: Colors.black54),
                              ),
                        filled: true,
                        fillColor: SplytPalette.cream,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.black12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: SplytPalette.gold, width: 2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
              child: _AnalyticsPanel(
                items: history,
                currency: currency,
                period: _analyticsPeriod,
                onPeriodChanged: (period) =>
                    setState(() => _analyticsPeriod = period),
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Text('Nothing here yet.',
                          style: TextStyle(color: Colors.black54)))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(22, 8, 22, 100),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final income = item.kind == 'income';
                        return _HistoryRow(
                          title: item.title,
                          subtitle: [
                            income ? 'Income' : 'Expense',
                            if (item.categoryName != null)
                              _displayName(item.categoryName ?? 'Category'),
                            dayLabel(item.date),
                          ].join(' · '),
                          amount:
                              '${income ? '+' : '-'}${formatPesewas(item.amountPesewas, currency: currency)}',
                          icon: item.categoryId == null || income
                              ? (income
                                  ? Icons.bolt_outlined
                                  : Icons.account_balance_wallet_outlined)
                              : iconForKey(item.icon ?? 'wallet'),
                          expense: !income,
                          onTap: item.categoryId == null
                              ? null
                              : () =>
                                  context.push('/category/${item.categoryId}'),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markFreeSpent(Category free) async {
    final result = await showDialog<({String amount, String title})>(
      context: context,
      builder: (context) => const _MarkSpentDialog(),
    );
    if (result == null) return;
    final amount =
        cedisToPesewas(double.tryParse(result.amount.replaceAll(',', '')) ?? 0);
    if (amount <= 0) return;
    final db = ref.read(databaseProvider);
    await db.addExpense(
      categoryId: free.id,
      amountPesewas: amount,
      description: result.title.trim().isEmpty ? 'Spent' : result.title.trim(),
      date: DateTime.now(),
    );
    await ref.read(notificationServiceProvider).refreshSchedules();
  }
}

String _displayName(String value) => value
    .split(RegExp(r'\s+'))
    .where((word) => word.isNotEmpty)
    .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
    .join(' ');

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader(
      {required this.onNotifications, required this.onProfile});

  final VoidCallback onNotifications;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _HeaderIcon(
            icon: Icons.notifications_none_rounded,
            tooltip: 'Notifications',
            onTap: onNotifications),
        const SizedBox(width: 12),
        const Expanded(
            child: Center(
                child: Text('History',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 27,
                        fontWeight: FontWeight.w700)))),
        const SizedBox(width: 12),
        _HeaderIcon(
            icon: Icons.person_outline_rounded,
            tooltip: 'Profile',
            onTap: onProfile),
      ],
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon(
      {required this.icon, required this.tooltip, required this.onTap});

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

class _FreeMoneyNotice extends StatelessWidget {
  const _FreeMoneyNotice({required this.amount, required this.onTap});

  final String amount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: SplytPalette.cream,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: SplytPalette.gold.withValues(alpha: 0.55)),
        ),
        child: Row(
          children: [
            const Icon(Icons.account_balance_wallet_outlined,
                color: Colors.black, size: 22),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Free money',
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.w700)),
                  Text('Tap to record a spend',
                      style: TextStyle(color: Colors.black54, fontSize: 12)),
                ],
              ),
            ),
            Text(amount,
                style: const TextStyle(
                    color: Colors.black, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _Filter extends StatelessWidget {
  const _Filter(
      {required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? SplytPalette.goldSoft : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: selected ? SplytPalette.gold : Colors.black12),
          ),
          child: Text(label,
              style: const TextStyle(
                  color: Colors.black, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow(
      {required this.title,
      required this.subtitle,
      required this.amount,
      required this.icon,
      required this.expense,
      this.onTap});

  final String title;
  final String subtitle;
  final String amount;
  final IconData icon;
  final bool expense;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: expense ? const Color(0xFFFFF8F6) : const Color(0xFFF5FBF7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: expense
                    ? const Color(0xFFF1D8D2)
                    : const Color(0xFFD9EBDD)),
          ),
          child: Row(
            children: [
              Icon(icon, color: SplytPalette.gold, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.black, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.black54, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                amount,
                style: TextStyle(
                  color: expense
                      ? const Color(0xFF9E5145)
                      : const Color(0xFF2D7A55),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnalyticsPanel extends StatelessWidget {
  const _AnalyticsPanel(
      {required this.items,
      required this.currency,
      required this.period,
      required this.onPeriodChanged});

  final List<HistoryItem> items;
  final String currency;
  final String period;
  final ValueChanged<String> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final start = switch (period) {
      'Weekly' => now.subtract(const Duration(days: 7)),
      'Yearly' => DateTime(now.year - 1, now.month, now.day),
      _ => DateTime(now.year, now.month - 1, now.day),
    };
    final periodItems =
        items.where((item) => !item.date.isBefore(start)).toList();
    final spent = periodItems
        .where((item) => item.kind == 'expense')
        .fold<int>(0, (sum, item) => sum + item.amountPesewas);
    final income = periodItems
        .where((item) => item.kind == 'income')
        .fold<int>(0, (sum, item) => sum + item.amountPesewas);
    final byCategory = <String, int>{};
    for (final item in periodItems.where((item) => item.kind == 'expense')) {
      final name = item.categoryName == null
          ? 'Unassigned'
          : _displayName(item.categoryName!);
      byCategory[name] = (byCategory[name] ?? 0) + item.amountPesewas;
    }
    final leaders = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
      decoration: BoxDecoration(
        color: SplytPalette.cream,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SplytPalette.gold.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                  child: Text('Spending overview',
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.w700))),
              for (final option in ['Weekly', 'Monthly', 'Yearly'])
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: InkWell(
                    onTap: () => onPeriodChanged(option),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 5),
                      decoration: BoxDecoration(
                        color:
                            period == option ? SplytPalette.gold : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(option[0],
                          style: const TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: _AnalyticsValue(
                      label: 'Spent',
                      value: formatPesewas(spent, currency: currency))),
              Expanded(
                  child: _AnalyticsValue(
                      label: 'Income',
                      value: formatPesewas(income, currency: currency))),
              Expanded(
                  child: _AnalyticsValue(
                      label: 'Entries', value: '${periodItems.length}')),
            ],
          ),
          if (leaders.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text('Top spending areas',
                style: TextStyle(color: Colors.black54, fontSize: 12)),
            const SizedBox(height: 6),
            for (final entry in leaders.take(2))
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(
                        child: Text(entry.key,
                            style: const TextStyle(
                                color: Colors.black, fontSize: 12))),
                    Text(formatPesewas(entry.value, currency: currency),
                        style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _AnalyticsValue extends StatelessWidget {
  const _AnalyticsValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.black54, fontSize: 11)),
        const SizedBox(height: 2),
        FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(value,
                style: const TextStyle(
                    color: Colors.black, fontWeight: FontWeight.w700))),
      ],
    );
  }
}

class _MarkSpentDialog extends StatefulWidget {
  const _MarkSpentDialog();

  @override
  State<_MarkSpentDialog> createState() => _MarkSpentDialogState();
}

class _MarkSpentDialogState extends State<_MarkSpentDialog> {
  final _amount = TextEditingController();
  final _title = TextEditingController(text: 'Spent');

  @override
  void dispose() {
    _amount.dispose();
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title:
          const Text('Record a spend', style: TextStyle(color: Colors.black)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _amount,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.black),
            decoration: const InputDecoration(
              labelText: 'Amount',
              labelStyle: TextStyle(color: Colors.black54),
              focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: SplytPalette.gold, width: 2)),
            ),
          ),
          TextField(
            controller: _title,
            style: const TextStyle(color: Colors.black),
            decoration: const InputDecoration(
              labelText: 'What for?',
              labelStyle: TextStyle(color: Colors.black54),
              focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: SplytPalette.gold, width: 2)),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(
              context, (amount: _amount.text, title: _title.text)),
          style: FilledButton.styleFrom(
              backgroundColor: SplytPalette.gold,
              foregroundColor: Colors.black),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
