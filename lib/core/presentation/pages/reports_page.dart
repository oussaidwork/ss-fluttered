import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../services/pdf_report_service.dart';
import '../../../data/datasource/firestore_datasource.dart';

/// Report type definition with metadata.
class _ReportType {
  final String title;
  final String description;
  final IconData icon;
  final bool requiresDateRange;

  const _ReportType({
    required this.title,
    required this.description,
    required this.icon,
    this.requiresDateRange = true,
  });
}

List<_ReportType> _reportTypes(ColorScheme cs) => [
  _ReportType(
    title: 'Sales Report',
    description: 'Detailed breakdown of all sales by period',
    icon: Icons.receipt_long,
  ),
  _ReportType(
    title: 'Shift Summary',
    description: 'Per-shift performance with cash reconciliation',
    icon: Icons.schedule,
  ),
  _ReportType(
    title: 'Debts Report',
    description: 'Outstanding debts by client with due dates',
    icon: Icons.money_off,
    requiresDateRange: false,
  ),
  _ReportType(
    title: 'Payments Settlement',
    description: 'Payment history and settlement status',
    icon: Icons.payments,
  ),
  _ReportType(
    title: 'Pump Indexes',
    description: 'Current pump counter readings for all nozzles',
    icon: Icons.speed,
    requiresDateRange: false,
  ),
  _ReportType(
    title: 'Pit Refill',
    description: 'Fuel tank refill history and volume tracking',
    icon: Icons.local_shipping,
  ),
  _ReportType(
    title: 'Fuel Price History',
    description: 'Price changes over time for all fuel types',
    icon: Icons.trending_up,
    requiresDateRange: false,
  ),
  _ReportType(
    title: 'Audit Log',
    description: 'System activity log with user actions',
    icon: Icons.security,
  ),
  _ReportType(
    title: 'Statistics',
    description: 'Aggregate metrics: totals, averages, and counts',
    icon: Icons.analytics,
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
    final cs = Theme.of(context).colorScheme;
    final types = _reportTypes(cs);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.assessment, color: cs.primary, size: 28),
              const SizedBox(width: 12),
              Text(
                'Reports Hub',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface),
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
                    itemCount: types.length,
                    itemBuilder: (ctx, idx) =>
                        _buildReportCard(types[idx]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeFilter() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.date_range, color: cs.primary, size: 20),
          const SizedBox(width: 12),
          Text('Period:', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.54))),
          const SizedBox(width: 12),
          _dateChip(_from, isFrom: true),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text('—', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.54))),
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
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          builder: (ctx, child) {
            final pickerCs = Theme.of(ctx).colorScheme;
            return Theme(
              data: Theme.of(ctx).copyWith(
                colorScheme: ColorScheme.dark(
                  primary: pickerCs.primary,
                  surface: pickerCs.surfaceContainerHighest,
                ),
              ),
              child: child!,
            );
          },
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
          color: cs.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatDate(date),
              style: TextStyle(
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13),
            ),
            const SizedBox(width: 4),
            Icon(Icons.edit_calendar,
                size: 14, color: cs.primary),
          ],
        ),
      ),
    );
  }

  Widget _presetChip(String label, int days) {
    final cs = Theme.of(context).colorScheme;
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
              ? cs.primary.withValues(alpha: 0.2)
              : cs.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? cs.primary
                : cs.onSurface.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? cs.primary : cs.onSurface.withValues(alpha: 0.54),
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildReportCard(_ReportType type) {
    final cs = Theme.of(context).colorScheme;
    final color = _reportTypeColor(type.title, cs);
    return Card(
      color: cs.surfaceContainerHighest,
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
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(type.icon, color: color, size: 24),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios,
                      color: cs.onSurface.withValues(alpha: 0.24), size: 16),
                ],
              ),
              const Spacer(),
              Text(
                type.title,
                style: TextStyle(
                  color: cs.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                type.description,
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.54), fontSize: 12),
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
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
                strokeWidth: 3, color: cs.primary),
          ),
          const SizedBox(height: 20),
          Text(
            'Generating $_generatingTitle...',
            style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7), fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait while we compile your report',
            style: TextStyle(color: cs.onSurface.withValues(alpha: 0.38), fontSize: 13),
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
            ds: FirestoreDataSourceImpl(),
          );
          break;
        case 'Shift Summary':
          pdfBytes = await PdfReportService.generateShiftReport(
            from: _from,
            to: _to,
            ds: FirestoreDataSourceImpl(),
          );
          break;
        case 'Debts Report':
          pdfBytes = await PdfReportService.generateDebtsReport(
            ds: FirestoreDataSourceImpl(),
          );
          break;
        case 'Payments Settlement':
          pdfBytes = await PdfReportService.generatePaymentsReport(
            from: _from,
            to: _to,
            ds: FirestoreDataSourceImpl(),
          );
          break;
        case 'Pump Indexes':
          pdfBytes = await PdfReportService.generatePumpIndexReport(
            ds: FirestoreDataSourceImpl(),
          );
          break;
        case 'Pit Refill':
          pdfBytes = await PdfReportService.generatePitRefillReport(
            from: _from,
            to: _to,
            ds: FirestoreDataSourceImpl(),
          );
          break;
        case 'Fuel Price History':
          pdfBytes = await PdfReportService.generateFuelPriceReport(
            ds: FirestoreDataSourceImpl(),
          );
          break;
        case 'Audit Log':
          pdfBytes = await PdfReportService.generateAuditLogReport(
            from: _from,
            to: _to,
            ds: FirestoreDataSourceImpl(),
          );
          break;
        case 'Statistics':
          pdfBytes = await PdfReportService.generateStatisticsReport(
            ds: FirestoreDataSourceImpl(),
          );
          break;
        default:
          throw Exception('Unknown report type: ${type.title}');
      }

      _downloadPdf(pdfBytes, type.title);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${type.title} downloaded successfully'),
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating report: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
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

  void _downloadPdf(Uint8List bytes, String title) async {
    final safeTitle = title.replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(' ', '_');
    final filename = 'SS_RAGRAGA_${safeTitle}_${_formatFileDate(DateTime.now())}.pdf';

    try {
      await Printing.sharePdf(
        bytes: bytes,
        filename: filename,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save report: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Color _reportTypeColor(String title, ColorScheme cs) {
    switch (title) {
      case 'Sales Report': return cs.primary;
      case 'Shift Summary': return cs.secondaryContainer;
      case 'Debts Report': return cs.error;
      case 'Payments Settlement': return cs.secondary;
      case 'Pump Indexes': return cs.primaryContainer;
      case 'Pit Refill': return cs.tertiary;
      case 'Fuel Price History': return cs.secondary;
      case 'Audit Log': return cs.onSurface.withValues(alpha: 0.54);
      case 'Statistics': return cs.primary;
      default: return cs.primary;
    }
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
