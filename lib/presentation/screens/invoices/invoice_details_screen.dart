// lib/presentation/screens/invoices/invoice_details_screen.dart

import 'package:flutter/material.dart';

// ✅ استخدم invoice.dart فقط (لأنه يحتوي على كل الـ Enums)
import '../../../data/models/invoice.dart';
// ❌ أزل هذا السطر تماماً
// import '../../../data/models/invoice_status.dart';
import '../../../data/services/invoice_service.dart';

// ✅ استيراد الـ Widgets
import '../../widgets/invoice_status_badge.dart';
import '../../widgets/payment_status_badge.dart';
import '../../widgets/invoice_item_tile.dart';
import '../../widgets/invoice_summary_card.dart';
import 'edit_invoice_screen.dart';

class InvoiceDetailsScreen extends StatefulWidget {
  final String invoiceId;

  const InvoiceDetailsScreen({super.key, required this.invoiceId});

  @override
  State<InvoiceDetailsScreen> createState() => _InvoiceDetailsScreenState();
}

class _InvoiceDetailsScreenState extends State<InvoiceDetailsScreen> {
  final InvoiceService _invoiceService = InvoiceService();

  Invoice? _invoice;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInvoice();
  }

  Future<void> _loadInvoice() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final invoice = await _invoiceService.getInvoiceWithDetails(
        widget.invoiceId,
      );
      if (invoice == null) {
        throw Exception('الفاتورة غير موجودة');
      }
      setState(() {
        _invoice = invoice;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _invoice != null
              ? 'فاتورة ${_invoice!.invoiceNumber}'
              : 'تفاصيل الفاتورة',
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_invoice != null) ...[
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: () => _printInvoice(),
              tooltip: 'طباعة',
            ),
            if (_invoice!.isEditable)
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _editInvoice(),
                tooltip: 'تعديل',
              ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('جاري تحميل البيانات...'),
                ],
              ),
            )
          : _error != null
          ? _buildErrorWidget()
          : _invoice == null
          ? _buildNotFoundWidget()
          : _buildContent(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              'حدث خطأ',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadInvoice,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFoundWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'الفاتورة غير موجودة',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('العودة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final invoice = _invoice!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== بطاقة الحالة =====
          _buildStatusCard(invoice),

          const SizedBox(height: 16),

          // ===== معلومات العميل =====
          _buildCustomerCard(invoice),

          const SizedBox(height: 16),

          // ===== معلومات الفاتورة =====
          _buildInfoCard(invoice),

          const SizedBox(height: 16),

          // ===== بنود الفاتورة =====
          _buildItemsCard(invoice),

          const SizedBox(height: 16),

          // ===== ملخص الفاتورة =====
          InvoiceSummaryCard(invoice: invoice),

          const SizedBox(height: 16),

          // ===== الشروط والملاحظات =====
          if (invoice.terms != null || invoice.notes != null)
            _buildNotesCard(invoice),

          const SizedBox(height: 16),

          // ===== أزرار الإجراءات =====
          _buildActionButtons(invoice),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatusCard(Invoice invoice) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: invoice.status.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: invoice.status.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(invoice.status.icon, color: invoice.status.color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'حالة الفاتورة',
                  style: TextStyle(fontSize: 12, color: invoice.status.color),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      invoice.statusLabel,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: invoice.status.color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InvoiceStatusBadge(status: invoice.status),
                  ],
                ),
              ],
            ),
          ),
          PaymentStatusBadge(status: invoice.paymentStatus),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(Invoice invoice) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                'بيانات العميل',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  invoice.customerName[0].toUpperCase(),
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invoice.customerName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (invoice.customerPhone.isNotEmpty)
                      Text(
                        invoice.customerPhone,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    if (invoice.customerEmail.isNotEmpty)
                      Text(
                        invoice.customerEmail,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(Invoice invoice) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                'معلومات الفاتورة',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildInfoRow('رقم الفاتورة', invoice.invoiceNumber),
          _buildInfoRow('التاريخ', invoice.formattedDate),
          if (invoice.dueDate != null)
            _buildInfoRow('تاريخ الاستحقاق', invoice.formattedDueDate),
          if (invoice.validUntil != null)
            _buildInfoRow('صالح حتى', invoice.formattedValidUntil),
          if (invoice.quotationId != null)
            _buildInfoRow('عرض السعر الأصلي', invoice.quotationId!),
          _buildInfoRow('طريقة الدفع', invoice.paymentMethod.label),
          if (invoice.warehouseId != null)
            _buildInfoRow('المخزن', invoice.warehouseName),
          _buildInfoRow('عدد المنتجات', '${invoice.itemCount}'),
          _buildInfoRow('الكمية الإجمالية', '${invoice.totalQuantity}'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsCard(Invoice invoice) {
    if (invoice.items == null || invoice.items!.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Center(child: Text('لا توجد منتجات في هذه الفاتورة')),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shopping_cart, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                'المنتجات',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const Spacer(),
              Text(
                '${invoice.items!.length} منتج',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: invoice.items!.length,
            itemBuilder: (context, index) {
              final item = invoice.items![index];
              return InvoiceItemTile(item: item, showControls: false);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard(Invoice invoice) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (invoice.terms != null) ...[
            Row(
              children: [
                const Icon(Icons.description, color: Colors.purple),
                const SizedBox(width: 8),
                Text(
                  'الشروط',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              invoice.terms!,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
          if (invoice.terms != null && invoice.notes != null)
            const SizedBox(height: 8),
          if (invoice.notes != null) ...[
            Row(
              children: [
                const Icon(Icons.note, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'ملاحظات',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              invoice.notes!,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(Invoice invoice) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // طباعة
        _buildActionButton(
          icon: Icons.print,
          label: 'طباعة',
          color: Colors.grey,
          onTap: _printInvoice,
        ),

        // تعديل (للمسودة، عرض السعر، المكتملة)
        if (invoice.isEditable)
          _buildActionButton(
            icon: Icons.edit,
            label: 'تعديل',
            color: Colors.orange,
            onTap: _editInvoice,
          ),

        // حذف (للمسودة، عرض السعر، المكتملة)
        if (invoice.isDeletable)
          _buildActionButton(
            icon: Icons.delete,
            label: 'حذف',
            color: Colors.red,
            onTap: _deleteInvoice,
          ),

        // تأكيد (للمسودة، عرض السعر، المعلقة)
        if (invoice.canBeConfirmed)
          _buildActionButton(
            icon: Icons.check_circle,
            label: 'تأكيد',
            color: Colors.green,
            onTap: _confirmInvoice,
          ),

        // إلغاء
        if (invoice.isCancellable)
          _buildActionButton(
            icon: Icons.cancel,
            label: 'إلغاء',
            color: Colors.red,
            onTap: _cancelInvoice,
          ),

        // دفع (للمؤكدة وعرض السعر)
        if (invoice.canBePaid && !invoice.isPaid)
          _buildActionButton(
            icon: Icons.payments,
            label: 'دفع',
            color: Colors.green,
            onTap: _showPaymentDialog,
          ),

        // مرتجع (للمكتملة)
        if (invoice.canBeReturned)
          _buildActionButton(
            icon: Icons.undo,
            label: 'مرتجع',
            color: Colors.deepPurple,
            onTap: _returnInvoice,
          ),

        // تحويل إلى فاتورة (لعرض السعر)
        if (invoice.isQuotation && invoice.isQuotationValid)
          _buildActionButton(
            icon: Icons.file_copy,
            label: 'تحويل لفاتورة',
            color: Colors.purple,
            onTap: _convertToInvoice,
          ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );
  }

  // ==================== ACTIONS ====================

  void _printInvoice() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🖨️ طباعة الفاتورة - سيتم إضافتها قريباً'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _editInvoice() {
    if (_invoice == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditInvoiceScreen(invoice: _invoice!),
      ),
    ).then((_) => _loadInvoice());
  }

  Future<void> _deleteInvoice() async {
    if (_invoice == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('حذف الفاتورة'),
        content: Text(
          'هل أنت متأكد من حذف الفاتورة رقم ${_invoice!.invoiceNumber}؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _invoiceService.deleteInvoice(_invoice!.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم حذف الفاتورة بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _confirmInvoice() async {
    if (_invoice == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('تأكيد الفاتورة'),
        content: Text(
          'هل أنت متأكد من تأكيد الفاتورة رقم ${_invoice!.invoiceNumber}؟\n\n'
          'سيتم خصم المنتجات من المخزون.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final errors = await _invoiceService.validateInvoiceBeforeConfirm(
        _invoice!.id!,
      );
      if (errors.isNotEmpty) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('لا يمكن تأكيد الفاتورة'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: errors
                    .map(
                      (error) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error,
                              color: Colors.red,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(error)),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('حسناً'),
                ),
              ],
            ),
          );
        }
        return;
      }

      await _invoiceService.confirmInvoice(_invoice!.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم تأكيد الفاتورة بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        _loadInvoice();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _cancelInvoice() async {
    if (_invoice == null) return;

    final TextEditingController reasonController = TextEditingController();
    bool? confirmed;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('إلغاء الفاتورة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'هل أنت متأكد من إلغاء الفاتورة رقم ${_invoice!.invoiceNumber}؟',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'سبب الإلغاء (اختياري)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              confirmed = true;
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('إلغاء الفاتورة'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final reason = reasonController.text.trim();

    try {
      await _invoiceService.cancelInvoice(
        _invoice!.id!,
        reason: reason.isNotEmpty ? reason : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم إلغاء الفاتورة بنجاح'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadInvoice();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showPaymentDialog() async {
    if (_invoice == null) return;

    final TextEditingController amountController = TextEditingController();
    amountController.text = _invoice!.remainingToPay.toStringAsFixed(2);

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('إكمال الدفع'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('المبلغ المتبقي: ${_invoice!.formattedRemaining}'),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'المبلغ المدفوع',
                border: OutlineInputBorder(),
                prefixText: '\$ ',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: 'cash',
              decoration: const InputDecoration(
                labelText: 'طريقة الدفع',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'cash', child: Text('نقدي')),
                DropdownMenuItem(value: 'card', child: Text('بطاقة')),
                DropdownMenuItem(value: 'bank', child: Text('تحويل بنكي')),
              ],
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text);
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('الرجاء إدخال مبلغ صحيح'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.pop(context, {'amount': amount, 'method': 'cash'});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('دفع'),
          ),
        ],
      ),
    );

    if (result == null) return;

    try {
      await _invoiceService.completePayment(
        _invoice!.id!,
        result['amount'] as double,
        paymentMethod: result['method'] as String,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم إكمال الدفع بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        _loadInvoice();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _returnInvoice() async {
    if (_invoice == null) return;

    final TextEditingController reasonController = TextEditingController();
    bool? confirmed;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('مرتجع الفاتورة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'هل أنت متأكد من إرجاع الفاتورة رقم ${_invoice!.invoiceNumber}؟\n\n'
              'سيتم إعادة المنتجات إلى المخزون.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'سبب المرتجع (اختياري)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              confirmed = true;
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('مرتجع'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final reason = reasonController.text.trim();

    try {
      await _invoiceService.returnInvoice(
        _invoice!.id!,
        reason: reason.isNotEmpty ? reason : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم إرجاع الفاتورة بنجاح'),
            backgroundColor: Colors.deepPurple,
          ),
        );
        _loadInvoice();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _convertToInvoice() async {
    if (_invoice == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('تحويل عرض السعر'),
        content: Text(
          'هل أنت متأكد من تحويل عرض السعر رقم ${_invoice!.invoiceNumber} إلى فاتورة؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('تحويل'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _invoiceService.convertQuotationToInvoice(_invoice!.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم تحويل عرض السعر إلى فاتورة بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
