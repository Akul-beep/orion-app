import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/stock_api_service.dart';
import '../utils/market_detector.dart';

class CustomStockChart extends StatefulWidget {
  final String symbol;
  final double height;
  final String theme; // 'light' or 'dark'
  final String interval; // 'D', 'W', 'M'

  const CustomStockChart({
    super.key,
    required this.symbol,
    this.height = 400,
    this.theme = 'light',
    this.interval = 'D',
  });

  @override
  State<CustomStockChart> createState() => _CustomStockChartState();
}

class _CustomStockChartState extends State<CustomStockChart> {
  List<Map<String, dynamic>> _allHistoricalData = [];
  List<Map<String, dynamic>> _displayedData = [];
  bool _isLoading = true;
  String? _error;
  String _chartType = 'line'; // 'line' or 'candlestick'
  String _selectedTimeframe = '1Y'; // '1M', '3M', '1Y', 'All'
  double? _priceChange;
  double? _priceChangePercent;

  @override
  void initState() {
    super.initState();
    _loadHistoricalData();
  }

  Future<void> _loadHistoricalData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Get historical data (works for both US and Indian stocks via Yahoo Finance)
      final normalizedSymbol = MarketDetector.isIndianStock(widget.symbol)
          ? MarketDetector.normalizeIndianSymbol(widget.symbol)
          : widget.symbol.toUpperCase();

      // Get 1 year of data (we'll filter based on timeframe)
      final data = await StockApiService.getHistoricalDataForChart(normalizedSymbol, days: 365);
      
      if (mounted) {
        setState(() {
          _allHistoricalData = data;
          _updateDisplayedData();
          _calculatePriceChange();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading chart data: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _updateDisplayedData() {
    if (_allHistoricalData.isEmpty) {
      _displayedData = [];
      return;
    }

    final now = DateTime.now();
    DateTime startDate;

    switch (_selectedTimeframe) {
      case '1M':
        startDate = now.subtract(const Duration(days: 30));
        break;
      case '3M':
        startDate = now.subtract(const Duration(days: 90));
        break;
      case '1Y':
        startDate = now.subtract(const Duration(days: 365));
        break;
      case 'All':
      default:
        _displayedData = _allHistoricalData;
        return;
    }

    _displayedData = _allHistoricalData.where((point) {
      final timestamp = point['t'] as int;
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      return date.isAfter(startDate);
    }).toList();
  }

  void _calculatePriceChange() {
    if (_displayedData.length < 2) {
      _priceChange = null;
      _priceChangePercent = null;
      return;
    }

    final firstPrice = (_displayedData.first['c'] as num).toDouble();
    final lastPrice = (_displayedData.last['c'] as num).toDouble();
    
    _priceChange = lastPrice - firstPrice;
    _priceChangePercent = firstPrice > 0 ? ((_priceChange! / firstPrice) * 100) : 0;
  }

  void _onTimeframeChanged(String timeframe) {
    setState(() {
      _selectedTimeframe = timeframe;
      _updateDisplayedData();
      _calculatePriceChange();
    });
  }

  double _getOptimalInterval() {
    if (_displayedData.isEmpty) return 1;
    final dataLength = _displayedData.length;
    // Show fewer labels for better readability
    if (dataLength <= 10) return 1;
    if (dataLength <= 30) return dataLength / 3;
    if (dataLength <= 60) return dataLength / 4;
    return dataLength / 5;
  }

  bool _shouldShowDateLabel(int index) {
    if (_displayedData.isEmpty) return false;
    final dataLength = _displayedData.length;
    
    // Always show first and last
    if (index == 0 || index == dataLength - 1) return true;
    
    // For short timeframes, show fewer labels
    if (dataLength <= 10) {
      return index % 3 == 0; // Every 3rd point
    } else if (dataLength <= 30) {
      return index % (dataLength ~/ 3) == 0; // ~3 labels
    } else if (dataLength <= 60) {
      return index % (dataLength ~/ 4) == 0; // ~4 labels
    } else {
      return index % (dataLength ~/ 5) == 0; // ~5 labels
    }
  }

  String _formatDateLabel(DateTime date) {
    // Format based on timeframe
    switch (_selectedTimeframe) {
      case '1M':
        return '${date.day}/${date.month}';
      case '3M':
      case '1Y':
      case 'All':
        return '${date.month}/${date.year.toString().substring(2)}';
      default:
        return '${date.month}/${date.day}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max, // Changed from min to max for fullscreen
        children: [
          // Header with price change and disclaimer
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Price change display
                if (_priceChange != null && _priceChangePercent != null) ...[
                  Row(
                    children: [
                      Text(
                        _priceChange! >= 0 ? '+' : '',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _priceChange! >= 0 
                              ? const Color(0xFF10B981) 
                              : const Color(0xFFEF4444),
                        ),
                      ),
                      Text(
                        '${_priceChangePercent!.toStringAsFixed(2)}%',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _priceChange! >= 0 
                              ? const Color(0xFF10B981) 
                              : const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                // Disclaimer banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0052FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF0052FF).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: const Color(0xFF0052FF),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Basic chart view. For advanced features, see US stocks. Enhanced features coming soon!',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF0052FF),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Chart type toggle - moved to top
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildChartTypeButton('Line', 'line'),
                const SizedBox(width: 8),
                _buildChartTypeButton('Candles', 'candlestick'),
              ],
            ),
          ),
          
          // Chart - Calculate available height
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0052FF)),
                    ),
                  )
                : _error != null || _displayedData.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.show_chart, size: 48, color: Color(0xFF9CA3AF)),
                            const SizedBox(height: 12),
                            Text(
                              'Chart Unavailable',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _error ?? 'No data available',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF9CA3AF),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _loadHistoricalData,
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('Retry'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0052FF),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _chartType == 'line' ? _buildLineChart() : _buildCandlestickChart(),
          ),
          
          // Timeframe selector - moved to bottom
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: ['1M', '3M', '1Y', 'All'].map((timeframe) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildTimeframeButton(timeframe),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeframeButton(String timeframe) {
    final isSelected = _selectedTimeframe == timeframe;
    return GestureDetector(
      onTap: () => _onTimeframeChanged(timeframe),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0052FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? const Color(0xFF0052FF) : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        child: Text(
          timeframe,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

  Widget _buildChartTypeButton(String label, String type) {
    final isSelected = _chartType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _chartType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0052FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? const Color(0xFF0052FF) : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

  Widget _buildLineChart() {
    if (_displayedData.isEmpty) return const SizedBox();

    final spots = _displayedData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final close = (data['c'] as num).toDouble();
      return FlSpot(index.toDouble(), close);
    }).toList();

    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) * 0.98;
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.02;

    // Color based on price change - blue if positive, red if negative
    final isPositive = spots.isNotEmpty && spots.last.y >= spots.first.y;
    final lineColor = isPositive ? const Color(0xFF0052FF) : const Color(0xFFEF4444);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (maxY - minY) / 5,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: const Color(0xFFE5E7EB),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: _displayedData.length > 50 ? _displayedData.length / 5 : 1,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < _displayedData.length) {
                    final timestamp = _displayedData[value.toInt()]['t'] as int;
                    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        '${date.month}/${date.day}',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                interval: (maxY - minY) / 5,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toStringAsFixed(0),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: const Color(0xFF6B7280),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: lineColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    lineColor.withOpacity(0.2),
                    lineColor.withOpacity(0.05),
                  ],
                ),
              ),
            ),
          ],
          minY: minY,
          maxY: maxY,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) => Colors.black87,
              tooltipRoundedRadius: 8,
              tooltipPadding: const EdgeInsets.all(8),
              getTooltipItems: (List<LineBarSpot> touchedSpots) {
                return touchedSpots.map((LineBarSpot touchedSpot) {
                  final index = touchedSpot.x.toInt();
                  if (index >= 0 && index < _displayedData.length) {
                    final data = _displayedData[index];
                    final timestamp = data['t'] as int;
                    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
                    final currencySymbol = MarketDetector.isIndianStock(widget.symbol) ? '₹' : '\$';
                    return LineTooltipItem(
                      '${date.toString().split(' ')[0]}\n$currencySymbol${touchedSpot.y.toStringAsFixed(2)}',
                      GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  }
                  return null;
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCandlestickChart() {
    if (_displayedData.isEmpty) return const SizedBox();

    final bars = _displayedData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final open = (data['o'] as num).toDouble();
      final high = (data['h'] as num).toDouble();
      final low = (data['l'] as num).toDouble();
      final close = (data['c'] as num).toDouble();
      final isPositive = close >= open;
      
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            fromY: low,
            toY: high,
            color: const Color(0xFF9CA3AF),
            width: 1,
          ),
          BarChartRodData(
            fromY: open < close ? open : close,
            toY: open < close ? close : open,
            color: isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            width: 4,
          ),
        ],
      );
    }).toList();

    final minY = _displayedData.map((d) => (d['l'] as num).toDouble()).reduce((a, b) => a < b ? a : b) * 0.98;
    final maxY = _displayedData.map((d) => (d['h'] as num).toDouble()).reduce((a, b) => a > b ? a : b) * 1.02;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: BarChart(
        BarChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (maxY - minY) / 4,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: const Color(0xFFE5E7EB),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 0, // Remove reserved space - we'll show dates only at key points
                interval: _getOptimalInterval(),
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < _displayedData.length) {
                    // Only show labels at start, middle, and end points
                    final shouldShow = _shouldShowDateLabel(index);
                    if (shouldShow) {
                      final timestamp = _displayedData[index]['t'] as int;
                      final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
                      return Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          _formatDateLabel(date),
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      );
                    }
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 45,
                interval: (maxY - minY) / 4,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 4.0),
                    child: Text(
                      value.toStringAsFixed(0),
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        color: const Color(0xFF6B7280),
                      ),
                      textAlign: TextAlign.right,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: bars,
          minY: minY,
          maxY: maxY,
        ),
      ),
    );
  }
}
