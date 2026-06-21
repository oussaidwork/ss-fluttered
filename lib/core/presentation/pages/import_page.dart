import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../l10n/app_localizations.dart';
import '../../services/import_service.dart';
import '../../services/json_import_service.dart';
import '../../services/json_export_service.dart';
import '../../../data/datasource/firestore_datasource.dart';

class ImportPage extends ConsumerStatefulWidget {
  final String? importType;

  const ImportPage({super.key, this.importType});

  @override
  ConsumerState<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends ConsumerState<ImportPage> {
  // State
  bool _isImporting = false;
  Map<String, int>? _results;
  String? _error;

  // Paste JSON tab
  final _pasteController = TextEditingController();
  bool _isPastingJson = false;

  // Toggle: false = file upload, true = paste JSON
  bool _usePasteMode = false;

  bool get _isBulkImport => widget.importType == null;

  @override
  void dispose() {
    _pasteController.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────
  // FILE UPLOAD (.xlsx / .json)
  // ──────────────────────────────────────────────

  Future<void> _handleFileUpload() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'json'],
        withData: true,
      );

      if (result == null || result.files.single.bytes == null) return;

      setState(() {
        _isImporting = true;
        _error = null;
        _results = null;
      });

      final fileName = result.files.single.name.toLowerCase();
      final Map<String, int> results;

      if (fileName.endsWith('.json')) {
        final jsonString = utf8.decode(result.files.single.bytes!);
        results = await JsonImportService(FirestoreDataSourceImpl()).importJson(jsonString);
      } else {
        final importService = ImportService(FirestoreDataSourceImpl());
        if (_isBulkImport) {
          results = await importService.importExcel(result.files.single.bytes!);
        } else {
          results = await importService.importByType(
              result.files.single.bytes!, widget.importType!);
        }
      }

      setState(() {
        _results = results;
        _isImporting = false;
      });

      if (mounted) {
        _showSnackBar('Import completed successfully!', const Color(0xFF84CC16));
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isImporting = false;
      });
      if (mounted) {
        _showSnackBar('Import failed: $e', const Color(0xFFEF4444));
      }
    }
  }

  // ──────────────────────────────────────────────
  // PASTE JSON
  // ──────────────────────────────────────────────

  Future<void> _handlePasteImport() async {
    final jsonString = _pasteController.text.trim();
    if (jsonString.isEmpty) {
      _showSnackBar('Please paste JSON content first', Colors.amber);
      return;
    }

    setState(() {
      _isPastingJson = true;
      _error = null;
      _results = null;
    });

    try {
        final results = await JsonImportService(FirestoreDataSourceImpl()).importJson(jsonString);
      setState(() {
        _results = results;
        _isPastingJson = false;
      });
      if (mounted) {
        _showSnackBar('Import completed successfully!', const Color(0xFF84CC16));
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isPastingJson = false;
      });
      if (mounted) {
        _showSnackBar('Import failed: $e', const Color(0xFFEF4444));
      }
    }
  }

  void _copyTemplateToClipboard() {
    final template = JsonExportService.generateTemplate();
    Clipboard.setData(ClipboardData(text: template));
    _showSnackBar('Template copied to clipboard!', const Color(0xFF0066CC));
  }

  void _downloadTemplate() {
    JsonExportService.downloadTemplate();
    _showSnackBar('Template downloaded!', const Color(0xFF84CC16));
  }

  // ──────────────────────────────────────────────
  // HELPERS
  // ──────────────────────────────────────────────

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              const Icon(Icons.upload_file, color: Color(0xFF0066CC), size: 28),
              const SizedBox(width: 12),
              Text(
                _isBulkImport ? '${l10n.import} Data' : l10n.importData,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Mode toggle + template buttons
          _buildTopBar(l10n),
          const SizedBox(height: 20),

          // Main card
          Expanded(
            child: Card(
              color: const Color(0xFF1A2332),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: _usePasteMode ? _buildPastePanel() : _buildFileUploadPanel(),
            ),
          ),

          // Error
          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withAlpha(20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFEF4444).withAlpha(60)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$_error',
                      style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Results
          if (_results != null) ...[
            const SizedBox(height: 16),
            _buildResultsSummary(),
          ],
        ],
      ),
    );
  }

  Widget _buildTopBar(AppLocalizations l10n) {
    return Row(
      children: [
        // Mode toggle
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0B1220),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _toggleButton('File Upload', !_usePasteMode, () => setState(() => _usePasteMode = false)),
              _toggleButton('Paste JSON', _usePasteMode, () => setState(() => _usePasteMode = true)),
            ],
          ),
        ),
        const Spacer(),
        // Template buttons
        OutlinedButton.icon(
          onPressed: _downloadTemplate,
          icon: const Icon(Icons.download, size: 16),
          label: const Text('Template'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF0066CC),
            side: const BorderSide(color: Color(0xFF0066CC)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: _copyTemplateToClipboard,
          icon: const Icon(Icons.copy, size: 16),
          label: const Text('Copy'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF84CC16),
            side: const BorderSide(color: Color(0xFF84CC16)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _toggleButton(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF0066CC) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white54,
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // FILE UPLOAD PANEL
  // ──────────────────────────────────────────────

  Widget _buildFileUploadPanel() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_upload, color: Colors.white24, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Upload .xlsx or .json file',
              style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select an export file to populate the database.\nData will be merged into existing collections.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 240,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isImporting ? null : _handleFileUpload,
                icon: _isImporting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.file_upload),
                label: Text(_isImporting ? 'Importing...' : 'Select File'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066CC),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // PASTE JSON PANEL
  // ──────────────────────────────────────────────

  Widget _buildPastePanel() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.paste, color: Color(0xFF0066CC), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Paste JSON Data',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${_pasteController.text.length} chars',
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Copy the template above, fill in your data, then paste here and click Import.',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 8),
          // ── Expected JSON structure guide ──
          _JsonStructureGuide(),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0B1220),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white12),
              ),
              child: TextField(
                controller: _pasteController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(
                  color: Color(0xFF84CC16),
                  fontSize: 12,
                  fontFamily: 'monospace',
                  height: 1.5,
                ),
                decoration: const InputDecoration(
                  hintText: 'Paste your JSON here...\n\n{\n  "version": "1.0",\n  "collections": {\n    ...\n  }\n}',
                  hintStyle: TextStyle(color: Colors.white24, fontSize: 12, fontFamily: 'monospace'),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: _pasteController.text.trim().isEmpty || _isPastingJson
                        ? null
                        : _handlePasteImport,
                    icon: _isPastingJson
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.upload, size: 18),
                    label: Text(_isPastingJson ? 'Importing...' : 'Import JSON'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF84CC16),
                      foregroundColor: const Color(0xFF0B1220),
                      disabledBackgroundColor: Colors.white12,
                      disabledForegroundColor: Colors.white24,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 44,
                child: OutlinedButton(
                  onPressed: () {
                    _pasteController.clear();
                    setState(() {});
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white54,
                    side: const BorderSide(color: Colors.white12),
                  ),
                  child: const Text('Clear'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // RESULTS
  // ──────────────────────────────────────────────

  Widget _buildResultsSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1220),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle, color: Color(0xFF84CC16), size: 20),
              SizedBox(width: 8),
              Text(
                'Import Summary',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const Divider(color: Colors.white12),
          ..._results!.entries.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.key, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    Text('${e.value} items', style: const TextStyle(color: Color(0xFF84CC16), fontSize: 13)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Expected JSON Structure Guide
// ─────────────────────────────────────────────────────────────────────────────

class _JsonStructureGuide extends StatelessWidget {
  const _JsonStructureGuide();

  static const _collections = <_Schema>[
    // ── Fuel & Payments ──
    _Schema('gas_types', description: 'Fuel types sold at the station', fields: [
      _Field('id', 'string', 'e.g. "gazole"'),
      _Field('name', 'Map<String,String>', 'localized name: {"en":"Diesel","fr":"Gazole","ar":"الغازوال"}'),
      _Field('unit_price', 'double', 'current selling price'),
      _Field('isDeleted', 'bool', 'soft delete flag'),
    ]),
    _Schema('payment_types', description: 'Accepted payment methods', fields: [
      _Field('id', 'string', 'e.g. "cash"'),
      _Field('name', 'Map<String,String>', 'localized name'),
      _Field('isDeleted', 'bool'),
    ]),

    // ── Station Layout ──
    _Schema('pits', description: 'Fuel dispensing islands', fields: [
      _Field('name', 'Map<String,String>', 'localized name'),
      _Field('code', 'string', 'short code e.g. "P1"'),
      _Field('isDeleted', 'bool'),
    ]),
    _Schema('pumps', description: 'Individual pumps within pits', fields: [
      _Field('pit_id', 'string', 'ref -> pits.id'),
      _Field('gas_type_id', 'string', 'ref -> gas_types.id'),
      _Field('pump_number', 'int', 'display number'),
      _Field('label', 'string', 'optional human label'),
      _Field('meter_reading', 'double', 'current meter totalizer'),
      _Field('isDeleted', 'bool'),
    ]),

    // ── Products & Services ──
    _Schema('products', description: 'Convenience store products & services', fields: [
      _Field('id', 'string'),
      _Field('name', 'Map<String,String>', 'localized name'),
      _Field('category', 'string', '"fuel" | "product" | "service"'),
      _Field('unit_price', 'double'),
      _Field('stock', 'double?', 'nullable for services'),
      _Field('unit', 'string?', 'e.g. "L", "pcs", "service"'),
      _Field('isDeleted', 'bool'),
    ]),

    // ── Clients ──
    _Schema('clients', description: 'Individual walk-in clients', fields: [
      _Field('id', 'string'),
      _Field('name', 'string'),
      _Field('phone', 'string?'),
      _Field('client_type', 'string', '"individual" | "fleet"'),
      _Field('credit_limit', 'double', '0 = no credit'),
      _Field('balance', 'double', 'outstanding debt'),
      _Field('isDeleted', 'bool'),
    ]),
    _Schema('client_fleet', description: 'Fleet vehicles for fleet clients', fields: [
      _Field('client_id', 'string', 'ref -> clients.id'),
      _Field('plate_number', 'string', 'e.g. "12345-67"'),
      _Field('vehicle_type', 'string', 'e.g. "truck", "car"'),
      _Field('gas_type_id', 'string', 'ref -> gas_types.id'),
      _Field('isDeleted', 'bool'),
    ]),

    // ── Users ──
    _Schema('users', description: 'Station employees', fields: [
      _Field('id', 'string'),
      _Field('email', 'string'),
      _Field('display_name', 'string'),
      _Field('role', 'string', '"admin" | "supervisor" | "cashier"'),
      _Field('phone', 'string?'),
      _Field('isDeleted', 'bool'),
    ]),

    // ── Operations ──
    _Schema('work_shifts', description: 'Daily shift records', fields: [
      _Field('id', 'string'),
      _Field('user_id', 'string', 'ref -> users.id'),
      _Field('start_time', 'Timestamp'),
      _Field('end_time', 'Timestamp?'),
      _Field('expected_total', 'double', 'expected cash total'),
      _Field('actual_total', 'double', 'actual counted cash'),
      _Field('notes', 'string?'),
      _Field('isDeleted', 'bool'),
    ]),
    _Schema('shift_pumps', description: 'Per-pump readings per shift', fields: [
      _Field('shift_id', 'string', 'ref -> work_shifts.id'),
      _Field('pump_id', 'string', 'ref -> pumps.id'),
      _Field('start_meter', 'double'),
      _Field('end_meter', 'double?'),
      _Field('isDeleted', 'bool'),
    ]),
    _Schema('sales', description: 'Sale transactions (header)', fields: [
      _Field('id', 'string'),
      _Field('shift_id', 'string?', 'ref -> work_shifts.id'),
      _Field('user_id', 'string?', 'ref -> users.id'),
      _Field('client_id', 'string?', 'ref -> clients.id'),
      _Field('total', 'double'),
      _Field('payment_method', 'string', 'ref -> payment_types.id'),
      _Field('created_at', 'Timestamp'),
      _Field('isDeleted', 'bool'),
    ]),
    _Schema('sale_items', description: 'Line items for a sale', fields: [
      _Field('id', 'string'),
      _Field('sale_id', 'string', 'ref -> sales.id'),
      _Field('product_id', 'string', 'ref -> products.id'),
      _Field('gas_type_id', 'string?', 'ref -> gas_types.id if fuel'),
      _Field('pump_id', 'string?', 'ref -> pumps.id if fuel'),
      _Field('quantity', 'double'),
      _Field('unit_price', 'double'),
      _Field('subtotal', 'double'),
      _Field('isDeleted', 'bool'),
    ]),
    _Schema('payments', description: 'Individual payment splits', fields: [
      _Field('id', 'string'),
      _Field('sale_id', 'string', 'ref -> sales.id'),
      _Field('payment_type_id', 'string', 'ref -> payment_types.id'),
      _Field('amount', 'double'),
      _Field('isDeleted', 'bool'),
    ]),

    _Schema('expenses', description: 'Operational expenses', fields: [
      _Field('id', 'string'),
      _Field('category', 'string', '"utilities" | "rent" | "supplies" | "maintenance" | "salary" | "other"'),
      _Field('amount', 'double'),
      _Field('description', 'string?'),
      _Field('date', 'Timestamp'),
      _Field('user_id', 'string?', 'ref -> users.id'),
      _Field('isDeleted', 'bool'),
    ]),

    // ── Refills ──
    _Schema('pit_refills', description: 'Fuel delivery / pit refill records', fields: [
      _Field('id', 'string'),
      _Field('pit_id', 'string', 'ref -> pits.id'),
      _Field('gas_type_id', 'string', 'ref -> gas_types.id'),
      _Field('volume', 'double', 'liters delivered'),
      _Field('unit_cost', 'double', 'cost per liter'),
      _Field('supplier', 'string?'),
      _Field('invoice_ref', 'string?'),
      _Field('date', 'Timestamp'),
      _Field('isDeleted', 'bool'),
    ]),
    _Schema('refill_payments', description: 'Payments for fuel deliveries', fields: [
      _Field('id', 'string'),
      _Field('refill_id', 'string', 'ref -> pit_refills.id'),
      _Field('payment_type_id', 'string', 'ref -> payment_types.id'),
      _Field('amount', 'double'),
      _Field('isDeleted', 'bool'),
    ]),

    // ── Financial ──
    _Schema('debts', description: 'Client debt / credit records', fields: [
      _Field('id', 'string'),
      _Field('client_id', 'string', 'ref -> clients.id'),
      _Field('amount', 'double', 'positive = debt, negative = payment'),
      _Field('type', 'string', '"debt" | "payment"'),
      _Field('description', 'string?'),
      _Field('date', 'Timestamp'),
      _Field('isDeleted', 'bool'),
    ]),
    _Schema('salary_advances', description: 'Employee salary advances', fields: [
      _Field('id', 'string'),
      _Field('user_id', 'string', 'ref -> users.id'),
      _Field('amount', 'double'),
      _Field('date', 'Timestamp'),
      _Field('notes', 'string?'),
      _Field('isDeleted', 'bool'),
    ]),

    // ── History & Logs ──
    _Schema('fuel_price_history', description: 'Historical fuel price changes', fields: [
      _Field('id', 'string'),
      _Field('gas_type_id', 'string', 'ref -> gas_types.id'),
      _Field('old_price', 'double'),
      _Field('new_price', 'double'),
      _Field('changed_by', 'string?', 'ref -> users.id'),
      _Field('changed_at', 'Timestamp'),
      _Field('isDeleted', 'bool'),
    ]),
    _Schema('daily_summaries', description: 'Daily aggregated KPIs (via cron)', fields: [
      _Field('id', 'string'),
      _Field('date', 'string', 'YYYY-MM-DD'),
      _Field('total_sales', 'double'),
      _Field('total_expenses', 'double'),
      _Field('fuel_volume', 'Map<String,double>', 'gas_type_id -> liters'),
      _Field('payment_breakdown', 'Map<String,double>', 'payment_type_id -> amount'),
      _Field('shift_count', 'int'),
      _Field('isDeleted', 'bool'),
    ]),
    _Schema('logs', description: 'Audit log (populated by Cloud Function)', fields: [
      _Field('id', 'string'),
      _Field('collection', 'string'),
      _Field('doc_id', 'string'),
      _Field('action', 'string', '"CREATE" | "UPDATE" | "DELETE"'),
      _Field('before', 'Map?'),
      _Field('after', 'Map?'),
      _Field('timestamp', 'Timestamp'),
      _Field('user_id', 'string?'),
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0B1220),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        leading: const Icon(Icons.schema_outlined, color: Color(0xFF0066CC), size: 18),
        title: const Text(
          'Expected JSON Structure',
          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
        ),
        subtitle: const Text(
          '21 collections — tap to view fields',
          style: TextStyle(color: Colors.white38, fontSize: 11),
        ),
        children: _collections.map((schema) {
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.table_rows, size: 14, color: Colors.white38),
                    const SizedBox(width: 6),
                    Text(
                      schema.name,
                      style: const TextStyle(
                        color: Color(0xFF84CC16),
                        fontSize: 13,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        schema.description,
                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ...schema.fields.map((f) => Padding(
                      padding: const EdgeInsets.only(left: 24, top: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(f.name, style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace')),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0066CC).withAlpha(50),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(f.type, style: const TextStyle(color: Color(0xFF0066CC), fontSize: 10, fontFamily: 'monospace')),
                          ),
                          if (f.notes != null) ...[
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(f.notes!, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                            ),
                          ],
                        ],
                      ),
                    )),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _Schema {
  final String name;
  final String description;
  final List<_Field> fields;
  const _Schema(this.name, {this.description = '', required this.fields});
}

class _Field {
  final String name;
  final String type;
  final String? notes;
  const _Field(this.name, this.type, [this.notes]);
}
