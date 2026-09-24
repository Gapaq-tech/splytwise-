import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../utils/format.dart';
import '../../widgets/ui_kit.dart';

class MonthlyRecapScreen extends ConsumerWidget {
  const MonthlyRecapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final recap = ref.watch(monthlyRecapProvider);
    final user = ref.watch(userProvider).valueOrNull;
    final currency = user?.currency ?? 'GHS';

    return Scaffold(
      appBar: AppBar(title: Text(monthLabel(now))),
      body: recap.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (data) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('This month, in one breath',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, height: 1.1)),
              const SizedBox(height: 16),
              GlowCard(
                color: SplytPalette.mint.withOpacity(0.12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('You put toward goals', style: TextStyle(color: SplytPalette.mute)),
                    MoneyText(formatPesewas(data.savedPesewas, currency: currency), fontSize: 36),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GlowCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('You spent', style: TextStyle(color: SplytPalette.mute)),
                    MoneyText(
                      formatPesewas(data.spentPesewas, currency: currency),
                      fontSize: 28,
                      color: SplytPalette.coral,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      data.topSpendBucket == null
                          ? 'No spend leader yet.'
                          : 'Most of it went to ${data.topSpendBucket}.',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GlowCard(
                child: Text(
                  data.incomeCount == 0
                      ? 'No inflows logged this month. Split the next one.'
                      : '${data.incomeCount} inflow${data.incomeCount == 1 ? '' : 's'} given a job.',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
