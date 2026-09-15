// lib/data/services/export_service.dart

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../models/report.dart';

class ExportService {
  // =============================================
  // ✅ MAIN ENTRY POINT
  // =============================================
  Future<void> exportByFormat(ReportData report, ExportFormat format) async {
    switch (format) {
      case ExportFormat.pdf:
        await exportToPdf(report);
        break;
      case ExportFormat.excel:
        await exportToExcel(report);
        break;
      case ExportFormat.csv:
        await exportToCsv(report);
        break;
    }
  }

  // =============================================
  // ✅ EXPORT TO PDF
  // =============================================
  Future<void> exportToPdf(ReportData report) async {
    try {
      debugPrint('📄 Generating PDF...');

      final pdf = pw.Document();

      final font = await PdfGoogleFonts.cairoRegular();
      final fontBold = await PdfGoogleFonts.cairoBold();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(20),
          theme: pw.ThemeData.withFont(base: font, bold: fontBold),
          header: (context) => _buildPdfHeader(report),
          footer: (context) => _buildPdfFooter(context),
          build: (context) => [
            pw.SizedBox(height: 8),
            _buildPdfSummary(report),
            pw.SizedBox(height: 16),
            _buildPdfTable(report),
          ],
        ),
      );

      final fileName = _generateFileName(report, 'pdf');
      final bytes = await pdf.save();

      await Printing.sharePdf(bytes: bytes, filename: fileName);

      debugPrint('✅ PDF generated: $fileName');
    } catch (e) {
      debugPrint('❌ Error exporting to PDF: $e');
      throw Exception('خطأ في تصدير PDF: $e');
    }
  }

  pw.Widget _buildPdfHeader(ReportData report) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.blue700, width: 2),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                report.type.arabic,
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'الفترة: ${report.periodLabel}',
                style: const pw.TextStyle(
                  fontSize: 11,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Kiya System',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
              pw.Text(
                'تاريخ التقرير: ${DateFormat('yyyy-MM-dd HH:mm').format(report.generatedAt)}',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                '${report.rows.length} سجل',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: 1),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'تم إنشاء هذا التقرير تلقائياً بواسطة Kiya System',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
          pw.Text(
            'صفحة ${context.pageNumber} من ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfSummary(ReportData report) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.blue200),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'الملخص',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Wrap(
            spacing: 20,
            runSpacing: 8,
            children: report.summary.entries.map((entry) {
              final label = _translateSummaryKey(entry.key);
              final value = _formatSummaryValue(entry.key, entry.value);
              return pw.Row(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Text(
                    '$label: ',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.Text(
                    value,
                    style: const pw.TextStyle(
                      fontSize: 11,
                      color: PdfColors.black,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfTable(ReportData report) {
    final columns = report.data['columns'] as List<ReportColumn>? ?? [];
    if (columns.isEmpty) return pw.SizedBox();

    return pw.TableHelper.fromTextArray(
      headers: columns.map((c) => c.label).toList(),
      data: report.rows.map((row) {
        return columns.map((col) {
          return _formatCellValue(row[col.key], col.key);
        }).toList();
      }).toList(),
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
        fontSize: 10,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
      cellStyle: const pw.TextStyle(fontSize: 9),
      cellHeight: 22,
      cellAlignments: {
        for (int i = 0; i < columns.length; i++)
          i: _pdfAlignment(columns[i].align),
      },
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      rowDecoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
        ),
      ),
    );
  }

  pw.Alignment _pdfAlignment(dynamic align) {
    final str = align.toString();
    if (str.contains('center')) return pw.Alignment.center;
    if (str.contains('left')) return pw.Alignment.centerLeft;
    return pw.Alignment.centerRight;
  }

  // =============================================
  // ✅ EXPORT TO EXCEL (via HTML — works everywhere)
  // =============================================
  /// نصدّر Excel عن طريق HTML Table — Excel بيفتحه زي .xlsx بالظبط
  /// مفيش محتاج أي excel package
  Future<void> exportToExcel(ReportData report) async {
    try {
      debugPrint('📊 Generating Excel (HTML-based)...');

      final html = _buildExcelHtml(report);
      final fileName = _generateFileName(report, 'xls');
      final bytes = Uint8List.fromList(utf8.encode(html));

      await _saveAndShare(bytes, fileName);

      debugPrint('✅ Excel generated: $fileName');
    } catch (e) {
      debugPrint('❌ Error exporting to Excel: $e');
      throw Exception('خطأ في تصدير Excel: $e');
    }
  }

  /// بناء ملف Excel بصيغة HTML Table
  /// Excel و Google Sheets بيفتحوه بشكل مثالي
  String _buildExcelHtml(ReportData report) {
    final columns = report.data['columns'] as List<ReportColumn>? ?? [];
    final buffer = StringBuffer();

    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html dir="rtl" lang="ar">');
    buffer.writeln('<head>');
    buffer.writeln('<meta charset="UTF-8">');
    buffer.writeln('<title>${report.type.arabic}</title>');
    buffer.writeln('<style>');
    buffer.writeln(
      'table { border-collapse: collapse; width: 100%; font-family: Cairo, Arial, sans-serif; }',
    );
    buffer.writeln(
      'th { background-color: #4472C4; color: white; padding: 8px; border: 1px solid #333; font-weight: bold; text-align: right; }',
    );
    buffer.writeln(
      'td { padding: 6px 8px; border: 1px solid #ccc; text-align: right; }',
    );
    buffer.writeln('tr:nth-child(even) { background-color: #F2F2F2; }');
    buffer.writeln(
      '.title { font-size: 18px; font-weight: bold; color: #4472C4; text-align: center; padding: 15px; }',
    );
    buffer.writeln(
      '.subtitle { font-size: 12px; color: #666; text-align: center; padding: 5px; }',
    );
    buffer.writeln(
      '.summary-title { font-size: 14px; font-weight: bold; color: #4472C4; padding: 10px; background-color: #E7F0FF; }',
    );
    buffer.writeln(
      '.summary-key { font-weight: bold; background-color: #F8F9FA; }',
    );
    buffer.writeln('</style>');
    buffer.writeln('</head>');
    buffer.writeln('<body>');

    // ===== Title =====
    buffer.writeln('<div class="title">${report.type.arabic}</div>');
    buffer.writeln(
      '<div class="subtitle">الفترة: ${report.periodLabel} | '
      'تاريخ التقرير: ${DateFormat('yyyy-MM-dd HH:mm').format(report.generatedAt)} | '
      'عدد السجلات: ${report.rows.length}</div>',
    );

    // ===== Data Table =====
    buffer.writeln('<table>');

    // Headers
    buffer.writeln('<thead><tr>');
    for (var col in columns) {
      buffer.writeln('<th>${col.label}</th>');
    }
    buffer.writeln('</tr></thead>');

    // Data
    buffer.writeln('<tbody>');
    for (var row in report.rows) {
      buffer.writeln('<tr>');
      for (var col in columns) {
        final value = _formatCellValue(row[col.key], col.key);
        buffer.writeln('<td>${_escapeHtml(value)}</td>');
      }
      buffer.writeln('</tr>');
    }
    buffer.writeln('</tbody>');
    buffer.writeln('</table>');

    // ===== Summary =====
    buffer.writeln('<br>');
    buffer.writeln('<table>');
    buffer.writeln(
      '<thead><tr><th colspan="2" class="summary-title">الملخص</th></tr></thead>',
    );
    buffer.writeln('<tbody>');
    for (var entry in report.summary.entries) {
      final key = _translateSummaryKey(entry.key);
      final value = _formatSummaryValue(entry.key, entry.value);
      buffer.writeln('<tr>');
      buffer.writeln('<td class="summary-key">${_escapeHtml(key)}</td>');
      buffer.writeln('<td>${_escapeHtml(value)}</td>');
      buffer.writeln('</tr>');
    }
    buffer.writeln('</tbody>');
    buffer.writeln('</table>');

    buffer.writeln('</body>');
    buffer.writeln('</html>');

    return buffer.toString();
  }

  // =============================================
  // ✅ EXPORT TO CSV
  // =============================================
  Future<void> exportToCsv(ReportData report) async {
    try {
      debugPrint('📄 Generating CSV...');

      final columns = report.data['columns'] as List<ReportColumn>? ?? [];
      final buffer = StringBuffer();

      // BOM for Excel Arabic support
      buffer.write('\uFEFF');

      // Title
      buffer.writeln('"${report.type.arabic} - الفترة: ${report.periodLabel}"');
      buffer.writeln('');

      // Headers
      buffer.writeln(columns.map((c) => '"${c.label}"').join(','));

      // Data
      for (var row in report.rows) {
        buffer.writeln(
          columns
              .map((col) {
                final value = _formatCellValue(row[col.key], col.key);
                return '"${value.replaceAll('"', '""')}"';
              })
              .join(','),
        );
      }

      // Summary
      buffer.writeln('');
      buffer.writeln('"الملخص"');
      for (var entry in report.summary.entries) {
        final key = _translateSummaryKey(entry.key);
        final value = _formatSummaryValue(entry.key, entry.value);
        buffer.writeln('"$key","$value"');
      }

      final fileName = _generateFileName(report, 'csv');
      final bytes = Uint8List.fromList(utf8.encode(buffer.toString()));

      await _saveAndShare(bytes, fileName);

      debugPrint('✅ CSV generated: $fileName');
    } catch (e) {
      debugPrint('❌ Error exporting to CSV: $e');
      throw Exception('خطأ في تصدير CSV: $e');
    }
  }

  // =============================================
  // ✅ SAVE & SHARE
  // =============================================
  Future<void> _saveAndShare(Uint8List bytes, String fileName) async {
    if (kIsWeb) {
      await Share.shareXFiles(
        [
          XFile.fromData(
            bytes,
            name: fileName,
            mimeType: _getMimeType(fileName),
          ),
        ],
        fileNameOverrides: [fileName],
        subject: fileName,
      );
      return;
    }

    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: _getMimeType(fileName))],
        subject: fileName,
        text: 'تقرير $fileName',
      );
    } catch (e) {
      debugPrint('⚠️ Share failed: $e');
      rethrow;
    }
  }

  String _getMimeType(String fileName) {
    if (fileName.endsWith('.pdf')) return 'application/pdf';
    if (fileName.endsWith('.xls')) return 'application/vnd.ms-excel';
    if (fileName.endsWith('.xlsx')) {
      return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    }
    if (fileName.endsWith('.csv')) return 'text/csv';
    return 'application/octet-stream';
  }

  // =============================================
  // ✅ FILE NAME
  // =============================================
  String _generateFileName(ReportData report, String extension) {
    final date = DateFormat('yyyy-MM-dd_HHmm').format(DateTime.now());
    final type = report.type.name;
    return 'Kiya_${type}_$date.$extension';
  }

  // =============================================
  // ✅ CELL VALUE FORMATTER
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
          key.contains('purchases') ||
          key.contains('subtotal') ||
          key.contains('shipping')) {
        return value.toStringAsFixed(2);
      }

      if (key.contains('margin') || key.contains('rate')) {
        return '${value.toStringAsFixed(1)}%';
      }

      return value.toStringAsFixed(2);
    }

    if (value is int) return value.toString();
    if (value is bool) return value ? 'نعم' : 'لا';

    return value.toString();
  }

  // =============================================
  // ✅ HTML ESCAPE
  // =============================================
  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  // =============================================
  // ✅ TRANSLATION MAPS
  // =============================================
  String _translateSummaryKey(String key) {
    const map = {
      'total_invoices': 'عدد الفواتير',
      'total_sales': 'إجمالي المبيعات',
      'total_discount': 'إجمالي الخصومات',
      'total_tax': 'إجمالي الضريبة',
      'total_paid': 'إجمالي المدفوع',
      'total_remaining': 'إجمالي المتبقي',
      'average_invoice': 'متوسط الفاتورة',
      'total_customers': 'إجمالي العملاء',
      'with_phone': 'لديهم هاتف',
      'with_email': 'لديهم بريد',
      'total_products': 'إجمالي المنتجات',
      'low_stock': 'مخزون منخفض',
      'out_of_stock': 'نفذ المخزون',
      'total_stock_value': 'قيمة المخزون',
      'total_quantity': 'إجمالي الكمية',
      'total_revenue': 'إجمالي الإيرادات',
      'total_cost': 'إجمالي التكلفة',
      'total_profit': 'إجمالي الربح',
      'profit_margin': 'هامش الربح',
      'total_records': 'إجمالي السجلات',
      'present': 'حاضر',
      'late': 'متأخر',
      'on_leave': 'في إجازة',
      'attendance_rate': 'نسبة الحضور',
      'average_hours': 'متوسط الساعات',
      'total_quotations': 'إجمالي عروض الأسعار',
      'valid': 'صالح',
      'expired': 'منتهي',
      'total_value': 'إجمالي القيمة',
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
        return '\$${value.toStringAsFixed(2)}';
      }
      return value.toStringAsFixed(2);
    }

    if (value is int) return value.toString();

    return value.toString();
  }
}
