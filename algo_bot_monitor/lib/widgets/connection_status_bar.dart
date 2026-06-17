import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/websocket_provider.dart';
import '../core/network/websocket_client.dart';

class ConnectionStatusBar extends ConsumerWidget {
  const ConnectionStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(connectionStatusProvider);
    
    return statusAsync.when(
      data: (status) {
        if (status == ConnectionStatus.connected) {
          return const SizedBox.shrink(); 
        }
        
        final isConnecting = status == ConnectionStatus.connecting;
        final color = isConnecting ? const Color(0xFFF59E0B) : const Color(0xFFEF4444);
        final text = isConnecting ? 'Connecting to live ticker...' : 'Live updates disconnected';
        final icon = isConnecting ? Icons.sync : Icons.cloud_off;

        return Container(
          color: color.withOpacity(0.95),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedRotation(
                turns: isConnecting ? 1 : 0,
                duration: const Duration(seconds: 2),
                child: Icon(icon, size: 14, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        color: const Color(0xFFF59E0B).withOpacity(0.95),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 12,
              width: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 8),
            Text(
              'Initializing WebSocket connection...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      error: (_, __) => Container(
        color: const Color(0xFFEF4444),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 14, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Connection error',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
