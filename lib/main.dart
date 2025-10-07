import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_web/webview_flutter_web.dart';

import 'screens/home_screen.dart';
import 'screens/stocks_screen.dart';
import 'screens/tradingview_demo_screen.dart';

void main() {
  // Initialize WebView platform for web
  WebViewPlatform.instance = WebWebViewPlatform();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Orion Financial App',
      theme: _buildThemeData(context),
      home: const MainScreen(),
    );
  }

  ThemeData _buildThemeData(BuildContext context) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2C2C54), // Dark Slate Blue
        background: Colors.white,
        primary: const Color(0xFF2C2C54), // Dark Slate Blue
        onPrimary: Colors.white,
        secondary: const Color(0xFF00D09C), // Vibrant Green
      ),
              textTheme: TextTheme(
                displayLarge: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
                titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                titleMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                bodyLarge: TextStyle(fontSize: 16, color: Colors.black),
                bodyMedium: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
      cardTheme: CardTheme(
        color: const Color(0xFF2C2C54),
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    StocksScreen(),
    TradingViewDemoScreen(),
    Center(child: Text('Settings Page')),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'Stocks'),
          BottomNavigationBarItem(icon: Icon(Icons.trending_up), label: 'Charts'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF2C2C54),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        showUnselectedLabels: true,
      ),
    );
  }
}
