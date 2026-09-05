import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/db/app_database.dart';
import '../../providers/app_providers.dart';
import '../../theme/tokens.dart';
import '../../utils/format.dart';
import '../../utils/money.dart';
import '../../widgets/ui_kit.dart';

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
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Free money running low'),
          content: Text(
            'This spend leaves ${formatPesewas(bucket.currentAmount - pesewas)} in Free money. Protected buckets stay untouched.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Spend anyway')),
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
      appBar: AppBar(title: const Text('Add expense')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            decoration: InputDecoration(
              prefixText: '${currencySymbol(user?.currency ?? 'GHS')} ',
              hintText: '0.00',
              filled: true,
              fillColor: SplytPalette.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _title,
            decoration: InputDecoration(
              hintText: 'Title',
              filled: true,
              fillColor: SplytPalette.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(dayLabel(_date)),
            trailing: const Icon(Icons.event_rounded),
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
          const SizedBox(height: 8),
          const Text('Charge to', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final cat in buckets)
                ChoiceChip(
                  avatar: GlyphBadge(iconKey: cat.icon, color: Color(cat.color), size: 28),
                  label: Text(cat.name),
                  selected: _categoryId == cat.id || (_categoryId == null && cat.systemKey == freeMoneyKey),
                  onSelected: (_) => setState(() => _categoryId = cat.id),
                ),
            ],
          ),
          if (_warn != null) ...[
            const SizedBox(height: 12),
            Text(_warn!, style: const TextStyle(color: SplytPalette.coral)),
          ],
          const SizedBox(height: 24),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: SplytPalette.coral,
              minimumSize: const Size.fromHeight(56),
            ),
            onPressed: _save,
            child: const Text('Log expense'),
          ),
        ],
      ),
    );
  }
}
