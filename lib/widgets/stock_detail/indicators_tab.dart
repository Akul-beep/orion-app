import 'package:flutter/material.dart';

class IndicatorsTab extends StatelessWidget {
  final Map<String, dynamic> indicators;

  const IndicatorsTab({
    super.key,
    required this.indicators,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // RSI Section
          if (indicators['rsi'] != null)
            _buildIndicatorCard(
              context,
              'RSI (Relative Strength Index)',
              'Measures the speed and change of price movements. Values above 70 indicate overbought conditions, while values below 30 indicate oversold conditions.',
              _buildRSIInfo(indicators['rsi']),
              const Color(0xFF4CAF50),
            ),
          
          const SizedBox(height: 16),
          
          // SMA Section
          if (indicators['sma'] != null)
            _buildIndicatorCard(
              context,
              'SMA (Simple Moving Average)',
              'A 20-day simple moving average that smooths out price data to identify trends. When price is above SMA, it indicates an upward trend.',
              _buildSMAInfo(indicators['sma']),
              const Color(0xFF2196F3),
            ),
          
          const SizedBox(height: 16),
          
          // MACD Section
          if (indicators['macd'] != null)
            _buildIndicatorCard(
              context,
              'MACD (Moving Average Convergence Divergence)',
              'Shows the relationship between two moving averages. When MACD line crosses above signal line, it\'s a bullish signal.',
              _buildMACDInfo(indicators['macd']),
              const Color(0xFFFF9800),
            ),
          
          const SizedBox(height: 16),
          
          // Educational Content
          _buildEducationalCard(context),
        ],
      ),
    );
  }

  Widget _buildIndicatorCard(
    BuildContext context,
    String title,
    String description,
    Widget content,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C2C54),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          content,
        ],
      ),
    );
  }

  Widget _buildRSIInfo(Map<String, dynamic> rsiData) {
    final values = rsiData['rsi'] as List?;
    if (values == null || values.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No RSI data available'),
      );
    }
    
    final currentRSI = values.last;
    String interpretation;
    Color color;
    
    if (currentRSI > 70) {
      interpretation = 'Overbought - Consider selling';
      color = Colors.red;
    } else if (currentRSI < 30) {
      interpretation = 'Oversold - Consider buying';
      color = Colors.green;
    } else {
      interpretation = 'Neutral - Hold position';
      color = Colors.orange;
    }
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Current RSI:', style: TextStyle(fontWeight: FontWeight.w500)),
              Text(
                currentRSI.toStringAsFixed(2),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    interpretation,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSMAInfo(Map<String, dynamic> smaData) {
    final values = smaData['sma'] as List?;
    if (values == null || values.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No SMA data available'),
      );
    }
    
    final currentSMA = values.last;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('20-Day SMA:', style: TextStyle(fontWeight: FontWeight.w500)),
              Text(
                '\$${currentSMA.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF2196F3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.trending_up, color: Color(0xFF2196F3), size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'SMA helps identify the overall trend direction',
                    style: TextStyle(
                      color: Color(0xFF2196F3),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMACDInfo(Map<String, dynamic> macdData) {
    final macdLine = macdData['macd'] as List?;
    final signalLine = macdData['macdSignal'] as List?;
    
    if (macdLine == null || signalLine == null || macdLine.isEmpty || signalLine.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No MACD data available'),
      );
    }
    
    final currentMACD = macdLine.last;
    final currentSignal = signalLine.last;
    final histogram = currentMACD - currentSignal;
    
    String interpretation;
    Color color;
    
    if (histogram > 0) {
      interpretation = 'Bullish - MACD above signal line';
      color = Colors.green;
    } else {
      interpretation = 'Bearish - MACD below signal line';
      color = Colors.red;
    }
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('MACD Line:', style: TextStyle(fontWeight: FontWeight.w500)),
              Text(
                currentMACD.toStringAsFixed(4),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFFFF9800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Signal Line:', style: TextStyle(fontWeight: FontWeight.w500)),
              Text(
                currentSignal.toStringAsFixed(4),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFFFF9800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.trending_up, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    interpretation,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEducationalCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.school, color: Color(0xFF2C2C54), size: 24),
                SizedBox(width: 8),
                Text(
                  'Understanding Technical Indicators',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C2C54),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildEducationalItem(
              'RSI',
              'Helps identify overbought and oversold conditions. Use it to time your entries and exits.',
            ),
            _buildEducationalItem(
              'SMA',
              'Shows the average price over a period. Price above SMA suggests an uptrend.',
            ),
            _buildEducationalItem(
              'MACD',
              'Compares two moving averages to show momentum. Crossovers indicate trend changes.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEducationalItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C2C54),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}


