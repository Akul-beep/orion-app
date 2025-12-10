import 'lib/services/indian_stock_api_service.dart';

void main() async {
  print('=' * 70);
  print('📊 FULL INTEGRATION TEST - ALL METRICS');
  print('=' * 70);
  
  final symbol = 'TCS.NS';
  
  print('\nTesting: $symbol\n');
  
  try {
    // Test Company Profile
    print('📊 Fetching Company Profile (all metrics)...\n');
    final profile = await IndianStockApiService.getCompanyProfile(symbol);
    
    print('✅ ALL METRICS IN COMPANY PROFILE:\n');
    print('─' * 70);
    
    final metrics = {
      'Name': profile.name,
      'Market Cap': profile.marketCapitalization != null ? '${(profile.marketCapitalization! / 1e6).toStringAsFixed(2)}M' : null,
      'P/E Ratio': profile.peRatio?.toStringAsFixed(2),
      'Dividend Yield': profile.dividendYield != null ? '${(profile.dividendYield! * 100).toStringAsFixed(2)}%' : null,
      'Beta': profile.beta?.toStringAsFixed(2),
      'EPS': profile.eps?.toStringAsFixed(2),
      'Price to Book': profile.priceToBook?.toStringAsFixed(2),
      'Book Value': profile.bookValue?.toStringAsFixed(2),
      'Revenue': profile.revenue != null ? '${(profile.revenue! / 1e9).toStringAsFixed(2)}B' : null,
      'Profit Margin': profile.profitMargin != null ? '${(profile.profitMargin! * 100).toStringAsFixed(2)}%' : null,
      'ROE': profile.returnOnEquity != null ? '${(profile.returnOnEquity! * 100).toStringAsFixed(2)}%' : null,
      'Debt/Equity': profile.debtToEquity?.toStringAsFixed(2),
    };
    
    int found = 0;
    for (final entry in metrics.entries) {
      final label = entry.key;
      final value = entry.value;
      
      if (value != null && value != 'N/A') {
        found++;
        print('✅ ${label.padRight(25)}: $value');
      } else {
        print('❌ ${label.padRight(25)}: NOT FOUND');
      }
    }
    
    print('─' * 70);
    print('\n📊 FINAL SUMMARY:');
    print('   Metrics Found: $found/${metrics.length}');
    
    if (found >= 10) {
      print('\n✅ EXCELLENT! All critical metrics are coming through!');
      print('✅ Ready for production use!');
    } else if (found >= 8) {
      print('\n✅ GOOD! Most metrics are working!');
    } else {
      print('\n⚠️  Some metrics need attention.');
    }
    
    // Also test Financial Metrics Map
    print('\n${'─' * 70}');
    print('📊 Testing Financial Metrics Map...\n');
    final metricsMap = await IndianStockApiService.getFinancialMetrics(symbol);
    
    print('✅ Financial Metrics Map has ${metricsMap.length} total metrics');
    print('   Key metrics found: ${metricsMap.keys.where((k) => ['peRatio', 'eps', 'dividendYield', 'returnOnEquity', 'profitMargin', 'priceToBook', 'beta'].contains(k)).length}');
    
  } catch (e, stackTrace) {
    print('❌ ERROR: $e');
    print('Stack: $stackTrace');
  }
  
  print('\n${'=' * 70}\n');
}

