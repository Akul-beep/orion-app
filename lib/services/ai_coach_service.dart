import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'paper_trading_service.dart';

/// AI Coach Service for providing personalized trading advice using Gemini
class AICoachService {
  static GenerativeModel? _model;
  static String? _apiKey;
  static bool _initialized = false;
  static String? _selectedModelName;
  
  /// Model priority based on actual rate limits from Google AI Studio (higher is better)
  /// Updated based on actual API limits: https://aistudio.google.com/
  static final Map<String, int> _modelPriority = {
    'gemini-2.5-flash-lite': 1000,     // Highest! 1K RPD, 15 RPM, 250K TPM
    'gemini-2.5-flash': 250,           // 250 RPD, 10 RPM, 250K TPM
    'gemini-2.0-flash': 200,           // 200 RPD, 15 RPM, 1M TPM
    'gemini-2.0-flash-lite': 200,      // 200 RPD, 30 RPM, 1M TPM
    'gemini-2.5-pro': 50,              // 50 RPD, 2 RPM, 125K TPM
    'gemini-2.0-flash-exp': 50,        // 50 RPD
    'gemini-1.5-pro': 1000,            // Legacy - if available
    'gemini-1.5-pro-latest': 1000,
    'gemini-1.5-flash': 2000,          // Legacy - if available
    'gemini-1.5-flash-latest': 2000,
    'gemini-pro': 500,                 // Legacy
    'gemini-pro-vision': 500,
  };
  
  /// List available models from the API
  static Future<List<String>> _listAvailableModels(String apiKey) async {
    try {
      final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey');
      print('🌐 Fetching models from: ${url.toString().replaceAll(apiKey, 'API_KEY_HIDDEN')}');
      final response = await http.get(url);
      
      print('📡 Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final allModels = (data['models'] as List<dynamic>?) ?? [];
        
        print('📦 Total models returned: ${allModels.length}');
        
        // Filter models that support generateContent
        final supportedModels = <String>[];
        for (var model in allModels) {
          final name = model['name'] as String?;
          final supportedMethods = model['supportedGenerationMethods'] as List<dynamic>?;
          final displayName = model['displayName'] as String?;
          
          if (name != null && 
              name.startsWith('models/') && 
              (supportedMethods?.contains('generateContent') ?? false)) {
            final modelName = name.replaceFirst('models/', '');
            supportedModels.add(modelName);
            print('   ✓ $modelName${displayName != null ? " ($displayName)" : ""}');
          } else if (name != null && name.startsWith('models/')) {
            // Log models that don't support generateContent for debugging
            final modelName = name.replaceFirst('models/', '');
            print('   ✗ $modelName (no generateContent support)');
          }
        }
        
        print('\n📋 SUMMARY: Found ${supportedModels.length} models supporting generateContent:');
        for (var model in supportedModels) {
          final priority = _modelPriority[model] ?? 0;
          print('   - $model (priority: $priority)');
        }
        
        return supportedModels;
      } else {
        print('⚠️ Failed to list models: ${response.statusCode}');
        print('⚠️ Response body: ${response.body}');
        return [];
      }
    } catch (e, stackTrace) {
      print('⚠️ Error listing models: $e');
      print('⚠️ Stack trace: $stackTrace');
      return [];
    }
  }
  
  /// Select the best model based on priority
  static String _selectBestModel(List<String> availableModels) {
    print('\n🎯 Selecting best model from ${availableModels.length} available models...');
    
    // Sort by priority (higher is better)
    availableModels.sort((a, b) {
      final priorityA = _modelPriority[a] ?? 0;
      final priorityB = _modelPriority[b] ?? 0;
      return priorityB.compareTo(priorityA);
    });
    
    // Print sorted list
    print('📊 Models sorted by priority:');
    for (var i = 0; i < availableModels.length && i < 5; i++) {
      final model = availableModels[i];
      final priority = _modelPriority[model] ?? 0;
      print('   ${i + 1}. $model (priority: $priority)');
    }
    
    if (availableModels.isNotEmpty) {
      final selected = availableModels.first;
      final priority = _modelPriority[selected] ?? 0;
      print('\n✅ SELECTED MODEL: $selected');
      print('   Priority: $priority');
      print('   Expected limits: ${priority >= 2000 ? "2000+ RPD" : priority >= 1000 ? "1000+ RPD" : priority >= 500 ? "500+ RPD" : "200 RPD"}');
      return selected;
    }
    
    // Fallback to known working model
    print('\n⚠️ No models found, using fallback: gemini-2.0-flash-lite');
    return 'gemini-2.0-flash-lite';
  }
  
  /// Initialize the AI model
  static Future<void> init() async {
    if (_initialized && _model != null) {
      return; // Already initialized
    }
    
    try {
      // Use the same API key as AIStockAnalysisService
      try {
        await dotenv.load(fileName: ".env");
        _apiKey = dotenv.env['GEMINI_API_KEY'];
      } catch (e) {
        print('⚠️ Could not load .env file: $e');
        _apiKey = null;
      }
      
      // Fallback to hardcoded key if .env fails (same pattern as AIStockAnalysisService)
      if (_apiKey == null || _apiKey!.isEmpty) {
        _apiKey = 'AIzaSyA3nAhM0gTQ6JEr73_gS3BSOyT3Z9uqiLE';
        print('🔑 AI Coach: Using Gemini API key: ${_apiKey!.substring(0, 10)}...');
      } else {
        print('🔑 AI Coach: Loaded Gemini API key from .env: ${_apiKey!.substring(0, 10)}...');
      }
      
      // First, try to list available models to find the best one
      print('🔍 Listing available models from API...');
      List<String> availableModels = [];
      try {
        availableModels = await _listAvailableModels(_apiKey!);
        if (availableModels.isNotEmpty) {
          print('✅ Found ${availableModels.length} available models');
          _selectedModelName = _selectBestModel(availableModels);
        }
      } catch (e) {
        print('⚠️ Model listing failed: $e');
        print('🔄 Will use fallback model');
      }
      
      // If no model selected from listing, use best available fallback
      if (_selectedModelName == null) {
        // Try gemini-2.5-flash-lite first (1K RPD - highest available)
        // Then fallback to gemini-2.0-flash-lite (200 RPD - known to work)
        _selectedModelName = 'gemini-2.5-flash-lite';
        print('📌 Using fallback model: $_selectedModelName (1K RPD - highest available)');
      }
      
      // Initialize the selected model with optimized settings for concise, context-aware responses
      print('🚀 Initializing model: $_selectedModelName');
      _model = GenerativeModel(
        model: _selectedModelName!,
        apiKey: _apiKey!,
        generationConfig: GenerationConfig(
          temperature: 0.6,  // Lower temperature for more focused, less verbose responses
          topK: 32,         // Reduced for more focused responses
          topP: 0.9,        // Slightly lower for better control
          maxOutputTokens: 1024,  // Reduced from 2048 to encourage conciseness
        ),
        systemInstruction: Content.text('''You are a concise, context-aware AI Trading Coach. 
- Answer questions directly without unnecessary context
- Keep responses appropriately sized (short for greetings, detailed for complex questions)
- Only mention portfolio when explicitly asked
- Be educational but brief
- Use minimal emojis (0-1 max)'''),
      );
      
      _initialized = true;
      final priority = _modelPriority[_selectedModelName!] ?? 0;
      print('✅ AI Coach Model ($_selectedModelName) initialized successfully');
      print('   Priority: $priority');
      if (priority >= 1000) {
        print('   Rate Limits: 1K RPD, 15 RPM, 250K TPM');
      } else if (priority >= 250) {
        print('   Rate Limits: 250 RPD, 10 RPM, 250K TPM');
      } else if (priority >= 200) {
        print('   Rate Limits: 200 RPD, 15-30 RPM, 1M TPM');
      } else {
        print('   Rate Limits: 50 RPD');
      }
    } catch (e) {
      print('❌ AI Coach Model initialization failed: $e');
      // Try fallback models in order of priority
      try {
        // Try gemini-2.5-flash-lite first (1K RPD)
        try {
          _selectedModelName = 'gemini-2.5-flash-lite';
          print('🔄 Trying fallback: $_selectedModelName (1K RPD)...');
          _model = GenerativeModel(
            model: _selectedModelName!,
            apiKey: _apiKey!,
            generationConfig: GenerationConfig(
              temperature: 0.6,
              topK: 32,
              topP: 0.9,
              maxOutputTokens: 1024,
        ),
        systemInstruction: Content.text('''You are a concise, context-aware AI Trading Coach. 
- Answer questions directly without unnecessary context
- Keep responses SHORT (max 12-15 lines)
- Only mention portfolio when explicitly asked
- Be educational but BRIEF
- Use minimal emojis (0-1 max)
- Use CAPS for emphasis (NOT **asterisks** - they don't render!)'''),
      );
      _initialized = true;
          print('✅ Fallback model ($_selectedModelName) initialized successfully');
        } catch (e) {
          print('⚠️ gemini-2.5-flash-lite failed, trying gemini-2.0-flash-lite: $e');
          _selectedModelName = 'gemini-2.0-flash-lite';
          _model = GenerativeModel(
            model: _selectedModelName!,
            apiKey: _apiKey!,
            generationConfig: GenerationConfig(
              temperature: 0.6,
              topK: 32,
              topP: 0.9,
              maxOutputTokens: 1024,
            ),
            systemInstruction: Content.text('''You are a concise, context-aware AI Trading Coach. 
- Answer questions directly without unnecessary context
- Keep responses SHORT (max 12-15 lines)
- Only mention portfolio when explicitly asked
- Be educational but BRIEF
- Use minimal emojis (0-1 max)
- Use CAPS for emphasis (NOT **asterisks** - they don't render!)'''),
          );
          _initialized = true;
          print('✅ AI Coach Model (fallback: $_selectedModelName) initialized successfully');
        }
      } catch (e2) {
        print('❌ Fallback model also failed: $e2');
        _initialized = false;
      }
    }
  }
  
  /// Get AI response for user message with portfolio context
  static Future<String> getCoachResponse({
    required String userMessage,
    PaperTradingService? paperTradingService,
  }) async {
    print('🤖 AI Coach: getCoachResponse called with message: "$userMessage"');
    
    if (_model == null) {
      print('🔄 AI Coach: Model is null, initializing...');
      await init();
      if (_model == null) {
        print('❌ AI Coach Model not initialized - returning fallback response');
        print('❌ API Key status: ${_apiKey != null ? "Present (${_apiKey!.substring(0, 10)}...)" : "NULL"}');
        print('❌ Initialized flag: $_initialized');
        return _getFallbackResponse(userMessage);
      }
      print('✅ AI Coach: Model initialized successfully');
    } else {
      print('✅ AI Coach: Model already initialized');
    }
    
    try {
      // Get portfolio context if available
      String portfolioContext = '';
      if (paperTradingService != null) {
        portfolioContext = _buildPortfolioContext(paperTradingService);
      }
      
      // Build the prompt
      final prompt = _buildPrompt(userMessage, portfolioContext);
      
      print('🤖 AI Coach: Generating response for user message...');
      
      // Generate response with retry logic
      int maxRetries = 3;
      int retryDelay = 2;
      
      for (int attempt = 1; attempt <= maxRetries; attempt++) {
        try {
          print('🤖 AI Coach: Attempting API call (attempt $attempt/$maxRetries)...');
          print('📝 Using model: $_selectedModelName');
          print('📝 Prompt length: ${prompt.length} characters');
          
          if (_model == null) {
            print('❌ Model is null! Re-initializing...');
            await init();
            if (_model == null) {
              throw Exception('Model initialization failed');
            }
          }
          
          final response = await _model!.generateContent([Content.text(prompt)]);
          
          print('📥 AI Coach: Response received');
          print('📥 Response text is null: ${response.text == null}');
          print('📥 Response text is empty: ${response.text?.isEmpty ?? true}');
          
          if (response.text != null && response.text!.isNotEmpty) {
            print('✅ AI Coach: Response generated successfully (${response.text!.length} chars)');
            return response.text!.trim();
          } else {
            print('⚠️ AI Coach: Empty response from AI');
            print('⚠️ Full response object: $response');
            if (attempt < maxRetries) {
              print('🔄 AI Coach: Retrying in ${retryDelay}s...');
              await Future.delayed(Duration(seconds: retryDelay));
              retryDelay *= 2;
              continue;
            }
            print('❌ AI Coach: All retries exhausted, using fallback');
            return _getFallbackResponse(userMessage);
          }
        } catch (e, stackTrace) {
          final errorMessage = e.toString().toLowerCase();
          print('⚠️ AI Coach: Error on attempt $attempt/$maxRetries');
          print('⚠️ Error type: ${e.runtimeType}');
          print('⚠️ Error message: $e');
          print('⚠️ Stack trace: $stackTrace');
          
          // Check if it's a retryable error
          if ((errorMessage.contains('503') || errorMessage.contains('429') || 
               errorMessage.contains('rate limit') || errorMessage.contains('unavailable') ||
               errorMessage.contains('quota') || errorMessage.contains('resource exhausted')) && 
              attempt < maxRetries) {
            print('🔄 AI Coach: Retrying in ${retryDelay}s...');
            await Future.delayed(Duration(seconds: retryDelay));
            retryDelay *= 2; // Exponential backoff
            continue;
          } else {
            // Not retryable or max retries reached
            print('❌ AI Coach: Not retrying - error: $e');
            print('❌ Returning fallback response');
            return _getFallbackResponse(userMessage);
          }
        }
      }
      
      return _getFallbackResponse(userMessage);
    } catch (e) {
      print('❌ AI Coach: Error generating response: $e');
      return _getFallbackResponse(userMessage);
    }
  }
  
  /// Build prompt for AI coach with smart context awareness
  static String _buildPrompt(String userMessage, String portfolioContext) {
    // Determine if portfolio context is relevant
    final messageLower = userMessage.toLowerCase();
    final isPortfolioRelevant = messageLower.contains('portfolio') || 
                                 messageLower.contains('my position') ||
                                 messageLower.contains('my stock') ||
                                 messageLower.contains('my investment') ||
                                 messageLower.contains('evaluate') ||
                                 messageLower.contains('analyze my') ||
                                 messageLower.contains('how am i doing') ||
                                 messageLower.contains('my performance');
    
    // Check if this is a trading tips request
    final isTradingTipsRequest = messageLower.contains('trading tip') ||
                                 messageLower.contains('tip') ||
                                 messageLower.contains('advice') ||
                                 messageLower.contains('best practice') ||
                                 messageLower.contains('how to trade') ||
                                 messageLower.contains('strategy');
    
    // Check if this is a stock discovery/recommendation request
    final isStockDiscoveryRequest = messageLower.contains('recommend') ||
                                     messageLower.contains('suggest') ||
                                     messageLower.contains('what stock') ||
                                     messageLower.contains('which stock') ||
                                     messageLower.contains('good stock') ||
                                     messageLower.contains('stocks to buy') ||
                                     messageLower.contains('stocks to watch') ||
                                     messageLower.contains('diversif') ||
                                     messageLower.contains('different sector') ||
                                     messageLower.contains('sector') ||
                                     messageLower.contains('trending') ||
                                     messageLower.contains('popular stock');
    
    // Determine response length based on query complexity
    final isSimpleQuery = messageLower.length < 20 || 
                         messageLower == 'hi' ||
                         messageLower == 'hello' ||
                         messageLower == 'hey' ||
                         messageLower.contains('thanks') ||
                         messageLower.contains('thank you');
    
    final isComplexQuery = messageLower.contains('explain') ||
                           messageLower.contains('what is') ||
                           messageLower.contains('how does') ||
                           messageLower.contains('tell me about') ||
                           messageLower.contains('analyze') ||
                           messageLower.length > 100;
    
    // Build context section only if relevant
    String contextSection = '';
    if (portfolioContext.isNotEmpty && isPortfolioRelevant) {
      contextSection = '\n**PORTFOLIO CONTEXT:**\n$portfolioContext\n\n**PORTFOLIO EVALUATION RULES:**\n- Keep under 12 lines\n- NO asterisks, NO bullets, NO special characters\n- Simple and clean\n\n**FORMAT:**\nPORTFOLIO STATUS: [Good/Needs Work/Mixed]\nTotal: [value] | P&L: [gain] ([%])\n\nSTRENGTHS:\n[1 line]\n\nCONCERNS:\n[1 line if any]\n\nACTIONS:\n1. [Specific action]\n2. [Specific action]\n';
    } else if (portfolioContext.isNotEmpty) {
      contextSection = '\n**NOTE: Portfolio data is available but NOT relevant to this question. DO NOT mention it unless the user specifically asks about their portfolio.**\n';
    }
    
    // Set response length instructions
    String lengthInstruction;
    if (isSimpleQuery) {
      lengthInstruction = 'Keep response VERY SHORT (1-2 sentences max). Be friendly and concise.';
    } else if (isPortfolioRelevant) {
      lengthInstruction = 'Portfolio evaluation under 12 lines. Use the FORMAT provided. NO asterisks, NO bullets. Simple and clean.';
    } else if (isTradingTipsRequest) {
      lengthInstruction = 'Give 3-4 tips MAX. Each tip: 2 lines (1 title, 1 explanation). Total under 12 lines. NO asterisks, NO bullets, NO special characters. Simple and clean.';
    } else if (isStockDiscoveryRequest) {
      lengthInstruction = 'FIRST give OPTIONS (4 choices max, 1 line each). If they chose, give 3-4 stocks MAX. Each stock: 1-2 lines ONLY. Total under 12 lines. Use CAPS for emphasis (NOT **asterisks**).';
    } else if (isComplexQuery) {
      lengthInstruction = 'Provide a detailed but well-structured explanation (3-5 paragraphs). Use bullet points for clarity.';
    } else {
      lengthInstruction = 'Keep response concise and focused (2-3 paragraphs). Get straight to the point.';
    }
    
    // Special instructions for trading tips and stock discovery
    String specialInstructions = '';
    if (isTradingTipsRequest) {
      specialInstructions = '''

**TRADING TIPS FORMAT:**

ULTRA SHORT - 3-4 tips MAX. NO ASTERISKS OR BULLETS!

1. DIVERSIFY SECTORS
Spread money across tech, healthcare, finance, energy. Reduces risk when one sector drops.

2. START SMALL
Begin with 1-3 stocks. Learn before adding more. Quality over quantity.

3. LONG-TERM THINKING
Hold 6+ months minimum. Short-term swings are noise. Focus on fundamentals.

4. SET STOP-LOSSES
Decide max loss (10%) before buying. Protects from drops. Removes emotion.

STRICT RULES:
- 3-4 tips ONLY
- Each tip: 2 lines MAX (1 line title, 1 line explanation)
- NO asterisks, NO bullets, NO special characters
- Just use numbers: 1. 2. 3.
- Total under 12 lines
- End with: "Not financial advice"''';
    } else if (isStockDiscoveryRequest) {
      specialInstructions = '''

**STOCK RECOMMENDATION FORMAT:**

ULTRA SHORT APPROACH:

STEP 1 - Give OPTIONS (4 lines max):
"Pick one:
1. Safe & Stable 2. Growth 3. Diversified 4. Specific Sector
Which?"

STEP 2 - If they picked, give 3-4 stocks MAX:

1. APPLE (AAPL) • Tech • Low Risk
Stable growth, strong brand. Good for: Beginners

2. VISA (V) • Finance • Medium Risk  
Digital payments leader. Good for: Growth

3. JOHNSON & JOHNSON (JNJ) • Healthcare • Low Risk
Defensive, 60yr dividend. Good for: Income

Want more? Ask! (Not financial advice)

STRICT RULES:
- 3-4 stocks MAX (not 5, not 6)
- Each stock: 1-2 lines ONLY
- Use CAPS for company names (NOT **asterisks**)
- Use numbers (1. 2. 3.) for organization
- Total response: under 12 lines
- Mix sectors
- End with disclaimer

SECTORS (use variety):
Tech: AAPL, MSFT, GOOGL | Healthcare: JNJ, UNH | Finance: JPM, V | Consumer: KO, WMT | Energy: NEE | Industrial: CAT''';
    }
    
    return '''You are an AI Trading Coach helping a beginner investor. Be smart, concise, and contextually aware.

$contextSection
**USER QUESTION:**
$userMessage

**CRITICAL RULES:**
1. **Context Awareness**: ${isPortfolioRelevant ? 'The user asked about their portfolio - use the portfolio context.' : 'The user did NOT ask about their portfolio. Answer their question directly without mentioning their portfolio or positions.'}
2. **Response Length**: $lengthInstruction
3. **Direct Answers**: Answer what they asked, not what you think they should know. If they ask "what's a trending stock?", give trending stocks, NOT advice about their current holdings.
4. **Tone**: ${isSimpleQuery ? 'Casual and friendly' : 'Professional but approachable'}
5. **Emojis**: Use 0-1 emoji only. Never use multiple emojis.
6. **Structure**: ${isComplexQuery || isTradingTipsRequest || isStockDiscoveryRequest ? 'Use clear paragraphs, bullet points, and sections for readability.' : 'Keep it conversational and flowing.'}
$specialInstructions

**WHAT TO DO:**
- Answer the specific question asked
- Be educational but concise
- Use simple language (high school level)
- For stock recommendations: Give OPTIONS first, then details if they choose
- For stock recommendations: Use CLEAN formatting (dividers, no markdown)
- Keep stock suggestions SHORT (2-3 lines per stock max)
- Mix sectors for diversification
- Be interactive and conversational

**CRITICAL FORMATTING:**
- NO asterisks, NO bullets, NO special characters
- Keep responses SHORT (under 12 lines)
- Use numbers (1. 2. 3.) for lists
- Use line breaks for readability
- Max 1 emoji total
- Be concise and punchy

**WHAT NOT TO DO:**
- Don't mention portfolio unless explicitly asked
- Don't give long responses (max 12 lines for stock suggestions)
- Don't suggest more than 4 stocks
- Don't write paragraphs - keep it to 1-2 lines per stock
- Don't forget disclaimer

**RESPONSE:**''';
  }
  
  /// Build portfolio context string
  static String _buildPortfolioContext(PaperTradingService service) {
    try {
      final portfolio = service.portfolio;
      final positions = portfolio.positions;
      final recentTrades = portfolio.recentTrades.take(5).toList();
      
      String context = '''
**Portfolio Summary:**
- Total Value: \$${portfolio.totalValue.toStringAsFixed(2)}
- Cash Balance: \$${portfolio.cashBalance.toStringAsFixed(2)}
- Invested Value: \$${portfolio.investedValue.toStringAsFixed(2)}
- Total P&L: \$${portfolio.totalPnL.toStringAsFixed(2)} (${portfolio.totalPnLPercent.toStringAsFixed(2)}%)
- Day Change: \$${portfolio.dayChange.toStringAsFixed(2)} (${portfolio.dayChangePercent.toStringAsFixed(2)}%)
- Number of Positions: ${positions.length}
''';
      
      if (positions.isNotEmpty) {
        context += '\n**Current Positions:**\n';
        for (var position in positions) {
          final pnlSign = position.unrealizedPnL >= 0 ? '+' : '';
          context += '- ${position.symbol}: ${position.quantity} shares @ \$${position.averagePrice.toStringAsFixed(2)} avg, Current: \$${position.currentPrice.toStringAsFixed(2)} (${pnlSign}\$${position.unrealizedPnL.toStringAsFixed(2)}, ${pnlSign}${position.unrealizedPnLPercent.toStringAsFixed(2)}%)\n';
        }
      }
      
      if (recentTrades.isNotEmpty) {
        context += '\n**Recent Trades:**\n';
        for (var trade in recentTrades) {
          context += '- ${trade.action.toUpperCase()} ${trade.quantity} ${trade.symbol} @ \$${trade.price.toStringAsFixed(2)} on ${_formatDate(trade.timestamp)}\n';
        }
      }
      
      return context;
    } catch (e) {
      print('⚠️ Error building portfolio context: $e');
      return '';
    }
  }
  
  /// Format date for display
  static String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
  
  /// Fallback response when AI is unavailable - context-aware and concise
  static String _getFallbackResponse(String userMessage) {
    final message = userMessage.toLowerCase().trim();
    
    // Handle simple greetings
    if (message == 'hi' || message == 'hello' || message == 'hey' || message.length < 5) {
      return "Hi! How can I help you with trading today?";
    }
    
    // Handle thanks
    if (message.contains('thanks') || message.contains('thank you')) {
      return "You're welcome! Feel free to ask if you need anything else.";
    }
    
    // Portfolio questions
    if (message.contains('portfolio') || message.contains('my position') || 
        message.contains('evaluate') || message.contains('analyze my')) {
      return "I can help analyze your portfolio! Key things to consider:\n• Diversification across sectors\n• Risk management with stop-losses\n• Regular performance reviews\n\nWhat specific aspect would you like to focus on?";
    }
    
    // Trending stocks / market questions
    if (message.contains('trending') || message.contains('hot stock') || 
        message.contains('popular stock') || message.contains('what stock')) {
      return "Some trending stocks to research: AAPL, MSFT, GOOGL, NVDA, TSLA. Always do your own research before investing!";
    }
    
    // Learning questions
    if (message.contains('learn') || message.contains('trading') || message.contains('education')) {
      return "Start with basics: market fundamentals, risk management, and paper trading practice. What specific topic interests you?";
    }
    
    // Buy/sell questions
    if (message.contains('buy') || message.contains('sell') || message.contains('should i')) {
      return "I can't give specific buy/sell advice. Consider: company fundamentals, market trends, your risk tolerance, and diversification. What stock are you researching?";
    }
    
    // Risk questions
    if (message.contains('risk') || message.contains('safe')) {
      return "Key risk principles: never invest more than you can afford to lose, diversify, use stop-losses, and start small. What's your main risk concern?";
    }
    
    // Tips/advice
    if (message.contains('tip') || message.contains('advice') || message.contains('help')) {
      return "Essential tips: practice with paper trading, set clear goals, learn from mistakes, stay informed, and keep a trading journal. What would you like to know more about?";
    }
    
    // Default - short and helpful
    return "I can help with trading education, portfolio analysis, risk management, and market insights. What would you like to know?";
  }
}

