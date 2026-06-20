// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../services/pdf_report_service.dart';

/// Report type definition with metadata.
class _ReportType {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool requiresDateRange;

  const _ReportType({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.requiresDateRange = true,
  });
}

const _reportTypes = [
  _ReportType(
    title: 'Sales Report',
    description: 'Detailed breakdown of all sales by period',
    icon: Icons.receipt_long,
    color: Color(0xFF0066CC),
  ),
  _ReportType(
    title: 'Shift Summary',
    description: 'Per-shift performance with cash reconciliation',
    icon: Icons.schedule,
    color: Color(0xFF8B5CF6),
  ),
  _ReportType(
    title: 'Debts Report',
    description: 'Outstanding debts by client with due dates',
    icon: Icons.money_off,
    color: Color(0xFFEF4444),
    requiresDateRange: false,
  ),
  _ReportType(
    title: 'Payments Settlement',
    description: 'Payment history and settlement status',
    icon: Icons.payments,
    color: Color(0xFF84CC16),
  ),
  _ReportType(
    title: 'Pump Indexes',
    description: 'Current pump counter readings for all nozzles',
    icon: Icons.speed,
    color: Color(0xFF06B6D4),
    requiresDateRange: false,
  ),
  _ReportType(
    title: 'Pit Refill',
    description: 'Fuel tank refill history and volume tracking',
    icon: Icons.local_shipping,
    color: Color(0xFFF59E0B),
  ),
  _ReportType(
    title: 'Fuel Price History',
    description: 'Price changes over time for all fuel types',
    icon: Icons.trending_up,
    color: Color(0xFF84CC16),
    requiresDateRange: false,
  ),
  _ReportType(
    title: 'Audit Log',
    description: 'System activity log with user actions',
    icon: Icons.security,
    color: Colors.white54,
  ),
  _ReportType(
    title: 'Statistics',
    description: 'Aggregate metrics: totals, averages, and counts',
    icon: Icons.analytics,
    color: Color(0xFF0066CC),
    requiresDateRange: false,
  ),
];

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  DateTime _from = DateTime.now().subtract(const Duration(days: 30));
  DateTime _to = DateTime.now();
  bool _isGenerating = false;
  String? _generatingTitle;

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
              const Icon(Icons.assessment, color: Color(0xFF0066CC), size: 28),
              const SizedBox(width: 12),
              const Text(
                'Reports Hub',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Date range filter
          _buildDateRangeFilter(),
          const SizedBox(height: 24),

          // Report grid
          Expanded(
            child: _isGenerating
                ? _buildLoadingState()
                : GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.4,
                    ),
                    itemCount: _reportTypes.length,
                    itemBuilder: (ctx, idx) =>
                        _buildReportCard(_reportTypes[idx]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeFilter() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2332),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.date_range, color: Color(0xFF0066CC), size: 20),
          const SizedBox(width: 12),
          const Text('Period:', style: TextStyle(color: Colors.white54)),
          const SizedBox(width: 12),
          _dateChip(_from, isFrom: true),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('—', style: TextStyle(color: Colors.white54)),
          ),
          _dateChip(_to, isFrom: false),
          const Spacer(),
          // Quick presets
          _presetChip('7 Days', 7),
          const SizedBox(width: 6),
          _presetChip('30 Days', 30),
          const SizedBox(width: 6),
          _presetChip('90 Days', 90),
        ],
      ),
    );
  }

  Widget _dateChip(DateTime date, {required bool isFrom}) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFF0066CC),
                surface: Color(0xFF1A2332),
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) {
          setState(() {
            if (isFrom) {
              _from = picked;
            } else {
              _to = picked;
            }
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF0066CC).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatDate(date),
              style: const TextStyle(
                  color: Color(0xFF0066CC),
                  fontWeight: FontWeight.w600,
                  fontSize: 13),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.edit_calendar,
                size: 14, color: Color(0xFF0066CC)),
          ],
        ),
      ),
    );
  }

  Widget _presetChip(String label, int days) {
    final isActive = _to == DateTime.now() &&
        _from == DateTime.now().subtract(Duration(days: days));
    return GestureDetector(
      onTap: () {
        setState(() {
          _to = DateTime.now();
          _from = DateTime.now().subtract(Duration(days: days));
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF0066CC).withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? const Color(0xFF0066CC)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? const Color(0xFF0066CC) : Colors.white54,
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildReportCard(_ReportType type) {
    return Card(
      color: const Color(0xFF1A2332),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: _isGenerating ? null : () => _generateReport(type),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: type.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(type.icon, color: type.color, size: 24),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios,
                      color: Colors.white24, size: 16),
                ],
              ),
              const Spacer(),
              Text(
                type.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                type.description,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
                strokeWidth: 3, color: Color(0xFF0066CC)),
          ),
          const SizedBox(height: 20),
          Text(
            'Generating $_generatingTitle...',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please wait while we compile your report',
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Future<void> _generateReport(_ReportType type) async {
    setState(() {
      _isGenerating = true;
      _generatingTitle = type.title;
    });

    try {
      Uint8List pdfBytes;

      switch (type.title) {
        case 'Sales Report':
          pdfBytes = await PdfReportService.generateSalesReport(
            from: _from,
            to: _to,
          );
          break;
        case 'Shift Summary':
          pdfBytes = await PdfReportService.generateShiftReport(
            from: _from,
            to: _to,
          );
          break;
        case 'Debts Report':
          pdfBytes = await PdfReportService.generateDebtsReport();
          break;
        case 'Payments Settlement':
          pdfBytes = await PdfReportService.generatePaymentsReport(
            from: _from,
            to: _to,
          );
          break;
        case 'Pump Indexes':
          pdfBytes = await PdfReportService.generatePumpIndexReport();
          break;
        case 'Pit Refill':
          pdfBytes = await PdfReportService.generatePitRefillReport(
            from: _from,
            to: _to,
          );
          break;
        case 'Fuel Price History':
          pdfBytes = await PdfReportService.generateFuelPriceReport();
          break;
        case 'Audit Log':
          pdfBytes = await PdfReportService.generateAuditLogReport(
            from: _from,
            to: _to,
          );
          break;
        case 'Statistics':
          pdfBytes = await PdfReportService.generateStatisticsReport();
          break;
        default:
          throw Exception('Unknown report type: ${type.title}');
      }

      _downloadPdf(pdfBytes, type.title);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${type.title} downloaded successfully'),
            backgroundColor: const Color(0xFF84CC16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating report: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _generatingTitle = null;
        });
      }
    }
  }

  void _downloadPdf(Uint8List bytes, String title) {
    if (!kIsWeb) {
      // For native platforms, we'd use path_provider + file write
      return;
    }

    final safeTitle = title.replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(' ', '_');
    final filename =
        'SS_RAGRAGA_${safeTitle}_${_formatFileDate(DateTime.now())}.pdf';

    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..target = 'blank'
      ..download = filename;
    anchor.click();
    html.Url.revokeObjectUrl(url);
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}';
  }

  String _formatFileDate(DateTime dt) {
    return '${dt.year}-'
        '${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')}';
  }
}
