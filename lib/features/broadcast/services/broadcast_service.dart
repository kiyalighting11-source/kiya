// lib/features/broadcast/services/broadcast_service.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/broadcast_message.dart';
// ✅ FIX: Import BroadcastRecipient from broadcast_result
import '../models/broadcast_result.dart';
import '../../../data/models/customer.dart';
import '../../../data/repositories/customer_repository.dart';

class BroadcastService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final CustomerRepository _customerRepo = CustomerRepository();

  // ==================== إرسال رسالة جماعية ====================

  Future<BroadcastMessage> sendBroadcast({
    required String message,
    required List<String> customerIds,
    required String userId,
    required String userName,
    bool useWeb = false,
    Function(int sent, int total)? onProgress,
  }) async {
    try {
      debugPrint('📤 بدء إرسال رسالة جماعية');
      debugPrint('   عدد العملاء: ${customerIds.length}');
      debugPrint('   المستخدم: $userName');

      final customers = await _getCustomersByIds(customerIds);

      final phoneNumbers = customers
          .map((c) => c.phone)
          .where((p) => p != null && p.isNotEmpty)
          .cast<String>()
          .toList();

      if (phoneNumbers.isEmpty) {
        throw Exception('لا توجد أرقام هاتف صالحة للإرسال');
      }

      final broadcast = BroadcastMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        message: message,
        customerIds: customerIds,
        phoneNumbers: phoneNumbers,
        sentAt: DateTime.now(),
        userId: userId,
        userName: userName,
        status: BroadcastStatus.pending,
      );

      await _saveBroadcast(broadcast);

      final recipients = await _sendMessages(
        customers: customers,
        message: message,
        useWeb: useWeb,
        onProgress: onProgress,
      );

      final successCount = recipients.where((r) => r.success).length;
      final failedCount = recipients.where((r) => !r.success).length;

      final updatedBroadcast = broadcast.copyWith(
        successCount: successCount,
        failedCount: failedCount,
        status: failedCount == 0
            ? BroadcastStatus.completed
            : successCount == 0
            ? BroadcastStatus.failed
            : BroadcastStatus.partial,
        recipients: recipients,
      );

      await _updateBroadcast(updatedBroadcast);

      debugPrint('✅ تم إرسال $successCount رسالة بنجاح');
      debugPrint('❌ فشل إرسال $failedCount رسالة');

      return updatedBroadcast;
    } catch (e) {
      debugPrint('❌ خطأ في إرسال البث: $e');
      throw Exception('خطأ في إرسال الرسائل: $e');
    }
  }

  // ==================== إرسال الرسائل ====================

  Future<List<BroadcastRecipient>> _sendMessages({
    required List<Customer> customers,
    required String message,
    required bool useWeb,
    Function(int sent, int total)? onProgress,
  }) async {
    final List<BroadcastRecipient> recipients = [];
    int sentCount = 0;
    final total = customers.length;

    for (var customer in customers) {
      final phone = customer.phone;

      if (phone == null || phone.isEmpty) {
        recipients.add(
          BroadcastRecipient(
            phoneNumber: '',
            customerId: customer.id,
            customerName: customer.name,
            success: false,
            errorMessage: 'رقم الهاتف غير موجود',
            sentAt: DateTime.now(),
          ),
        );
        continue;
      }

      try {
        final success = await _sendSingleMessage(
          phone: phone,
          message: message,
          useWeb: useWeb,
        );

        recipients.add(
          BroadcastRecipient(
            phoneNumber: phone,
            customerId: customer.id,
            customerName: customer.name,
            success: success,
            errorMessage: success ? null : 'فشل الإرسال',
            sentAt: DateTime.now(),
          ),
        );

        if (success) {
          sentCount++;
        }

        onProgress?.call(sentCount, total);
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        recipients.add(
          BroadcastRecipient(
            phoneNumber: phone,
            customerId: customer.id,
            customerName: customer.name,
            success: false,
            errorMessage: e.toString(),
            sentAt: DateTime.now(),
          ),
        );
      }
    }

    return recipients;
  }

  // ==================== إرسال رسالة واحدة ====================

  Future<bool> _sendSingleMessage({
    required String phone,
    required String message,
    required bool useWeb,
  }) async {
    try {
      final cleanedPhone = _cleanPhoneNumber(phone);

      if (cleanedPhone.isEmpty) {
        return false;
      }

      if (useWeb) {
        final encodedMessage = Uri.encodeComponent(message);
        final url = Uri.parse(
          'https://wa.me/$cleanedPhone?text=$encodedMessage',
        );

        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
          return true;
        }
        return false;
      } else {
        final url = Uri.parse(
          'whatsapp://send?phone=$cleanedPhone&text=${Uri.encodeComponent(message)}',
        );

        if (await canLaunchUrl(url)) {
          await launchUrl(url);
          return true;
        }
        return false;
      }
    } catch (e) {
      debugPrint('❌ فشل إرسال للرقم $phone: $e');
      return false;
    }
  }

  // ==================== جلب العملاء بواسطة المعرفات ====================

  Future<List<Customer>> _getCustomersByIds(List<String> ids) async {
    try {
      final allCustomers = await _customerRepo.getAllCustomers();
      final selectedCustomers = allCustomers
          .where((c) => ids.contains(c.id))
          .toList();

      debugPrint('✅ تم جلب ${selectedCustomers.length} عميل');
      return selectedCustomers;
    } catch (e) {
      debugPrint('❌ خطأ في جلب العملاء: $e');
      return [];
    }
  }

  // ==================== حفظ البث في قاعدة البيانات ====================

  Future<void> _saveBroadcast(BroadcastMessage broadcast) async {
    try {
      await _supabase.from('broadcast_messages').insert({
        'id': broadcast.id,
        'message': broadcast.message,
        'customer_ids': broadcast.customerIds,
        'phone_numbers': broadcast.phoneNumbers,
        'sent_at': broadcast.sentAt.toIso8601String(),
        'user_id': broadcast.userId,
        'user_name': broadcast.userName,
        'status': broadcast.status.code,
        'success_count': 0,
        'failed_count': 0,
        'recipients': [],
      });
      debugPrint('✅ تم حفظ سجل البث');
    } catch (e) {
      debugPrint('❌ خطأ في حفظ البث: $e');
    }
  }

  // ==================== تحديث البث في قاعدة البيانات ====================

  Future<void> _updateBroadcast(BroadcastMessage broadcast) async {
    try {
      // ✅ التحقق من وجود id قبل التحديث
      if (broadcast.id == null || broadcast.id!.isEmpty) {
        debugPrint('❌ لا يمكن تحديث البث: معرف البث غير موجود');
        return;
      }

      final recipientsJson =
          broadcast.recipients
              ?.map(
                (r) => {
                  'customer_id': r.customerId,
                  'phone_number': r.phoneNumber,
                  'customer_name': r.customerName,
                  'success': r.success,
                  'error_message': r.errorMessage,
                  'sent_at': r.sentAt?.toIso8601String(),
                },
              )
              .toList() ??
          [];

      await _supabase
          .from('broadcast_messages')
          .update({
            'success_count': broadcast.successCount,
            'failed_count': broadcast.failedCount,
            'status': broadcast.status.code,
            'recipients': recipientsJson,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', broadcast.id!);

      debugPrint('✅ تم تحديث سجل البث');
    } catch (e) {
      debugPrint('❌ خطأ في تحديث البث: $e');
    }
  }

  // ==================== جلب تاريخ البث ====================

  Future<List<BroadcastMessage>> getBroadcastHistory({
    String? userId,
    int limit = 50,
  }) async {
    try {
      final String filterUserId = userId ?? '';

      var query = _supabase.from('broadcast_messages').select('*');

      if (filterUserId.isNotEmpty) {
        query = query.eq('user_id', filterUserId);
      }

      final response = await query
          .order('sent_at', ascending: false)
          .limit(limit);

      return response
          .map<BroadcastMessage>((json) => BroadcastMessage.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ خطأ في جلب تاريخ البث: $e');
      return [];
    }
  }

  // ==================== حذف سجل بث ====================

  Future<void> deleteBroadcast(String id) async {
    try {
      await _supabase.from('broadcast_messages').delete().eq('id', id);
      debugPrint('✅ تم حذف سجل البث');
    } catch (e) {
      debugPrint('❌ خطأ في حذف البث: $e');
      throw Exception('فشل حذف السجل');
    }
  }

  // ==================== مساعدة: تنظيف رقم الهاتف ====================

  String _cleanPhoneNumber(String phone) {
    String cleaned = phone
        .replaceAll(' ', '')
        .replaceAll('-', '')
        .replaceAll('(', '')
        .replaceAll(')', '')
        .replaceAll('+', '')
        .trim();

    if (cleaned.startsWith('0') && cleaned.length > 10) {
      cleaned = cleaned.substring(1);
    }

    if (!cleaned.startsWith('20') && cleaned.length == 10) {
      cleaned = '20$cleaned';
    }

    if (cleaned.startsWith('0') && cleaned.length == 11) {
      cleaned = '20${cleaned.substring(1)}';
    }

    return cleaned;
  }

  // ==================== إحصائيات ====================

  Future<Map<String, dynamic>> getBroadcastStats({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      var query = _supabase.from('broadcast_messages').select('*');

      if (fromDate != null) {
        query = query.gte('sent_at', fromDate.toIso8601String());
      }
      if (toDate != null) {
        query = query.lte('sent_at', toDate.toIso8601String());
      }

      final response = await query;

      int total = response.length;
      int successTotal = 0;
      int failedTotal = 0;
      int pendingTotal = 0;

      for (var item in response) {
        final status = item['status'] ?? 'pending';
        final successCount = item['success_count'] as int? ?? 0;
        final failedCount = item['failed_count'] as int? ?? 0;

        switch (status) {
          case 'completed':
            successTotal += successCount;
            failedTotal += failedCount;
            break;
          case 'pending':
            pendingTotal++;
            break;
          case 'partial':
            successTotal += successCount;
            failedTotal += failedCount;
            break;
          case 'failed':
            failedTotal += failedCount;
            break;
        }
      }

      final totalAttempts = successTotal + failedTotal;
      return {
        'total_broadcasts': total,
        'total_success': successTotal,
        'total_failed': failedTotal,
        'total_pending': pendingTotal,
        'success_rate': totalAttempts > 0
            ? (successTotal / totalAttempts) * 100
            : 0.0,
      };
    } catch (e) {
      debugPrint('❌ خطأ في جلب إحصائيات البث: $e');
      return {
        'total_broadcasts': 0,
        'total_success': 0,
        'total_failed': 0,
        'total_pending': 0,
        'success_rate': 0.0,
      };
    }
  }
}
