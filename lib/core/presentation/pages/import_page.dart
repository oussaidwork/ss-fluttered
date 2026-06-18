import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/import_service.dart';

class ImportPage extends ConsumerStatefulWidget {
  const ImportPage({super.key});

  @override
  ConsumerState<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends ConsumerState<ImportPage> {
  bool _isImporting = false;
  Map<String, int>? _results;
  String? _error;

  Future<void> _handleFileUpload() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        withData: true,
      );

      if (result == null || result.files.single.bytes == null) return;

      setState(() {
        _isImporting = true;
        _error = null;
        _results = null;
      });

      final importService = ImportService();
      final results = await importService.importExcel(result.files.single.bytes!);

      setState(() {
        _results = results;
        _isImporting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Import completed successfully!'),
          backgroundColor: Color(0xFF84CC16),
        ),
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isImporting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Import failed: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.upload_file, color: Color(0xFF0066CC), size: 28),
              const SizedBox(width: 12),
              const Text(
                'Data Import',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
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
                  const Icon(Icons.table_chart, color: Colors.white24, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'Import Database Backup',
                    style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Select an .xlsx export file to populate the database.\nThis will merge data into existing collections.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: 200,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _isImporting ? null : _handleFileUpload,
                      icon: _isImporting 
                          ? constHndleLoading() 
                          : const Icon(Icons.file_upload),
                      label: Text(_isImporting ? 'Importing...' : 'Select Excel File'),
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

  Widget constHndleLoading() {
    return const SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
    );
  }
}
