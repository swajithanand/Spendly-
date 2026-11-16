import 'package:intl/intl.dart';

/// Formats money amounts for display (without the currency symbol).
///
/// Whole amounts show no decimals ("1,450"); anything else always shows two
/// ("4.20", never "4.2"). Currencies that conventionally use lakh/crore
/// grouping get it ("1,50,000").
class MoneyFormat {
  final String currencyCode;
  const MoneyFormat(this.currencyCode);

  static const _indianGrouping = {'INR', 'PKR', 'BDT', 'NPR', 'LKR'};

  String format(num value) {
    final cents = (value * 100).round();
    final whole = cents % 100 == 0;
    final grouping =
        _indianGrouping.contains(currencyCode) ? '#,##,##0' : '#,##0';
    return NumberFormat(whole ? grouping : '$grouping.00', 'en_US')
        .format(cents / 100);
  }
}
