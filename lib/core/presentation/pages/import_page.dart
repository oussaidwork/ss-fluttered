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

enum _SnackBarType { success, error, warning, info }

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
        final cs = Theme.of(context).colorScheme;
        _showSnackBar('Import completed successfully!', cs);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isImporting = false;
      });
      if (mounted) {
        final cs = Theme.of(context).colorScheme;
        _showSnackBar('Import failed: $e', cs, type: _SnackBarType.error);
      }
    }
  }

  // ──────────────────────────────────────────────
  // PASTE JSON
  // ──────────────────────────────────────────────

  Future<void> _handlePasteImport() async {
    final jsonString = _pasteController.text.trim();
    if (jsonString.isEmpty) {
      final cs = Theme.of(context).colorScheme;
      _showSnackBar('Please paste JSON content first', cs, type: _SnackBarType.warning);
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
        final cs = Theme.of(context).colorScheme;
        _showSnackBar('Import completed successfully!', cs);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isPastingJson = false;
      });
      if (mounted) {
        final cs = Theme.of(context).colorScheme;
        _showSnackBar('Import failed: $e', cs, type: _SnackBarType.error);
      }
    }
  }

  void _copyTemplateToClipboard() {
    final template = JsonExportService.generateTemplate();
    Clipboard.setData(ClipboardData(text: template));
    final cs = Theme.of(context).colorScheme;
    _showSnackBar('Template copied to clipboard!', cs, type: _SnackBarType.info);
  }

  void _downloadTemplate() {
    JsonExportService.downloadTemplate();
    final cs = Theme.of(context).colorScheme;
    _showSnackBar('Template downloaded!', cs);
  }

  // ──────────────────────────────────────────────
  // HELPERS
  // ──────────────────────────────────────────────

  void _showSnackBar(String message, ColorScheme cs, {_SnackBarType type = _SnackBarType.success}) {
    if (!mounted) return;
    final Color color;
    switch (type) {
      case _SnackBarType.success:
        color = cs.secondary;
      case _SnackBarType.error:
        color = cs.error;
      case _SnackBarType.warning:
        color = cs.tertiary;
      case _SnackBarType.info:
        color = cs.primary;
    }
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
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Icon(Icons.upload_file, color: cs.primary, size: 28),
              const SizedBox(width: 12),
              Text(
                _isBulkImport ? '${l10n.import} Data' : l10n.importData,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Mode toggle + template buttons
          _buildTopBar(cs, l10n),
          const SizedBox(height: 20),

          // Main card
          Expanded(
            child: Card(
              color: cs.surfaceContainerHighest,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: _usePasteMode ? _buildPastePanel(cs) : _buildFileUploadPanel(cs),
            ),
          ),

          // Error
          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.error.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: cs.error.withAlpha(60)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: cs.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$_error',
                      style: TextStyle(color: cs.error, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Results
          if (_results != null) ...[
            const SizedBox(height: 16),
            _buildResultsSummary(cs),
          ],
        ],
      ),
    );
  }

  Widget _buildTopBar(ColorScheme cs, AppLocalizations l10n) {
    return Row(
      children: [
        // Mode toggle
        Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: cs.onSurface.withValues(alpha: 0.12)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _toggleButton(cs, 'File Upload', !_usePasteMode, () => setState(() => _usePasteMode = false)),
              _toggleButton(cs, 'Paste JSON', _usePasteMode, () => setState(() => _usePasteMode = true)),
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
            foregroundColor: cs.primary,
            side: BorderSide(color: cs.primary),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: _copyTemplateToClipboard,
          icon: const Icon(Icons.copy, size: 16),
          label: const Text('Copy'),
          style: OutlinedButton.styleFrom(
            foregroundColor: cs.secondary,
            side: BorderSide(color: cs.secondary),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _toggleButton(ColorScheme cs, String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? cs.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? cs.onSurface : cs.onSurface.withValues(alpha: 0.54),
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

  Widget _buildFileUploadPanel(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_upload, color: cs.onSurface.withValues(alpha: 0.24), size: 64),
            const SizedBox(height: 16),
            Text(
              'Upload .xlsx or .json file',
              style: TextStyle(fontSize: 18, color: cs.onSurface, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'Select an export file to populate the database.\nData will be merged into existing collections.',
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurface.withValues(alpha: 0.54), fontSize: 14),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 240,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isImporting ? null : _handleFileUpload,
                icon: _isImporting
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: cs.onSurface),
                      )
                    : const Icon(Icons.file_upload),
                label: Text(_isImporting ? 'Importing...' : 'Select File'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onSurface,
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

  Widget _buildPastePanel(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.paste, color: cs.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Paste JSON Data',
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${_pasteController.text.length} chars',
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.38), fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Copy the template above, fill in your data, then paste here and click Import.',
            style: TextStyle(color: cs.onSurface.withValues(alpha: 0.54), fontSize: 12),
          ),
          const SizedBox(height: 8),
          // ── Expected JSON structure guide ──
          const _JsonStructureGuide(),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: cs.onSurface.withValues(alpha: 0.12)),
              ),
              child: TextField(
                controller: _pasteController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: TextStyle(
                  color: cs.secondary,
                  fontSize: 12,
                  fontFamily: 'monospace',
                  height: 1.5,
                ),
                decoration: InputDecoration(
                  hintText: 'Paste your JSON here...\n\n{\n  "version": "1.0",\n  "collections": {\n    ...\n  }\n}',
                  hintStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.24), fontSize: 12, fontFamily: 'monospace'),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
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
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: cs.onSurface),
                          )
                        : const Icon(Icons.upload, size: 18),
                    label: Text(_isPastingJson ? 'Importing...' : 'Import JSON'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.secondary,
                      foregroundColor: cs.surface,
                      disabledBackgroundColor: cs.onSurface.withValues(alpha: 0.12),
                      disabledForegroundColor: cs.onSurface.withValues(alpha: 0.24),
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
                    foregroundColor: cs.onSurface.withValues(alpha: 0.54),
                    side: BorderSide(color: cs.onSurface.withValues(alpha: 0.12)),
                  ),
                  child: Text('Clear'),
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

  Widget _buildResultsSummary(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: cs.secondary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Import Summary',
                style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          Divider(color: cs.onSurface.withValues(alpha: 0.12)),
          ..._results!.entries.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.key, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7), fontSize: 13)),
                    Text('${e.value} items', style: TextStyle(color: cs.secondary, fontSize: 13)),
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
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.12)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        leading: Icon(Icons.schema_outlined, color: cs.primary, size: 18),
        title: Text(
          'Expected JSON Structure',
          style: TextStyle(color: cs.onSurface, fontSize: 13, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '21 collections — tap to view fields',
          style: TextStyle(color: cs.onSurface.withValues(alpha: 0.38), fontSize: 11),
        ),
        children: _collections.map((schema) {
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.table_rows, size: 14, color: cs.onSurface.withValues(alpha: 0.38)),
                    const SizedBox(width: 6),
                    Text(
                      schema.name,
                      style: TextStyle(
                        color: cs.secondary,
                        fontSize: 13,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        schema.description,
                        style: TextStyle(color: cs.onSurface.withValues(alpha: 0.38), fontSize: 11),
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
                          Text(f.name, style: TextStyle(color: cs.onSurface, fontSize: 12, fontFamily: 'monospace')),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: cs.primary.withAlpha(50),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(f.type, style: TextStyle(color: cs.primary, fontSize: 10, fontFamily: 'monospace')),
                          ),
                          if (f.notes != null) ...[
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(f.notes!, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.38), fontSize: 11)),
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
