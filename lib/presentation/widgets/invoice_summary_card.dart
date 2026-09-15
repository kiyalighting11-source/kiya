// lib/presentation/widgets/invoice_summary_card.dart

import 'package:flutter/material.dart';

// ✅ استخدم invoice.dart فقط
import '../../data/models/invoice.dart';

// ❌ أزل هذا السطر
// import '../../data/models/invoice_status.dart';

class InvoiceSummaryCard extends StatelessWidget {
  final Invoice invoice;
  final bool showPaymentDetails;

  const InvoiceSummaryCard({
    super.key,
    required this.invoice,
    this.showPaymentDetails = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade50,
            Colors.blue.shade100.withValues(alpha: 0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // العنوان
          Row(
            children: [
              const Icon(Icons.summarize, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                'ملخص الفاتورة',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ===== الإجماليات =====
          _buildSummaryRow('المجموع الفرعي', invoice.formattedSubtotal),
          if (invoice.discountAmount != null && invoice.discountAmount! > 0)
            _buildSummaryRow(
              'الخصم',
              '-${invoice.formattedDiscount}',
              isNegative: true,
            ),
          if (invoice.taxAmount != null && invoice.taxAmount! > 0)
            _buildSummaryRow('الضريبة', invoice.formattedTax),
          if (invoice.shippingCost != null && invoice.shippingCost! > 0)
            _buildSummaryRow('الشحن', invoice.formattedShippingCost),
          const Divider(height: 16),

          // ===== الإجمالي النهائي =====
          _buildSummaryRow(
            'الإجمالي النهائي',
            invoice.formattedTotal,
            isTotal: true,
          ),

          if (showPaymentDetails) ...[
            const SizedBox(height: 8),
            const Divider(height: 16),

            // ===== تفاصيل الدفع =====
            if (invoice.isPaid) ...[
              _buildSummaryRow(
                'المدفوع',
                invoice.formattedPaidAmount,
                icon: Icons.check_circle,
                iconColor: Colors.green,
              ),
              _buildSummaryRow(
                'المتبقي',
                '\$0.00',
                icon: Icons.money_off, // ✅ تم التصحيح
                iconColor: Colors.grey,
              ),
            ] else if (invoice.isPartial) ...[
              _buildSummaryRow(
                'المدفوع',
                invoice.formattedPaidAmount,
                icon: Icons.payment,
                iconColor: Colors.orange,
              ),
              _buildSummaryRow(
                'المتبقي',
                invoice.formattedRemaining,
                icon: Icons.money_off, // ✅ تم التصحيح
                iconColor: Colors.red,
                isNegative: true,
              ),
            ] else ...[
              _buildSummaryRow(
                'المتبقي للدفع',
                invoice.formattedRemaining,
                icon: Icons.money_off, // ✅ تم التصحيح
                iconColor: Colors.red,
                isNegative: true,
              ),
            ],
          ],

          // ===== معلومات إضافية =====
          if (invoice.isQuotation && invoice.validUntil != null) ...[
            const SizedBox(height: 8),
            const Divider(height: 16),
            Row(
              children: [
                Icon(
                  invoice.isQuotationExpired ? Icons.timer_off : Icons.timer,
                  size: 16,
                  color: invoice.isQuotationExpired ? Colors.red : Colors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  invoice.isQuotationExpired
                      ? '⚠️ منتهي الصلاحية منذ ${invoice.quotationDaysRemaining?.abs() ?? 0} يوم'
                      : '✅ صالح لمدة ${invoice.quotationDaysRemaining ?? 0} يوم متبقي',
                  style: TextStyle(
                    fontSize: 13,
                    color: invoice.isQuotationExpired
                        ? Colors.red
                        : Colors.green.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],

          // ===== نسبة الدفع (Progress Bar) =====
          if (!invoice.isQuotation && showPaymentDetails) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: invoice.paymentPercentage / 100,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        invoice.isPaid
                            ? Colors.green
                            : invoice.isPartial
                            ? Colors.orange
                            : Colors.red,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${invoice.paymentPercentage.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: invoice.isPaid
                        ? Colors.green
                        : invoice.isPartial
                        ? Colors.orange
                        : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isTotal = false,
    bool isNegative = false,
    IconData? icon,
    Color? iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: iconColor ?? Colors.grey),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isTotal ? 15 : 13,
                fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
                color: isTotal ? Colors.blue.shade700 : Colors.grey.shade700,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 13,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isNegative
                  ? Colors.red.shade700
                  : isTotal
                  ? Colors.blue.shade700
                  : Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
}
