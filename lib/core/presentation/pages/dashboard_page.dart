import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';
import '../widgets/editorial_ticker_bar.dart';

class DashboardPage extends StatelessWidget {
  final Widget child;
  const DashboardPage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Scaffold(
      appBar: isDesktop ? const EditorialTickerBar() : null,
      body: Row(
        children: [
          if (isDesktop) const Sidebar(),
          Expanded(child: child),
        ],
      ),
    );
  }
}
