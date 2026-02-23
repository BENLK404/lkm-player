import 'package:flutter/material.dart';

class OnlineScreen extends StatelessWidget {
  const OnlineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Découvrir'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.public, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Musique en ligne',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Bientôt disponible...'),
          ],
        ),
      ),
    );
  }
}
