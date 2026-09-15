// lib/presentation/widgets/invoice_item_tile.dart

import 'package:flutter/material.dart';

// ✅ استخدم invoice.dart فقط
import '../../data/models/invoice.dart';

// ❌ أزل هذا السطر
// import '../../data/models/invoice_status.dart';

class InvoiceItemTile extends StatelessWidget {
  final InvoiceItem item;
  final Function(int)? onQuantityChanged;
  final Function(double)? onPriceChanged;
  final VoidCallback? onRemove;
  final bool showControls;
  final bool showPriceControl;

  const InvoiceItemTile({
    super.key,
    required this.item,
    this.onQuantityChanged,
    this.onPriceChanged,
    this.onRemove,
    this.showControls = true,
    this.showPriceControl = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // صورة المنتج
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: item.product?.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item.product!.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(Icons.inventory, color: Colors.grey.shade400),
                    ),
                  )
                : Icon(Icons.inventory, color: Colors.grey.shade400, size: 28),
          ),
          const SizedBox(width: 12),

          // معلومات المنتج
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // اسم المنتج
                Text(
                  item.productName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // التصنيف (إذا كان موجود)
                if (item.product?.category != null)
                  Text(
                    item.product!.category!,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),

                // السعر والكمية والإجمالي
                Row(
                  children: [
                    // السعر
                    Text(
                      '\$${item.unitPrice.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // الكمية
                    Text(
                      '× ${item.quantity}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const Spacer(),
                    // الإجمالي
                    Text(
                      '\$${item.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),

                // الخصم والضريبة (إذا وجدت)
                if ((item.discountRate != null && item.discountRate! > 0) ||
                    (item.taxRate != null && item.taxRate! > 0)) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (item.discountRate != null && item.discountRate! > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'خصم ${item.discountRate!.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                      if (item.taxRate != null && item.taxRate! > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'ضريبة ${item.taxRate!.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],

                // أدوات التحكم (إذا كانت مفعلة)
                if (showControls) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // التحكم في الكمية
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, size: 16),
                            onPressed:
                                onQuantityChanged != null && item.quantity > 1
                                ? () => onQuantityChanged!(item.quantity - 1)
                                : null,
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.grey.shade100,
                              padding: const EdgeInsets.all(4),
                              minimumSize: const Size(28, 28),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${item.quantity}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.add, size: 16),
                            onPressed: onQuantityChanged != null
                                ? () => onQuantityChanged!(item.quantity + 1)
                                : null,
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.grey.shade100,
                              padding: const EdgeInsets.all(4),
                              minimumSize: const Size(28, 28),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),

                      // التحكم في السعر (إذا كان مفعلاً)
                      if (showPriceControl && onPriceChanged != null)
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 16),
                              onPressed: () => _showPriceDialog(context),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.orange.shade50,
                                padding: const EdgeInsets.all(4),
                                minimumSize: const Size(28, 28),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '\$${item.unitPrice.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ],
                        ),

                      // زر الحذف
                      if (onRemove != null)
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: onRemove,
                          style: IconButton.styleFrom(
                            padding: const EdgeInsets.all(4),
                            minimumSize: const Size(28, 28),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPriceDialog(BuildContext context) {
    final controller = TextEditingController(
      text: item.unitPrice.toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.price_change, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'تعديل سعر ${item.productName}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'السعر الحالي: \$${item.unitPrice.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'السعر الجديد',
                border: OutlineInputBorder(),
                prefixText: '\$ ',
                hintText: '0.00',
              ),
              onSubmitted: (_) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final price = double.tryParse(controller.text);
              if (price != null && price > 0 && onPriceChanged != null) {
                onPriceChanged!(price);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('❌ الرجاء إدخال سعر صحيح'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('تحديث'),
          ),
        ],
      ),
    );
  }
}
