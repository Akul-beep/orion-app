import 'package:flutter/material.dart';
import '../services/stock_api_service.dart';
import '../models/stock_quote.dart';

class ApiTestWidget extends StatefulWidget {
  const ApiTestWidget({Key? key}) : super(key: key);

  @override
  State<ApiTestWidget> createState() => _ApiTestWidgetState();
}

class _ApiTestWidgetState extends State<ApiTestWidget> {
  StockQuote? _quote;
  bool _isLoading = false;
  String _status = 'Ready to test';

  Future<void> _testApi() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing API...';
    });

    try {
      final result = await StockApiService.testApiKey();
      
      if (result['success']) {
        final quote = await StockApiService.getQuote('AAPL');
        setState(() {
          _quote = quote;
          _status = result['message'] ?? 'API test completed';
          _isLoading = false;
        });
      } else {
        setState(() {
          _status = result['message'] ?? 'API test failed';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _status = 'API test failed: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'API Test',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text('Status: $_status'),
            const SizedBox(height: 16),
            if (_quote != null) ...[
              Text('Symbol: ${_quote!.symbol}'),
              Text('Price: \$${_quote!.currentPrice.toStringAsFixed(2)}'),
              Text('Change: \$${_quote!.change.toStringAsFixed(2)} (${_quote!.changePercent.toStringAsFixed(2)}%)'),
              Text('Volume: ${_quote!.volume}'),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _testApi,
              child: _isLoading 
                ? const CircularProgressIndicator()
                : const Text('Test API'),
            ),
          ],
        ),
      ),
    );
  }
}
