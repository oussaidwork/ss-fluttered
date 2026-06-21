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
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.local_gas_station,
                    color: cs.primary, size: 28),
                const SizedBox(width: 12),
                Text('Pit Management',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface)),
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
