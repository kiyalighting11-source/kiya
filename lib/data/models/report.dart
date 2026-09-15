// lib/data/models/report.dart

import 'package:flutter/material.dart';

// =============================================
// ✅ REPORT TYPE ENUM
// =============================================
enum ReportType {
  sales('تقرير المبيعات', Icons.trending_up, Colors.green),
  invoices('تقرير الفواتير', Icons.receipt_long, Colors.blue),
  customers('تقرير العملاء', Icons.people, Colors.purple),
  products('تقرير المنتجات', Icons.inventory_2, Colors.orange),
  inventory('تقرير المخزون', Icons.warehouse, Colors.teal),
  attendance('تقرير الحضور', Icons.access_time, Colors.indigo),
  profit('تقرير الأرباح', Icons.attach_money, Colors.amber),
  quotations('تقرير عروض الأسعار', Icons.description, Colors.cyan);

  final String arabic;
  final IconData icon;
  final Color color;

  const ReportType(this.arabic, this.icon, this.color);

  String get label => arabic;
}

// =============================================
// ✅ REPORT PERIOD ENUM
// =============================================
enum ReportPeriod {
  today('اليوم'),
  yesterday('أمس'),
  thisWeek('هذا الأسبوع'),
  thisMonth('هذا الشهر'),
  lastMonth('الشهر الماضي'),
  thisQuarter('هذا الربع'),
  thisYear('هذه السنة'),
  lastYear('السنة الماضية'),
  custom('فترة مخصصة');

  final String arabic;
  const ReportPeriod(this.arabic);
  String get label => arabic;

  /// حساب تاريخ البداية والنهاية للفترة
  DateTimeRange? getDateRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (this) {
      case ReportPeriod.today:
        return DateTimeRange(
          start: today,
          end: today.add(const Duration(days: 1)),
        );
      case ReportPeriod.yesterday:
        return DateTimeRange(
          start: today.subtract(const Duration(days: 1)),
          end: today,
        );
      case ReportPeriod.thisWeek:
        final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
        return DateTimeRange(
          start: startOfWeek,
          end: startOfWeek.add(const Duration(days: 7)),
        );
      case ReportPeriod.thisMonth:
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 1),
        );
      case ReportPeriod.lastMonth:
        return DateTimeRange(
          start: DateTime(now.year, now.month - 1, 1),
          end: DateTime(now.year, now.month, 1),
        );
      case ReportPeriod.thisQuarter:
        final quarterStart = ((now.month - 1) ~/ 3) * 3 + 1;
        return DateTimeRange(
          start: DateTime(now.year, quarterStart, 1),
          end: DateTime(now.year, quarterStart + 3, 1),
        );
      case ReportPeriod.thisYear:
        return DateTimeRange(
          start: DateTime(now.year, 1, 1),
          end: DateTime(now.year + 1, 1, 1),
        );
      case ReportPeriod.lastYear:
        return DateTimeRange(
          start: DateTime(now.year - 1, 1, 1),
          end: DateTime(now.year, 1, 1),
        );
      case ReportPeriod.custom:
        return null;
    }
  }
}

// =============================================
// ✅ REPORT DATA MODEL
// =============================================
class ReportData {
  final ReportType type;
  final DateTime fromDate;
  final DateTime toDate;
  final Map<String, dynamic> data;
  final List<ReportRow> rows;
  final Map<String, dynamic> summary;
  final DateTime generatedAt;

  ReportData({
    required this.type,
    required this.fromDate,
    required this.toDate,
    required this.data,
    required this.rows,
    required this.summary,
    DateTime? generatedAt,
  }) : generatedAt = generatedAt ?? DateTime.now();

  String get periodLabel {
    return '${_formatDate(fromDate)} - ${_formatDate(toDate)}';
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

// =============================================
// ✅ REPORT ROW MODEL
// =============================================
class ReportRow {
  final Map<String, dynamic> values;

  ReportRow(this.values);

  dynamic operator [](String key) => values[key];

  @override
  String toString() => values.toString();
}

// =============================================
// ✅ REPORT COLUMN MODEL
// =============================================
class ReportColumn {
  final String key;
  final String label;
  final double? width;
  final TextAlign align;

  const ReportColumn({
    required this.key,
    required this.label,
    this.width,
    this.align = TextAlign.right,
  });
}

// =============================================
// ✅ EXPORT FORMAT ENUM
// =============================================
enum ExportFormat {
  pdf('PDF', Icons.picture_as_pdf, Colors.red),
  excel('Excel', Icons.table_chart, Colors.green),
  csv('CSV', Icons.text_snippet, Colors.orange);

  final String label;
  final IconData icon;
  final Color color;

  const ExportFormat(this.label, this.icon, this.color);
}
