import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'database_service.dart';
import 'stock_api_service.dart';
import '../models/stock_quote.dart';

class WatchlistService extends ChangeNotifier {
  List<String> _watchlistSymbols = [];
  List<StockQuote> _watchlistStocks = [];
  bool _isLoading = false;

  List<String> get watchlistSymbols => _watchlistSymbols;
  List<StockQuote> get watchlistStocks => _watchlistStocks;
  bool get isLoading => _isLoading;

  // Load watchlist from database
  Future<void> loadWatchlist() async {
    _isLoading = true;
    notifyListeners();

    try {
      _watchlistSymbols = await DatabaseService.loadWatchlist();

      // Load stock quotes for watchlist
      if (_watchlistSymbols.isNotEmpty) {
        await _loadWatchlistQuotes();
      }
    } catch (e) {
      print('Error loading watchlist: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadWatchlistQuotes() async {
    _watchlistStocks = [];
    for (final symbol in _watchlistSymbols) {
      try {
        final quote = await StockApiService.getQuote(symbol);
        _watchlistStocks.add(quote);
      } catch (e) {
        print('Error loading quote for $symbol: $e');
      }
    }
    notifyListeners();
  }

  // Add symbol to watchlist
  Future<bool> addToWatchlist(String symbol) async {
    if (_watchlistSymbols.contains(symbol)) {
      return false; // Already in watchlist
    }

    _watchlistSymbols.add(symbol);
    await _saveWatchlist();

    // Load quote for new symbol
    try {
      final quote = await StockApiService.getQuote(symbol);
      _watchlistStocks.add(quote);
    } catch (e) {
      print('Error loading quote for $symbol: $e');
    }

    notifyListeners();
    return true;
  }

  // Remove symbol from watchlist
  Future<bool> removeFromWatchlist(String symbol) async {
    final removed = _watchlistSymbols.remove(symbol);
    if (removed) {
      _watchlistStocks.removeWhere((stock) => stock.symbol == symbol);
      await _saveWatchlist();
      notifyListeners();
    }
    return removed;
  }

  // Check if symbol is in watchlist
  bool isInWatchlist(String symbol) {
    return _watchlistSymbols.contains(symbol);
  }

  // Save watchlist to database
  Future<void> _saveWatchlist() async {
    try {
      await DatabaseService.saveWatchlist(_watchlistSymbols);
    } catch (e) {
      print('Error saving watchlist: $e');
    }
  }

  // Refresh watchlist quotes
  Future<void> refreshWatchlist() async {
    await _loadWatchlistQuotes();
  }
}

