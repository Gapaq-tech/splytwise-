import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import '../utils/money.dart';
import 'app_providers.dart';

class AddIncomeState {
  const AddIncomeState({
    this.step = 0,
    this.amountPesewas = 0,
    this.source = '',
    this.date,
    this.selectedIds = const {},
    this.percents = const {},
    this.submitting = false,
    this.error,
  });

  final int step;
  final int amountPesewas;
  final String source;
  final DateTime? date;
  final Set<int> selectedIds;
  final Map<int, double> percents;
  final bool submitting;
  final String? error;

  double get allocatedPercent => allocatedPercentOf(percents);
  double get remainderPercent => (100 - allocatedPercent).clamp(0, 100);

  AddIncomeState copyWith({
    int? step,
    int? amountPesewas,
    String? source,
    DateTime? date,
    Set<int>? selectedIds,
    Map<int, double>? percents,
    bool? submitting,
    String? error,
    bool clearError = false,
  }) {
    return AddIncomeState(
      step: step ?? this.step,
      amountPesewas: amountPesewas ?? this.amountPesewas,
      source: source ?? this.source,
      date: date ?? this.date,
      selectedIds: selectedIds ?? this.selectedIds,
      percents: percents ?? this.percents,
      submitting: submitting ?? this.submitting,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class SplitCommit {
  const SplitCommit({
    required this.incomeId,
    required this.amountPesewas,
    required this.source,
    required this.settled,
    required this.completedGoalIds,
  });

  final int incomeId;
  final int amountPesewas;
  final String source;
  final List<SettledAllocation> settled;
  final List<int> completedGoalIds;
}

class AddIncomeController extends Notifier<AddIncomeState> {
  @override
  AddIncomeState build() => AddIncomeState(date: DateTime.now());

  void setAmountFromCedis(String raw) {
    final parsed = double.tryParse(raw.replaceAll(',', '')) ?? 0;
    state = state.copyWith(amountPesewas: cedisToPesewas(parsed), clearError: true);
  }

  void setSource(String source) => state = state.copyWith(source: source);

  void setDate(DateTime date) => state = state.copyWith(date: date);

  void nextFromDetails() {
    if (state.amountPesewas <= 0 || state.source.trim().isEmpty) {
      state = state.copyWith(error: 'Enter an amount and where it came from.');
      return;
    }
    state = state.copyWith(step: 1, clearError: true);
  }

  void back() {
    if (state.step > 0) state = state.copyWith(step: state.step - 1);
  }

  void toggleCategory(int id) {
    final selected = {...state.selectedIds};
    final percents = {...state.percents};
    if (selected.contains(id)) {
      selected.remove(id);
      percents.remove(id);
    } else {
      selected.add(id);
      percents[id] = 0;
    }
    state = state.copyWith(selectedIds: selected, percents: percents);
  }

  void setPercent(int id, double percent) {
    final next = percent.clamp(0, 100).toDouble();
    final percents = {...state.percents, id: next};
    final others = percents.entries.where((e) => e.key != id).fold<double>(0, (s, e) => s + e.value);
    if (others + next > 100) {
      percents[id] = (100 - others).clamp(0, 100);
    }
    state = state.copyWith(percents: percents);
  }

  void bumpPercent(int id, double delta) => setPercent(id, (state.percents[id] ?? 0) + delta);

  void evenSplit() {
    if (state.selectedIds.isEmpty) return;
    final share = (100 / state.selectedIds.length * 10).floor() / 10;
    final percents = {for (final id in state.selectedIds) id: share};
    final keys = percents.keys.toList();
    percents[keys.last] = 100 - share * (keys.length - 1);
    state = state.copyWith(percents: percents);
  }

  Future<SplitCommit?> confirm() async {
    if (state.selectedIds.isEmpty && state.remainderPercent <= 0) {
      state = state.copyWith(error: 'Pick at least one place for this money — or send it all to Free money.');
      return null;
    }
    state = state.copyWith(submitting: true, clearError: true);
    final db = ref.read(databaseProvider);
    final freeId = await db.freeMoneyId();
    final settled = settleSplits(
      totalPesewas: state.amountPesewas,
      chosen: [
        for (final id in state.selectedIds)
          SplitLine(categoryId: id, percent: state.percents[id] ?? 0),
      ],
      freeMoneyCategoryId: freeId,
    );
    if (settled.isEmpty) {
      state = state.copyWith(submitting: false, error: 'Nothing to allocate.');
      return null;
    }
    final result = await db.addIncomeWithAllocations(
      amountPesewas: state.amountPesewas,
      source: state.source.trim(),
      date: state.date ?? DateTime.now(),
      splits: settled,
    );
    await ref.read(notificationServiceProvider).refreshSchedules();
    state = state.copyWith(submitting: false);
    return SplitCommit(
      incomeId: result.incomeId,
      amountPesewas: state.amountPesewas,
      source: state.source.trim(),
      settled: settled,
      completedGoalIds: result.completedGoalIds,
    );
  }

  void reset() => state = AddIncomeState(date: DateTime.now());
}

final addIncomeProvider = NotifierProvider<AddIncomeController, AddIncomeState>(
  AddIncomeController.new,
);
