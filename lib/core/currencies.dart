/// Catalog of world currencies (ISO 4217) used by the profile picker and
/// for symbol lookup. Popular currencies come first, the rest are grouped
/// by region.
class Currency {
  final String code;
  final String name;
  final String symbol;
  const Currency(this.code, this.name, this.symbol);
}

class Currencies {
  Currencies._();

  static const List<Currency> all = [
    // Popular
    Currency('USD', 'US Dollar', '\$'),
    Currency('EUR', 'Euro', '€'),
    Currency('GBP', 'British Pound', '£'),
    Currency('INR', 'Indian Rupee', '₹'),
    Currency('JPY', 'Japanese Yen', '¥'),
    Currency('CNY', 'Chinese Yuan', 'CN¥'),
    Currency('CAD', 'Canadian Dollar', 'CA\$'),
    Currency('AUD', 'Australian Dollar', 'A\$'),
    Currency('CHF', 'Swiss Franc', 'CHF'),
    Currency('SGD', 'Singapore Dollar', 'S\$'),
    // Americas
    Currency('ARS', 'Argentine Peso', 'AR\$'),
    Currency('BBD', 'Barbadian Dollar', 'Bds\$'),
    Currency('BOB', 'Bolivian Boliviano', 'Bs'),
    Currency('BRL', 'Brazilian Real', 'R\$'),
    Currency('BSD', 'Bahamian Dollar', 'B\$'),
    Currency('BZD', 'Belize Dollar', 'BZ\$'),
    Currency('CLP', 'Chilean Peso', 'CL\$'),
    Currency('COP', 'Colombian Peso', 'CO\$'),
    Currency('CRC', 'Costa Rican Colón', '₡'),
    Currency('CUP', 'Cuban Peso', '\$MN'),
    Currency('DOP', 'Dominican Peso', 'RD\$'),
    Currency('GTQ', 'Guatemalan Quetzal', 'Q'),
    Currency('HNL', 'Honduran Lempira', 'L'),
    Currency('HTG', 'Haitian Gourde', 'G'),
    Currency('JMD', 'Jamaican Dollar', 'J\$'),
    Currency('MXN', 'Mexican Peso', 'MX\$'),
    Currency('NIO', 'Nicaraguan Córdoba', 'C\$'),
    Currency('PAB', 'Panamanian Balboa', 'B/.'),
    Currency('PEN', 'Peruvian Sol', 'S/'),
    Currency('PYG', 'Paraguayan Guaraní', '₲'),
    Currency('TTD', 'Trinidad & Tobago Dollar', 'TT\$'),
    Currency('UYU', 'Uruguayan Peso', '\$U'),
    Currency('VES', 'Venezuelan Bolívar', 'Bs.'),
    Currency('XCD', 'East Caribbean Dollar', 'EC\$'),
    // Europe
    Currency('ALL', 'Albanian Lek', 'L'),
    Currency('AMD', 'Armenian Dram', '֏'),
    Currency('AZN', 'Azerbaijani Manat', '₼'),
    Currency('BAM', 'Bosnian Convertible Mark', 'KM'),
    Currency('BGN', 'Bulgarian Lev', 'лв'),
    Currency('BYN', 'Belarusian Ruble', 'Br'),
    Currency('CZK', 'Czech Koruna', 'Kč'),
    Currency('DKK', 'Danish Krone', 'kr'),
    Currency('GEL', 'Georgian Lari', '₾'),
    Currency('HUF', 'Hungarian Forint', 'Ft'),
    Currency('ISK', 'Icelandic Króna', 'kr'),
    Currency('MDL', 'Moldovan Leu', 'L'),
    Currency('MKD', 'Macedonian Denar', 'ден'),
    Currency('NOK', 'Norwegian Krone', 'kr'),
    Currency('PLN', 'Polish Złoty', 'zł'),
    Currency('RON', 'Romanian Leu', 'lei'),
    Currency('RSD', 'Serbian Dinar', 'дин'),
    Currency('RUB', 'Russian Ruble', '₽'),
    Currency('SEK', 'Swedish Krona', 'kr'),
    Currency('TRY', 'Turkish Lira', '₺'),
    Currency('UAH', 'Ukrainian Hryvnia', '₴'),
    // Middle East
    Currency('AED', 'UAE Dirham', 'د.إ'),
    Currency('BHD', 'Bahraini Dinar', 'BD'),
    Currency('ILS', 'Israeli New Shekel', '₪'),
    Currency('IQD', 'Iraqi Dinar', 'ع.د'),
    Currency('IRR', 'Iranian Rial', '﷼'),
    Currency('JOD', 'Jordanian Dinar', 'JD'),
    Currency('KWD', 'Kuwaiti Dinar', 'KD'),
    Currency('LBP', 'Lebanese Pound', 'ل.ل'),
    Currency('OMR', 'Omani Rial', 'ر.ع.'),
    Currency('QAR', 'Qatari Riyal', 'QR'),
    Currency('SAR', 'Saudi Riyal', 'SR'),
    Currency('YER', 'Yemeni Rial', '﷼'),
    // Africa
    Currency('AOA', 'Angolan Kwanza', 'Kz'),
    Currency('BWP', 'Botswana Pula', 'P'),
    Currency('DZD', 'Algerian Dinar', 'دج'),
    Currency('EGP', 'Egyptian Pound', 'E£'),
    Currency('ETB', 'Ethiopian Birr', 'Br'),
    Currency('GHS', 'Ghanaian Cedi', 'GH₵'),
    Currency('KES', 'Kenyan Shilling', 'KSh'),
    Currency('LYD', 'Libyan Dinar', 'LD'),
    Currency('MAD', 'Moroccan Dirham', 'DH'),
    Currency('MUR', 'Mauritian Rupee', '₨'),
    Currency('MWK', 'Malawian Kwacha', 'MK'),
    Currency('MZN', 'Mozambican Metical', 'MT'),
    Currency('NAD', 'Namibian Dollar', 'N\$'),
    Currency('NGN', 'Nigerian Naira', '₦'),
    Currency('RWF', 'Rwandan Franc', 'FRw'),
    Currency('SCR', 'Seychellois Rupee', 'SR'),
    Currency('SDG', 'Sudanese Pound', 'SDG'),
    Currency('TND', 'Tunisian Dinar', 'DT'),
    Currency('TZS', 'Tanzanian Shilling', 'TSh'),
    Currency('UGX', 'Ugandan Shilling', 'USh'),
    Currency('XAF', 'Central African CFA Franc', 'FCFA'),
    Currency('XOF', 'West African CFA Franc', 'CFA'),
    Currency('ZAR', 'South African Rand', 'R'),
    Currency('ZMW', 'Zambian Kwacha', 'ZK'),
    // Asia-Pacific
    Currency('AFN', 'Afghan Afghani', '؋'),
    Currency('BDT', 'Bangladeshi Taka', '৳'),
    Currency('BND', 'Brunei Dollar', 'B\$'),
    Currency('BTN', 'Bhutanese Ngultrum', 'Nu.'),
    Currency('FJD', 'Fijian Dollar', 'FJ\$'),
    Currency('HKD', 'Hong Kong Dollar', 'HK\$'),
    Currency('IDR', 'Indonesian Rupiah', 'Rp'),
    Currency('KGS', 'Kyrgyzstani Som', 'с'),
    Currency('KHR', 'Cambodian Riel', '៛'),
    Currency('KRW', 'South Korean Won', '₩'),
    Currency('KZT', 'Kazakhstani Tenge', '₸'),
    Currency('LAK', 'Lao Kip', '₭'),
    Currency('LKR', 'Sri Lankan Rupee', 'Rs'),
    Currency('MMK', 'Myanmar Kyat', 'K'),
    Currency('MNT', 'Mongolian Tögrög', '₮'),
    Currency('MVR', 'Maldivian Rufiyaa', 'Rf'),
    Currency('MYR', 'Malaysian Ringgit', 'RM'),
    Currency('NPR', 'Nepalese Rupee', 'रू'),
    Currency('NZD', 'New Zealand Dollar', 'NZ\$'),
    Currency('PGK', 'Papua New Guinean Kina', 'K'),
    Currency('PHP', 'Philippine Peso', '₱'),
    Currency('PKR', 'Pakistani Rupee', 'Rs'),
    Currency('THB', 'Thai Baht', '฿'),
    Currency('TJS', 'Tajikistani Somoni', 'SM'),
    Currency('TMT', 'Turkmenistani Manat', 'm'),
    Currency('TOP', 'Tongan Paʻanga', 'T\$'),
    Currency('TWD', 'New Taiwan Dollar', 'NT\$'),
    Currency('UZS', 'Uzbekistani Som', 'soʻm'),
    Currency('VND', 'Vietnamese Dong', '₫'),
    Currency('WST', 'Samoan Tala', 'WS\$'),
  ];

  /// Symbol for [code], falling back to the code itself when unknown.
  static String symbolFor(String code) {
    for (final c in all) {
      if (c.code == code) return c.symbol;
    }
    return code;
  }
}
