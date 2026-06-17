import 'package:flutter/material.dart';

class LoadingSplashPage extends StatelessWidget {
  const LoadingSplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_gas_station, size: 80, color: Colors.blue),
            SizedBox(height: 24),
            Text('SS-RAGRAGA Station OS'),
            SizedBox(height: 16),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
