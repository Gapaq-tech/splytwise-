import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/add_income_provider.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../utils/format.dart';
import '../../widgets/ui_kit.dart';

class AddIncomeFlow extends ConsumerWidget {
  const AddIncomeFlow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addIncomeProvider);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            ref.read(addIncomeProvider.notifier).reset();
            context.pop();
          },
        ),
        title: Text(state.step == 0 ? 'New income' : 'Where should it go?'),
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('How much landed?', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('Source next — salary, momo, side hustle, whatever.',
              style: TextStyle(color: Colors.white.withOpacity(0.65))),
          const SizedBox(height: 24),
          TextField(
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
            decoration: InputDecoration(
              prefixText: '${currencySymbol(user?.currency ?? 'GHS')} ',
              hintText: '0.00',
              filled: true,
              fillColor: SplytPalette.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
            ),
            onChanged: ref.read(addIncomeProvider.notifier).setAmountFromCedis,
          ),
          const SizedBox(height: 16),
          TextField(
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Source — e.g. Salary, MoMo, Freelance',
              filled: true,
              fillColor: SplytPalette.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
            ),
            onChanged: ref.read(addIncomeProvider.notifier).setSource,
          ),
          if (state.error != null) ...[
            const SizedBox(height: 12),
            Text(state.error!, style: const TextStyle(color: SplytPalette.coral)),
          ],
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: SplytPalette.mint,
                foregroundColor: SplytPalette.deep,
              ),
              onPressed: ref.read(addIncomeProvider.notifier).nextFromDetails,
              child: const Text('Allocate this'),
            ),
          ),
        ],
      ),
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
    if (hit100) HapticFeedback.mediumImpact();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: GlowCard(
            color: hit100 ? SplytPalette.mint.withOpacity(0.16) : SplytPalette.surfaceHigh,
            child: Column(
              children: [
                MoneyText(formatPesewas(state.amountPesewas, currency: currency), fontSize: 28),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (state.allocatedPercent / 100).clamp(0, 1),
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(20),
                  color: hit100 ? SplytPalette.mint : SplytPalette.coral,
                  backgroundColor: Colors.white12,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text('${formatPercent(state.allocatedPercent)} allocated',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Text(
                      '${formatPercent(state.remainderPercent)} Free money',
                      style: TextStyle(
                        color: state.remainderPercent > 0 ? SplytPalette.mint : SplytPalette.mute,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                if (hit100)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('Locked in — every cedi has a job.',
                        style: TextStyle(color: SplytPalette.mint, fontWeight: FontWeight.w700)),
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
                onPressed: buckets.isEmpty ? null : ref.read(addIncomeProvider.notifier).evenSplit,
                child: const Text('Split evenly'),
              ),
            ],
          ),
        ),
        Expanded(
          child: buckets.isEmpty
              ? const Center(child: Text('Add a category or goal first — or send it all to Free money.'))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: buckets.length,
                  itemBuilder: (context, i) {
                    final cat = buckets[i];
                    final selected = state.selectedIds.contains(cat.id);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GlowCard(
                        color: selected ? Color(cat.color).withOpacity(0.12) : null,
                        onTap: () => ref.read(addIncomeProvider.notifier).toggleCategory(cat.id),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                GlyphBadge(iconKey: cat.icon, color: Color(cat.color)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                                      Text(
                                        cat.isGoal
                                            ? 'Goal · ${formatPesewas(cat.currentAmount, currency: currency)} / ${formatPesewas(cat.targetAmount ?? 0, currency: currency)}'
                                            : 'Category',
                                        style: const TextStyle(color: SplytPalette.mute, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                                  color: selected ? SplytPalette.mint : SplytPalette.mute,
                                ),
                              ],
                            ),
                            if (selected) ...[
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  formatPercent(state.percents[cat.id] ?? 0),
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                                ),
                              ),
                              PercentStepper(
                                value: state.percents[cat.id] ?? 0,
                                onChanged: (v) => ref.read(addIncomeProvider.notifier).setPercent(cat.id, v),
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
            child: Text(state.error!, style: const TextStyle(color: SplytPalette.coral)),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: SplytPalette.mint,
                foregroundColor: SplytPalette.deep,
              ),
              onPressed: state.submitting
                  ? null
                  : () async {
                      final commit = await ref.read(addIncomeProvider.notifier).confirm();
                      if (commit != null && context.mounted) {
                        ref.read(addIncomeProvider.notifier).reset();
                        context.pushReplacement('/income/result', extra: commit);
                      }
                    },
              child: state.submitting
                  ? const CircularProgressIndicator()
                  : Text(state.remainderPercent > 0 ? 'Confirm · remainder is Free money' : 'Confirm split'),
            ),
          ),
        ),
      ],
    );
  }
}
