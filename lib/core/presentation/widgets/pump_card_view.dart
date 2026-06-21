import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/firestore/firestore_provider.dart';
import 'pump_dialog.dart';

class PumpCardView extends StatelessWidget {
  final List<QueryDocumentSnapshot> docs;
  final Map<String, Map<String, dynamic>> pitMap;

  const PumpCardView({
    super.key,
    required this.docs,
    required this.pitMap,
  });

  static const _colorMap = {
    'red': Colors.red,
    'blue': Colors.blue,
    'green': Color(0xFF84CC16),
    'yellow': Colors.yellow,
    'white': Colors.white,
  };

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<QueryDocumentSnapshot>>{};
    for (final doc in docs) {
      final d = doc.data() as Map<String, dynamic>;
      final g = d['groupId'] as String? ?? 'Ungrouped';
      grouped.putIfAbsent(g, () => []).add(doc);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: grouped.length,
      itemBuilder: (ctx, idx) {
        final group = grouped.keys.elementAt(idx);
        final pumps = grouped[group]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0066CC).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      group,
                      style: const TextStyle(
                        color: Color(0xFF0066CC),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${pumps.length} pump${pumps.length != 1 ? 's' : ''}',
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: pumps
                  .map((doc) => _buildCard(context, doc))
                  .toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCard(BuildContext context, QueryDocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final id = doc.id;
    final name = d['name'] ?? '';
    final counter =
        (d['initialAnalogCounter'] as num?)?.toDouble() ?? 0;
    final active = d['isActive'] ?? false;
    final colorName = d['color'] ?? 'red';
    final pitId = d['pitId'] as String? ?? '';
    final pit = pitMap[pitId];
    final pitName = pit?['name'] ?? '-';
    final chipColor = _colorMap[colorName] ?? Colors.blue;

    return SizedBox(
      width: 260,
      child: Card(
        color: const Color(0xFF1A2332),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                        color: chipColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: active
                          ? const Color(0xFF84CC16)
                              .withValues(alpha: 0.15)
                          : Colors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      active ? 'Active' : 'Inactive',
                      style: TextStyle(
                        color: active
                            ? const Color(0xFF84CC16)
                            : Colors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _infoRow('Pit', pitName),
              _infoRow('Counter', counter.toStringAsFixed(1)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          showPumpDialog(context, pump: d, docId: id),
                      icon: const Icon(Icons.edit, size: 14),
                      label: const Text('Edit',
                          style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0066CC),
                        side: const BorderSide(
                            color: Color(0xFF0066CC)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await firestore
                            .collection('pumps')
                            .doc(id)
                            .update({'isDeleted': true});
                      },
                      icon: const Icon(Icons.delete, size: 14),
                      label: const Text('Delete',
                          style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding:
                            const EdgeInsets.symmetric(vertical: 6),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style:
                const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
