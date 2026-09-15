// lib/data/repositories/invoice_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/invoice.dart';

// ❌ لا تستورد invoice_status.dart - يحتوي على تعارض
// import '../models/invoice_status.dart';

class InvoiceRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  final String _table = 'invoices';
  final String _itemsTable = 'invoice_items';

  // ==================== GET ALL INVOICES ====================
  Future<List<Invoice>> getAllInvoices({
    InvoiceStatus? status,
    String? customerId,
    String? userId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final filter = _supabase.from(_table).select('''
            *,
            customer:customers(*),
            user:users(*),
            warehouse:warehouses(*),
            items:invoice_items(
              *,
              product:products(*)
            )
          ''');

      // فلترة حسب الحالة
      if (status != null) {
        filter.eq('status', status.english.toLowerCase());
      }

      // فلترة حسب العميل
      if (customerId != null && customerId.isNotEmpty) {
        filter.eq('customer_id', customerId);
      }

      // فلترة حسب المستخدم
      if (userId != null && userId.isNotEmpty) {
        filter.eq('user_id', userId);
      }

      // فلترة حسب التاريخ
      if (fromDate != null) {
        filter.gte('date', fromDate.toIso8601String());
      }
      if (toDate != null) {
        filter.lte('date', toDate.toIso8601String());
      }

      // الترتيب
      filter.order('date', ascending: false);

      final response = await filter;

      return List<Invoice>.from(response.map((json) => Invoice.fromJson(json)));
    } catch (e) {
      throw Exception('خطأ في جلب الفواتير: $e');
    }
  }

  // ==================== GET INVOICE BY ID ====================
  Future<Invoice?> getInvoiceById(String id) async {
    try {
      final response = await _supabase
          .from(_table)
          .select('''
            *,
            customer:customers(*),
            user:users(*),
            warehouse:warehouses(*),
            items:invoice_items(
              *,
              product:products(*)
            )
          ''')
          .eq('id', id)
          .maybeSingle();

      if (response != null) {
        return Invoice.fromJson(response);
      }
      return null;
    } catch (e) {
      throw Exception('خطأ في جلب بيانات الفاتورة: $e');
    }
  }

  // ==================== GET INVOICE BY NUMBER ====================
  Future<Invoice?> getInvoiceByNumber(String invoiceNumber) async {
    try {
      final response = await _supabase
          .from(_table)
          .select('''
            *,
            customer:customers(*),
            user:users(*),
            warehouse:warehouses(*),
            items:invoice_items(
              *,
              product:products(*)
            )
          ''')
          .eq('invoice_number', invoiceNumber)
          .maybeSingle();

      if (response != null) {
        return Invoice.fromJson(response);
      }
      return null;
    } catch (e) {
      throw Exception('خطأ في جلب الفاتورة برقم: $e');
    }
  }

  // ==================== CREATE INVOICE ====================
  Future<Invoice> createInvoice(Invoice invoice) async {
    try {
      if (!invoice.isValid) {
        throw Exception('بيانات الفاتورة غير مكتملة');
      }

      final invoiceData = invoice.toJson();
      invoiceData['invoice_number'] = invoice.invoiceNumber;

      final response = await _supabase
          .from(_table)
          .insert(invoiceData)
          .select()
          .single();

      final createdInvoiceId = response['id'];

      if (invoice.items != null && invoice.items!.isNotEmpty) {
        for (var item in invoice.items!) {
          final itemData = item.toJson();
          itemData['invoice_id'] = createdInvoiceId;
          await _supabase.from(_itemsTable).insert(itemData);
        }
      }

      final createdInvoice = await getInvoiceById(createdInvoiceId);
      if (createdInvoice != null) {
        return createdInvoice;
      }

      return Invoice.fromJson(response);
    } catch (e) {
      throw Exception('خطأ في إنشاء الفاتورة: $e');
    }
  }

  // ==================== UPDATE INVOICE ====================
  Future<Invoice> updateInvoice(Invoice invoice) async {
    try {
      if (invoice.id == null) {
        throw Exception('معرف الفاتورة مطلوب للتحديث');
      }

      if (invoice.isConfirmed || invoice.isCompleted) {
        throw Exception('لا يمكن تعديل فاتورة مؤكدة أو مكتملة');
      }

      final response = await _supabase
          .from(_table)
          .update(invoice.toJson())
          .eq('id', invoice.id!)
          .select()
          .single();

      if (invoice.items != null) {
        await _supabase
            .from(_itemsTable)
            .delete()
            .eq('invoice_id', invoice.id!);

        for (var item in invoice.items!) {
          final updatedItem = item.copyWith(invoiceId: invoice.id!);
          await _supabase.from(_itemsTable).insert(updatedItem.toJson());
        }
      }

      final updatedInvoice = await getInvoiceById(invoice.id!);
      if (updatedInvoice != null) {
        return updatedInvoice;
      }

      return Invoice.fromJson(response);
    } catch (e) {
      throw Exception('خطأ في تحديث الفاتورة: $e');
    }
  }

  // ==================== CONFIRM INVOICE ====================
  Future<Invoice> confirmInvoice(String invoiceId) async {
    try {
      final invoice = await getInvoiceById(invoiceId);
      if (invoice == null) {
        throw Exception('الفاتورة غير موجودة');
      }

      if (!invoice.canBeConfirmed) {
        throw Exception('لا يمكن تأكيد هذه الفاتورة');
      }

      await _supabase
          .from(_table)
          .update({
            'status': 'confirmed',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', invoiceId);

      final confirmedInvoice = await getInvoiceById(invoiceId);
      if (confirmedInvoice != null) {
        return confirmedInvoice;
      }

      throw Exception('فشل في تأكيد الفاتورة');
    } catch (e) {
      throw Exception('خطأ في تأكيد الفاتورة: $e');
    }
  }

  // ==================== CANCEL INVOICE ====================
  Future<Invoice> cancelInvoice(String invoiceId, {String? reason}) async {
    try {
      final invoice = await getInvoiceById(invoiceId);
      if (invoice == null) {
        throw Exception('الفاتورة غير موجودة');
      }

      if (!invoice.isCancellable) {
        throw Exception('لا يمكن إلغاء هذه الفاتورة');
      }

      final notes = invoice.notes ?? '';
      final cancelNote = 'تم الإلغاء: ${reason ?? 'بدون سبب'}';
      final updatedNotes = notes.isNotEmpty
          ? '$notes\n$cancelNote'
          : cancelNote;

      await _supabase
          .from(_table)
          .update({
            'status': 'cancelled',
            'notes': updatedNotes,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', invoiceId);

      final cancelledInvoice = await getInvoiceById(invoiceId);
      if (cancelledInvoice != null) {
        return cancelledInvoice;
      }

      throw Exception('فشل في إلغاء الفاتورة');
    } catch (e) {
      throw Exception('خطأ في إلغاء الفاتورة: $e');
    }
  }

  // ==================== RETURN INVOICE ====================
  Future<Invoice> returnInvoice(String invoiceId, {String? reason}) async {
    try {
      final invoice = await getInvoiceById(invoiceId);
      if (invoice == null) {
        throw Exception('الفاتورة غير موجودة');
      }

      if (!invoice.canBeReturned) {
        throw Exception('لا يمكن إرجاع هذه الفاتورة');
      }

      // التحقق من أن الفاتورة مدفوعة بالكامل
      if (!invoice.isPaid) {
        throw Exception('لا يمكن إرجاع فاتورة غير مدفوعة بالكامل');
      }

      final notes = invoice.notes ?? '';
      final returnNote = 'تم الإرجاع: ${reason ?? 'بدون سبب'}';
      final updatedNotes = notes.isNotEmpty
          ? '$notes\n$returnNote'
          : returnNote;

      // تحديث حالة الفاتورة إلى returned
      await _supabase
          .from(_table)
          .update({
            'status': InvoiceStatus.returned.english.toLowerCase(),
            'notes': updatedNotes,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', invoiceId);

      // إعادة المنتجات إلى المخزون
      if (invoice.items != null &&
          invoice.items!.isNotEmpty &&
          invoice.warehouseId != null) {
        for (var item in invoice.items!) {
          // جلب المخزون الحالي
          final stockResponse = await _supabase
              .from('warehouse_stock')
              .select('quantity')
              .eq('product_id', item.productId)
              .eq('warehouse_id', invoice.warehouseId!)
              .maybeSingle();

          int currentQuantity = 0;
          if (stockResponse != null) {
            currentQuantity = stockResponse['quantity'] as int? ?? 0;
          }

          // تحديث المخزون بإضافة الكمية المرتجعة
          await _supabase
              .from('warehouse_stock')
              .update({
                'quantity': currentQuantity + item.quantity,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('product_id', item.productId)
              .eq('warehouse_id', invoice.warehouseId!);

          // تسجيل حركة مخزون (مرتجع)
          await _supabase.from('stock_movements').insert({
            'product_id': item.productId,
            'warehouse_id': invoice.warehouseId!,
            'type': 'in',
            'quantity': item.quantity,
            'reason': 'مرتجع فاتورة: ${invoice.invoiceNumber}',
            'reference': invoice.id,
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      }

      // جلب الفاتورة المحدثة
      final returnedInvoice = await getInvoiceById(invoiceId);
      if (returnedInvoice != null) {
        return returnedInvoice;
      }

      throw Exception('فشل في إرجاع الفاتورة');
    } catch (e) {
      throw Exception('خطأ في إرجاع الفاتورة: $e');
    }
  }

  // ==================== COMPLETE PAYMENT ====================
  Future<Invoice> completePayment(
    String invoiceId,
    double amount, {
    String? paymentMethod,
    String? reference,
  }) async {
    try {
      final invoice = await getInvoiceById(invoiceId);
      if (invoice == null) {
        throw Exception('الفاتورة غير موجودة');
      }

      if (!invoice.canBePaid) {
        throw Exception('لا يمكن دفع هذه الفاتورة');
      }

      final newPaidAmount = (invoice.paidAmount ?? 0) + amount;
      final remainingAmount = invoice.total - newPaidAmount;

      PaymentStatus newStatus;
      if (remainingAmount <= 0) {
        newStatus = PaymentStatus.paid;
      } else if (newPaidAmount > 0) {
        newStatus = PaymentStatus.partial;
      } else {
        newStatus = PaymentStatus.unpaid;
      }

      await _supabase
          .from(_table)
          .update({
            'paid_amount': newPaidAmount,
            'remaining_amount': remainingAmount > 0 ? remainingAmount : 0,
            'payment_status': newStatus.english.toLowerCase(),
            'payment_method':
                paymentMethod ?? invoice.paymentMethod.english.toLowerCase(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', invoiceId);

      await _supabase.from('payments').insert({
        'invoice_id': invoiceId,
        'amount': amount,
        'method': paymentMethod ?? invoice.paymentMethod.english.toLowerCase(),
        'reference': reference,
        'payment_date': DateTime.now().toIso8601String(),
      });

      if (newStatus == PaymentStatus.paid) {
        await _supabase
            .from(_table)
            .update({
              'status': InvoiceStatus.completed.english.toLowerCase(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', invoiceId);
      }

      final updatedInvoice = await getInvoiceById(invoiceId);
      if (updatedInvoice != null) {
        return updatedInvoice;
      }

      throw Exception('فشل في إكمال الدفع');
    } catch (e) {
      throw Exception('خطأ في إكمال الدفع: $e');
    }
  }

  // ==================== DELETE INVOICE ====================
  Future<void> deleteInvoice(String invoiceId) async {
    try {
      final invoice = await getInvoiceById(invoiceId);
      if (invoice == null) {
        throw Exception('الفاتورة غير موجودة');
      }

      if (!invoice.isDeletable) {
        throw Exception('لا يمكن حذف هذه الفاتورة');
      }

      await _supabase.from(_itemsTable).delete().eq('invoice_id', invoiceId);

      await _supabase.from(_table).delete().eq('id', invoiceId);
    } catch (e) {
      throw Exception('خطأ في حذف الفاتورة: $e');
    }
  }

  // ==================== GET INVOICES BY CUSTOMER ====================
  Future<List<Invoice>> getInvoicesByCustomer(String customerId) async {
    try {
      return await getAllInvoices(customerId: customerId);
    } catch (e) {
      throw Exception('خطأ في جلب فواتير العميل: $e');
    }
  }

  // ==================== GET INVOICES BY USER ====================
  Future<List<Invoice>> getInvoicesByUser(String userId) async {
    try {
      return await getAllInvoices(userId: userId);
    } catch (e) {
      throw Exception('خطأ في جلب فواتير المستخدم: $e');
    }
  }

  // ==================== GET INVOICES BY DATE RANGE ====================
  Future<List<Invoice>> getInvoicesByDateRange(
    DateTime fromDate,
    DateTime toDate,
  ) async {
    try {
      return await getAllInvoices(fromDate: fromDate, toDate: toDate);
    } catch (e) {
      throw Exception('خطأ في جلب الفواتير حسب التاريخ: $e');
    }
  }

  // ==================== GET TODAY'S INVOICES ====================
  Future<List<Invoice>> getTodayInvoices() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      return await getInvoicesByDateRange(today, tomorrow);
    } catch (e) {
      throw Exception('خطأ في جلب فواتير اليوم: $e');
    }
  }

  // ==================== SEARCH INVOICES ====================
  Future<List<Invoice>> searchInvoices(String query) async {
    try {
      final response = await _supabase
          .from(_table)
          .select('''
            *,
            customer:customers(*),
            user:users(*),
            warehouse:warehouses(*),
            items:invoice_items(
              *,
              product:products(*)
            )
          ''')
          .or(
            'invoice_number.ilike.%$query%,'
            'customer:customers.name.ilike.%$query%,'
            'customer:customers.phone.ilike.%$query%,'
            'customer:customers.email.ilike.%$query%',
          )
          .order('date', ascending: false);

      return List<Invoice>.from(response.map((json) => Invoice.fromJson(json)));
    } catch (e) {
      throw Exception('خطأ في البحث عن الفواتير: $e');
    }
  }

  // ==================== STATISTICS ====================
  Future<Map<String, dynamic>> getInvoiceStatistics() async {
    try {
      final allInvoices = await getAllInvoices();

      int total = allInvoices.length;
      double totalAmount = 0;
      double paidAmount = 0;
      double unpaidAmount = 0;

      for (var invoice in allInvoices) {
        totalAmount += invoice.total;
        if (invoice.isPaid) {
          paidAmount += invoice.total;
        } else {
          unpaidAmount += invoice.total;
        }
      }

      final today = await getTodayInvoices();

      return {
        'total_invoices': total,
        'total_amount': totalAmount,
        'paid_amount': paidAmount,
        'unpaid_amount': unpaidAmount,
        'today_invoices': today.length,
        'today_amount': today.fold(0.0, (sum, inv) => sum + inv.total),
        'pending_invoices': allInvoices.where((inv) => inv.isPending).length,
        'draft_invoices': allInvoices.where((inv) => inv.isDraft).length,
        'completed_invoices': allInvoices
            .where((inv) => inv.isCompleted)
            .length,
        'cancelled_invoices': allInvoices
            .where((inv) => inv.isCancelled)
            .length,
        'quotation_invoices': allInvoices
            .where((inv) => inv.isQuotation)
            .length,
        'returned_invoices': allInvoices.where((inv) => inv.isReturned).length,
      };
    } catch (e) {
      throw Exception('خطأ في جلب إحصائيات الفواتير: $e');
    }
  }

  // ==================== CONVERT QUOTATION TO INVOICE ====================
  Future<Invoice> convertQuotationToInvoice(String quotationId) async {
    try {
      final quotation = await getInvoiceById(quotationId);
      if (quotation == null) {
        throw Exception('عرض السعر غير موجود');
      }

      if (!quotation.isQuotation) {
        throw Exception('هذا ليس عرض سعر');
      }

      if (quotation.isQuotationExpired) {
        throw Exception('عرض السعر منتهي الصلاحية');
      }

      final newInvoice = quotation.copyWith(
        id: null,
        invoiceNumber: await generateInvoiceNumber(),
        status: InvoiceStatus.draft,
        date: DateTime.now(),
        quotationId: quotation.id,
        createdAt: null,
        updatedAt: null,
        customer: null,
        user: null,
        warehouse: null,
        items: quotation.items
            ?.map((item) => item.copyWith(id: null, invoiceId: ''))
            .toList(),
      );

      final createdInvoice = await createInvoice(newInvoice);

      await _supabase
          .from(_table)
          .update({
            'status': InvoiceStatus.expired.english.toLowerCase(),
            'notes':
                '${quotation.notes ?? ''}\nتم تحويله إلى فاتورة رقم: ${createdInvoice.invoiceNumber}',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', quotationId);

      return createdInvoice;
    } catch (e) {
      throw Exception('خطأ في تحويل عرض السعر إلى فاتورة: $e');
    }
  }

  // ==================== GENERATE INVOICE NUMBER ====================
  Future<String> generateInvoiceNumber() async {
    try {
      final now = DateTime.now();
      final year = now.year.toString();

      final response = await _supabase
          .from(_table)
          .select('invoice_number')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null && response['invoice_number'] != null) {
        final lastNumber = response['invoice_number'] as String;
        final parts = lastNumber.split('-');
        if (parts.length == 3 && parts[1] == year) {
          final num = int.parse(parts[2]) + 1;
          return 'INV-$year-${num.toString().padLeft(4, '0')}';
        }
      }

      return 'INV-$year-0001';
    } catch (e) {
      final now = DateTime.now();
      return 'INV-${now.year}-${now.microsecondsSinceEpoch.toString().padLeft(4, '0')}';
    }
  }

  // ==================== GENERATE QUOTATION NUMBER ====================
  Future<String> generateQuotationNumber() async {
    try {
      final now = DateTime.now();
      final year = now.year.toString();

      final response = await _supabase
          .from(_table)
          .select('invoice_number')
          .like('invoice_number', 'Q-$year-%')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null && response['invoice_number'] != null) {
        final lastNumber = response['invoice_number'] as String;
        final parts = lastNumber.split('-');
        if (parts.length == 3) {
          final num = int.parse(parts[2]) + 1;
          return 'Q-$year-${num.toString().padLeft(4, '0')}';
        }
      }

      return 'Q-$year-0001';
    } catch (e) {
      final now = DateTime.now();
      return 'Q-${now.year}-${now.microsecondsSinceEpoch.toString().padLeft(4, '0')}';
    }
  }
}
