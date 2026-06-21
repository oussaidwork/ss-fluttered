import 'package:flutter/material.dart';
import '../widgets/pits_list_section.dart';
import '../widgets/refill_history_section.dart';
import '../widgets/fuel_suppliers_section.dart';

/// Pits management page with 3 accordion sections:
/// Pits List, Refill History, Fuel Suppliers.
class PitsPage extends StatefulWidget {
  const PitsPage({super.key});

  @override
  State<PitsPage> createState() => _PitsPageState();
}

class _PitsPageState extends State<PitsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.local_gas_station,
                    color: Color(0xFF0066CC), size: 28),
                const SizedBox(width: 12),
                const Text('Pit Management',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ],
            ),
            const SizedBox(height: 24),
            const PitsListSection(),
            const SizedBox(height: 16),
            const RefillHistorySection(),
            const SizedBox(height: 16),
            const FuelSuppliersSection(),
          ],
        ),
      ),
    );
  }
}
