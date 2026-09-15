// lib/features/broadcast/screens/broadcast_history_screen.dart

import 'package:flutter/material.dart';

class BroadcastHistoryScreen extends StatelessWidget {
  const BroadcastHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📋 تاريخ الرسائل'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'قيد التطوير',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'سيتم إضافة تاريخ الرسائل قريباً',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('العودة'),
            ),
          ],
        ),
      ),
    );
  }
}
