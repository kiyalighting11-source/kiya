// lib/presentation/widgets/invoice_status_badge.dart

import 'package:flutter/material.dart';

// ✅ استخدم invoice.dart فقط - ده أهم حاجة
import '../../data/models/invoice.dart';

// ❌ أزل هذا السطر تماماً
// import '../../data/models/invoice_status.dart';

class InvoiceStatusBadge extends StatelessWidget {
  final InvoiceStatus status;
  final bool showLabel;
  final double size;

  const InvoiceStatusBadge({
    super.key,
    required this.status,
    this.showLabel = true,
    this.size = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: status.color.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: size, color: status.color),
          if (showLabel) ...[
            const SizedBox(width: 4),
            Text(
              status.arabic,
              style: TextStyle(
                fontSize: size,
                fontWeight: FontWeight.w500,
                color: status.color,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
