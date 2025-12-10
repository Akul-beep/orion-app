import 'package:flutter/material.dart';
import '../widgets/tradingview_embedded_chart.dart';
import '../services/user_progress_service.dart';

class TradingViewDemoScreen extends StatefulWidget {
  const TradingViewDemoScreen({super.key});

  @override
  State<TradingViewDemoScreen> createState() => _TradingViewDemoScreenState();
}

class _TradingViewDemoScreenState extends State<TradingViewDemoScreen> {
  @override
  void initState() {
    super.initState();
    // Track screen visit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UserProgressService().trackScreenVisit(
        screenName: 'TradingViewDemoScreen',
        screenType: 'main',
        metadata: {'section': 'chart_demo'},
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'TradingView Advanced Charts',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Real-time TradingView Charts',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C2C54),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Powered by TradingView Advanced Chart Widget',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),

            // AAPL Chart
            const Text(
              'Apple Inc. (AAPL)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C2C54),
              ),
            ),
            const SizedBox(height: 12),
            TradingViewEmbeddedChart(
              symbol: 'AAPL',
              height: 400,
              theme: 'light',
              showToolbar: true,
              showVolume: true,
              showLegend: true,
              interval: 'D',
            ),
            const SizedBox(height: 24),

            // TSLA Chart
            const Text(
              'Tesla Inc. (TSLA)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C2C54),
              ),
            ),
            const SizedBox(height: 12),
            TradingViewEmbeddedChart(
              symbol: 'TSLA',
              height: 400,
              theme: 'light',
              showToolbar: true,
              showVolume: true,
              showLegend: true,
              interval: 'D',
            ),
            const SizedBox(height: 24),

            // MSFT Chart
            const Text(
              'Microsoft Corporation (MSFT)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C2C54),
              ),
            ),
            const SizedBox(height: 12),
            TradingViewEmbeddedChart(
              symbol: 'MSFT',
              height: 400,
              theme: 'light',
              showToolbar: true,
              showVolume: true,
              showLegend: true,
              interval: 'D',
            ),
            const SizedBox(height: 24),

            // Features Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Features',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C2C54),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem('Real-time data from TradingView'),
                  _buildFeatureItem('Interactive charts with zoom and pan'),
                  _buildFeatureItem('Multiple timeframes (1H, 1D, 1W, 1M, 1Y)'),
                  _buildFeatureItem('Technical indicators and studies'),
                  _buildFeatureItem('Volume analysis'),
                  _buildFeatureItem('Fullscreen mode support'),
                  _buildFeatureItem('Light and dark themes'),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green[600],
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
