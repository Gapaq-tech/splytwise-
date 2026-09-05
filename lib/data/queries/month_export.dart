import 'package:csv/csv.dart';
import 'package:intl/intl.dart';

import '../db/app_database.dart';
import '../../utils/format.dart';

/// Scaffold for month export. CSV is ready; PDF can wrap the same rows later.
class MonthExportQuery {
  MonthExportQuery(this.db);

  final AppDatabase db;

  Future<List<MonthExportRow>> rowsFor(DateTime month) => db.monthExport(month);

  Future<String> csvFor(DateTime month, {String currency = 'GHS'}) async {
    final rows = await rowsFor(month);
    final table = <List<dynamic>>[
      ['date', 'kind', 'title', 'bucket', 'amount'],
      ...rows.map(
        (row) => [
          DateFormat('yyyy-MM-dd').format(row.date),
          row.kind,
          row.title,
          row.bucket,
          formatPesewas(row.amountPesewas, currency: currency),
        ],
      ),
    ];
    return const ListToCsvConverter().convert(table);
  }
}
