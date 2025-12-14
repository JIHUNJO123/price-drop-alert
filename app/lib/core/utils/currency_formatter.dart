/// Currency formatting utility for global price display
class CurrencyFormatter {
  /// Currency symbols
  static const Map<String, String> currencySymbols = {
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
    'CAD': 'CA\$',
    'AUD': 'A\$',
    'BRL': 'R\$',
    'MXN': 'MX\$',
    'INR': '₹',
    'PLN': 'zł',
    'SEK': 'kr',
    'SGD': 'S\$',
    'AED': 'AED',
    'SAR': 'SAR',
  };
  
  /// Currency locale mapping
  static const Map<String, String> currencyLocales = {
    'USD': 'en_US',
    'EUR': 'de_DE',
    'GBP': 'en_GB',
    'JPY': 'ja_JP',
    'CAD': 'en_CA',
    'AUD': 'en_AU',
    'BRL': 'pt_BR',
    'MXN': 'es_MX',
    'INR': 'en_IN',
    'PLN': 'pl_PL',
    'SEK': 'sv_SE',
    'SGD': 'en_SG',
    'AED': 'ar_AE',
    'SAR': 'ar_SA',
  };
  
  /// Get currency symbol
  static String getSymbol(String currency) {
    return currencySymbols[currency.toUpperCase()] ?? '\$';
  }
  
  /// Format price with currency
  static String format(double price, {String currency = 'USD'}) {
    final curr = currency.toUpperCase();
    
    // JPY doesn't use decimal places
    if (curr == 'JPY') {
      return '¥${price.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      )}';
    }
    
    final symbol = getSymbol(curr);
    final formatted = price.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    
    // Some currencies put symbol after
    if (curr == 'EUR' || curr == 'PLN' || curr == 'SEK') {
      return '$formatted $symbol';
    }
    
    return '$symbol$formatted';
  }
  
  /// Format price compact (for small spaces)
  static String formatCompact(double price, {String currency = 'USD'}) {
    final curr = currency.toUpperCase();
    final symbol = getSymbol(curr);
    
    if (price >= 1000000) {
      return '$symbol${(price / 1000000).toStringAsFixed(1)}M';
    } else if (price >= 1000) {
      return '$symbol${(price / 1000).toStringAsFixed(1)}K';
    }
    
    if (curr == 'JPY') {
      return '$symbol${price.toStringAsFixed(0)}';
    }
    
    return '$symbol${price.toStringAsFixed(2)}';
  }
  
  /// Get currency name
  static String getCurrencyName(String currency) {
    const names = {
      'USD': 'US Dollar',
      'EUR': 'Euro',
      'GBP': 'British Pound',
      'JPY': 'Japanese Yen',
      'CAD': 'Canadian Dollar',
      'AUD': 'Australian Dollar',
      'BRL': 'Brazilian Real',
      'MXN': 'Mexican Peso',
      'INR': 'Indian Rupee',
      'PLN': 'Polish Zloty',
      'SEK': 'Swedish Krona',
      'SGD': 'Singapore Dollar',
      'AED': 'UAE Dirham',
      'SAR': 'Saudi Riyal',
    };
    return names[currency.toUpperCase()] ?? currency;
  }
}
