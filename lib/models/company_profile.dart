class CompanyProfile {
  final String name;
  final String ticker;
  final String symbol;
  final String country;
  final String currency;
  final String industry;
  final String finnhubIndustry;
  final String weburl;
  final String logo;
  final String phone;
  final String ipo;
  final double marketCapitalization;
  final double shareOutstanding;
  final String description;
  final String exchange;
  final double? peRatio;
  final double? dividendYield;
  final double? beta;
  final double? eps;
  final double? bookValue;
  final double? priceToBook;
  final double? priceToSales;
  final double? revenue;
  final double? profitMargin;
  final double? returnOnEquity;
  final double? debtToEquity;

  CompanyProfile({
    required this.name,
    required this.ticker,
    required this.country,
    required this.industry,
    required this.weburl,
    required this.logo,
    required this.marketCapitalization,
    required this.shareOutstanding,
    required this.description,
    required this.exchange,
    this.symbol = '',
    this.currency = 'USD',
    this.finnhubIndustry = '',
    this.phone = '',
    this.ipo = '',
    this.peRatio,
    this.dividendYield,
    this.beta,
    this.eps,
    this.bookValue,
    this.priceToBook,
    this.priceToSales,
    this.revenue,
    this.profitMargin,
    this.returnOnEquity,
    this.debtToEquity,
  });

  // Alternative constructor for service compatibility
  CompanyProfile.fromService({
    required this.symbol,
    required this.name,
    required this.country,
    required this.currency,
    required this.exchange,
    required this.ipo,
    required this.marketCapitalization,
    required this.shareOutstanding,
    required this.logo,
    required this.phone,
    required this.weburl,
    required this.finnhubIndustry,
  }) : ticker = symbol,
       industry = finnhubIndustry,
       description = '',
       peRatio = null,
       dividendYield = null,
       beta = null,
       eps = null,
       bookValue = null,
       priceToBook = null,
       priceToSales = null,
       revenue = null,
       profitMargin = null,
       returnOnEquity = null,
       debtToEquity = null;

  factory CompanyProfile.fromJson(Map<String, dynamic> json) {
    return CompanyProfile(
      name: json['name'] ?? '',
      ticker: json['ticker'] ?? '',
      symbol: json['ticker'] ?? '', // Add symbol field
      country: json['country'] ?? '',
      industry: json['finnhubIndustry'] ?? '',
      weburl: json['weburl'] ?? '',
      logo: json['logo'] ?? '',
      marketCapitalization: (json['marketCapitalization'] as num? ?? 0).toDouble(),
      shareOutstanding: (json['shareOutstanding'] as num? ?? 0).toDouble(),
      description: json['description'] ?? '',
      exchange: json['exchange'] ?? 'NASDAQ',
      peRatio: json['pe'] != null ? (json['pe'] as num).toDouble() : null,
      dividendYield: json['dividendYield'] != null ? (json['dividendYield'] as num).toDouble() : null,
      beta: json['beta'] != null ? (json['beta'] as num).toDouble() : null,
      eps: json['eps'] != null ? (json['eps'] as num).toDouble() : null,
      bookValue: json['bookValue'] != null ? (json['bookValue'] as num).toDouble() : null,
      priceToBook: json['priceToBook'] != null ? (json['priceToBook'] as num).toDouble() : null,
      priceToSales: json['priceToSales'] != null ? (json['priceToSales'] as num).toDouble() : null,
      revenue: json['revenue'] != null ? (json['revenue'] as num).toDouble() : null,
      profitMargin: json['profitMargin'] != null ? (json['profitMargin'] as num).toDouble() : null,
      returnOnEquity: json['returnOnEquity'] != null ? (json['returnOnEquity'] as num).toDouble() : null,
      debtToEquity: json['debtToEquity'] != null ? (json['debtToEquity'] as num).toDouble() : null,
    );
  }
}

