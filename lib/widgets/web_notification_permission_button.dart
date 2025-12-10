import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import '../services/web_notification_service.dart';

/// Button to request web notification permissions
/// Must be triggered by user interaction (button tap)
class WebNotificationPermissionButton extends StatelessWidget {
  final VoidCallback? onPermissionGranted;
  final VoidCallback? onPermissionDenied;
  
  const WebNotificationPermissionButton({
    super.key,
    this.onPermissionGranted,
    this.onPermissionDenied,
  });

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return const SizedBox.shrink();
    }
    
    final webNotification = WebNotificationService();
    
    return FutureBuilder<bool>(
      future: webNotification.areNotificationsEnabled(),
      builder: (context, snapshot) {
        final isEnabled = snapshot.data ?? false;
        final permissionStatus = webNotification.getPermissionStatus();
        
        // Already granted - show enabled state
        if (isEnabled || permissionStatus == 'granted') {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF10B981)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.notifications_active, color: Color(0xFF10B981), size: 20),
                const SizedBox(width: 8),
                Text(
                  'Notifications Enabled',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF10B981),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }
        
        // Permission denied - show disabled state
        if (permissionStatus == 'denied') {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.notifications_off, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Notifications Disabled',
                  style: GoogleFonts.inter(
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }
        
        // Not requested yet - show enable button
        return ElevatedButton.icon(
          onPressed: () async {
            final granted = await webNotification.requestPermission();
            if (granted) {
              onPermissionGranted?.call();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Notifications enabled!'),
                  backgroundColor: Color(0xFF10B981),
                ),
              );
            } else {
              onPermissionDenied?.call();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please enable notifications in your browser settings'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          },
          icon: const Icon(Icons.notifications_none, size: 20),
          label: const Text('Enable Notifications'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0052FF),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
    );
  }
}


