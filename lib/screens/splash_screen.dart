import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.radar, size: 72, color: Color(0xFF00D1B2)),
            SizedBox(height: 20),
            Text(
              'ROV Commander',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 8),
            Text('Real-Time Surveillance ROV', textAlign: TextAlign.center),
            SizedBox(height: 28),
            SizedBox(
              width: 34,
              height: 34,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            SizedBox(height: 14),
            Text('Connecting to vehicle...'),
          ],
        ),
      ),
    );
  }
}
