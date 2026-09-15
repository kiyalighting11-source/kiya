// lib/presentation/widgets/invoice_card.dart

import 'package:flutter/material.dart';

// ✅ استخدم invoice.dart فقط
import '../../data/models/invoice.dart';
// ❌ أزل هذا السطر
// import '../../data/models/invoice_status.dart';
import 'invoice_status_badge.dart';
import 'payment_status_badge.dart';

class InvoiceCard extends StatelessWidget {
  final Invoice invoice;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const InvoiceCard({
    super.key,
    required this.invoice,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== الصف الأول: الرقم والتاريخ =====
              Row(
                children: [
                  // رقم الفاتورة
                  Expanded(
                    child: Text(
                      invoice.invoiceNumber,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  // التاريخ
                  Text(
                    invoice.formattedDate,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // ===== الصف الثاني: العميل والمبلغ =====
              Row(
                children: [
                  // معلومات العميل
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          invoice.customerName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (invoice.customerPhone.isNotEmpty)
                          Text(
                            invoice.customerPhone,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // المبلغ
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        invoice.formattedTotal,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      if (!invoice.isPaid && !invoice.isQuotation)
                        Text(
                          'متبقي: ${invoice.formattedRemaining}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade600,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ===== الصف الثالث: الحالات =====
              Row(
                children: [
                  // حالة الفاتورة
                  InvoiceStatusBadge(status: invoice.status),
                  const SizedBox(width: 8),
                  // حالة الدفع (إذا كانت فاتورة فعلية)
                  if (!invoice.isQuotation) ...[
                    PaymentStatusBadge(status: invoice.paymentStatus),
                  ],
                  const Spacer(),
                  // عدد المنتجات
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.shopping_cart,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${invoice.itemCount}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // أيقونة التحويل (إذا كان عرض سعر)
                  if (invoice.isQuotation && invoice.isQuotationValid) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          // ✅ تم التصحيح من convert_to_invoice إلى file_copy
                          const Icon(
                            Icons.file_copy,
                            size: 12,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'تحويل',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  // أيقونة منتهي الصلاحية (إذا كان عرض سعر منتهي)
                  if (invoice.isQuotation && invoice.isQuotationExpired) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.timer_off,
                            size: 12,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'منتهي',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
