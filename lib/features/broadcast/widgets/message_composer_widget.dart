// lib/features/broadcast/widgets/message_composer_widget.dart

import 'package:flutter/material.dart';

class MessageComposerWidget extends StatelessWidget {
  final String message;
  final Function(String) onChanged;
  final int selectedCount;
  final bool useWeb;
  final Function(bool) onToggleWeb;

  const MessageComposerWidget({
    super.key,
    required this.message,
    required this.onChanged,
    required this.selectedCount,
    required this.useWeb,
    required this.onToggleWeb,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 عنوان
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '📝 كتابة الرسالة',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                '${message.length}/1000',
                style: TextStyle(
                  color: message.length > 900 ? Colors.red : Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 🔹 حقل النص
          Expanded(
            child: TextFormField(
              initialValue: message,
              onChanged: onChanged,
              maxLines: null,
              maxLength: 1000,
              expands: true,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: 'اكتب رسالتك هنا...',
                hintTextDirection: TextDirection.rtl,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.all(12),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              style: const TextStyle(fontSize: 15),
            ),
          ),

          // 🔹 خيارات
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // خيار واتساب ويب
              Row(
                children: [
                  Switch(
                    value: useWeb,
                    onChanged: onToggleWeb,
                    // ✅ تم إصلاح: استخدام activeThumbColor بدلاً من activeColor
                    activeThumbColor: Colors.white,
                    activeTrackColor: Colors.green,
                    inactiveThumbColor: Colors.grey.shade400,
                    inactiveTrackColor: Colors.grey.shade300,
                    thumbColor: WidgetStateProperty.resolveWith<Color>((
                      states,
                    ) {
                      if (states.contains(WidgetState.selected)) {
                        return Colors.white;
                      }
                      return Colors.grey.shade400;
                    }),
                    trackColor: WidgetStateProperty.resolveWith<Color>((
                      states,
                    ) {
                      if (states.contains(WidgetState.selected)) {
                        return Colors.green;
                      }
                      return Colors.grey.shade300;
                    }),
                  ),
                  const Text('واتساب ويب', style: TextStyle(fontSize: 14)),
                ],
              ),
              // عدد المستلمين
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: selectedCount > 0
                      ? Colors.green.shade100
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '📤 $selectedCount مستلم',
                  style: TextStyle(
                    color: selectedCount > 0
                        ? Colors.green.shade800
                        : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
