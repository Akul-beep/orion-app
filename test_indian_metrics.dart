import 'lib/services/indian_stock_api_service.dart';
import 'lib/services/screener_in_service.dart';

void main() async {
  final separator = '=' * 70;
  print(separator);
  print('📊 COMPREHENSIVE INDIAN STOCK METRICS TEST');
  print(separator);
  
  final testStocks = ['TCS', 'INFY'];
  
  for (final symbol in testStocks) {
    print('\n$separator');
    print('Testing: $symbol');
    print('$separator\n');
    
    try {
      // Test 1: Get Company Profile (includes all metrics)
      print('📊 Test 1: Getting Company Profile...\n');
      final profile = await IndianStockApiService.getCompanyProfile('$symbol.NS');
      
      print('✅ PROFILE METRICS EXTRACTED:');
      print('─' * 70);
      print('Name:                    ${profile.name}');
      print('Symbol:                  ${profile.symbol}');
      print('Market Cap:              ${profile.marketCapitalization != null ? "${(profile.marketCapitalization! / 1e6).toStringAsFixed(2)}M" : "N/A"}');
      print('P/E Ratio:               ${profile.peRatio?.toStringAsFixed(2) ?? "N/A"}');
      print('Dividend Yield:          ${profile.dividendYield != null ? "${(profile.dividendYield! * 100).toStringAsFixed(2)}%" : "N/A"}');
      print('Beta:                    ${profile.beta?.toStringAsFixed(2) ?? "N/A"}');
      print('EPS:                     ${profile.eps?.toStringAsFixed(2) ?? "N/A"}');
      print('Price to Book:           ${profile.priceToBook?.toStringAsFixed(2) ?? "N/A"}');
      print('Book Value:              ${profile.bookValue?.toStringAsFixed(2) ?? "N/A"}');
      print('Revenue:                 ${profile.revenue != null ? "${(profile.revenue! / 1e9).toStringAsFixed(2)}B" : "N/A"}');
      print('Profit Margin:           ${profile.profitMargin != null ? "${(profile.profitMargin! * 100).toStringAsFixed(2)}%" : "N/A"}');
      print('ROE:                     ${profile.returnOnEquity != null ? "${(profile.returnOnEquity! * 100).toStringAsFixed(2)}%" : "N/A"}');
      print('Debt/Equity:             ${profile.debtToEquity?.toStringAsFixed(2) ?? "N/A"}');
      
      // Count metrics
      int metricsFound = 0;
      if (profile.peRatio != null) metricsFound++;
      if (profile.dividendYield != null) metricsFound++;
      if (profile.beta != null) metricsFound++;
      if (profile.eps != null) metricsFound++;
      if (profile.priceToBook != null) metricsFound++;
      if (profile.bookValue != null) metricsFound++;
      if (profile.revenue != null) metricsFound++;
      if (profile.profitMargin != null) metricsFound++;
      if (profile.returnOnEquity != null) metricsFound++;
      if (profile.debtToEquity != null) metricsFound++;
      
      print('\n📊 METRICS COUNT: $metricsFound/10 key metrics found');
      
      // Test 2: Get Financial Metrics Map
      print('\n${'─' * 70}');
      print('📊 Test 2: Getting Financial Metrics Map...\n');
      final metrics = await IndianStockApiService.getFinancialMetrics('$symbol.NS');
      
      print('✅ FINANCIAL METRICS MAP:');
      print('─' * 70);
      final keyMetrics = [
        'peRatio', 'pe', 'dividendYield', 'beta', 'eps', 'earningsPerShare',
        'priceToBook', 'bookValue', 'revenue', 'profitMargin', 'returnOnEquity',
        'debtToEquity', 'marketCap', 'currentPrice', 'name'
      ];
      
      int metricsMapCount = 0;
      for (final key in keyMetrics) {
        if (metrics.containsKey(key) && metrics[key] != null) {
          metricsMapCount++;
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
          print('  ✅ $key: $displayValue');
        }
      }
      
      print('\n📊 METRICS MAP COUNT: $metricsMapCount/${keyMetrics.length} key metrics found');
      print('📊 TOTAL METRICS IN MAP: ${metrics.length}');
      print('📊 ALL METRIC KEYS: ${metrics.keys.toList()}');
      
      // Test 3: Direct Screener.in test
      print('\n${'─' * 70}');
      print('📊 Test 3: Direct Screener.in Service Test...\n');
      final screenerMetrics = await ScreenerInService.getFinancialMetrics(symbol);
      
      print('✅ SCREENER.IN METRICS:');
      print('─' * 70);
      int screenerCount = 0;
      for (final key in keyMetrics) {
        if (screenerMetrics.containsKey(key) && screenerMetrics[key] != null) {
          screenerCount++;
          final value = screenerMetrics[key];
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
          print('  ✅ $key: $displayValue');
        }
      }
      
      print('\n📊 SCREENER.IN COUNT: $screenerCount/${keyMetrics.length} key metrics found');
      
      // Summary
      print('\n$separator');
      print('📊 SUMMARY FOR $symbol:');
      print(separator);
      print('Profile Metrics:    $metricsFound/10 ✅');
      print('Metrics Map:        $metricsMapCount/${keyMetrics.length} ✅');
      print('Screener.in Direct: $screenerCount/${keyMetrics.length} ✅');
      
      if (metricsFound >= 8 && metricsMapCount >= 10 && screenerCount >= 8) {
        print('\n✅ EXCELLENT! All metrics are being extracted!');
      } else if (metricsFound >= 6 && metricsMapCount >= 8) {
        print('\n✅ GOOD! Most metrics are being extracted!');
      } else {
        print('\n⚠️  Some metrics are missing. Check extraction logic.');
      }
      
    } catch (e, stackTrace) {
      print('❌ ERROR for $symbol: $e');
      print('Stack trace: $stackTrace');
    }
    
    // Wait between requests to be respectful
    await Future.delayed(Duration(seconds: 3));
  }
  
  print('\n$separator');
  print('✅ ALL TESTS COMPLETE!');
  print('$separator\n');
}
