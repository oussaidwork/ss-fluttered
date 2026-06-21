import 'package:flutter/material.dart';

class LoadingSplashPage extends StatelessWidget {
  const LoadingSplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_gas_station, size: 80, color: cs.primary),
            const SizedBox(height: 24),
            Text('SS-RAGRAGA Station OS'),
            const SizedBox(height: 16),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
