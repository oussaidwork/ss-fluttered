import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../l10n/app_localizations.dart';
import '../../services/import_service.dart';
import '../../services/json_import_service.dart';
import '../../services/json_export_service.dart';

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
        results = await JsonImportService().importJson(jsonString);
      } else {
        final importService = ImportService();
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
      final results = await JsonImportService().importJson(jsonString);
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
          const SizedBox(height: 12),
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
