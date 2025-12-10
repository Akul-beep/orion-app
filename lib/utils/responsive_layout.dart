import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ResponsiveLayout extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsets? padding;

  const ResponsiveLayout({
    super.key,
    required this.child,
    this.maxWidth = 1200,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      // Mobile: full width with padding
      return Padding(
        padding: padding ?? EdgeInsets.zero,
        child: child,
      );
    }

    // Web: centered with max width
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 24),
          child: child,
        ),
      ),
    );
  }
}

class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final EdgeInsets mobilePadding;
  final EdgeInsets webPadding;

  const ResponsivePadding({
    super.key,
    required this.child,
    this.mobilePadding = const EdgeInsets.all(20),
    this.webPadding = const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: kIsWeb ? webPadding : mobilePadding,
      child: child,
    );
  }
}

bool get isWeb => kIsWeb;

bool get isMobile => !kIsWeb;

double getWebMaxWidth(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  if (width > 1400) return 1200;
  if (width > 1024) return 1000;
  return width * 0.9;
}


