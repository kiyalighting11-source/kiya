// lib/features/broadcast/widgets/customer_selection_widget.dart

import 'package:flutter/material.dart';

import '../../../data/models/customer.dart';

class CustomerSelectionWidget extends StatelessWidget {
  final List<Customer> customers;
  final List<String> selectedIds;
  final bool isLoading;
  final Function(String) onSelect;
  final VoidCallback onSelectAll;
  final VoidCallback onDeselectAll;

  const CustomerSelectionWidget({
    super.key,
    required this.customers,
    required this.selectedIds,
    required this.isLoading,
    required this.onSelect,
    required this.onSelectAll,
    required this.onDeselectAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🔹 رأس القائمة
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '👥 اختيار العملاء (${selectedIds.length}/${customers.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: onSelectAll,
                    child: const Text('اختيار الكل'),
                  ),
                  const SizedBox(width: 4),
                  TextButton(
                    onPressed: onDeselectAll,
                    child: const Text('إلغاء الكل'),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 🔹 قائمة العملاء
        Expanded(
          child: customers.isEmpty
              ? const Center(child: Text('لا يوجد عملاء'))
              : ListView.builder(
                  itemCount: customers.length,
                  itemBuilder: (context, index) {
                    final customer = customers[index];
                    final isSelected = selectedIds.contains(customer.id);
                    final hasPhone =
                        customer.phone != null && customer.phone!.isNotEmpty;

                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: hasPhone
                          ? (_) => onSelect(customer.id!)
                          : null,
                      title: Text(
                        customer.name,
                        style: TextStyle(color: hasPhone ? null : Colors.grey),
                      ),
                      subtitle: Text(
                        hasPhone
                            ? '📱 ${customer.phone}'
                            : '⚠️ لا يوجد رقم هاتف',
                        style: TextStyle(
                          color: hasPhone ? Colors.grey.shade700 : Colors.red,
                          fontSize: 12,
                        ),
                      ),
                      secondary: hasPhone
                          ? const Icon(Icons.person, color: Colors.green)
                          : const Icon(Icons.person_off, color: Colors.grey),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      selected: isSelected,
                      activeColor: Colors.green,
                      checkColor: Colors.white,
                    );
                  },
                ),
        ),
      ],
    );
  }
}
