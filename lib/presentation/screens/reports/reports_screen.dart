// lib/presentation/screens/reports/reports_screen.dart

import 'package:flutter/material.dart';

import '../../../data/models/report.dart';
import '../../../data/services/report_service.dart';
import 'report_view_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ReportService _reportService = ReportService();

  ReportType _selectedType = ReportType.sales;
  ReportPeriod _selectedPeriod = ReportPeriod.thisMonth;
  DateTimeRange? _customRange;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('التقارير'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== Report Type Selection =====
            _buildSectionHeader('📊 نوع التقرير'),
            const SizedBox(height: 12),
            _buildReportTypeGrid(),
            const SizedBox(height: 24),

            // ===== Period Selection =====
            _buildSectionHeader('📅 الفترة الزمنية'),
            const SizedBox(height: 12),
            _buildPeriodSelector(),
            const SizedBox(height: 24),

            // ===== Generate Button =====
            _buildGenerateButton(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            color: Colors.indigo.shade700,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.indigo.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildReportTypeGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.4,
      ),
      itemCount: ReportType.values.length,
      itemBuilder: (context, index) {
        final type = ReportType.values[index];
        final isSelected = _selectedType == type;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _selectedType = type),
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected
                    ? type.color.withValues(alpha: 0.1)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? type.color : Colors.grey.shade200,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: type.color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(type.icon, color: type.color, size: 24),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    type.arabic,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isSelected ? type.color : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: ReportPeriod.values.map((period) {
          final isSelected = _selectedPeriod == period;
          return InkWell(
            onTap: () async {
              if (period == ReportPeriod.custom) {
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  initialDateRange: _customRange,
                  locale: const Locale('ar', 'EG'),
                );
                if (range != null) {
                  setState(() {
                    _customRange = range;
                    _selectedPeriod = period;
                  });
                }
              } else {
                setState(() => _selectedPeriod = period);
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: isSelected ? Colors.indigo : Colors.grey.shade400,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      period.arabic,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected ? Colors.indigo : Colors.black87,
                      ),
                    ),
                  ),
                  if (period == ReportPeriod.custom && _customRange != null)
                    Text(
                      '${_customRange!.start.day}/${_customRange!.start.month} - ${_customRange!.end.day}/${_customRange!.end.month}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _generateReport,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.assessment),
        label: Text(
          _isLoading ? 'جاري إنشاء التقرير...' : 'إنشاء التقرير',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
        ),
      ),
    );
  }

  // =============================================
  // ✅ GENERATE REPORT
  // =============================================
  Future<void> _generateReport() async {
    // ✅ احصل على الفترة
    DateTimeRange? range;
    if (_selectedPeriod == ReportPeriod.custom) {
      range = _customRange;
    } else {
      range = _selectedPeriod.getDateRange();
    }

    if (range == null) {
      _showError('الرجاء اختيار الفترة');
      return;
    }

    setState(() => _isLoading = true);

    try {
      ReportData report;

      switch (_selectedType) {
        case ReportType.sales:
          report = await _reportService.getSalesReport(
            fromDate: range.start,
            toDate: range.end,
          );
          break;
        case ReportType.customers:
          report = await _reportService.getCustomersReport(
            fromDate: range.start,
            toDate: range.end,
          );
          break;
        case ReportType.products:
          report = await _reportService.getProductsReport(
            fromDate: range.start,
            toDate: range.end,
          );
          break;
        case ReportType.inventory:
          report = await _reportService.getInventoryReport(
            fromDate: range.start,
            toDate: range.end,
          );
          break;
        case ReportType.attendance:
          report = await _reportService.getAttendanceReport(
            fromDate: range.start,
            toDate: range.end,
          );
          break;
        case ReportType.profit:
          report = await _reportService.getProfitReport(
            fromDate: range.start,
            toDate: range.end,
          );
          break;
        case ReportType.quotations:
          report = await _reportService.getQuotationsReport(
            fromDate: range.start,
            toDate: range.end,
          );
          break;
        case ReportType.invoices:
          // Use sales report for invoices
          report = await _reportService.getSalesReport(
            fromDate: range.start,
            toDate: range.end,
          );
          break;
      }

      if (!mounted) return;
      setState(() => _isLoading = false);

      // ✅ افتح شاشة عرض التقرير
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ReportViewScreen(report: report)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError('$e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ $message'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
