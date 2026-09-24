import 'package:flutter_test/flutter_test.dart';
import 'package:splytwise/utils/money.dart';

void main() {
  group('settleSplits', () {
    test('sends remainder under 100% to Free money', () {
      final settled = settleSplits(
        totalPesewas: 10000,
        chosen: const [
          SplitLine(categoryId: 1, percent: 40),
          SplitLine(categoryId: 2, percent: 25),
        ],
        freeMoneyCategoryId: 99,
      );
      expect(settled.fold<int>(0, (s, e) => s + e.amountPesewas), 10000);
      final free = settled.singleWhere((e) => e.isFreeMoney);
      expect(free.percent, 35);
      expect(free.amountPesewas, 3500);
    });

    test('all to Free money when nothing is chosen', () {
      final settled = settleSplits(
        totalPesewas: 500,
        chosen: const [],
        freeMoneyCategoryId: 99,
      );
      expect(settled, hasLength(1));
      expect(settled.first.categoryId, 99);
      expect(settled.first.amountPesewas, 500);
    });

    test('pesewa rounding still sums to the income', () {
      final settled = settleSplits(
        totalPesewas: 100,
        chosen: const [
          SplitLine(categoryId: 1, percent: 33.3),
          SplitLine(categoryId: 2, percent: 33.3),
          SplitLine(categoryId: 3, percent: 33.4),
        ],
        freeMoneyCategoryId: 99,
      );
      expect(settled.any((e) => e.isFreeMoney), isFalse);
      expect(settled.fold<int>(0, (s, e) => s + e.amountPesewas), 100);
    });
  });
}
