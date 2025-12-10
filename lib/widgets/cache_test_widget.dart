import 'package:flutter/material.dart';
import '../services/stock_api_service.dart';
import '../services/database_service.dart';

/// Debug widget to test the caching system
/// Add this to your app temporarily for testing
class CacheTestWidget extends StatefulWidget {
  const CacheTestWidget({super.key});

  @override
  State<CacheTestWidget> createState() => _CacheTestWidgetState();
}

class _CacheTestWidgetState extends State<CacheTestWidget> {
  String _testResults = 'Tap "Run Tests" to start...';
  bool _isRunning = false;

  Future<void> _runTests() async {
    setState(() {
      _isRunning = true;
      _testResults = '🧪 Running cache tests...\n\n';
    });

    final results = StringBuffer(_testResults);

    try {
      // Test 1: First fetch (should hit API)
      results.writeln('📊 Test 1: First fetch (cold cache)');
      results.writeln('Fetching popular stocks...');
      final startTime1 = DateTime.now();
      final stocks1 = await StockApiService.getPopularStocks();
      final duration1 = DateTime.now().difference(startTime1);
      results.writeln('✅ Got ${stocks1.length} stocks in ${duration1.inMilliseconds}ms');
      results.writeln('');

      // Wait 1 second
      await Future.delayed(const Duration(seconds: 1));

      // Test 2: Second fetch (should hit cache)
      results.writeln('📊 Test 2: Second fetch (warm cache)');
      results.writeln('Fetching popular stocks again...');
      final startTime2 = DateTime.now();
      final stocks2 = await StockApiService.getPopularStocks();
      final duration2 = DateTime.now().difference(startTime2);
      results.writeln('✅ Got ${stocks2.length} stocks in ${duration2.inMilliseconds}ms');
      if (duration2 < duration1) {
        results.writeln('🚀 Cache is working! (${duration1.inMilliseconds - duration2.inMilliseconds}ms faster)');
      }
      results.writeln('');

      // Test 3: Check Supabase cache
      results.writeln('📊 Test 3: Checking Supabase cache');
      final cached = await DatabaseService.getCachedQuote('AAPL');
      if (cached != null) {
        results.writeln('✅ AAPL is cached in Supabase!');
        results.writeln('   Price: \$${cached['c'] ?? 'N/A'}');
      } else {
        results.writeln('❌ AAPL not found in cache');
      }
      results.writeln('');

      // Test 4: Check stale cache
      results.writeln('📊 Test 4: Checking stale cache fallback');
      final staleCache = await DatabaseService.getStaleCachedQuote('AAPL');
      if (staleCache != null) {
        results.writeln('✅ Stale cache available for AAPL');
      } else {
        results.writeln('⚠️ No stale cache available');
      }
      results.writeln('');

      // Test 5: Clear cache and test again
      results.writeln('📊 Test 5: Clearing cache and testing');
      StockApiService.clearCache();
      results.writeln('✅ Cache cleared');
      results.writeln('Fetching again (should hit API)...');
      final startTime3 = DateTime.now();
      final stocks3 = await StockApiService.getPopularStocks();
      final duration3 = DateTime.now().difference(startTime3);
      results.writeln('✅ Got ${stocks3.length} stocks in ${duration3.inMilliseconds}ms');
      results.writeln('');

      results.writeln('✅ All tests completed!');
      results.writeln('\n💡 Check console logs for detailed cache hit/miss messages');

    } catch (e, stack) {
      results.writeln('❌ Test failed: $e');
      results.writeln('Stack: $stack');
    }

    setState(() {
      _testResults = results.toString();
      _isRunning = false;
    });
  }

  Future<void> _clearCache() async {
    StockApiService.clearCache();
    setState(() {
      _testResults = '✅ Cache cleared!\n\nTap "Run Tests" to test again.';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cache cleared!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.bug_report, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'Cache System Tester',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isRunning ? null : _runTests,
                    icon: _isRunning
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.play_arrow),
                    label: Text(_isRunning ? 'Running...' : 'Run Tests'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _isRunning ? null : _clearCache,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Clear Cache'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade100,
                    foregroundColor: Colors.red.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              constraints: const BoxConstraints(maxHeight: 300),
              child: SingleChildScrollView(
                child: Text(
                  _testResults,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '💡 Watch console logs for detailed cache messages',
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

