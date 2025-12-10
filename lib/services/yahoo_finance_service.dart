import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/company_profile.dart';

/// Yahoo Finance API Service for Indian Stocks
/// FREE - No API key needed
/// Provides comprehensive financial data for NSE/BSE stocks
class YahooFinanceService {
  static const String _baseUrl = 'https://query1.finance.yahoo.com/v8/finance/chart';
  
  /// Get comprehensive financial metrics for Indian stock
  /// Symbol format: RELIANCE.NS or TCS.NS for NSE, RELIANCE.BO for BSE
  static Future<Map<String, dynamic>> getFinancialMetrics(String symbol) async {
    print('📊 [Yahoo Finance] Fetching metrics for $symbol...');
    
    try {
      // Yahoo Finance uses .NS for NSE and .BO for BSE
      final yahooSymbol = symbol.toUpperCase();
      
      // Get quote data
      final quoteUrl = '$_baseUrl/$yahooSymbol?interval=1d&range=1d';
      final quoteResponse = await http.get(
        Uri.parse(quoteUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));
      
      if (quoteResponse.statusCode != 200) {
        print('⚠️ [Yahoo Finance] Quote failed: ${quoteResponse.statusCode}');
        return {};
      }
      
      final quoteData = jsonDecode(quoteResponse.body);
      final result = quoteData['chart']?['result']?[0];
      
      if (result == null) {
        print('⚠️ [Yahoo Finance] No data found');
        return {};
      }
      
      final metrics = <String, dynamic>{};
      
      // Get current price
      final meta = result['meta'] as Map<String, dynamic>? ?? {};
      if (meta['regularMarketPrice'] != null) {
        metrics['currentPrice'] = (meta['regularMarketPrice'] as num).toDouble();
      }
      
      // Get summary data (includes financial metrics)
      final summaryUrl = 'https://query2.finance.yahoo.com/v10/finance/quoteSummary/$yahooSymbol?modules=summaryProfile,defaultKeyStatistics,financialData,calendarEvents';
      final summaryResponse = await http.get(
        Uri.parse(summaryUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));
      
      if (summaryResponse.statusCode == 200) {
        final summaryData = jsonDecode(summaryResponse.body);
        final quoteSummary = summaryData['quoteSummary']?['result']?[0];
        
        if (quoteSummary != null) {
          // Extract defaultKeyStatistics
          final keyStats = quoteSummary['defaultKeyStatistics'] as Map<String, dynamic>? ?? {};
          if (keyStats['trailingPE'] != null) {
            metrics['pe'] = (keyStats['trailingPE'] as num).toDouble();
            metrics['peRatio'] = metrics['pe'];
          }
          if (keyStats['beta'] != null) {
            metrics['beta'] = (keyStats['beta'] as num).toDouble();
          }
          if (keyStats['trailingEps'] != null) {
            metrics['eps'] = (keyStats['trailingEps'] as num).toDouble();
          }
          if (keyStats['priceToBook'] != null) {
            metrics['priceToBook'] = (keyStats['priceToBook'] as num).toDouble();
          }
          if (keyStats['enterpriseToRevenue'] != null) {
            metrics['priceToSales'] = (keyStats['enterpriseToRevenue'] as num).toDouble();
          }
          if (keyStats['bookValue'] != null) {
            metrics['bookValue'] = (keyStats['bookValue'] as num).toDouble();
          }
          if (keyStats['marketCap'] != null) {
            final mcap = (keyStats['marketCap'] as num).toDouble();
            metrics['marketCap'] = mcap / 1e6; // Convert to millions
          }
          if (keyStats['sharesOutstanding'] != null) {
            metrics['sharesOutstanding'] = (keyStats['sharesOutstanding'] as num).toDouble();
          }
          
          // Extract financialData
          final financialData = quoteSummary['financialData'] as Map<String, dynamic>? ?? {};
          if (financialData['totalRevenue'] != null) {
            final revenue = (financialData['totalRevenue'] as Map<String, dynamic>?)?['raw'] as num?;
            if (revenue != null) {
              metrics['revenue'] = revenue.toDouble() / 1e9; // Convert to billions
            }
          }
          if (financialData['profitMargins'] != null) {
            final margin = (financialData['profitMargins'] as Map<String, dynamic>?)?['raw'] as num?;
            if (margin != null) {
              metrics['profitMargin'] = margin.toDouble();
            }
          }
          if (financialData['returnOnEquity'] != null) {
            final roe = (financialData['returnOnEquity'] as Map<String, dynamic>?)?['raw'] as num?;
            if (roe != null) {
              metrics['returnOnEquity'] = roe.toDouble();
            }
          }
          if (financialData['debtToEquity'] != null) {
            final de = (financialData['debtToEquity'] as Map<String, dynamic>?)?['raw'] as num?;
            if (de != null) {
              metrics['debtToEquity'] = de.toDouble();
            }
          }
          
          // Extract dividend yield from summaryProfile or calendarEvents
          final calendarEvents = quoteSummary['calendarEvents'] as Map<String, dynamic>? ?? {};
          final dividends = calendarEvents['dividends'] as Map<String, dynamic>? ?? {};
          if (dividends['yield'] != null) {
            final divYield = (dividends['yield'] as num).toDouble();
            metrics['dividendYield'] = divYield / 100; // Convert percentage to decimal
          } else if (keyStats['yield'] != null) {
            final divYield = (keyStats['yield'] as num).toDouble();
            metrics['dividendYield'] = divYield / 100;
          }
        }
      }
      
      print('✅ [Yahoo Finance] Extracted ${metrics.length} metrics: ${metrics.keys.toList()}');
      return metrics;
      
    } catch (e, stackTrace) {
      print('❌ [Yahoo Finance] Error: $e');
      print('Stack: $stackTrace');
      return {};
    }
  }
  
  /// Get company profile from Yahoo Finance
  static Future<CompanyProfile?> getCompanyProfile(String symbol) async {
    try {
      final yahooSymbol = symbol.toUpperCase();
      final url = 'https://query2.finance.yahoo.com/v10/finance/quoteSummary/$yahooSymbol?modules=summaryProfile,defaultKeyStatistics,financialData';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode != 200) {
        return null;
      }
      
      final data = jsonDecode(response.body);
      final result = data['quoteSummary']?['result']?[0];
      
      if (result == null) return null;
      
      final profile = result['summaryProfile'] as Map<String, dynamic>? ?? {};
      final keyStats = result['defaultKeyStatistics'] as Map<String, dynamic>? ?? {};
      final financialData = result['financialData'] as Map<String, dynamic>? ?? {};
      
      // Extract market cap
      double marketCap = 0.0;
      if (keyStats['marketCap'] != null) {
        marketCap = (keyStats['marketCap'] as num).toDouble() / 1e6; // Convert to millions
      }
      
      // Extract shares outstanding
      double sharesOutstanding = 0.0;
      if (keyStats['sharesOutstanding'] != null) {
        sharesOutstanding = (keyStats['sharesOutstanding'] as num).toDouble();
      }
      
      return CompanyProfile(
        name: profile['longName'] ?? profile['shortName'] ?? symbol,
        ticker: symbol,
        symbol: symbol,
        country: 'IN',
        currency: 'INR',
        industry: profile['industry'] ?? '',
        finnhubIndustry: profile['sector'] ?? '',
        weburl: profile['website'] ?? '',
        logo: '',
        phone: '',
        ipo: '',
        marketCapitalization: marketCap,
        shareOutstanding: sharesOutstanding,
        description: profile['longBusinessSummary'] ?? '',
        exchange: symbol.endsWith('.BO') ? 'BSE' : 'NSE',
        peRatio: keyStats['trailingPE'] != null ? (keyStats['trailingPE'] as num).toDouble() : null,
        dividendYield: keyStats['yield'] != null ? (keyStats['yield'] as num).toDouble() / 100 : null,
        beta: keyStats['beta'] != null ? (keyStats['beta'] as num).toDouble() : null,
        eps: keyStats['trailingEps'] != null ? (keyStats['trailingEps'] as num).toDouble() : null,
        bookValue: keyStats['bookValue'] != null ? (keyStats['bookValue'] as num).toDouble() : null,
        priceToBook: keyStats['priceToBook'] != null ? (keyStats['priceToBook'] as num).toDouble() : null,
        priceToSales: keyStats['enterpriseToRevenue'] != null ? (keyStats['enterpriseToRevenue'] as num).toDouble() : null,
        revenue: financialData['totalRevenue'] != null 
            ? (((financialData['totalRevenue'] as Map<String, dynamic>?)?['raw'] as num?)?.toDouble() ?? 0.0) / 1e9
            : null,
        profitMargin: financialData['profitMargins'] != null 
            ? ((financialData['profitMargins'] as Map<String, dynamic>?)?['raw'] as num?)?.toDouble()
            : null,
        returnOnEquity: financialData['returnOnEquity'] != null 
            ? ((financialData['returnOnEquity'] as Map<String, dynamic>?)?['raw'] as num?)?.toDouble()
            : null,
        debtToEquity: financialData['debtToEquity'] != null 
            ? ((financialData['debtToEquity'] as Map<String, dynamic>?)?['raw'] as num?)?.toDouble()
            : null,
      );
    } catch (e) {
      print('❌ [Yahoo Finance] Profile error: $e');
      return null;
    }
  }
}
