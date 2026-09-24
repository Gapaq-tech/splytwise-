import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/db/app_database.dart';
import '../../providers/add_income_provider.dart';
import '../../providers/app_providers.dart';
import '../../theme/tokens.dart';
import '../../utils/format.dart';
import '../../widgets/ui_kit.dart';

class AddIncomeFlow extends ConsumerWidget {
  const AddIncomeFlow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addIncomeProvider);
    ref.listen(addIncomeProvider, (prev, next) {
      if ((prev?.allocatedPercent ?? 0) < 99.95 &&
          next.allocatedPercent >= 99.95) {
        HapticFeedback.mediumImpact();
      }
    });
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            ref.read(addIncomeProvider.notifier).reset();
            context.pop();
          },
        ),
        title: Text(
          state.step == 0 ? 'New income' : 'Where should it go?',
          style: const TextStyle(color: Colors.black),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        child: state.step == 0 ? const _DetailsStep() : const _AllocateStep(),
      ),
    );
  }
}

class _DetailsStep extends ConsumerWidget {
  const _DetailsStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addIncomeProvider);
    final user = ref.watch(userProvider).valueOrNull;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('How much landed?',
              style: TextStyle(color: Colors.black, fontSize: 25, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text('Add the source and give this money a clear job.',
              style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 22),
          _IncomeField(
            label: 'Amount',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefix: '${currencySymbol(user?.currency ?? 'GHS')} ',
            hint: '0.00',
            onChanged: ref.read(addIncomeProvider.notifier).setAmountFromCedis,
          ),
          const SizedBox(height: 16),
          _IncomeField(
            label: 'Source',
            hint: 'Salary, MoMo, Freelance',
            textCapitalization: TextCapitalization.sentences,
            onChanged: ref.read(addIncomeProvider.notifier).setSource,
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(dayLabel(state.date ?? DateTime.now()), style: const TextStyle(color: Colors.black)),
            trailing: const Icon(Icons.event_rounded, color: Colors.black),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 1)),
                initialDate: state.date ?? DateTime.now(),
              );
              if (picked != null) {
                ref.read(addIncomeProvider.notifier).setDate(picked);
              }
            },
          ),
          if (state.error != null) ...[
            const SizedBox(height: 12),
            Text(state.error!,
                style: const TextStyle(color: Colors.black)),
          ],
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: SplytPalette.gold,
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: ref.read(addIncomeProvider.notifier).nextFromDetails,
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }
}

class _IncomeField extends StatelessWidget {
  const _IncomeField({
    required this.label,
    this.prefix,
    this.hint,
    this.keyboardType,
    this.textCapitalization,
    required this.onChanged,
  });

  final String label;
  final String? prefix;
  final String? hint;
  final TextInputType? keyboardType;
  final TextCapitalization? textCapitalization;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 5),
        TextField(
          keyboardType: keyboardType,
          textCapitalization: textCapitalization ?? TextCapitalization.none,
          style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            prefixText: prefix,
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.black38),
            contentPadding: const EdgeInsets.only(bottom: 8),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.black26)),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: SplytPalette.gold, width: 2)),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _AllocateStep extends ConsumerWidget {
  const _AllocateStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addIncomeProvider);
    final buckets = ref.watch(allocatableProvider).valueOrNull ?? [];
    final user = ref.watch(userProvider).valueOrNull;
    final currency = user?.currency ?? 'GHS';
    final hit100 = state.allocatedPercent >= 99.95;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: SplytPalette.cream,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: SplytPalette.gold.withValues(alpha: 0.55)),
            ),
            child: Column(
              children: [
                Text(
                  formatPesewas(state.amountPesewas, currency: currency),
                  style: const TextStyle(color: Colors.black, fontSize: 28, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (state.allocatedPercent / 100).clamp(0, 1),
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(20),
                  color: SplytPalette.gold,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text('${formatPercent(state.allocatedPercent)} allocated',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Text(
                      '${formatPercent(state.remainderPercent)} Free money',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                if (hit100)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('Locked in — every cedi has a job.',
                        style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(
            children: [
              TextButton(
                onPressed: ref.read(addIncomeProvider.notifier).back,
                child: const Text('Back'),
              ),
              const Spacer(),
              TextButton(
                onPressed: buckets.isEmpty
                    ? null
                    : () => ref.read(addIncomeProvider.notifier).evenSplit(
                          fallbackIds: buckets.map((b) => b.id),
                        ),
                child: const Text('Split evenly'),
              ),
            ],
          ),
        ),
        Expanded(
          child: buckets.isEmpty
              ? const Center(
                  child: Text(
                      'Add a category or goal first — or send it all to Free money.'))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: buckets.length,
                  itemBuilder: (context, i) {
                    final cat = buckets[i];
                    final selected = state.selectedIds.contains(cat.id);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        onTap: () => ref.read(addIncomeProvider.notifier).toggleCategory(cat.id),
                        borderRadius: BorderRadius.circular(12),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: selected ? SplytPalette.goldSoft : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: selected ? SplytPalette.gold : Colors.black12),
                              ),
                              child: Row(
                                children: [
                                Icon(
                                    cat.systemKey == freeMoneyKey
                                        ? Icons.account_balance_wallet_outlined
                                        : iconForKey(cat.icon),
                                    color: Colors.black,
                                    size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                        Text(cat.systemKey == freeMoneyKey ? 'Free money' : cat.name,
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.w700)),
                                      Text(
                                        cat.isGoal
                                            ? 'Goal · ${formatPesewas(cat.currentAmount, currency: currency)} / ${formatPesewas(cat.targetAmount ?? 0, currency: currency)}'
                                            : 'Category',
                                        style: const TextStyle(
                                            color: Colors.black54,
                                            fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  selected
                                      ? Icons.check_circle_rounded
                                      : Icons.circle_outlined,
                                  color: selected ? Colors.black : Colors.black54,
                                ),
                                ],
                              ),
                            ),
                            if (selected) ...[
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  formatPercent(state.percents[cat.id] ?? 0),
                                  style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18),
                                ),
                              ),
                              PercentStepper(
                                value: state.percents[cat.id] ?? 0,
                                onChanged: (v) => ref
                                    .read(addIncomeProvider.notifier)
                                    .setPercent(cat.id, v),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        if (state.error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(state.error!,
              style: const TextStyle(color: Colors.black)),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: SplytPalette.gold,
                foregroundColor: Colors.black,
              ),
              onPressed: state.submitting
                  ? null
                  : () async {
                      final commit =
                          await ref.read(addIncomeProvider.notifier).confirm();
                      if (commit != null && context.mounted) {
                        ref.read(addIncomeProvider.notifier).reset();
                        context.pushReplacement('/income/result',
                            extra: commit);
                      }
                    },
              child: state.submitting
                  ? const CircularProgressIndicator()
                  : Text(state.remainderPercent > 0
                      ? 'Confirm · remainder is Free money'
                      : 'Confirm split'),
            ),
          ),
        ),
      ],
    );
  }
}
