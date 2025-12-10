# AI Setup Instructions for Gemini API

## Quick Setup

To enable the AI Explain functionality, you need a Gemini API key:

1. **Get Your API Key:**
   - Go to: https://makersuite.google.com/app/apikey
   - Sign in with your Google account
   - Click "Create API Key"
   - Copy your API key

2. **Add to .env file:**
   - Open `.env` file in the project root
   - Add this line:
   ```
   GEMINI_API_KEY=your_api_key_here
   ```
   - Replace `your_api_key_here` with your actual API key

3. **Restart the app:**
   - The AI service will automatically initialize on app start
   - Check console for "✅ AI Model (Gemini) initialized successfully"

## What Happens Without API Key?

- The app will still work perfectly
- AI Explain tab will show a fallback analysis (still uses live stock data)
- All other features work normally
- No errors or crashes

## Features Enabled with AI:

- **Real-time AI Analysis:** Uses Gemini to analyze live stock data
- **Context-Aware Explanations:** Considers current price, metrics, news, and indicators
- **Beginner-Friendly:** Tailored explanations for high school students
- **Professional Prompts:** Optimized prompt engineering for accurate analysis

## Model Used:

- **gemini-1.5-flash** - Fast, cost-effective, perfect for real-time analysis
- Can be changed to `gemini-1.5-pro` in `ai_stock_analysis_service.dart` for more detailed analysis






