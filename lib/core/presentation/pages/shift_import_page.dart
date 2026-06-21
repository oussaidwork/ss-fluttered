import 'dart:async';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/firestore/firestore_provider.dart';

class ShiftImportPage extends StatefulWidget {
  const ShiftImportPage({super.key});

  @override
  State<ShiftImportPage> createState() => _ShiftImportPageState();
}

// ──────────────────────────────────────────────────────────────
// Data models for the preview
// ──────────────────────────────────────────────────────────────

class _PumpReading {
  final String code;
  String? pumpId;
  String? pumpName;
  double? startAnalog;
  double? endAnalog;
  double? volume;
  _PumpStatus status;
  String? error;

  _PumpReading({required this.code}) : status = _PumpStatus.pending;
}

enum _PumpStatus { pending, matched, unmatched, noData, error }

class _ShiftPreview {
  String? date;
  String? operatorName;
  String? operatorId;
  double? superPrice;
  double? dieselPrice;
  List<_PumpReading> pumps = [];
  List<String> warnings = [];
  bool operatorFound = false;
}

// ──────────────────────────────────────────────────────────────
// Page
// ──────────────────────────────────────────────────────────────

class _ShiftImportPageState extends State<ShiftImportPage> {
  bool _isLoading = false;
  bool _parsed = false;
  bool _importing = false;
  String? _error;
  Map<String, int>? _result;

  _ShiftPreview? _preview;

  Future<void> _pickAndParse() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _parsed = false;
      _preview = null;
    });

    try {
      final preview = await _parseFile(result.files.single.bytes!);
      setState(() {
        _preview = preview;
        _parsed = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<_ShiftPreview> _parseFile(List<int> bytes) async {
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables['Shift Import'];
    if (sheet == null || sheet.rows.length < 34) {
      throw Exception(
        'Invalid file: expected "Shift Import" sheet with at least 34 rows',
      );
    }

    final preview = _ShiftPreview();

    // ── Row 8: Shift Header ──
    final headerRow = sheet.rows[8]
        .map((c) => c?.value?.toString().trim())
        .toList();
    preview.date = headerRow[0];
    preview.operatorName = headerRow[1];
    preview.superPrice = _parseDouble(headerRow[2]);
    preview.dieselPrice = _parseDouble(headerRow[3]);

    if (preview.date == null || preview.date!.isEmpty) {
      throw Exception('Missing date in shift header (row 8)');
    }

    // ── Resolve operator name → user ──
    if (preview.operatorName != null && preview.operatorName!.isNotEmpty) {
      final userSnap = await firestore
          .collection('users')
          .where('fullName', isEqualTo: preview.operatorName)
          .where('isDeleted', isEqualTo: false)
          .limit(1)
          .get();
      if (userSnap.docs.isNotEmpty) {
        preview.operatorId = userSnap.docs.first.id;
        preview.operatorFound = true;
      } else {
        preview.warnings.add(
          'Operator "${preview.operatorName}" not found in users collection',
        );
      }
    }

    // ── Rows 10-33: Pump readings ──
    // Pre-fetch all pumps to resolve codes
    final allPumps = await firestore
        .collection('pumps')
        .where('isDeleted', isEqualTo: false)
        .get();
    final pumpByCode = <String, String>{};
    final pumpNameByCode = <String, String>{};
    for (final doc in allPumps.docs) {
      final data = doc.data();
      final code = (data['label'] as String? ?? data['name'] as String? ?? '')
          .toString()
          .toUpperCase()
          .trim();
      if (code.isNotEmpty) {
        pumpByCode[code] = doc.id;
        pumpNameByCode[code] = data['name'] as String? ?? code;
      }
    }

    for (var i = 10; i <= 33 && i < sheet.rows.length; i++) {
      final row = sheet.rows[i]
          .map((c) => c?.value?.toString().trim())
          .toList();
      final code = (row[0] ?? '').toString().toUpperCase().trim();
      if (code.isEmpty) continue;

      final reading = _PumpReading(code: code);
      reading.startAnalog = _parseDouble(row[1]);
      reading.endAnalog = _parseDouble(row[2]);

      if (pumpByCode.containsKey(code)) {
        reading.pumpId = pumpByCode[code];
        reading.pumpName = pumpNameByCode[code];
        reading.status = _PumpStatus.matched;
      } else {
        reading.status = _PumpStatus.unmatched;
        reading.error = 'No pump found with code "$code"';
        preview.warnings.add('Unmatched pump: $code');
      }

      if (reading.startAnalog != null && reading.endAnalog != null) {
        reading.volume = reading.endAnalog! - reading.startAnalog!;
        if (reading.volume! < 0) {
          reading.status = _PumpStatus.error;
          reading.error =
              'End reading (${reading.endAnalog}) < Start reading (${reading.startAnalog})';
        }
      } else if (reading.startAnalog == null && reading.endAnalog == null) {
        reading.status = _PumpStatus.noData;
      }

      preview.pumps.add(reading);
    }

    return preview;
  }

  double? _parseDouble(String? s) {
    if (s == null || s.isEmpty) return null;
    return double.tryParse(s.replaceAll(',', '.'));
  }

  Future<void> _importToFirestore() async {
    if (_preview == null || _importing) return;
    setState(() => _importing = true);

    try {
      final preview = _preview!;
      final batch = firestore.batch();
      int shiftPumpsCount = 0;
      int fuelHistoryCount = 0;

      // 1. Create shift
      final shiftId = firestore.collection('work_shifts').doc().id;
      final shiftDate = DateTime.tryParse(preview.date ?? '');
      if (shiftDate == null) throw Exception('Invalid date: ${preview.date}');

      batch.set(firestore.collection('work_shifts').doc(shiftId), {
        'id': shiftId,
        'workerId': preview.operatorId ?? '',
        'startTime': Timestamp.fromDate(shiftDate),
        'endTime': Timestamp.fromDate(shiftDate.add(const Duration(hours: 8))),
        'status': 'CLOSED',
        'actualCash': null,
        'expectedCash': null,
        'isDeleted': false,
      });

      // 2. Create shift_pumps for matched pumps
      for (final pump in preview.pumps) {
        if (pump.pumpId == null ||
            pump.status == _PumpStatus.noData ||
            pump.status == _PumpStatus.error)
          continue;
        final spId = firestore.collection('shift_pumps').doc().id;
        batch.set(firestore.collection('shift_pumps').doc(spId), {
          'id': spId,
          'shiftId': shiftId,
          'pumpId': pump.pumpId,
          'startAnalogCounter': pump.startAnalog ?? 0,
          'endAnalogCounter': pump.endAnalog ?? pump.startAnalog ?? 0,
          'volume': pump.volume ?? 0,
          'revenue': 0,
        });
        shiftPumpsCount++;
      }

      // 3. Create fuel price history records
      if (preview.superPrice != null) {
        // Resolve gas type for "Super" — match by name containing
        final gasTypes = await firestore
            .collection('gas_types')
            .where('isDeleted', isEqualTo: false)
            .get();
        for (final doc in gasTypes.docs) {
          final data = doc.data();
          final n = (data['name'] as String? ?? '').toLowerCase();
          double? price;
          if (n.contains('super')) {
            price = preview.superPrice;
          } else if (n.contains('diesel') ||
              n.contains('gasoil') ||
              n.contains('gazole')) {
            price = preview.dieselPrice;
          }
          if (price != null) {
            final fhId = firestore.collection('fuelPriceHistory').doc().id;
            batch.set(firestore.collection('fuelPriceHistory').doc(fhId), {
              'id': fhId,
              'gasTypeId': doc.id,
              'price': price,
              'date': Timestamp.fromDate(shiftDate),
              'isDeleted': false,
            });
            fuelHistoryCount++;
          }
        }
      }

      await batch.commit();

      setState(() {
        _result = {
          'work_shifts': 1,
          'shift_pumps': shiftPumpsCount,
          'fuelPriceHistory': fuelHistoryCount,
        };
        _importing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Import completed: $shiftPumpsCount pump readings, $fuelHistoryCount price records',
            ),
            backgroundColor: const Color(0xFF84CC16),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _importing = false;
      });
    }
  }

  // ──────────────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.schedule, color: Color(0xFF0066CC), size: 28),
              const SizedBox(width: 12),
              const Text(
                'Shift Import',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              if (!_parsed && !_isLoading)
                ElevatedButton.icon(
                  onPressed: _pickAndParse,
                  icon: const Icon(Icons.file_upload, size: 18),
                  label: const Text('Select XLSX'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066CC),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              if (_parsed && !_importing && _result == null)
                ElevatedButton.icon(
                  onPressed: _importToFirestore,
                  icon: const Icon(Icons.cloud_upload, size: 18),
                  label: const Text('Import to Firestore'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF84CC16),
                    foregroundColor: const Color(0xFF0B1220),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Upload the shift readings XLSX template to preview and import shift data.',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 20),

          if (_isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF0066CC)),
              ),
            ),

          if (_error != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withAlpha(20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFEF4444).withAlpha(60),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFEF4444)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: Color(0xFFEF4444),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (_result != null) _buildResults(),

          if (_parsed && _preview != null && _result == null)
            Expanded(child: _buildPreview()),

          if (!_parsed && !_isLoading && _error == null)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.upload_file, color: Colors.white24, size: 64),
                    SizedBox(height: 16),
                    Text(
                      'Select a shift readings XLSX file to begin',
                      style: TextStyle(color: Colors.white38, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    return Expanded(
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF0B1220),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF84CC16).withAlpha(60)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: Color(0xFF84CC16),
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'Import Complete!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...(_result?.entries ?? <MapEntry<String, int>>[]).map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${e.key}: ',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${e.value}',
                        style: const TextStyle(
                          color: Color(0xFF84CC16),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        ' records',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () => setState(() {
                  _parsed = false;
                  _preview = null;
                  _result = null;
                  _error = null;
                }),
                child: const Text('Import Another'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreview() {
    final p = _preview!;
    final totalVolume = p.pumps.fold<double>(
      0.0,
      (acc, r) => acc + (r.volume ?? 0),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (p.warnings.isNotEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEAB308).withAlpha(20),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFEAB308).withAlpha(60)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.warning_amber,
                      color: Color(0xFFEAB308),
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Warnings',
                      style: TextStyle(
                        color: Color(0xFFEAB308),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ...p.warnings.map(
                  (w) => Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '• $w',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0B1220),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Shift Summary',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  _summaryCard(
                    'Total Volume',
                    '${totalVolume.toStringAsFixed(1)} L',
                    Icons.local_gas_station,
                    const Color(0xFF84CC16),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 16,
                runSpacing: 12,
                children: [
                  _summaryCard(
                    'Date',
                    p.date ?? '-',
                    Icons.calendar_today,
                    const Color(0xFF0066CC),
                  ),
                  _summaryCard(
                    'Operator',
                    p.operatorName ?? '-',
                    p.operatorFound ? Icons.check_circle : Icons.error_outline,
                    p.operatorFound
                        ? const Color(0xFF84CC16)
                        : const Color(0xFFEAB308),
                  ),
                  if (p.superPrice != null)
                    _summaryCard(
                      'Super Price',
                      '${p.superPrice!.toStringAsFixed(2)} MAD',
                      Icons.attach_money,
                      const Color(0xFF84CC16),
                    ),
                  if (p.dieselPrice != null)
                    _summaryCard(
                      'Diesel Price',
                      '${p.dieselPrice!.toStringAsFixed(2)} MAD',
                      Icons.attach_money,
                      const Color(0xFF0066CC),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0B1220),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFF111A2E),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          '#',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Text(
                          'Pump',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Code',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Start',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'End',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Volume',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Status',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: List.generate(p.pumps.length, (i) {
                        final pump = p.pumps[i];
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: i.isEven
                                ? Colors.transparent
                                : Colors.white.withAlpha(3),
                            border: const Border(
                              bottom: BorderSide(
                                color: Colors.white12,
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '${i + 1}',
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 4,
                                child: Text(
                                  pump.pumpName ?? '-',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  pump.code,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  pump.startAnalog?.toStringAsFixed(0) ?? '-',
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  pump.endAnalog?.toStringAsFixed(0) ?? '-',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: pump.volume != null
                                    ? Text(
                                        pump.volume!.toStringAsFixed(1),
                                        style: const TextStyle(
                                          color: Color(0xFF84CC16),
                                          fontSize: 12,
                                          fontFamily: 'monospace',
                                        ),
                                      )
                                    : const Text(
                                        '-',
                                        style: TextStyle(
                                          color: Colors.white38,
                                          fontSize: 12,
                                        ),
                                      ),
                              ),
                              Expanded(flex: 3, child: _pumpStatusBadge(pump)),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryCard(
    String label,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pumpStatusBadge(_PumpReading pump) {
    switch (pump.status) {
      case _PumpStatus.matched:
        return Row(
          children: const [
            Icon(Icons.check_circle, color: Color(0xFF84CC16), size: 14),
            SizedBox(width: 4),
            Text(
              'OK',
              style: TextStyle(color: Color(0xFF84CC16), fontSize: 11),
            ),
          ],
        );
      case _PumpStatus.unmatched:
        return Row(
          children: const [
            Icon(Icons.error_outline, color: Color(0xFFEAB308), size: 14),
            SizedBox(width: 4),
            Text(
              'Unmatched',
              style: TextStyle(color: Color(0xFFEAB308), fontSize: 11),
            ),
          ],
        );
      case _PumpStatus.noData:
        return Row(
          children: const [
            Icon(Icons.remove_circle_outline, color: Colors.white38, size: 14),
            SizedBox(width: 4),
            Text(
              'No data',
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        );
      case _PumpStatus.error:
        return Row(
          children: [
            const Icon(Icons.cancel, color: Color(0xFFEF4444), size: 14),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                pump.error ?? 'Error',
                style: const TextStyle(color: Color(0xFFEF4444), fontSize: 11),
              ),
            ),
          ],
        );
      case _PumpStatus.pending:
        return const Text(
          'Pending',
          style: TextStyle(color: Colors.white38, fontSize: 11),
        );
    }
  }
}
