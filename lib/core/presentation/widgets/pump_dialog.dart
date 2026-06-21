import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/firestore/firestore_provider.dart';

class PumpDialog extends StatefulWidget {
  final Map<String, dynamic>? pump;
  final String? docId;

  const PumpDialog({super.key, this.pump, this.docId});

  @override
  State<PumpDialog> createState() => _PumpDialogState();
}

class _PumpDialogState extends State<PumpDialog> {
  late TextEditingController _nameCtrl;
  late TextEditingController _counterCtrl;
  late String? _selectedGroupId;
  late String? _selectedPitId;
  late bool _isActive;
  late String _selectedColor;

  final _blockOptions = ['Block A', 'Block B', 'Block C', 'Block D'];
  final _colorOptions = ['red', 'blue', 'green', 'yellow', 'white'];

  @override
  void initState() {
    super.initState();
    final p = widget.pump;
    _nameCtrl = TextEditingController(text: p?['name'] ?? '');
    _counterCtrl = TextEditingController(
        text: p?['initialAnalogCounter']?.toString() ?? '');
    _selectedGroupId = p?['groupId'] ?? 'Block A';
    _selectedPitId = p?['pitId'];
    _isActive = p?['isActive'] ?? true;
    _selectedColor = p?['color'] ?? 'red';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _counterCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A2332),
      title: Text(
        widget.docId == null ? 'Add Pump' : 'Edit Pump',
        style: const TextStyle(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: _nameCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Name',
              labelStyle: TextStyle(color: Colors.white54),
              enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24)),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedGroupId,
            dropdownColor: const Color(0xFF1A2332),
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
                labelText: 'Block (Group)',
                labelStyle: TextStyle(color: Colors.white54)),
            items: _blockOptions
                .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                .toList(),
            onChanged: (v) => setState(() => _selectedGroupId = v),
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: firestore
                .collection('pits')
                .where('isDeleted', isEqualTo: false)
                .snapshots(),
            builder: (ctx, snap) {
              final docs = snap.data?.docs ?? [];
              return DropdownButtonFormField<String>(
                value: _selectedPitId,
                dropdownColor: const Color(0xFF1A2332),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                    labelText: 'Pit',
                    labelStyle: TextStyle(color: Colors.white54)),
                items: docs
                    .map((d) => DropdownMenuItem(
                        value: d.id,
                        child: Text(
                            (d.data() as Map<String, dynamic>)['name'] ?? '')))
                    .toList(),
                onChanged: (v) => setState(() => _selectedPitId = v),
              );
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _counterCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Initial Counter',
              labelStyle: TextStyle(color: Colors.white54),
              enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24)),
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
            title: const Text('Active',
                style: TextStyle(color: Colors.white)),
            activeColor: const Color(0xFF84CC16),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedColor,
            dropdownColor: const Color(0xFF1A2332),
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
                labelText: 'Color',
                labelStyle: TextStyle(color: Colors.white54)),
            items: _colorOptions
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) =>
                setState(() => _selectedColor = v ?? 'red'),
          ),
        ]),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel',
              style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0066CC)),
          onPressed: _save,
          child: Text(widget.docId == null ? 'Add' : 'Save',
              style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final counter = double.tryParse(_counterCtrl.text) ?? 0;
    if (name.isEmpty || _selectedPitId == null) return;
    final data = {
      'name': name,
      'groupId': _selectedGroupId,
      'pitId': _selectedPitId,
      'initialAnalogCounter': counter,
      'isActive': _isActive,
      'color': _selectedColor,
      'isDeleted': false,
    };
    if (widget.docId == null) {
      final id = firestore.collection('pumps').doc().id;
      await firestore.collection('pumps').doc(id).set({...data, 'id': id});
    } else {
      await firestore.collection('pumps').doc(widget.docId!).update(data);
    }
    if (context.mounted) Navigator.pop(context);
  }
}

/// Shows the pump dialog as a modal.
Future<void> showPumpDialog(BuildContext context,
    {Map<String, dynamic>? pump, String? docId}) {
  return showDialog(
    context: context,
    builder: (_) => PumpDialog(pump: pump, docId: docId),
  );
}
