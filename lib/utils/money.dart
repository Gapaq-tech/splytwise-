/// Money is stored as integer pesewas (1 cedi = 100 pesewas).
const int pesewasPerCedi = 100;

int cedisToPesewas(num cedis) => (cedis * pesewasPerCedi).round();

double pesewasToCedis(int pesewas) => pesewas / pesewasPerCedi;

class SplitLine {
  const SplitLine({required this.categoryId, required this.percent});

  final int categoryId;
  final double percent;
}

class SettledAllocation {
  const SettledAllocation({
    required this.categoryId,
    required this.amountPesewas,
    required this.percent,
    required this.isFreeMoney,
  });

  final int categoryId;
  final int amountPesewas;
  final double percent;
  final bool isFreeMoney;
}

/// Converts percents into pesewa amounts that always sum to [totalPesewas].
/// Remainder under 100% becomes a Free money allocation.
List<SettledAllocation> settleSplits({
  required int totalPesewas,
  required List<SplitLine> chosen,
  required int freeMoneyCategoryId,
}) {
  final chosenPositive =
      chosen.where((line) => line.percent > 0 && line.categoryId != freeMoneyCategoryId).toList();
  final allocatedPercent = chosenPositive.fold<double>(0, (sum, line) => sum + line.percent);
  final remainderPercent = (100 - allocatedPercent).clamp(0, 100).toDouble();

  final lines = <SplitLine>[
    ...chosenPositive,
    if (remainderPercent > 0.0001)
      SplitLine(categoryId: freeMoneyCategoryId, percent: remainderPercent),
  ];

  if (lines.isEmpty || totalPesewas <= 0) {
    return const [];
  }

  final settled = <SettledAllocation>[];
  var remaining = totalPesewas;
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final isLast = i == lines.length - 1;
    final amount = isLast
        ? remaining
        : ((totalPesewas * line.percent) / 100).round().clamp(0, remaining);
    remaining -= amount;
    settled.add(
      SettledAllocation(
        categoryId: line.categoryId,
        amountPesewas: amount,
        percent: line.percent,
        isFreeMoney: line.categoryId == freeMoneyCategoryId,
      ),
    );
  }
  return settled.where((item) => item.amountPesewas > 0).toList();
}

double allocatedPercentOf(Map<int, double> percents) =>
    percents.values.fold<double>(0, (sum, value) => sum + value);
