import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/firestore/firestore_provider.dart';
import 'pump_dialog.dart';

class PumpListView extends StatelessWidget {
  final List<QueryDocumentSnapshot> docs;
  final Map<String, Map<String, dynamic>> pitMap;

  const PumpListView({
    super.key,
    required this.docs,
    required this.pitMap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columns: const [
            DataColumn(
                label: Text('Name',
                    style: TextStyle(color: Colors.white))),
            DataColumn(
                label: Text('Block',
                    style: TextStyle(color: Colors.white))),
            DataColumn(
                label: Text('Pit',
                    style: TextStyle(color: Colors.white))),
            DataColumn(
                label: Text('Counter',
                    style: TextStyle(color: Colors.white))),
            DataColumn(
                label: Text('Active',
                    style: TextStyle(color: Colors.white))),
            DataColumn(
                label: Text('Actions',
                    style: TextStyle(color: Colors.white))),
          ],
          rows: docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            final id = doc.id;
            final name = d['name'] ?? '';
            final groupId = d['groupId'] ?? '';
            final pitId = d['pitId'] ?? '';
            final counter =
                (d['initialAnalogCounter'] as num?)?.toDouble() ?? 0;
            final active = d['isActive'] ?? false;
            final pitName = pitMap[pitId]?['name'] ?? '-';
            return DataRow(cells: [
              DataCell(Text(name,
                  style: const TextStyle(color: Colors.white))),
              DataCell(Text(groupId,
                  style: const TextStyle(color: Colors.white54))),
              DataCell(Text(pitName,
                  style: const TextStyle(color: Colors.white54))),
              DataCell(Text(counter.toStringAsFixed(1),
                  style: const TextStyle(color: Colors.white54))),
              DataCell(
                Icon(
                  active
                      ? Icons.check_circle
                      : Icons.cancel,
                  color: active
                      ? const Color(0xFF84CC16)
                      : Colors.red,
                  size: 20,
                ),
              ),
              DataCell(
                Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                    icon: const Icon(Icons.edit,
                        size: 20,
                        color: Color(0xFF0066CC)),
                    onPressed: () => showPumpDialog(context,
                        pump: d, docId: id),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete,
                        size: 20, color: Colors.red),
                    onPressed: () async {
                      await firestore
                          .collection('pumps')
                          .doc(id)
                          .update({'isDeleted': true});
                    },
                  ),
                ]),
              ),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}
