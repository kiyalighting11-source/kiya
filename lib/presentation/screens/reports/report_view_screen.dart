// lib/presentation/screens/reports/report_view_screen.dart

import 'package:flutter/material.dart';

import '../../../data/models/report.dart';
import '../../../data/services/export_service.dart';

class ReportViewScreen extends StatefulWidget {
  final ReportData report;

  const ReportViewScreen({super.key, required this.report});

  @override
  State<ReportViewScreen> createState() => _ReportViewScreenState();
}

class _ReportViewScreenState extends State<ReportViewScreen> {
  final ExportService _exportService = ExportService();
  bool _isExporting = false;

  ReportData get report => widget.report;

  List<ReportColumn> get columns =>
      report.data['columns'] as List<ReportColumn>? ?? [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(report.type.arabic),
        backgroundColor: report.type.color,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<ExportFormat>(
            icon: const Icon(Icons.download),
            tooltip: 'تصدير',
            enabled: !_isExporting, // ✅ استخدمنا _isExporting
            onSelected: _exportReport,
            itemBuilder: (context) => ExportFormat.values.map((format) {
              return PopupMenuItem(
                value: format,
                child: Row(
                  children: [
                    Icon(format.icon, color: format.color, size: 20),
                    const SizedBox(width: 10),
                    Text('تصدير ${format.label}'),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // ===== Summary Cards =====
              _buildSummarySection(),

              // ===== Period Info =====
              _buildPeriodInfo(),

              // ===== Data Table =====
              Expanded(child: _buildDataTable()),
            ],
          ),

          // ✅ Loading overlay أثناء التصدير
          if (_isExporting)
            Container(
              color: Colors.black.withValues(alpha: 0.4),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'جاري التصدير...',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    if (report.summary.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: SizedBox(
        height: 90,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: report.summary.length,
          separatorBuilder: (_, _) =>
              const SizedBox(width: 8), // ✅ (_, _) بدل (_, __)
          itemBuilder: (context, index) {
            final entry = report.summary.entries.elementAt(index);
            return _buildSummaryCard(entry.key, entry.value);
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String key, dynamic value) {
    final label = _translateSummaryKey(key);
    final displayValue = _formatSummaryValue(key, value);
    final color = _getSummaryColor(key);

    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            displayValue,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.grey.shade100,
      child: Row(
        children: [
          Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            'الفترة: ${report.periodLabel}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            '${report.rows.length} سجل',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    if (report.rows.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'لا توجد بيانات في هذه الفترة',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            report.type.color.withValues(alpha: 0.1),
          ),
          headingTextStyle: TextStyle(
            fontWeight: FontWeight.bold,
            color: report.type.color,
            fontSize: 12,
          ),
          dataTextStyle: const TextStyle(fontSize: 12),
          columnSpacing: 16,
          horizontalMargin: 12,
          columns: columns.map((col) {
            return DataColumn(
              label: SizedBox(
                width: col.width ?? 100,
                child: Text(
                  col.label,
                  textAlign: col.align,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            );
          }).toList(),
          rows: report.rows.map((row) {
            return DataRow(
              cells: columns.map((col) {
                final value = row[col.key];
                return DataCell(
                  SizedBox(
                    width: col.width ?? 100,
                    child: Text(
                      _formatCellValue(value, col.key),
                      textAlign: col.align,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              }).toList(),
            );
          }).toList(),
        ),
      ),
    );
  }

  // =============================================
  // ✅ EXPORT
  // =============================================
  Future<void> _exportReport(ExportFormat format) async {
    setState(() => _isExporting = true);

    try {
      await _exportService.exportByFormat(report, format);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ تم تصدير ${format.label} بنجاح'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ خطأ: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  // =============================================
  // ✅ HELPERS
  // =============================================
  String _formatCellValue(dynamic value, String key) {
    if (value == null) return '-';

    if (value is double) {
      if (key.contains('total') ||
          key.contains('price') ||
          key.contains('cost') ||
          key.contains('revenue') ||
          key.contains('profit') ||
          key.contains('discount') ||
          key.contains('tax') ||
          key.contains('paid') ||
          key.contains('remaining') ||
          key.contains('value') ||
          key.contains('purchases')) {
        return '\$${value.toStringAsFixed(2)}';
      }
      if (key.contains('margin') || key.contains('rate')) {
        return '${value.toStringAsFixed(1)}%';
      }
      return value.toStringAsFixed(2);
    }

    return value.toString();
  }

  String _translateSummaryKey(String key) {
    const map = {
      'total_invoices': 'عدد الفواتير',
      'total_sales': 'إجمالي المبيعات',
      'total_discount': 'الخصومات',
      'total_tax': 'الضريبة',
      'total_paid': 'المدفوع',
      'total_remaining': 'المتبقي',
      'average_invoice': 'متوسط الفاتورة',
      'total_customers': 'العملاء',
      'with_phone': 'لديهم هاتف',
      'with_email': 'لديهم بريد',
      'total_products': 'المنتجات',
      'low_stock': 'مخزون منخفض',
      'out_of_stock': 'نفذ المخزون',
      'total_stock_value': 'قيمة المخزون',
      'total_quantity': 'إجمالي الكمية',
      'total_revenue': 'الإيرادات',
      'total_cost': 'التكلفة',
      'total_profit': 'الربح',
      'profit_margin': 'هامش الربح',
      'total_records': 'السجلات',
      'present': 'حاضر',
      'late': 'متأخر',
      'on_leave': 'إجازة',
      'attendance_rate': 'نسبة الحضور',
      'average_hours': 'متوسط الساعات',
      'total_quotations': 'العروض',
      'valid': 'صالح',
      'expired': 'منتهي',
      'total_value': 'القيمة',
    };
    return map[key] ?? key;
  }

  String _formatSummaryValue(String key, dynamic value) {
    if (value == null) return '-';
    if (value is double) {
      if (key.contains('rate') || key.contains('margin')) {
        return '${value.toStringAsFixed(1)}%';
      }
      if (key.contains('sales') ||
          key.contains('revenue') ||
          key.contains('cost') ||
          key.contains('profit') ||
          key.contains('value') ||
          key.contains('paid') ||
          key.contains('remaining') ||
          key.contains('discount') ||
          key.contains('tax') ||
          key.contains('invoice') ||
          key.contains('stock') ||
          key.contains('purchases')) {
        return '\$${value.toStringAsFixed(0)}';
      }
      return value.toStringAsFixed(1);
    }
    return value.toString();
  }

  Color _getSummaryColor(String key) {
    if (key.contains('total_sales') ||
        key.contains('total_revenue') ||
        key.contains('total_profit')) {
      return Colors.green;
    }
    if (key.contains('total_remaining') ||
        key.contains('total_cost') ||
        key.contains('expired') ||
        key.contains('out_of_stock')) {
      return Colors.red;
    }
    if (key.contains('low_stock') || key.contains('late')) {
      return Colors.orange;
    }
    if (key.contains('rate') || key.contains('margin')) {
      return Colors.purple;
    }
    return Colors.blue;
  }
}
