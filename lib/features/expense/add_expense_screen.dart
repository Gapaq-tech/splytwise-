import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/db/app_database.dart';
import '../../providers/app_providers.dart';
import '../../theme/tokens.dart';
import '../../utils/format.dart';
import '../../utils/money.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _title = TextEditingController();
  final _amount = TextEditingController();
  DateTime _date = DateTime.now();
  int? _categoryId;
  String? _warn;

  String _displayName(String name) {
    return name
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final parsed = double.tryParse(_amount.text.replaceAll(',', '')) ?? 0;
    final pesewas = cedisToPesewas(parsed);
    if (pesewas <= 0 || _title.text.trim().isEmpty) {
      setState(() => _warn = 'Add an amount and a title.');
      return;
    }
    final db = ref.read(databaseProvider);
    final settings = await db.settings();
    final free = await db.freeMoneyCategory();
    final bucketId = _categoryId ?? free?.id;
    if (bucketId == null) return;
    final bucket = await db.categoryById(bucketId);
    if (bucket.systemKey == freeMoneyKey &&
        bucket.currentAmount - pesewas < settings.freeMoneyWarnPesewas) {
      if (!mounted) return;
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Free money running low'),
          content: Text(
            'This spend leaves ${formatPesewas(bucket.currentAmount - pesewas)} in Free money. Protected buckets stay untouched.',
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: SplytPalette.gold,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Spend anyway')),
          ],
        ),
      );
      if (ok != true) return;
    }
    await db.addExpense(
      categoryId: bucketId,
      amountPesewas: pesewas,
      description: _title.text.trim(),
      date: _date,
    );
    await ref.read(notificationServiceProvider).refreshSchedules();
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final buckets = ref.watch(allBucketsProvider).valueOrNull ?? [];
    final user = ref.watch(userProvider).valueOrNull;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        leading: IconButton(
            onPressed: context.pop, icon: const Icon(Icons.close_rounded)),
        title: const Text('Log expense', style: TextStyle(color: Colors.black)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const Text('Keep your spending visible',
              style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 18),
          _ExpenseField(
            label: 'Amount',
            controller: _amount,
            prefix: '${currencySymbol(user?.currency ?? 'GHS')} ',
            hint: '0.00',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            fontSize: 28,
          ),
          const SizedBox(height: 12),
          _ExpenseField(
            label: 'What was it for?',
            controller: _title,
            hint: 'Title',
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(dayLabel(_date), style: const TextStyle(color: Colors.black)),
            trailing: const Icon(Icons.event_rounded, color: Colors.black),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 1)),
                initialDate: _date,
              );
              if (picked != null) setState(() => _date = picked);
            },
          ),
          const SizedBox(height: 22),
          const Text('Choose a bucket',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final cat in buckets)
                _BucketChoice(
                  label: cat.systemKey == freeMoneyKey ? 'Free money' : _displayName(cat.name),
                  icon: cat.systemKey == freeMoneyKey ? Icons.account_balance_wallet_outlined : iconForKey(cat.icon),
                  selected: _categoryId == cat.id ||
                      (_categoryId == null && cat.systemKey == freeMoneyKey),
                  onTap: () => setState(() => _categoryId = cat.id),
                ),
            ],
          ),
          if (_warn != null) ...[
            const SizedBox(height: 12),
            Text(_warn!, style: const TextStyle(color: Colors.black)),
          ],
          const SizedBox(height: 28),
          FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(
              backgroundColor: SplytPalette.gold,
              foregroundColor: Colors.black,
              minimumSize: const Size.fromHeight(52),
            ),
            child: const Text('Log expense'),
          ),
        ],
      ),
    );
  }
}

class _ExpenseField extends StatelessWidget {
  const _ExpenseField({
    required this.label,
    required this.controller,
    this.prefix,
    this.hint,
    this.keyboardType,
    this.fontSize = 16,
  });

  final String label;
  final TextEditingController controller;
  final String? prefix;
  final String? hint;
  final TextInputType? keyboardType;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(color: Colors.black, fontSize: fontSize, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            prefixText: prefix,
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.black38),
            contentPadding: const EdgeInsets.only(bottom: 8),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.black26)),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: SplytPalette.gold, width: 2)),
          ),
        ),
      ],
    );
  }
}

class _BucketChoice extends StatelessWidget {
  const _BucketChoice({required this.label, required this.icon, required this.selected, required this.onTap});

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? SplytPalette.goldSoft : SplytPalette.cream,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? SplytPalette.gold : Colors.black12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.black, size: 18),
              const SizedBox(width: 7),
              Text(label, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
