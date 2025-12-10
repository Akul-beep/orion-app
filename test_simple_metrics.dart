import 'lib/services/screener_in_service.dart';

void main() async {
  print('=' * 70);
  print('📊 QUICK SCREENER.IN METRICS TEST');
  print('=' * 70);
  
  final symbol = 'TCS';
  
  print('\nTesting: $symbol\n');
  
  try {
    print('📊 Fetching metrics from Screener.in...\n');
    final metrics = await ScreenerInService.getFinancialMetrics(symbol);
    
    print('✅ METRICS EXTRACTED:\n');
    print('─' * 70);
    
    // Check for all key metrics
    final keyMetrics = {
      'name': 'Name',
      'currentPrice': 'Current Price',
      'marketCap': 'Market Cap (M)',
      'peRatio': 'P/E Ratio',
      'dividendYield': 'Dividend Yield (%)',
      'beta': 'Beta',
      'eps': 'EPS',
      'priceToBook': 'Price to Book',
      'bookValue': 'Book Value',
      'revenue': 'Revenue (B)',
      'profitMargin': 'Profit Margin (%)',
      'returnOnEquity': 'ROE (%)',
      'debtToEquity': 'Debt/Equity',
    };
    
    int found = 0;
    for (final entry in keyMetrics.entries) {
      final key = entry.key;
      final label = entry.value;
      
      if (metrics.containsKey(key) && metrics[key] != null) {
        found++;
        final value = metrics[key];
        String displayValue;
        
        if (value is double) {
          if (key == 'marketCap') {
            displayValue = '${(value / 1e6).toStringAsFixed(2)}M';
          } else if (key == 'revenue') {
            displayValue = '${(value / 1e9).toStringAsFixed(2)}B';
          } else if (key == 'dividendYield' || key == 'profitMargin' || key == 'returnOnEquity') {
            displayValue = '${(value * 100).toStringAsFixed(2)}%';
          } else {
            displayValue = value.toStringAsFixed(2);
          }
        } else {
          displayValue = value.toString();
        }
        
        print('✅ ${label.padRight(25)}: $displayValue');
      } else {
        print('❌ ${label.padRight(25)}: NOT FOUND');
      }
    }
    
    print('─' * 70);
    print('\n📊 SUMMARY:');
    print('   Found: $found/${keyMetrics.length} metrics');
    print('   Total metrics in map: ${metrics.length}');
    print('   All keys: ${metrics.keys.toList()}');
    
    if (found >= 10) {
      print('\n✅ EXCELLENT! All critical metrics are being extracted!');
    } else if (found >= 8) {
      print('\n✅ GOOD! Most metrics are being extracted!');
    } else {
      print('\n⚠️  Some metrics are missing.');
    }
    
  } catch (e, stackTrace) {
    print('❌ ERROR: $e');
    print('Stack: $stackTrace');
  }
  
  print('\n${'=' * 70}\n');
}

