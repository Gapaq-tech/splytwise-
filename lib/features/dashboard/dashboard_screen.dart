import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/db/app_database.dart';
import '../../providers/app_providers.dart';
import '../../providers/dashboard_provider.dart';
import '../../theme/tokens.dart';
import '../../utils/format.dart';

String _maskValue(String value) => '********';

String _timeGreeting(DateTime time) {
  if (time.hour < 12) return 'Good morning';
  if (time.hour < 18) return 'Good afternoon';
  return 'Good evening';
}

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _balanceVisible = true;
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider).valueOrNull;
    final dashboard = ref.watch(dashboardProvider);
    final currency = user?.currency ?? 'GHS';
    final name = user?.name.trim();
    final fullName = (name != null && name.isNotEmpty) ? name : 'there';
    final firstName = fullName.split(RegExp(r'\s+')).first;
    final now = DateTime.now();

    return dashboard.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Could not load your dashboard\n$error')),
      data: (snapshot) {
        final freeMoney = snapshot.freeMoney?.currentAmount ?? 0;
        final balance = formatPesewas(snapshot.totalBalance, currency: currency);
        final freeLabel = formatPesewas(
          freeMoney < 0 ? 0 : freeMoney,
          currency: currency,
        );

        return ColoredBox(
          color: Colors.white,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TopBar(
                    greeting: _timeGreeting(now),
                    name: firstName,
                    date: dayLabel(now),
                    onProfile: () => context.push('/settings'),
                    onNotifications: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('You are all caught up.')),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  _BalanceSection(
                    balance: _balanceVisible ? balance : _maskValue(balance),
                    freeMoney: _balanceVisible ? freeLabel : _maskValue(freeLabel),
                    goalSaved: _balanceVisible
                        ? formatPesewas(snapshot.goalSaved, currency: currency)
                        : _maskValue(formatPesewas(snapshot.goalSaved, currency: currency)),
                    visible: _balanceVisible,
                    onToggle: () => setState(() => _balanceVisible = !_balanceVisible),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _Metric(
                          icon: Icons.local_fire_department_outlined,
                          label: 'Momentum',
                          value: snapshot.weeksOnTrack == 0
                              ? 'Start today'
                              : '${snapshot.weeksOnTrack} week${snapshot.weeksOnTrack == 1 ? '' : 's'}',
                          color: SplytPalette.gold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _Metric(
                          icon: Icons.show_chart_rounded,
                          label: 'Spent this month',
                          value: formatPesewas(snapshot.spentThisMonth, currency: currency),
                          color: Colors.black,
                          onTap: () => context.push('/recap'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: _SpendingList(
                      rows: snapshot.spendByBucket,
                      total: snapshot.spentThisMonth,
                      currency: currency,
                    ),
                  ),
                  if (snapshot.protectedWarnings.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _LowMoneyNotice(
                      amount: formatPesewas(freeMoney.abs(), currency: currency),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.greeting, required this.name, required this.date, required this.onProfile, required this.onNotifications});

  final String greeting;
  final String name;
  final String date;
  final VoidCallback onProfile;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SmallIcon(icon: Icons.person_outline_rounded, tooltip: 'Profile', onTap: onProfile),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '$greeting, $name',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(date, style: const TextStyle(color: Colors.black54)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _SmallIcon(icon: Icons.notifications_none_rounded, tooltip: 'Notifications', onTap: onNotifications),
      ],
    );
  }
}

class _SmallIcon extends StatelessWidget {
  const _SmallIcon({required this.icon, required this.tooltip, required this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      icon: Icon(icon, color: Colors.black, size: 23),
      style: IconButton.styleFrom(
        backgroundColor: SplytPalette.cream,
        fixedSize: const Size(44, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _BalanceSection extends StatelessWidget {
  const _BalanceSection({required this.balance, required this.freeMoney, required this.goalSaved, required this.visible, required this.onToggle});

  final String balance;
  final String freeMoney;
  final String goalSaved;
  final bool visible;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SplytPalette.cream),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: Text('AVAILABLE BALANCE', style: TextStyle(color: Colors.black54, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.1))),
            IconButton(
              onPressed: onToggle,
              tooltip: visible ? 'Hide balance' : 'Show balance',
              icon: Icon(visible ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.black54, size: 21),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          balance,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 38,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 16),
        const Divider(color: SplytPalette.cream, height: 1),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _BalanceValue(label: 'Free money', value: freeMoney, color: Colors.black)),
            Expanded(child: _BalanceValue(label: 'Toward goals', value: goalSaved, color: SplytPalette.gold)),
          ],
        ),
      ],
      ),
    );
  }
}

class _BalanceValue extends StatelessWidget {
  const _BalanceValue({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 16)),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.label, required this.value, required this.color, this.onTap});

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black54, fontSize: 11)),
                  const SizedBox(height: 3),
                  FittedBox(alignment: Alignment.centerLeft, fit: BoxFit.scaleDown, child: Text(value, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 15))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LowMoneyNotice extends StatelessWidget {
  const _LowMoneyNotice({required this.amount});

  final String amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: SplytPalette.goldSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SplytPalette.gold.withValues(alpha: 0.55)),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_none_rounded,
              color: Colors.black, size: 19),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Free money is low. You are $amount over.',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpendingList extends StatelessWidget {
  const _SpendingList({required this.rows, required this.total, required this.currency});

  final List<({Category category, int spent})> rows;
  final int total;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final visibleRows = rows.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: Text('Spending this month', style: TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.w700))),
            Text(formatPesewas(total, currency: currency), style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 14),
        if (visibleRows.isEmpty)
          const Text('No spending yet. That is a kind of win.', style: TextStyle(color: Colors.black54))
        else
          for (final row in visibleRows) ...[
            _SpendingRow(row: row, total: total, currency: currency),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _SpendingRow extends StatelessWidget {
  const _SpendingRow({required this.row, required this.total, required this.currency});

  final ({Category category, int spent}) row;
  final int total;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : (row.spent / total).clamp(0.0, 1.0);
    const color = SplytPalette.gold;
    return Column(
      children: [
        Row(
          children: [
            const SizedBox(
              width: 9,
              height: 9,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: SplytPalette.gold,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(row.category.name, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600))),
            Text(formatPesewas(row.spent, currency: currency), style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: ratio, minHeight: 4, backgroundColor: SplytPalette.cream, valueColor: const AlwaysStoppedAnimation<Color>(color)),
        ),
      ],
    );
  }
}
