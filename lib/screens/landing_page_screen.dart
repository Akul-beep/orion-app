import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'dart:convert';
import 'auth/login_screen.dart';
import 'auth/signup_screen.dart';

/// Landing page that embeds the Next.js landing page
/// For web: embeds Next.js app via iframe
/// For mobile: shows a simple message
class LandingPageScreen extends StatefulWidget {
  const LandingPageScreen({super.key});

  @override
  State<LandingPageScreen> createState() => _LandingPageScreenState();
}

class _LandingPageScreenState extends State<LandingPageScreen> {
  static const String _viewId = 'orion-landing-page-iframe';
  bool _isRegistered = false;

  // URL for the Next.js landing page
  // In development: use localhost:3000 (make sure Next.js dev server is running)
  // In production: use your Vercel deployment URL
  static const String _landingPageUrl = 
    kDebugMode 
      ? 'http://localhost:3000' 
      : 'https://orion-landing-phi.vercel.app';

  @override
  void initState() {
    super.initState();
    if (kIsWeb && !_isRegistered) {
      _registerIframe();
      _setupMessageListener();
      _isRegistered = true;
    }
  }

  void _registerIframe() {
    // Create iframe element
    final iframe = html.IFrameElement()
      ..src = _landingPageUrl
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.margin = '0'
      ..style.padding = '0'
      ..allowFullscreen = true
      ..allow = 'clipboard-read; clipboard-write';

    // Register the platform view
    ui_web.platformViewRegistry.registerViewFactory(
      _viewId,
      (int viewId) => iframe,
    );
  }

  void _setupMessageListener() {
    // Listen for messages from the iframe
    html.window.onMessage.listen((html.MessageEvent event) {
      try {
        // Parse the message data (it comes as a string or Map)
        dynamic data;
        if (event.data is String) {
          data = jsonDecode(event.data as String);
        } else {
          data = event.data;
        }
        
        if (data is Map) {
          final type = data['type'];
          final route = data['route'];
          
          if (type == 'navigate' && route != null) {
            // Navigate immediately without waiting for frame callback for better performance
            if (mounted) {
              if (route == '/signup' || route == '/signup/' || route == 'signup') {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const SignUpScreen()),
                );
              } else if (route == '/login' || route == '/login/' || route == 'login') {
                // Navigate to login immediately
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            }
          }
        }
      } catch (e) {
        print('❌ Error handling message from iframe: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // Embed Next.js landing page via iframe
      return Scaffold(
        body: SizedBox.expand(
          child: HtmlElementView(viewType: _viewId),
        ),
      );
    } else {
      // For mobile: show message (landing page is web-only)
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.trending_up,
                size: 64,
                color: Color(0xFF0052FF),
              ),
              const SizedBox(height: 24),
              const Text(
                'Orion',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0052FF),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Please visit our website\nto view the landing page',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}
