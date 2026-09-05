import 'package:intl/intl.dart';

import 'money.dart';

String currencySymbol(String code) {
  switch (code) {
    case 'GHS':
      return 'GH₵';
    case 'USD':
      return '\$';
    case 'EUR':
      return '€';
    case 'GBP':
      return '£';
    default:
      return code;
  }
}

final _number = NumberFormat('#,##0.00');

String formatPesewas(int pesewas, {String currency = 'GHS', bool compact = false}) {
  final value = pesewasToCedis(pesewas);
  if (compact && value.abs() >= 1000) {
    return '${currencySymbol(currency)}${(value / 1000).toStringAsFixed(value >= 10000 ? 0 : 1)}k';
  }
  return '${currencySymbol(currency)}${_number.format(value)}';
}

String formatPercent(double value) {
  if (value == value.roundToDouble()) {
    return '${value.round()}%';
  }
  return '${value.toStringAsFixed(1)}%';
}

String monthLabel(DateTime date) => DateFormat('MMMM y').format(date);

String dayLabel(DateTime date) => DateFormat('EEE d MMM').format(date);
