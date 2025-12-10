import 'dart:io';
import 'lib/services/indian_stock_api_service.dart';

void main() async {
  print('=' * 70);
  print('⚡ SPEED TEST - INDIAN STOCK METRICS');
  print('=' * 70);
  
  final symbol = 'TCS.NS';
  
  print('\nTesting: $symbol\n');
  
  // Test 1: First call (cold start)
  print('📊 Test 1: First call (cold start)...');
  final start1 = DateTime.now();
  
  try {
    final profile1 = await IndianStockApiService.getCompanyProfile(symbol);
    final duration1 = DateTime.now().difference(start1);
    
    print('✅ Completed in: ${duration1.inSeconds}s ${duration1.inMilliseconds % 1000}ms');
    print('   Metrics found: ${_countMetrics(profile1)}/12');
    
    // Test 2: Second call (should be faster with cached cookies/sessions)
    print('\n📊 Test 2: Second call (warm - cached sessions)...');
    await Future.delayed(Duration(seconds: 1));
    final start2 = DateTime.now();
    
    final profile2 = await IndianStockApiService.getCompanyProfile(symbol);
    final duration2 = DateTime.now().difference(start2);
    
    print('✅ Completed in: ${duration2.inSeconds}s ${duration2.inMilliseconds % 1000}ms');
    print('   Metrics found: ${_countMetrics(profile2)}/12');
    
    // Test 3: Financial Metrics Map (alternative endpoint)
    print('\n📊 Test 3: Financial Metrics Map...');
    final start3 = DateTime.now();
    
    final metrics = await IndianStockApiService.getFinancialMetrics(symbol);
    final duration3 = DateTime.now().difference(start3);
    
    print('✅ Completed in: ${duration3.inSeconds}s ${duration3.inMilliseconds % 1000}ms');
    print('   Total metrics: ${metrics.length}');
    
    // Summary
    print('\n${'=' * 70}');
    print('📊 SPEED SUMMARY:');
    print('${'=' * 70}');
    print('First call:      ${duration1.inSeconds}s ${duration1.inMilliseconds % 1000}ms');
    print('Second call:     ${duration2.inSeconds}s ${duration2.inMilliseconds % 1000}ms');
    print('Metrics Map:     ${duration3.inSeconds}s ${duration3.inMilliseconds % 1000}ms');
    
    final avgTime = (duration1.inMilliseconds + duration2.inMilliseconds + duration3.inMilliseconds) / 3;
    print('\nAverage time:    ${(avgTime / 1000).toStringAsFixed(2)}s');
    
    if (avgTime < 3000) {
      print('\n✅ EXCELLENT! Very fast (< 3 seconds)');
    } else if (avgTime < 5000) {
      print('\n✅ GOOD! Acceptable speed (< 5 seconds)');
    } else {
      print('\n⚠️  Could be optimized (>= 5 seconds)');
    }
    
    // Verify all metrics
    print('\n${'=' * 70}');
    print('✅ METRICS VERIFICATION:');
    print('${'=' * 70}');
    final metricsList = [
      ('Name', profile1.name.isNotEmpty),
      ('Market Cap', profile1.marketCapitalization != null && profile1.marketCapitalization! > 0),
      ('P/E Ratio', profile1.peRatio != null),
      ('Dividend Yield', profile1.dividendYield != null),
      ('Beta', profile1.beta != null),
      ('EPS', profile1.eps != null),
      ('Price to Book', profile1.priceToBook != null),
      ('Book Value', profile1.bookValue != null),
      ('Revenue', profile1.revenue != null),
      ('Profit Margin', profile1.profitMargin != null),
      ('ROE', profile1.returnOnEquity != null),
      ('Debt/Equity', profile1.debtToEquity != null),
    ];
    
    int found = 0;
    for (final (name, present) in metricsList) {
      if (present) {
        found++;
        print('✅ $name');
      } else {
        print('❌ $name');
      }
    }
    
    print('\n📊 Final Score: $found/${metricsList.length} metrics');
    
    if (found >= 10) {
      print('\n🎉 PERFECT! All critical metrics are coming through FAST!');
    }
    
  } catch (e, stackTrace) {
    print('❌ ERROR: $e');
    print('Stack: $stackTrace');
  }
  
  print('\n${'=' * 70}\n');
}

int _countMetrics(dynamic profile) {
  int count = 0;
  if (profile.name.isNotEmpty) count++;
  if (profile.marketCapitalization != null && profile.marketCapitalization! > 0) count++;
  if (profile.peRatio != null) count++;
  if (profile.dividendYield != null) count++;
  if (profile.beta != null) count++;
  if (profile.eps != null) count++;
  if (profile.priceToBook != null) count++;
  if (profile.bookValue != null) count++;
  if (profile.revenue != null) count++;
  if (profile.profitMargin != null) count++;
  if (profile.returnOnEquity != null) count++;
  if (profile.debtToEquity != null) count++;
  return count;
}

