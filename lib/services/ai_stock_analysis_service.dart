import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/stock_quote.dart';
import '../models/company_profile.dart';
import '../models/news_article.dart';
import 'weekly_challenge_service.dart';

/// AI Service for generating professional stock analysis using Gemini
class AIStockAnalysisService {
  static GenerativeModel? _model;
  static String? _apiKey;
  
  /// Initialize the AI model
  static Future<void> init() async {
    try {
      // Try to load from .env file
      try {
        await dotenv.load(fileName: ".env");
        _apiKey = dotenv.env['GEMINI_API_KEY'];
      } catch (e) {
        print('⚠️ Could not load .env file: $e');
        _apiKey = null;
      }
      
      // Fallback to hardcoded key if .env fails (for production use)
      if (_apiKey == null || _apiKey!.isEmpty) {
        _apiKey = 'AIzaSyA3nAhM0gTQ6JEr73_gS3BSOyT3Z9uqiLE';
        print('🔑 Using Gemini API key from fallback: ${_apiKey!.substring(0, 10)}...');
      } else {
        print('🔑 Loaded Gemini API key from .env: ${_apiKey!.substring(0, 10)}...');
      }
      
      // Initialize the model - using gemini-2.5-flash-lite (SAME AS TRADING COACH!)
      // This model has: 15 RPM, 250K TPM, 1K RPD - HIGHEST daily limit!
      _model = GenerativeModel(
        model: 'gemini-2.5-flash-lite',
        apiKey: _apiKey!,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 8192, // Increased from 2048 to allow full detailed responses
        ),
      );
      print('✅ AI Model (Gemini 2.5 Flash Lite) initialized successfully - SAME AS TRADING COACH: 15 RPM, 250K TPM, 1K RPD!');
    } catch (e) {
      print('❌ AI Model initialization failed: $e');
      // Don't throw - let it fail gracefully and show error in UI
    }
  }
  
  /// Generate comprehensive stock analysis
  static Future<String> generateStockAnalysis({
    required StockQuote quote,
    required CompanyProfile profile,
    List<NewsArticle>? recentNews,
    Map<String, dynamic>? indicators,
    Map<String, dynamic>? metrics,
  }) async {
    if (_model == null) {
      await init();
      if (_model == null) {
        print('❌ AI Model not initialized - cannot generate analysis');
        throw Exception('AI service not available. Please check GEMINI_API_KEY in .env file.');
      }
    }
    
    try {
      print('🤖 Starting AI analysis for ${quote.symbol}...');
      print('Model status: ${_model != null ? "Initialized" : "NULL"}');
      
      // Track AI analysis for weekly challenge (Research First Challenge)
      try {
        WeeklyChallengeService().trackProgress('ai_analysis', 1);
        print('🔍 AI analysis tracked for Research First Challenge');
      } catch (e) {
        print('⚠️ Error tracking AI analysis: $e');
      }
      
      // Build comprehensive prompt with all live data
      final prompt = _buildAnalysisPrompt(
        quote: quote,
        profile: profile,
        recentNews: recentNews,
        indicators: indicators,
        metrics: metrics,
      );
      
      print('📝 Prompt built (length: ${prompt.length} chars)');
      print('🤖 Calling Gemini API...');
      
      // Retry logic for rate limit errors
      int maxRetries = 5; // More retries for rate limits
      int retryDelay = 5; // Start with 5 seconds for rate limits
      dynamic lastError;
      
      for (int attempt = 1; attempt <= maxRetries; attempt++) {
        try {
          final response = await _model!.generateContent([Content.text(prompt)]);
          print('📥 Response received: ${response.text != null ? "YES (${response.text!.length} chars)" : "NO"}');
          
          if (response.text != null && response.text!.isNotEmpty) {
            print('✅ AI analysis generated successfully');
            // Try to parse as JSON
            try {
              // Clean the response - extract JSON from any text
              String cleanedResponse = response.text!.trim();
              
              // Remove markdown code blocks if present
              if (cleanedResponse.startsWith('```json')) {
                cleanedResponse = cleanedResponse.substring(7);
              }
              if (cleanedResponse.startsWith('```')) {
                cleanedResponse = cleanedResponse.substring(3);
              }
              if (cleanedResponse.endsWith('```')) {
                cleanedResponse = cleanedResponse.substring(0, cleanedResponse.length - 3);
              }
              cleanedResponse = cleanedResponse.trim();
              
              // Extract JSON object - find first { and last }
              final firstBrace = cleanedResponse.indexOf('{');
              final lastBrace = cleanedResponse.lastIndexOf('}');
              
              if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace) {
                cleanedResponse = cleanedResponse.substring(firstBrace, lastBrace + 1);
              }
              
              cleanedResponse = cleanedResponse.trim();
              
              // Parse JSON to validate
              final jsonData = jsonDecode(cleanedResponse);
              print('✅ Valid JSON received from AI');
              return cleanedResponse; // Return the cleaned JSON string
            } catch (e) {
              print('⚠️ Response is not valid JSON, using as text: $e');
              print('Raw response: ${response.text}');
              // If not JSON, return as text (fallback)
              return response.text!;
            }
          } else {
            print('⚠️ Empty response from AI');
            throw Exception('AI returned empty response. Please try again.');
          }
        } catch (e) {
          lastError = e;
          final errorMessage = e.toString().toLowerCase();
          
          print('⚠️ Error on attempt $attempt/$maxRetries: $e');
          
          // Check if it's a retryable error (503, 429, resource exhausted, but NOT quota exceeded)
          // Don't retry quota errors - they won't resolve quickly
          if (errorMessage.contains('quota') || (errorMessage.contains('limit: 0') && errorMessage.contains('free_tier'))) {
            print('❌ Quota exceeded - not retrying');
            rethrow; // Don't retry quota errors
          } else if ((errorMessage.contains('503') || errorMessage.contains('overloaded') || 
               errorMessage.contains('429') || errorMessage.contains('rate limit') ||
               errorMessage.contains('resource exhausted') || errorMessage.contains('unavailable')) && 
              attempt < maxRetries) {
            // For rate limit errors, use longer delays (5s, 10s, 20s, 40s, 80s)
            // For other errors, use shorter delays
            int delay = errorMessage.contains('429') || errorMessage.contains('resource exhausted') || errorMessage.contains('rate limit')
                ? retryDelay * 2  // Longer delays for rate limits: 5s, 10s, 20s, 40s, 80s
                : retryDelay;     // Shorter delays for other errors
            
            print('🔄 Retrying in ${delay}s... (attempt $attempt/$maxRetries, exponential backoff)');
            await Future.delayed(Duration(seconds: delay));
            retryDelay *= 2; // Exponential backoff
            continue;
          } else {
            // Not a retryable error or max retries reached
            print('❌ Not retrying - error: $e');
            rethrow;
          }
        }
      }
      
      // If we get here, all retries failed
      throw lastError ?? Exception('Failed after $maxRetries attempts');
    } catch (e) {
      print('❌ AI generation error: $e');
      rethrow; // Don't use fallback - let the UI handle the error
    }
  }
  
  /// Build comprehensive prompt for AI analysis
  static String _buildAnalysisPrompt({
    required StockQuote quote,
    required CompanyProfile profile,
    List<NewsArticle>? recentNews,
    Map<String, dynamic>? indicators,
    Map<String, dynamic>? metrics,
  }) {
    final changePercent = quote.changePercent;
    final isPositive = changePercent >= 0;
    final marketCap = profile.marketCapitalization;
    final marketCapFormatted = _formatMarketCap(marketCap);
    
    // Build comprehensive news context - ONLY 3 MOST IMPORTANT articles
    String newsContext = '';
    String newsAnalysisSection = '';
    if (recentNews != null && recentNews.isNotEmpty) {
      // Take only 3 most important articles (prioritize by relevance and impact)
      final importantNews = recentNews.take(3).toList();
      newsContext = '\n\n**Recent News (3 most important articles):**\n';
      for (var news in importantNews) {
        newsContext += '- Headline: ${news.headline}\n';
        if (news.summary != null && news.summary.isNotEmpty) {
          newsContext += '  Summary: ${news.summary.substring(0, news.summary.length > 150 ? 150 : news.summary.length)}...\n';
        }
        newsContext += '  Source: ${news.source}\n\n';
      }
      newsAnalysisSection = '\n\n**NEWS ANALYSIS - CRITICAL:** Analyze ONLY these 3 most important articles. Focus on the BIGGER PICTURE - choose news that shows major trends, not minor updates. For each article:\n1. What it means in simple terms (1 sentence)\n2. Why it matters for stock price (1 sentence)\n3. Good/bad/neutral and price impact (1 sentence)\n4. Keep it CONCISE - users get overwhelmed with too much text';
    }
    
    // Build indicators context - FULL DETAILS for AI analysis
    String indicatorsContext = '';
    if (indicators != null && indicators.isNotEmpty) {
      indicatorsContext = '\n\n**Technical Indicators:**\n';
      if (indicators['RSI']?['value'] != null) {
        indicatorsContext += 'RSI: ${indicators['RSI']['value']} (Momentum indicator: <30=oversold, >70=overbought)\n';
      }
      if (indicators['SMA']?['value'] != null) {
        indicatorsContext += 'SMA (20-day): ${indicators['SMA']['value']} (Moving average trend indicator)\n';
      }
      if (indicators['MACD']?['value'] != null) {
        indicatorsContext += 'MACD: ${indicators['MACD']['value']} (Trend-following indicator: >0=bullish, <0=bearish)\n';
      }
    }
    
    // Build metrics context (compact format to save tokens)
    String metricsContext = '';
    if (metrics != null && metrics.isNotEmpty) {
      metricsContext = '\n\n**Key Metrics:**\n';
      List<String> metricList = [];
      if (metrics['pe'] != null) metricList.add('P/E: ${metrics['pe']}');
      if (metrics['dividendYield'] != null) metricList.add('Div Yield: ${(metrics['dividendYield'] * 100).toStringAsFixed(2)}%');
      if (metrics['profitMargin'] != null) metricList.add('Profit Margin: ${(metrics['profitMargin'] * 100).toStringAsFixed(1)}%');
      if (metrics['returnOnEquity'] != null) metricList.add('ROE: ${(metrics['returnOnEquity'] * 100).toStringAsFixed(1)}%');
      if (metrics['beta'] != null) metricList.add('Beta: ${metrics['beta']}');
      metricsContext += metricList.join(', ');
    }
    
    // Calculate RSI value for direct explanation
    final rsiValue = indicators?['rsi'] ?? indicators?['RSI']?['value'];
    final rsiNum = rsiValue != null ? (rsiValue is num ? rsiValue.toDouble() : double.tryParse(rsiValue.toString()) ?? 50.0) : 50.0;
    
    // Calculate MACD value
    final macdValue = indicators?['macd'] ?? indicators?['MACD']?['value'];
    final macdNum = macdValue != null ? (macdValue is num ? macdValue.toDouble() : double.tryParse(macdValue.toString()) ?? 0.0) : 0.0;
    
    // Calculate SMA value
    final smaValue = indicators?['sma'] ?? indicators?['sma20'] ?? indicators?['SMA']?['value'] ?? indicators?['SMA20']?['value'];
    final smaNum = smaValue != null ? (smaValue is num ? smaValue.toDouble() : double.tryParse(smaValue.toString()) ?? quote.currentPrice) : quote.currentPrice;
    
    // Calculate confidence score
    final confidenceScore = _calculateConfidenceScore(rsiNum, macdNum, quote.currentPrice, smaNum, changePercent);
    
    return '''You are a MASTER STOCK TEACHER explaining stocks to complete beginners. Your goal is to make them UNDERSTAND stocks, not just give them information. Think of yourself as a patient tutor who explains everything step-by-step.

**YOUR MISSION:** Solve the pain point of users not understanding stocks. Make them feel confident and educated after reading your analysis.

**STOCK DATA:**
Symbol: ${quote.symbol}
Current Price: \$${quote.currentPrice.toStringAsFixed(2)}
Price Change Today: ${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(2)}%
Market Cap: \$$marketCapFormatted
Industry: ${profile.industry}${metricsContext}${indicatorsContext}${newsContext}${newsAnalysisSection}

**CRITICAL TEACHING PRINCIPLES:**

1. **EDUCATIONAL APPROACH - TEACH AS YOU EXPLAIN**:
   - Don't just tell them what something is - explain WHY it matters
   - Use simple analogies when helpful (e.g., "Market cap is like the total value of all the company's shares combined")
   - Connect concepts together so they understand the big picture
   - Make them feel smarter after reading, not confused

2. **WORD COUNT - PERFECT BALANCE (CRITICAL)**:
   - Each explanation: 1-2 sentences (NOT 2-3, that's too much!)
   - Summary/overview: 2 sentences max
   - Individual explanations: 1-2 sentences each
   - News analysis: 1 sentence per point (what it means, why it matters, price impact)
   - Be CONCISE - users get overwhelmed with too much text
   - Enough to understand, NOT enough to overwhelm

3. **DIRECT LANGUAGE - NO JARGON**:
   - NEVER use: "cool off", "pull back", "retreat", "consolidate", "retrace"
   - ALWAYS use: "going up", "going down", "dropping", "rising", "staying the same"
   - If RSI is above 70: "RSI is ${rsiNum.toStringAsFixed(1)}, which means OVERBOUGHT. Think of it like a store that sold too many items - there's a HIGH CHANCE the stock price will GO DOWN soon because too many people already bought it, and there aren't many buyers left."
   - If RSI is below 30: "RSI is ${rsiNum.toStringAsFixed(1)}, which means OVERSOLD. Think of it like a store having a huge sale - there's a HIGH CHANCE the stock price will GO UP soon because it's been sold too much and might be a good deal now."
   - If MACD is negative: "MACD is ${macdNum.toStringAsFixed(2)}, which is NEGATIVE. This means the stock is in a SHORT-TERM DOWNWARD TREND - the price is going DOWN right now. But remember: short-term means days/weeks, not months/years. This doesn't mean it will keep going down forever."

4. **EXPLAIN TECHNICAL TERMS LIKE A TEACHER**:
   - Don't just state facts - explain the CONCEPT
   - RSI example: "RSI (Relative Strength Index) measures if a stock is overbought or oversold. It's like a speedometer for buying/selling pressure. RSI is ${rsiNum.toStringAsFixed(1)}, which means ${rsiNum > 70 ? 'OVERBOUGHT - too many people bought it, so the price might GO DOWN soon' : rsiNum < 30 ? 'OVERSOLD - too many people sold it, so the price might GO UP soon' : 'at a normal level - not too high, not too low'}."
   - MACD example: "MACD shows if a stock is trending up or down. It's like a compass for price direction. MACD is ${macdNum.toStringAsFixed(2)}, which is ${macdNum > 0 ? 'POSITIVE - the stock is trending UP right now' : 'NEGATIVE - the stock is trending DOWN right now, but this is short-term'}."
   - Always connect the indicator to what it means for the STOCK PRICE DIRECTION

5. **NEWS ANALYSIS - EXPLAIN WHAT NEWS MEANS**:
   - For EACH news article, explain:
     * What the news means in simple, everyday language
     * Why it matters for the stock (does it affect sales? profits? reputation?)
     * Whether it's GOOD news (likely makes price go UP) or BAD news (likely makes price go DOWN)
     * How it connects to the current stock performance
   - Use real-world examples: "This news is like when a restaurant gets a great review - more people want to eat there, so the business value goes up"
   - Connect news to price movements: "This news explains why the stock went ${changePercent >= 0 ? 'up' : 'down'} today"

6. **VARY RECOMMENDATIONS - BE HONEST**:
   - DO NOT always say "Hold" - that's not helpful
   - Analyze ALL data: RSI, MACD, SMA, news, metrics, price trends
   - If bullish (RSI < 30, MACD positive, price above SMA, positive news): Say "Buy" and explain why
   - If bearish (RSI > 70, MACD negative, price below SMA, negative news): Say "Sell" and explain why
   - Only say "Hold" if signals are truly mixed or unclear
   - Each stock gets a unique recommendation based on its actual situation

7. **CONFIDENCE SCALE (1-10) - BE REALISTIC**:
   - Use numbers 1-10, NOT words
   - Vary naturally: 3, 5, 7, 8, 6, 4, 9, etc. - NOT always 5
   - 1-3 = Very uncertain (mixed signals)
   - 4-6 = Somewhat certain (some clear signals)
   - 7-8 = Pretty certain (most signals agree)
   - 9-10 = Very certain (all signals strongly agree)
   - Base on signal clarity and consistency

**RETURN ONLY JSON (no markdown, no extra text):**

{
  "summary": {
    "title": "Simple title (3-5 words, e.g. 'Apple Stock Analysis')",
    "overview": "2 sentences MAX explaining what's happening with this stock right now. Connect the price movement (${changePercent >= 0 ? 'up' : 'down'} ${changePercent.abs().toStringAsFixed(2)}%) to what it means. Be direct and concise.",
    "sentiment": "positive|negative|neutral",
    "keyTakeaway": "One clear sentence about the most important thing to know. Be specific but brief."
  },
  "performance": {
    "currentPrice": "The current price is \$${quote.currentPrice.toStringAsFixed(2)}. ${quote.currentPrice > 100 ? 'This is a high-priced stock, but the price per share doesn\'t tell you if it\'s a good deal - you need to look at metrics like P/E ratio.' : quote.currentPrice < 10 ? 'This is a low-priced stock, but the price per share doesn\'t tell you if it\'s cheap - you need to look at metrics like P/E ratio.' : 'This is a moderately-priced stock.'}",
    "priceChange": "Today the stock price ${changePercent >= 0 ? 'WENT UP' : 'WENT DOWN'} by ${changePercent.abs().toStringAsFixed(2)}%. ${changePercent.abs() > 5 ? 'This is a BIG move (stocks usually move 1-2% per day), which suggests ${changePercent > 0 ? 'something positive happened - maybe good news or strong investor interest.' : 'something negative happened - maybe bad news or investors selling.'}' : changePercent.abs() > 2 ? 'This is a MODERATE move, suggesting ${changePercent > 0 ? 'positive sentiment.' : 'negative sentiment.'}' : 'This is a SMALL move - normal daily fluctuation.'}",
    "volatility": "low|medium|high",
    "trend": "upward|downward|stable"
  },
  "indicators": {
    "rsi": {
      "value": "${rsiNum.toStringAsFixed(1)}",
      "explanation": "RSI measures if a stock is overbought or oversold - think of it like a speedometer for buying/selling pressure.",
      "whatItTellsUs": "RSI is ${rsiNum.toStringAsFixed(1)}, which means ${rsiNum > 70 ? 'OVERBOUGHT - there\'s a HIGH CHANCE the price will GO DOWN soon because too many people already bought it.' : rsiNum < 30 ? 'OVERSOLD - there\'s a HIGH CHANCE the price will GO UP soon because it\'s been sold too much.' : 'NEUTRAL - the stock is at a normal level.'}"
    },
    "sma": {
      "value": "\$${smaNum.toStringAsFixed(2)}",
      "explanation": "A moving average smooths out daily ups and downs to show the overall trend - like the average temperature over 20 days.",
      "whatItTellsUs": "The 20-day average is \$${smaNum.toStringAsFixed(2)}. Current price is \$${quote.currentPrice.toStringAsFixed(2)}, which is ${quote.currentPrice > smaNum ? 'ABOVE the average - this means UPWARD TREND.' : 'BELOW the average - this means DOWNWARD TREND.'}"
    },
    "macd": {
      "value": "${macdNum.toStringAsFixed(2)}",
      "explanation": "MACD shows if a stock is trending up or down - like a compass for price direction.",
      "whatItTellsUs": "MACD is ${macdNum.toStringAsFixed(2)}, which is ${macdNum > 0 ? 'POSITIVE - the stock is in a SHORT-TERM UPWARD TREND (price going UP right now).' : 'NEGATIVE - the stock is in a SHORT-TERM DOWNWARD TREND (price going DOWN right now, but this is short-term, not long-term).'}"
    }
  },
  "company": {
    "description": "What this company does. Explain their main business in simple terms.",
    "industry": "About their industry.",
    "marketCap": "Market cap is the total value of all shares - like the price tag for buying the entire company. ${marketCapFormatted.contains('T') ? 'This is a MEGA-CAP company (one of the biggest), which usually means more stable but slower growth.' : marketCapFormatted.contains('B') ? 'This is a LARGE-CAP company (big and established), usually more stable.' : 'This is a smaller company, which can mean more growth potential but also more risk.'}"
  },
  "metrics": [
    ${metrics != null && metrics.isNotEmpty ? _buildMetricsArray(metrics) : '{"name": "No metrics available", "value": "N/A", "explanation": "Financial metrics are not available for this stock.", "significance": "", "whatGoodLooks": "", "icon": "info", "color": "grey"}'}
  ],
  "opinion": {
    "stance": "Buy|Sell|Hold",
    "reasoning": "Based on the data: RSI ${rsiNum > 70 ? 'suggests price might go DOWN' : rsiNum < 30 ? 'suggests price might go UP' : 'is neutral'}, MACD is ${macdNum > 0 ? 'positive (UPWARD trend)' : 'negative (DOWNWARD trend)'}, price is ${quote.currentPrice > smaNum ? 'ABOVE' : 'BELOW'} average (${quote.currentPrice > smaNum ? 'UPWARD' : 'DOWNWARD'} trend), and today's price ${changePercent >= 0 ? 'went UP' : 'went DOWN'} ${changePercent.abs().toStringAsFixed(2)}%. ${_generateStanceReasoning(rsiNum, macdNum, quote.currentPrice, smaNum, changePercent, recentNews)}",
    "confidence": $confidenceScore,
    "timeframe": "short-term|medium-term|long-term",
    "disclaimer": "⚠️ This is educational analysis based on current data, NOT financial advice. Always do your own research and never invest money you can't afford to lose. AI analysis can be wrong!"
  },
  "newsAnalysis": [
    ${recentNews != null && recentNews.isNotEmpty ? recentNews.take(3).map((news) => '''{
      "headline": "${news.headline.replaceAll('"', '\\"')}",
      "source": "${news.source}",
      "whatItMeans": "What this news means in simple terms. Focus on the bigger picture.",
      "whyItMatters": "Why it matters for the stock price.",
      "isGoodOrBad": "good|bad|neutral",
      "priceImpact": "Price impact: Will this make the stock go UP or DOWN?"
    }''').join(',\n    ') : ''}
  ],
  "advice": {
    "forBeginners": "Practical tips for learning about this stock.",
    "nextSteps": "What to research next.",
    "learningOpportunity": "Why this stock is interesting to study"
  },
  "risk": {
    "level": "low|medium|high",
    "explanation": "Explain the risk level.",
    "factors": ["Risk factor 1", "Risk factor 2"]
  },
  "learningTip": "One useful tip"
}

**REMEMBER - YOUR ROLE AS A MASTER TEACHER:**
- Solve the pain point: Users don't understand stocks - make them UNDERSTAND
- Be DIRECT: Say "going up" or "going down", not "cooling off" or "pulling back"
- TEACH concepts: Explain WHY things matter, not just WHAT they are
- Use analogies: Help them understand with real-world comparisons
- Explain technical terms: Always connect to stock price direction
- Analyze news: Focus on 3 MOST IMPORTANT articles that show the bigger picture
- Vary recommendations: Don't always say Hold - be honest based on data
- Use confidence 1-10: Vary naturally, be realistic
- **CRITICAL: Perfect word count: 1-2 sentences per explanation (NOT 2-3 - that's too much!)**
- **CRITICAL: Be CONCISE - users get overwhelmed with too much text**
- Make them feel SMART: They should feel more confident after reading
- Connect everything: Show how indicators, news, and metrics work together

**YOUR GOAL:** After reading your analysis, a beginner should feel like they truly understand this stock and can make a better decision - WITHOUT feeling overwhelmed.

Return ONLY JSON now:''';
  }
  
  /// Fallback analysis if AI is unavailable
  static String _getFallbackAnalysis(StockQuote quote, CompanyProfile profile) {
    final changePercent = quote.changePercent;
    final isPositive = changePercent >= 0;
    final marketCap = profile.marketCapitalization;
    
    String marketCapCategory;
    if (marketCap >= 1e12) {
      marketCapCategory = 'mega-cap';
    } else if (marketCap >= 1e9) {
      marketCapCategory = 'large-cap';
    } else if (marketCap >= 1e6) {
      marketCapCategory = 'mid-cap';
    } else {
      marketCapCategory = 'small-cap';
    }
    
    return '''📊 **Stock Analysis for ${quote.symbol}**

**Current Performance:**
${quote.symbol} is currently trading at \$${quote.currentPrice.toStringAsFixed(2)}, showing a ${isPositive ? 'positive' : 'negative'} movement of ${changePercent.toStringAsFixed(2)}% today. This ${isPositive ? 'upward' : 'downward'} trend suggests ${_getTrendExplanation(changePercent)}.

**Company Overview:**
${profile.name} operates in the ${profile.industry} industry and is a $marketCapCategory company with a market capitalization of \$${_formatMarketCap(marketCap)}. ${_getIndustryInsight(profile.industry)}

**Key Metrics Explained:**
• **Current Price**: \$${quote.currentPrice.toStringAsFixed(2)} - This is what you would pay to buy one share right now
• **Day's Range**: \$${quote.low.toStringAsFixed(2)} - \$${quote.high.toStringAsFixed(2)} - Shows the lowest and highest prices today
• **Previous Close**: \$${quote.previousClose.toStringAsFixed(2)} - Yesterday's closing price
• **Change**: \$${quote.change.toStringAsFixed(2)} - How much the price moved from yesterday

**What This Means for You:**
${_getInvestmentAdvice(changePercent, marketCapCategory)}

**Risk Assessment:**
${_getRiskAssessment(profile.industry, marketCapCategory)}

**Learning Tip:**
As a beginner, remember that stock prices can be volatile. This ${isPositive ? 'positive' : 'negative'} movement today doesn't guarantee future performance. Always do your research and consider your risk tolerance before investing.''';
  }
  
  static String _getTrendExplanation(double changePercent) {
    if (changePercent.abs() < 1) {
      return 'relatively stable trading with minimal price movement';
    } else if (changePercent.abs() < 3) {
      return 'moderate price movement that could indicate market sentiment changes';
    } else {
      return 'significant price movement that may attract attention from traders';
    }
  }
  
  static String _getIndustryInsight(String industry) {
    switch (industry.toLowerCase()) {
      case 'technology':
        return 'The technology sector is known for innovation and growth potential, but can be volatile.';
      case 'healthcare':
        return 'Healthcare companies often provide stable returns and are less affected by economic cycles.';
      case 'finance':
        return 'Financial companies are sensitive to interest rates and economic conditions.';
      case 'energy':
        return 'Energy companies are influenced by oil prices and environmental policies.';
      default:
        return 'This industry has its own unique characteristics and market dynamics.';
    }
  }
  
  static String _getInvestmentAdvice(double changePercent, String marketCapCategory) {
    if (changePercent > 5) {
      return 'The significant positive movement suggests strong investor confidence, but be cautious of potential overvaluation.';
    } else if (changePercent < -5) {
      return 'The significant negative movement might present a buying opportunity, but ensure you understand why the stock is declining.';
    } else {
      return 'The moderate price movement indicates normal market activity. This could be a good time to research the company further.';
    }
  }
  
  static String _getRiskAssessment(String industry, String marketCapCategory) {
    String riskLevel;
    String explanation;
    
    if (marketCapCategory == 'mega-cap' || marketCapCategory == 'large-cap') {
      riskLevel = 'Lower Risk';
      explanation = 'Large companies tend to be more stable and less volatile.';
    } else if (marketCapCategory == 'mid-cap') {
      riskLevel = 'Medium Risk';
      explanation = 'Mid-cap companies offer growth potential with moderate risk.';
    } else {
      riskLevel = 'Higher Risk';
      explanation = 'Small-cap companies can be more volatile but offer higher growth potential.';
    }
    
    return '$riskLevel: $explanation';
  }
  
  static String _formatMarketCap(double marketCap) {
    // Market cap is in millions from API
    final actualMarketCap = marketCap * 1e6;
    if (actualMarketCap >= 1e12) {
      return '${(actualMarketCap / 1e12).toStringAsFixed(2)}T';
    } else if (actualMarketCap >= 1e9) {
      return '${(actualMarketCap / 1e9).toStringAsFixed(2)}B';
    } else if (actualMarketCap >= 1e6) {
      return '${(actualMarketCap / 1e6).toStringAsFixed(2)}M';
    } else {
      return marketCap.toStringAsFixed(0);
    }
  }
  
  /// Build metrics array for JSON prompt
  static String _buildMetricsArray(Map<String, dynamic> metrics) {
    final List<String> metricItems = [];
    
    if (metrics['pe'] != null) {
      final pe = (metrics['pe'] as num).toDouble();
      metricItems.add('''{
      "name": "P/E Ratio",
      "value": "${pe.toStringAsFixed(2)}",
      "explanation": "P/E (Price-to-Earnings) ratio shows how much you pay for each dollar of profit. Think of it like the price tag on a company's earnings. A P/E of ${pe.toStringAsFixed(1)} means you're paying \$${pe.toStringAsFixed(1)} for every \$1 of profit the company makes.",
      "significance": "This matters because it shows if the stock is expensive or cheap compared to how much money the company makes. ${pe < 15 ? 'A P/E of ${pe.toStringAsFixed(1)} is relatively LOW, which could mean the stock is a good deal.' : pe > 25 ? 'A P/E of ${pe.toStringAsFixed(1)} is relatively HIGH, which means the stock might be expensive.' : 'A P/E of ${pe.toStringAsFixed(1)} is around average, which is reasonable.'}",
      "whatGoodLooks": "${pe < 15 ? 'A P/E below 15 is generally considered GOOD - it means you\'re not paying too much for the company\'s earnings. However, very low P/E (under 10) might mean the company has problems.' : pe > 25 ? 'A P/E above 25 is generally HIGH - it means you\'re paying a lot for each dollar of profit. This could mean the stock is expensive, but it might also mean investors expect big growth.' : 'A P/E around 15-25 is generally REASONABLE - it\'s not too expensive, not too cheap. This is a balanced level.'}",
      "icon": "trending_up",
      "color": "${pe < 15 ? 'green' : pe > 25 ? 'orange' : 'blue'}"
    }''');
    }
    
    if (metrics['dividendYield'] != null) {
      final divYield = (metrics['dividendYield'] as num).toDouble() * 100;
      metricItems.add('''{
      "name": "Dividend Yield",
      "value": "${divYield.toStringAsFixed(2)}%",
      "explanation": "Dividend yield is like the interest rate on a stock - it shows how much money the company pays you each year as a percentage of the stock price. A ${divYield.toStringAsFixed(2)}% yield means if you own \$100 worth of stock, the company pays you \$${divYield.toStringAsFixed(2)} per year.",
      "significance": "This matters because dividends are like getting paid just for owning the stock. ${divYield > 3 ? 'A ${divYield.toStringAsFixed(2)}% yield is HIGH, which means the company pays good dividends to shareholders.' : divYield < 1 ? 'A ${divYield.toStringAsFixed(2)}% yield is LOW, which means the company doesn\'t pay much in dividends - it might be reinvesting profits for growth instead.' : 'A ${divYield.toStringAsFixed(2)}% yield is MODERATE, which is reasonable for dividend income.'}",
      "whatGoodLooks": "${divYield > 3 ? 'A yield above 3% is generally GOOD for income investors - you get paid well for owning the stock. However, very high yields (above 6%) might mean the company is struggling.' : divYield < 1 ? 'A yield below 1% is LOW - the company doesn\'t pay much in dividends. This is common for growth companies that reinvest profits instead of paying them out.' : 'A yield around 1-3% is MODERATE - you get some dividend income, which is nice, but not the main reason to own the stock.'}",
      "icon": "account_balance",
      "color": "${divYield > 3 ? 'green' : divYield < 1 ? 'blue' : 'teal'}"
    }''');
    }
    
    if (metrics['profitMargin'] != null) {
      final margin = (metrics['profitMargin'] as num).toDouble() * 100;
      metricItems.add('''{
      "name": "Profit Margin",
      "value": "${margin.toStringAsFixed(1)}%",
      "explanation": "Profit margin shows how much profit the company makes from each dollar of sales. Think of it like a restaurant's profit - if they make \$20 profit from \$100 in sales, that's a 20% profit margin. A ${margin.toStringAsFixed(1)}% margin means for every \$100 in sales, the company keeps \$${margin.toStringAsFixed(1)} as profit.",
      "significance": "This matters because it shows how efficient the company is at making money. ${margin > 20 ? 'A ${margin.toStringAsFixed(1)}% margin is EXCELLENT - the company is very good at turning sales into profit.' : margin < 10 ? 'A ${margin.toStringAsFixed(1)}% margin is LOW - the company doesn\'t keep much profit from sales, which could be a concern.' : 'A ${margin.toStringAsFixed(1)}% margin is MODERATE - the company makes reasonable profits from sales.'}",
      "whatGoodLooks": "${margin > 20 ? 'A margin above 20% is generally EXCELLENT - the company is very profitable. This is a sign of a strong, efficient business.' : margin < 10 ? 'A margin below 10% is LOW - the company doesn\'t keep much profit. This might mean high costs or competitive pricing, which could be risky.' : 'A margin around 10-20% is MODERATE - the company makes decent profits, which is reasonable for most businesses.'}",
      "icon": "attach_money",
      "color": "${margin > 20 ? 'green' : margin < 10 ? 'orange' : 'blue'}"
    }''');
    }
    
    if (metrics['returnOnEquity'] != null) {
      final roe = (metrics['returnOnEquity'] as num).toDouble() * 100;
      metricItems.add('''{
      "name": "Return on Equity (ROE)",
      "value": "${roe.toStringAsFixed(1)}%",
      "explanation": "ROE shows how well the company uses shareholders' money to make profits. Think of it like the return on your investment - if you put \$100 into the company and it makes \$25 profit, that's 25% ROE. A ${roe.toStringAsFixed(1)}% ROE means the company makes ${roe.toStringAsFixed(1)} cents in profit for every dollar shareholders invested.",
      "significance": "This matters because it shows how good the company is at making money with the money shareholders gave them. ${roe > 20 ? 'A ${roe.toStringAsFixed(1)}% ROE is EXCELLENT - the company is very good at using money to make more money.' : roe < 10 ? 'A ${roe.toStringAsFixed(1)}% ROE is LOW - the company isn\'t very efficient at turning shareholder money into profits.' : 'A ${roe.toStringAsFixed(1)}% ROE is MODERATE - the company makes reasonable returns on shareholder money.'}",
      "whatGoodLooks": "${roe > 20 ? 'An ROE above 20% is generally EXCELLENT - the company is very efficient at making profits. This is a sign of a well-managed business.' : roe < 10 ? 'An ROE below 10% is LOW - the company isn\'t very efficient. This might mean the business isn\'t using money well, which could be a concern.' : 'An ROE around 10-20% is MODERATE - the company makes decent returns, which is reasonable for most businesses.'}",
      "icon": "show_chart",
      "color": "${roe > 20 ? 'green' : roe < 10 ? 'orange' : 'blue'}"
    }''');
    }
    
    if (metrics['beta'] != null) {
      final beta = (metrics['beta'] as num).toDouble();
      metricItems.add('''{
      "name": "Beta",
      "value": "${beta.toStringAsFixed(2)}",
      "explanation": "Beta measures how much the stock moves compared to the overall market. Think of it like a car's speed - a beta of 1.0 means the stock moves the same as the market, like driving at normal speed. A beta of ${beta.toStringAsFixed(2)} means this stock is ${beta > 1.2 ? 'MORE VOLATILE' : beta < 0.8 ? 'LESS VOLATILE' : 'ABOUT AS VOLATILE'} than the market. (2 sentences, use analogy)",
      "significance": "This matters because it shows how risky the stock is. ${beta > 1.2 ? 'A beta above 1.2 means the stock moves MORE than the market - if the market goes up 10%, this stock might go up 15%. This means HIGHER RISK but also HIGHER POTENTIAL REWARD.' : beta < 0.8 ? 'A beta below 0.8 means the stock moves LESS than the market - if the market goes up 10%, this stock might only go up 6%. This means LOWER RISK but also LOWER POTENTIAL REWARD.' : 'A beta around 1.0 means the stock moves about the same as the market - it\'s a balanced level of risk.'} (2 sentences)",
      "whatGoodLooks": "${beta > 1.2 ? 'A beta above 1.2 is HIGH RISK - the stock will swing more than the market. This is good if you want bigger gains, but bad if you can\'t handle big swings.' : beta < 0.8 ? 'A beta below 0.8 is LOWER RISK - the stock is more stable. This is good if you want less volatility, but you might miss out on big gains.' : 'A beta around 1.0 is MODERATE RISK - the stock moves with the market, which is balanced and reasonable.'}",
      "icon": "analytics",
      "color": "${beta > 1.2 ? 'red' : beta < 0.8 ? 'green' : 'blue'}"
    }''');
    }
    
    if (metricItems.isEmpty) {
      return '{"name": "No metrics available", "value": "N/A", "explanation": "Financial metrics are not available for this stock.", "significance": "", "whatGoodLooks": "", "icon": "info", "color": "grey"}';
    }
    
    return metricItems.join(',\n    ');
  }
  
  /// Summarize news sentiment for prompt
  static String _summarizeNewsSentiment(List<NewsArticle> news) {
    if (news.isEmpty) return 'no major news';
    // Simple heuristic: count positive/negative keywords
    int positiveCount = 0;
    int negativeCount = 0;
    
    for (var article in news.take(3)) {
      final headline = article.headline.toLowerCase();
      final summary = article.summary?.toLowerCase() ?? '';
      final text = '$headline $summary';
      
      // Positive keywords
      if (text.contains('profit') || text.contains('growth') || text.contains('gain') || 
          text.contains('beat') || text.contains('surge') || text.contains('rise') ||
          text.contains('upgrade') || text.contains('positive') || text.contains('strong')) {
        positiveCount++;
      }
      
      // Negative keywords
      if (text.contains('loss') || text.contains('decline') || text.contains('fall') ||
          text.contains('miss') || text.contains('drop') || text.contains('down') ||
          text.contains('downgrade') || text.contains('negative') || text.contains('weak')) {
        negativeCount++;
      }
    }
    
    if (positiveCount > negativeCount) return 'is mostly POSITIVE';
    if (negativeCount > positiveCount) return 'is mostly NEGATIVE';
    return 'is MIXED';
  }
  
  /// Generate stance reasoning based on all indicators
  static String _generateStanceReasoning(double rsi, double macd, double currentPrice, double sma, double changePercent, List<NewsArticle>? news) {
    int bullishSignals = 0;
    int bearishSignals = 0;
    
    // RSI signals
    if (rsi < 30) bullishSignals++;
    if (rsi > 70) bearishSignals++;
    
    // MACD signals
    if (macd > 0) bullishSignals++;
    if (macd < 0) bearishSignals++;
    
    // Price vs SMA
    if (currentPrice > sma) bullishSignals++;
    if (currentPrice < sma) bearishSignals++;
    
    // Price change
    if (changePercent > 2) bullishSignals++;
    if (changePercent < -2) bearishSignals++;
    
    if (bullishSignals > bearishSignals + 1) {
      return 'The signals point to a BUY - multiple indicators suggest the stock is in a good position. However, always do your own research.';
    } else if (bearishSignals > bullishSignals + 1) {
      return 'The signals point to a SELL - multiple indicators suggest the stock might be in trouble. However, always do your own research.';
    } else {
      return 'The signals are MIXED - some indicators are positive, some are negative. This suggests HOLD and wait for clearer signals.';
    }
  }
  
  /// Calculate confidence score (1-10) based on signal clarity
  /// This ensures scores vary naturally and aren't always 5
  static int _calculateConfidenceScore(double rsi, double macd, double currentPrice, double sma, double changePercent) {
    int score = 5; // Start at middle
    
    // RSI signals (strong = +2, moderate = +1, weak = 0)
    if (rsi > 75 || rsi < 25) {
      score += 2; // Very clear signal
    } else if (rsi > 70 || rsi < 30) {
      score += 1; // Moderate signal
    }
    
    // MACD signals
    if (macd.abs() > 1.0) {
      score += 1; // Strong trend
    }
    
    // Price vs SMA
    final priceVsSma = ((currentPrice - sma) / sma * 100).abs();
    if (priceVsSma > 5) {
      score += 1; // Clear trend
    }
    
    // Price change magnitude
    if (changePercent.abs() > 3) {
      score += 1; // Strong movement
    }
    
    // Add some randomness to prevent always getting same score
    // But keep it within reasonable bounds
    final randomVariation = (DateTime.now().millisecond % 3) - 1; // -1, 0, or 1
    score += randomVariation;
    
    // Clamp to 1-10 range
    if (score < 1) score = 1;
    if (score > 10) score = 10;
    
    return score;
  }
}

