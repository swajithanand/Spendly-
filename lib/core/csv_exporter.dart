import 'package:intl/intl.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';

/// Builds a CSV (RFC 4180) document from a list of transactions.
class CsvExporter {
  CsvExporter._();

  static String build(
    List<TransactionModel> txs,
    List<CategoryModel> categories,
    String currency,
  ) {
    final catById = {for (final c in categories) c.id: c.name};
    final date = DateFormat('yyyy-MM-dd');
    final time = DateFormat('HH:mm');

    final buf = StringBuffer(
        'Date,Time,Label,Category,Subcategory,Amount,Currency\r\n');
    for (final t in txs) {
      buf.writeAll([
        date.format(t.createdAt),
        time.format(t.createdAt),
        _esc(t.label),
        _esc(catById[t.categoryId] ?? ''),
        _esc(t.subcategory),
        t.amount.toStringAsFixed(2),
        currency,
      ], ',');
      buf.write('\r\n');
    }
    return buf.toString();
  }

  /// Quotes a field when it contains a comma, quote, or newline.
  static String _esc(String v) {
    if (v.contains(',') || v.contains('"') || v.contains('\n')) {
      return '"${v.replaceAll('"', '""')}"';
    }
    return v;
  }
}
