/// Local stocks database for instant search without API calls
/// Contains a curated list of popular stocks with symbols and company names
class LocalStocksDatabase {
  // Curated list of popular stocks (symbol, name)
  // This list covers major US stocks across different sectors
  static final List<Map<String, String>> _stocks = [
    // Technology
    {'symbol': 'AAPL', 'name': 'Apple Inc.'},
    {'symbol': 'MSFT', 'name': 'Microsoft Corporation'},
    {'symbol': 'GOOGL', 'name': 'Alphabet Inc.'},
    {'symbol': 'GOOG', 'name': 'Alphabet Inc.'},
    {'symbol': 'AMZN', 'name': 'Amazon.com Inc.'},
    {'symbol': 'META', 'name': 'Meta Platforms Inc.'},
    {'symbol': 'NVDA', 'name': 'NVIDIA Corporation'},
    {'symbol': 'TSLA', 'name': 'Tesla Inc.'},
    {'symbol': 'NFLX', 'name': 'Netflix Inc.'},
    {'symbol': 'AMD', 'name': 'Advanced Micro Devices Inc.'},
    {'symbol': 'INTC', 'name': 'Intel Corporation'},
    {'symbol': 'CRM', 'name': 'Salesforce Inc.'},
    {'symbol': 'ORCL', 'name': 'Oracle Corporation'},
    {'symbol': 'ADBE', 'name': 'Adobe Inc.'},
    {'symbol': 'CSCO', 'name': 'Cisco Systems Inc.'},
    {'symbol': 'IBM', 'name': 'International Business Machines Corporation'},
    {'symbol': 'QCOM', 'name': 'QUALCOMM Incorporated'},
    {'symbol': 'TXN', 'name': 'Texas Instruments Incorporated'},
    {'symbol': 'AVGO', 'name': 'Broadcom Inc.'},
    {'symbol': 'NOW', 'name': 'ServiceNow Inc.'},
    
    // Finance
    {'symbol': 'JPM', 'name': 'JPMorgan Chase & Co.'},
    {'symbol': 'BAC', 'name': 'Bank of America Corp.'},
    {'symbol': 'WFC', 'name': 'Wells Fargo & Company'},
    {'symbol': 'GS', 'name': 'The Goldman Sachs Group Inc.'},
    {'symbol': 'MS', 'name': 'Morgan Stanley'},
    {'symbol': 'C', 'name': 'Citigroup Inc.'},
    {'symbol': 'BLK', 'name': 'BlackRock Inc.'},
    {'symbol': 'SCHW', 'name': 'The Charles Schwab Corporation'},
    {'symbol': 'AXP', 'name': 'American Express Company'},
    {'symbol': 'V', 'name': 'Visa Inc.'},
    {'symbol': 'MA', 'name': 'Mastercard Incorporated'},
    
    // Healthcare
    {'symbol': 'JNJ', 'name': 'Johnson & Johnson'},
    {'symbol': 'UNH', 'name': 'UnitedHealth Group Incorporated'},
    {'symbol': 'PFE', 'name': 'Pfizer Inc.'},
    {'symbol': 'ABBV', 'name': 'AbbVie Inc.'},
    {'symbol': 'TMO', 'name': 'Thermo Fisher Scientific Inc.'},
    {'symbol': 'ABT', 'name': 'Abbott Laboratories'},
    {'symbol': 'DHR', 'name': 'Danaher Corporation'},
    {'symbol': 'BMY', 'name': 'Bristol-Myers Squibb Company'},
    {'symbol': 'AMGN', 'name': 'Amgen Inc.'},
    {'symbol': 'GILD', 'name': 'Gilead Sciences Inc.'},
    
    // Consumer
    {'symbol': 'WMT', 'name': 'Walmart Inc.'},
    {'symbol': 'HD', 'name': 'The Home Depot Inc.'},
    {'symbol': 'MCD', 'name': 'McDonald\'s Corporation'},
    {'symbol': 'SBUX', 'name': 'Starbucks Corporation'},
    {'symbol': 'NKE', 'name': 'Nike Inc.'},
    {'symbol': 'TGT', 'name': 'Target Corporation'},
    {'symbol': 'LOW', 'name': 'Lowe\'s Companies Inc.'},
    {'symbol': 'COST', 'name': 'Costco Wholesale Corporation'},
    {'symbol': 'DIS', 'name': 'The Walt Disney Company'},
    {'symbol': 'CMCSA', 'name': 'Comcast Corporation'},
    
    // Energy
    {'symbol': 'XOM', 'name': 'Exxon Mobil Corporation'},
    {'symbol': 'CVX', 'name': 'Chevron Corporation'},
    {'symbol': 'COP', 'name': 'ConocoPhillips'},
    {'symbol': 'SLB', 'name': 'Schlumberger Limited'},
    {'symbol': 'EOG', 'name': 'EOG Resources Inc.'},
    
    // Industrial
    {'symbol': 'BA', 'name': 'The Boeing Company'},
    {'symbol': 'CAT', 'name': 'Caterpillar Inc.'},
    {'symbol': 'GE', 'name': 'General Electric Company'},
    {'symbol': 'HON', 'name': 'Honeywell International Inc.'},
    {'symbol': 'UPS', 'name': 'United Parcel Service Inc.'},
    {'symbol': 'RTX', 'name': 'Raytheon Technologies Corporation'},
    
    // Communication
    {'symbol': 'VZ', 'name': 'Verizon Communications Inc.'},
    {'symbol': 'T', 'name': 'AT&T Inc.'},
    {'symbol': 'TMUS', 'name': 'T-Mobile US Inc.'},
    
    // Consumer Staples
    {'symbol': 'PG', 'name': 'The Procter & Gamble Company'},
    {'symbol': 'KO', 'name': 'The Coca-Cola Company'},
    {'symbol': 'PEP', 'name': 'PepsiCo Inc.'},
    {'symbol': 'PM', 'name': 'Philip Morris International Inc.'},
    {'symbol': 'MO', 'name': 'Altria Group Inc.'},
    
    // Utilities
    {'symbol': 'NEE', 'name': 'NextEra Energy Inc.'},
    {'symbol': 'DUK', 'name': 'Duke Energy Corporation'},
    {'symbol': 'SO', 'name': 'The Southern Company'},
    
    // Real Estate
    {'symbol': 'AMT', 'name': 'American Tower Corporation'},
    {'symbol': 'PLD', 'name': 'Prologis Inc.'},
    {'symbol': 'EQIX', 'name': 'Equinix Inc.'},
    
    // Materials
    {'symbol': 'LIN', 'name': 'Linde plc'},
    {'symbol': 'APD', 'name': 'Air Products and Chemicals Inc.'},
    {'symbol': 'FCX', 'name': 'Freeport-McMoRan Inc.'},
    
    // ETFs
    {'symbol': 'SPY', 'name': 'SPDR S&P 500 ETF Trust'},
    {'symbol': 'QQQ', 'name': 'Invesco QQQ Trust'},
    {'symbol': 'DIA', 'name': 'SPDR Dow Jones Industrial Average ETF'},
    {'symbol': 'VTI', 'name': 'Vanguard Total Stock Market ETF'},
    {'symbol': 'VOO', 'name': 'Vanguard S&P 500 ETF'},
    
    // Popular Growth Stocks
    {'symbol': 'ROKU', 'name': 'Roku Inc.'},
    {'symbol': 'ZOOM', 'name': 'Zoom Video Communications Inc.'},
    {'symbol': 'SHOP', 'name': 'Shopify Inc.'},
    {'symbol': 'SQ', 'name': 'Block Inc.'},
    {'symbol': 'PYPL', 'name': 'PayPal Holdings Inc.'},
    {'symbol': 'UBER', 'name': 'Uber Technologies Inc.'},
    {'symbol': 'LYFT', 'name': 'Lyft Inc.'},
    {'symbol': 'SNAP', 'name': 'Snap Inc.'},
    {'symbol': 'TWTR', 'name': 'Twitter Inc.'},
    {'symbol': 'PINS', 'name': 'Pinterest Inc.'},
    
    // Crypto-related
    {'symbol': 'COIN', 'name': 'Coinbase Global Inc.'},
    {'symbol': 'MARA', 'name': 'Marathon Digital Holdings Inc.'},
    {'symbol': 'RIOT', 'name': 'Riot Platforms Inc.'},
    
    // Electric Vehicles
    {'symbol': 'RIVN', 'name': 'Rivian Automotive Inc.'},
    {'symbol': 'LCID', 'name': 'Lucid Group Inc.'},
    {'symbol': 'F', 'name': 'Ford Motor Company'},
    {'symbol': 'GM', 'name': 'General Motors Company'},
    
    // Retail
    {'symbol': 'AMZN', 'name': 'Amazon.com Inc.'},
    {'symbol': 'EBAY', 'name': 'eBay Inc.'},
    {'symbol': 'ETSY', 'name': 'Etsy Inc.'},
    
    // Semiconductors
    {'symbol': 'TSM', 'name': 'Taiwan Semiconductor Manufacturing Company Limited'},
    {'symbol': 'ASML', 'name': 'ASML Holding N.V.'},
    {'symbol': 'LRCX', 'name': 'Lam Research Corporation'},
    {'symbol': 'KLAC', 'name': 'KLA Corporation'},
    
    // Gaming
    {'symbol': 'EA', 'name': 'Electronic Arts Inc.'},
    {'symbol': 'TTWO', 'name': 'Take-Two Interactive Software Inc.'},
    {'symbol': 'ATVI', 'name': 'Activision Blizzard Inc.'},
    
    // Social Media
    {'symbol': 'BMBL', 'name': 'Bumble Inc.'},
    {'symbol': 'MTCH', 'name': 'Match Group Inc.'},
    
    // ========== INDIAN STOCKS (NSE) ==========
    // Large Cap
    {'symbol': 'RELIANCE.NS', 'name': 'Reliance Industries Ltd.'},
    {'symbol': 'TCS.NS', 'name': 'Tata Consultancy Services Ltd.'},
    {'symbol': 'HDFCBANK.NS', 'name': 'HDFC Bank Ltd.'},
    {'symbol': 'INFY.NS', 'name': 'Infosys Ltd.'},
    {'symbol': 'ICICIBANK.NS', 'name': 'ICICI Bank Ltd.'},
    {'symbol': 'HINDUNILVR.NS', 'name': 'Hindustan Unilever Ltd.'},
    {'symbol': 'SBIN.NS', 'name': 'State Bank of India'},
    {'symbol': 'BHARTIARTL.NS', 'name': 'Bharti Airtel Ltd.'},
    {'symbol': 'ITC.NS', 'name': 'ITC Ltd.'},
    {'symbol': 'KOTAKBANK.NS', 'name': 'Kotak Mahindra Bank Ltd.'},
    {'symbol': 'LT.NS', 'name': 'Larsen & Toubro Ltd.'},
    {'symbol': 'AXISBANK.NS', 'name': 'Axis Bank Ltd.'},
    {'symbol': 'ASIANPAINT.NS', 'name': 'Asian Paints Ltd.'},
    {'symbol': 'MARUTI.NS', 'name': 'Maruti Suzuki India Ltd.'},
    {'symbol': 'TITAN.NS', 'name': 'Titan Company Ltd.'},
    {'symbol': 'ULTRACEMCO.NS', 'name': 'UltraTech Cement Ltd.'},
    {'symbol': 'NESTLEIND.NS', 'name': 'Nestle India Ltd.'},
    {'symbol': 'WIPRO.NS', 'name': 'Wipro Ltd.'},
    {'symbol': 'HCLTECH.NS', 'name': 'HCL Technologies Ltd.'},
    {'symbol': 'SUNPHARMA.NS', 'name': 'Sun Pharmaceutical Industries Ltd.'},
    {'symbol': 'BAJFINANCE.NS', 'name': 'Bajaj Finance Ltd.'},
    {'symbol': 'ONGC.NS', 'name': 'Oil and Natural Gas Corporation Ltd.'},
    {'symbol': 'POWERGRID.NS', 'name': 'Power Grid Corporation of India Ltd.'},
    {'symbol': 'NTPC.NS', 'name': 'NTPC Ltd.'},
    {'symbol': 'INDUSINDBK.NS', 'name': 'IndusInd Bank Ltd.'},
    {'symbol': 'TECHM.NS', 'name': 'Tech Mahindra Ltd.'},
    {'symbol': 'TATAMOTORS.NS', 'name': 'Tata Motors Ltd.'},
    {'symbol': 'JSWSTEEL.NS', 'name': 'JSW Steel Ltd.'},
    {'symbol': 'ADANIENT.NS', 'name': 'Adani Enterprises Ltd.'},
    {'symbol': 'ADANIPORTS.NS', 'name': 'Adani Ports and Special Economic Zone Ltd.'},
    {'symbol': 'DIVISLAB.NS', 'name': 'Dr. Reddy\'s Laboratories Ltd.'},
    {'symbol': 'CIPLA.NS', 'name': 'Cipla Ltd.'},
    {'symbol': 'BAJAJFINSV.NS', 'name': 'Bajaj Finserv Ltd.'},
    {'symbol': 'GRASIM.NS', 'name': 'Grasim Industries Ltd.'},
    {'symbol': 'M&M.NS', 'name': 'Mahindra & Mahindra Ltd.'},
    {'symbol': 'TATASTEEL.NS', 'name': 'Tata Steel Ltd.'},
    {'symbol': 'HEROMOTOCO.NS', 'name': 'Hero MotoCorp Ltd.'},
    {'symbol': 'EICHERMOT.NS', 'name': 'Eicher Motors Ltd.'},
    {'symbol': 'BRITANNIA.NS', 'name': 'Britannia Industries Ltd.'},
    {'symbol': 'COALINDIA.NS', 'name': 'Coal India Ltd.'},
    {'symbol': 'BPCL.NS', 'name': 'Bharat Petroleum Corporation Ltd.'},
    {'symbol': 'IOC.NS', 'name': 'Indian Oil Corporation Ltd.'},
    {'symbol': 'VEDL.NS', 'name': 'Vedanta Ltd.'},
    {'symbol': 'HINDALCO.NS', 'name': 'Hindalco Industries Ltd.'},
    {'symbol': 'GODREJCP.NS', 'name': 'Godrej Consumer Products Ltd.'},
    {'symbol': 'DABUR.NS', 'name': 'Dabur India Ltd.'},
    {'symbol': 'MARICO.NS', 'name': 'Marico Ltd.'},
    {'symbol': 'PIDILITIND.NS', 'name': 'Pidilite Industries Ltd.'},
    {'symbol': 'HAVELLS.NS', 'name': 'Havells India Ltd.'},
    {'symbol': 'VOLTAS.NS', 'name': 'Voltas Ltd.'},
    {'symbol': 'WHIRLPOOL.NS', 'name': 'Whirlpool of India Ltd.'},
    {'symbol': 'BAJAJ-AUTO.NS', 'name': 'Bajaj Auto Ltd.'},
    {'symbol': 'TVSMOTOR.NS', 'name': 'TVS Motor Company Ltd.'},
    {'symbol': 'APOLLOHOSP.NS', 'name': 'Apollo Hospitals Enterprise Ltd.'},
    {'symbol': 'FORTIS.NS', 'name': 'Fortis Healthcare Ltd.'},
    {'symbol': 'LUPIN.NS', 'name': 'Lupin Ltd.'},
    {'symbol': 'TORNTPHARM.NS', 'name': 'Torrent Pharmaceuticals Ltd.'},
    {'symbol': 'ZOMATO.NS', 'name': 'Zomato Ltd.'},
    {'symbol': 'PAYTM.NS', 'name': 'One 97 Communications Ltd. (Paytm)'},
    {'symbol': 'NYKAA.NS', 'name': 'FSN E-Commerce Ventures Ltd. (Nykaa)'},
    {'symbol': 'POLICYBZR.NS', 'name': 'PB Fintech Ltd. (Policybazaar)'},
  ];

  /// Search for stocks locally by symbol or name
  /// Returns list of matching stocks (symbol, name)
  /// OPTIMIZED: Early exit and optimized matching
  static List<Map<String, String>> searchLocal(String query) {
    if (query.isEmpty) return [];
    
    final lowerQuery = query.toLowerCase().trim();
    final queryLength = lowerQuery.length;
    final results = <Map<String, String>>[];
    
    // Optimize: Use where for filtering (more efficient than manual loop)
    final matches = _stocks.where((stock) {
      final symbol = stock['symbol']!.toLowerCase();
      final name = stock['name']!.toLowerCase();
      
      // Fast path: exact symbol match
      if (symbol == lowerQuery) return true;
      
      // Fast path: symbol starts with query
      if (symbol.startsWith(lowerQuery)) return true;
      
      // Check if query matches symbol or name (partial match)
      if (symbol.contains(lowerQuery) || name.contains(lowerQuery)) {
        return true;
      }
      
      return false;
    }).toList();
    
    // Sort results: exact symbol matches first, then symbol starts with, then name matches
    matches.sort((a, b) {
      final aSymbol = a['symbol']!.toLowerCase();
      final bSymbol = b['symbol']!.toLowerCase();
      final aName = a['name']!.toLowerCase();
      final bName = b['name']!.toLowerCase();
      
      // Exact symbol match
      if (aSymbol == lowerQuery && bSymbol != lowerQuery) return -1;
      if (bSymbol == lowerQuery && aSymbol != lowerQuery) return 1;
      
      // Symbol starts with query
      if (aSymbol.startsWith(lowerQuery) && !bSymbol.startsWith(lowerQuery)) return -1;
      if (bSymbol.startsWith(lowerQuery) && !aSymbol.startsWith(lowerQuery)) return 1;
      
      // Name starts with query
      if (aName.startsWith(lowerQuery) && !bName.startsWith(lowerQuery)) return -1;
      if (bName.startsWith(lowerQuery) && !aName.startsWith(lowerQuery)) return 1;
      
      // Alphabetical by symbol
      return aSymbol.compareTo(bSymbol);
    });
    
    // Limit to top 50 results
    return matches.take(50).toList();
  }

  /// Get all stocks in the database
  static List<Map<String, String>> getAllStocks() {
    return List.from(_stocks);
  }

  /// Check if a symbol exists in local database
  static bool hasSymbol(String symbol) {
    return _stocks.any((stock) => stock['symbol']!.toUpperCase() == symbol.toUpperCase());
  }

  /// Get stock name by symbol
  static String? getNameBySymbol(String symbol) {
    try {
      return _stocks.firstWhere(
        (stock) => stock['symbol']!.toUpperCase() == symbol.toUpperCase(),
      )['name'];
    } catch (e) {
      return null;
    }
  }
}


