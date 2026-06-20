import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../l10n/app_localizations.dart';
import '../../services/import_service.dart';
import '../../services/json_import_service.dart';

/// Describes a specific import type configuration.
class _ImportTypeConfig {
  final IconData icon;
  final String titleKey;
  final String description;
  final List<String> expectedSheets;

  const _ImportTypeConfig({
    required this.icon,
    required this.titleKey,
    required this.description,
    required this.expectedSheets,
  });
}

const Map<String, _ImportTypeConfig> _importConfigs = {
  'clients': _ImportTypeConfig(
    icon: Icons.people,
    titleKey: 'importClients',
    description: 'Import and merge client records from an Excel file.\nExpected sheet: Clients',
    expectedSheets: ['Clients'],
  ),
  'workers': _ImportTypeConfig(
    icon: Icons.group,
    titleKey: 'importWorkers',
    description: 'Import and merge worker / staff records from an Excel file.\nExpected sheet: Workers',
    expectedSheets: ['Workers'],
  ),
  'shifts': _ImportTypeConfig(
    icon: Icons.schedule,
    titleKey: 'importShifts',
    description: 'Import shift records and pump assignments from an Excel file.\nExpected sheets: Shifts, shift_pumps',
    expectedSheets: ['Shifts', 'shift_pumps'],
  ),
  'station': _ImportTypeConfig(
    icon: Icons.local_gas_station,
    titleKey: 'importStation',
    description: 'Import fuel types, pumps, and pit configurations from an Excel file.\nExpected sheets: Fuel Types, Pumps, Pits',
    expectedSheets: ['Fuel Types', 'Pumps', 'Pits'],
  ),
  'financial': _ImportTypeConfig(
    icon: Icons.receipt_long,
    titleKey: 'importFinancial',
    description: 'Import sales, payments, and expense records from an Excel file.\nExpected sheets: Sales, Payments, Expenses',
    expectedSheets: ['Sales', 'Payments', 'Expenses'],
  ),
};

class ImportPage extends ConsumerStatefulWidget {
  final String? importType;

  const ImportPage({super.key, this.importType});

  @override
  ConsumerState<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends ConsumerState<ImportPage> {
  bool _isImporting = false;
  Map<String, int>? _results;
  String? _error;

  _ImportTypeConfig get _config => _importConfigs[widget.importType] ??
      const _ImportTypeConfig(
        icon: Icons.upload_file,
        titleKey: 'import',
        description: 'Select an .xlsx or .json file to populate the database.\nThis will merge data into existing collections.',
        expectedSheets: ['Workers', 'Clients', 'Fuel Types', 'Pumps', 'Pits', 'Shifts', 'shift_pumps', 'Sales', 'Payments', 'Expenses'],
      );

  bool get _isBulkImport => widget.importType == null;

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
        // Import from JSON
        final jsonString = utf8.decode(result.files.single.bytes!);
        final jsonService = JsonImportService();
        results = await jsonService.importJson(jsonString);
      } else {
        // Import from Excel
        final importService = ImportService();
        if (_isBulkImport) {
          results = await importService.importExcel(result.files.single.bytes!);
        } else {
          results = await importService.importByType(result.files.single.bytes!, widget.importType!);
        }
      }

      setState(() {
        _results = results;
        _isImporting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Import completed successfully!'),
            backgroundColor: Color(0xFF84CC16),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isImporting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final config = _config;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(config.icon, color: const Color(0xFF0066CC), size: 28),
              const SizedBox(width: 12),
              Text(
                _resolveTitle(l10n, config),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            color: const Color(0xFF1A2332),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(config.icon, color: Colors.white24, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    _resolveTitle(l10n, config),
                    style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    config.description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  _buildExpectedSheets(config.expectedSheets),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: 200,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _isImporting ? null : _handleFileUpload,
                      icon: _isImporting
                          ? _buildLoading()
                          : const Icon(Icons.file_upload),
                      label: Text(_isImporting ? 'Importing...' : 'Select File (.xlsx / .json)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0066CC),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 24),
            Text('Error: $_error', style: const TextStyle(color: Color(0xFFEF4444))),
          ],
          if (_results != null) ...[
            const SizedBox(height: 24),
            _buildResultsSummary(),
          ],
        ],
      ),
    );
  }

  String _resolveTitle(AppLocalizations l10n, _ImportTypeConfig config) {
    if (_isBulkImport) return '${l10n.import} Data';
    switch (widget.importType) {
      case 'clients': return l10n.importClients;
      case 'workers': return l10n.importWorkers;
      case 'shifts': return l10n.importShifts;
      case 'station': return l10n.importStation;
      case 'financial': return l10n.importFinancial;
      default: return l10n.importData;
    }
  }

  Widget _buildExpectedSheets(List<String> sheets) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children: sheets.map((sheet) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF0B1220),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF0066CC).withAlpha(80)),
        ),
        child: Text(
          sheet,
          style: const TextStyle(color: Color(0xFF0066CC), fontSize: 12, fontWeight: FontWeight.w500),
        ),
      )).toList(),
    );
  }

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
          const Text('Import Summary',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const Divider(color: Colors.white12),
          ..._results!.entries.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.key.toUpperCase(), style: const TextStyle(color: Colors.white70)),
                    Text('${e.value} items', style: const TextStyle(color: Color(0xFF84CC16))),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
    );
  }
}
