// lib/data/services/invoice_service.dart

import 'package:flutter/material.dart';

import '../models/invoice.dart';
// ❌ لا تستورد invoice_status.dart - يحتوي على تعارض
// import '../models/invoice_status.dart';
import '../repositories/invoice_repository.dart';
import '../repositories/invoice_item_repository.dart';

// ✅ تم إزالة الـ imports غير المستخدمة
// import '../repositories/product_repository.dart';
// import '../repositories/warehouse_repository.dart';

class InvoiceService {
  final InvoiceRepository _invoiceRepo = InvoiceRepository();
  final InvoiceItemRepository _itemRepo = InvoiceItemRepository();

  // ==================== CREATE INVOICE ====================

  /// إنشاء فاتورة جديدة مع التحقق من المخزون
  Future<Invoice> createInvoice(
    Invoice invoice, {
    required bool checkStock,
  }) async {
    try {
      debugPrint('📝 بدء إنشاء فاتورة جديدة');
      debugPrint('   العميل: ${invoice.customerName}');
      debugPrint('   عدد المنتجات: ${invoice.items?.length ?? 0}');

      // 1. التحقق من صحة البيانات
      if (!invoice.isValid) {
        throw Exception('بيانات الفاتورة غير مكتملة');
      }

      // 2. التحقق من المخزون
      if (checkStock && invoice.items != null) {
        final errors = await _itemRepo.validateItems(invoice.items!);
        if (errors.isNotEmpty) {
          throw Exception('خطأ في المخزون:\n${errors.join('\n')}');
        }
      }

      // 3. حساب الإجماليات
      final calculatedInvoice = invoice.calculateTotals();

      // 4. إنشاء الفاتورة
      final createdInvoice = await _invoiceRepo.createInvoice(
        calculatedInvoice,
      );

      debugPrint('✅ تم إنشاء الفاتورة بنجاح');
      debugPrint('   رقم الفاتورة: ${createdInvoice.invoiceNumber}');
      debugPrint('   الإجمالي: ${createdInvoice.formattedTotal}');

      return createdInvoice;
    } catch (e) {
      debugPrint('❌ خطأ في إنشاء الفاتورة: $e');
      throw Exception('خطأ في إنشاء الفاتورة: $e');
    }
  }

  // ==================== CREATE QUOTATION ====================

  /// إنشاء عرض سعر جديد
  Future<Invoice> createQuotation(Invoice quotation) async {
    try {
      debugPrint('📝 بدء إنشاء عرض سعر جديد');

      // 1. التأكد من أن النوع هو عرض سعر
      final quotationWithStatus = quotation.copyWith(
        status: InvoiceStatus.quotation,
        invoiceNumber: await _invoiceRepo.generateQuotationNumber(),
      );

      // 2. حساب الإجماليات
      final calculatedQuotation = quotationWithStatus.calculateTotals();

      // 3. إنشاء عرض السعر (بدون التحقق من المخزون)
      final createdQuotation = await _invoiceRepo.createInvoice(
        calculatedQuotation,
      );

      debugPrint('✅ تم إنشاء عرض السعر بنجاح');
      debugPrint('   رقم عرض السعر: ${createdQuotation.invoiceNumber}');

      return createdQuotation;
    } catch (e) {
      debugPrint('❌ خطأ في إنشاء عرض السعر: $e');
      throw Exception('خطأ في إنشاء عرض السعر: $e');
    }
  }

  // ==================== CONFIRM INVOICE ====================

  /// تأكيد الفاتورة (خصم المخزون)
  Future<Invoice> confirmInvoice(String invoiceId) async {
    try {
      debugPrint('✅ بدء تأكيد الفاتورة: $invoiceId');

      // 1. جلب الفاتورة
      final invoice = await _invoiceRepo.getInvoiceById(invoiceId);
      if (invoice == null) {
        throw Exception('الفاتورة غير موجودة');
      }

      // 2. التحقق من إمكانية التأكيد
      if (!invoice.isDraft && !invoice.isPending && !invoice.isQuotation) {
        throw Exception('لا يمكن تأكيد فاتورة بحالة: ${invoice.statusLabel}');
      }

      // 3. التحقق من المخزون قبل التأكيد (للفواتير فقط وليس عروض الأسعار)
      if (!invoice.isQuotation &&
          invoice.items != null &&
          invoice.items!.isNotEmpty) {
        final errors = await _itemRepo.validateItems(invoice.items!);
        if (errors.isNotEmpty) {
          throw Exception('لا يمكن تأكيد الفاتورة:\n${errors.join('\n')}');
        }
      }

      // 4. تأكيد الفاتورة
      final confirmedInvoice = await _invoiceRepo.confirmInvoice(invoiceId);

      debugPrint('✅ تم تأكيد الفاتورة بنجاح');
      debugPrint('   رقم الفاتورة: ${confirmedInvoice.invoiceNumber}');

      return confirmedInvoice;
    } catch (e) {
      debugPrint('❌ خطأ في تأكيد الفاتورة: $e');
      throw Exception('خطأ في تأكيد الفاتورة: $e');
    }
  }

  // ==================== CANCEL INVOICE ====================

  /// إلغاء الفاتورة (إعادة المخزون)
  Future<Invoice> cancelInvoice(String invoiceId, {String? reason}) async {
    try {
      debugPrint('❌ بدء إلغاء الفاتورة: $invoiceId');

      // 1. جلب الفاتورة
      final invoice = await _invoiceRepo.getInvoiceById(invoiceId);
      if (invoice == null) {
        throw Exception('الفاتورة غير موجودة');
      }

      // 2. التحقق من إمكانية الإلغاء
      if (!invoice.isCancellable) {
        throw Exception('لا يمكن إلغاء فاتورة بحالة: ${invoice.statusLabel}');
      }

      // 3. إلغاء الفاتورة
      final cancelledInvoice = await _invoiceRepo.cancelInvoice(
        invoiceId,
        reason: reason,
      );

      debugPrint('✅ تم إلغاء الفاتورة بنجاح');
      debugPrint('   رقم الفاتورة: ${cancelledInvoice.invoiceNumber}');

      return cancelledInvoice;
    } catch (e) {
      debugPrint('❌ خطأ في إلغاء الفاتورة: $e');
      throw Exception('خطأ في إلغاء الفاتورة: $e');
    }
  }

  // ==================== COMPLETE PAYMENT ====================

  /// إكمال الدفع للفاتورة
  Future<Invoice> completePayment(
    String invoiceId,
    double amount, {
    String? paymentMethod,
    String? reference,
  }) async {
    try {
      debugPrint('💰 بدء إكمال الدفع للفاتورة: $invoiceId');
      debugPrint('   المبلغ: $amount');

      // 1. جلب الفاتورة
      final invoice = await _invoiceRepo.getInvoiceById(invoiceId);
      if (invoice == null) {
        throw Exception('الفاتورة غير موجودة');
      }

      // 2. التحقق من إمكانية الدفع
      if (!invoice.canBePaid) {
        throw Exception('لا يمكن دفع فاتورة بحالة: ${invoice.statusLabel}');
      }

      if (amount <= 0) {
        throw Exception('المبلغ يجب أن يكون أكبر من صفر');
      }

      final remaining = invoice.remainingToPay;
      if (amount > remaining) {
        throw Exception(
          'المبلغ المدفوع ($amount) أكبر من المتبقي ($remaining)',
        );
      }

      // 3. إكمال الدفع
      final completedInvoice = await _invoiceRepo.completePayment(
        invoiceId,
        amount,
        paymentMethod: paymentMethod,
        reference: reference,
      );

      debugPrint('✅ تم إكمال الدفع بنجاح');
      debugPrint('   المبلغ المدفوع: ${completedInvoice.formattedPaidAmount}');
      debugPrint('   المتبقي: ${completedInvoice.formattedRemaining}');

      return completedInvoice;
    } catch (e) {
      debugPrint('❌ خطأ في إكمال الدفع: $e');
      throw Exception('خطأ في إكمال الدفع: $e');
    }
  }

  // ==================== RETURN INVOICE ====================

  /// إرجاع الفاتورة (للمكتملة)
  Future<Invoice> returnInvoice(String invoiceId, {String? reason}) async {
    try {
      debugPrint('🔄 بدء إرجاع الفاتورة: $invoiceId');

      // 1. جلب الفاتورة
      final invoice = await _invoiceRepo.getInvoiceById(invoiceId);
      if (invoice == null) {
        throw Exception('الفاتورة غير موجودة');
      }

      // 2. التحقق من إمكانية الإرجاع
      if (!invoice.canBeReturned) {
        throw Exception('لا يمكن إرجاع فاتورة بحالة: ${invoice.statusLabel}');
      }

      // 3. التحقق من أن الفاتورة مدفوعة بالكامل
      if (!invoice.isPaid) {
        throw Exception('لا يمكن إرجاع فاتورة غير مدفوعة بالكامل');
      }

      // 4. إرجاع الفاتورة
      final returnedInvoice = await _invoiceRepo.returnInvoice(
        invoiceId,
        reason: reason,
      );

      debugPrint('✅ تم إرجاع الفاتورة بنجاح');
      debugPrint('   رقم الفاتورة: ${returnedInvoice.invoiceNumber}');

      return returnedInvoice;
    } catch (e) {
      debugPrint('❌ خطأ في إرجاع الفاتورة: $e');
      throw Exception('خطأ في إرجاع الفاتورة: $e');
    }
  }

  // ==================== CONVERT QUOTATION TO INVOICE ====================

  /// تحويل عرض السعر إلى فاتورة
  Future<Invoice> convertQuotationToInvoice(String quotationId) async {
    try {
      debugPrint('🔄 بدء تحويل عرض السعر إلى فاتورة: $quotationId');

      // 1. جلب عرض السعر
      final quotation = await _invoiceRepo.getInvoiceById(quotationId);
      if (quotation == null) {
        throw Exception('عرض السعر غير موجود');
      }

      // 2. التحقق من صحة عرض السعر
      if (!quotation.isQuotation) {
        throw Exception('هذا ليس عرض سعر');
      }

      if (quotation.isQuotationExpired) {
        throw Exception('عرض السعر منتهي الصلاحية');
      }

      // 3. التحقق من المخزون
      if (quotation.items != null && quotation.items!.isNotEmpty) {
        final errors = await _itemRepo.validateItems(quotation.items!);
        if (errors.isNotEmpty) {
          throw Exception('لا يمكن تحويل عرض السعر:\n${errors.join('\n')}');
        }
      }

      // 4. تحويل عرض السعر إلى فاتورة
      final invoice = await _invoiceRepo.convertQuotationToInvoice(quotationId);

      debugPrint('✅ تم تحويل عرض السعر إلى فاتورة بنجاح');
      debugPrint('   رقم الفاتورة: ${invoice.invoiceNumber}');

      return invoice;
    } catch (e) {
      debugPrint('❌ خطأ في تحويل عرض السعر: $e');
      throw Exception('خطأ في تحويل عرض السعر إلى فاتورة: $e');
    }
  }

  // ==================== UPDATE INVOICE ====================

  /// تحديث الفاتورة
  Future<Invoice> updateInvoice(Invoice invoice) async {
    try {
      debugPrint('📝 بدء تحديث الفاتورة: ${invoice.id}');

      // 1. جلب الفاتورة القديمة
      final oldInvoice = await _invoiceRepo.getInvoiceById(invoice.id!);
      if (oldInvoice == null) {
        throw Exception('الفاتورة غير موجودة');
      }

      // 2. التحقق من إمكانية التعديل
      if (!oldInvoice.isEditable) {
        throw Exception(
          'لا يمكن تعديل فاتورة بحالة: ${oldInvoice.statusLabel}',
        );
      }

      // 3. حساب الإجماليات
      final calculatedInvoice = invoice.calculateTotals();

      // 4. تحديث الفاتورة
      final updatedInvoice = await _invoiceRepo.updateInvoice(
        calculatedInvoice,
      );

      debugPrint('✅ تم تحديث الفاتورة بنجاح');
      debugPrint('   رقم الفاتورة: ${updatedInvoice.invoiceNumber}');

      return updatedInvoice;
    } catch (e) {
      debugPrint('❌ خطأ في تحديث الفاتورة: $e');
      throw Exception('خطأ في تحديث الفاتورة: $e');
    }
  }

  // ==================== DELETE INVOICE ====================

  /// حذف الفاتورة
  Future<void> deleteInvoice(String invoiceId) async {
    try {
      debugPrint('🗑️ بدء حذف الفاتورة: $invoiceId');

      // 1. جلب الفاتورة
      final invoice = await _invoiceRepo.getInvoiceById(invoiceId);
      if (invoice == null) {
        throw Exception('الفاتورة غير موجودة');
      }

      // 2. التحقق من إمكانية الحذف
      if (!invoice.isDeletable) {
        throw Exception('لا يمكن حذف فاتورة بحالة: ${invoice.statusLabel}');
      }

      // 3. حذف الفاتورة
      await _invoiceRepo.deleteInvoice(invoiceId);

      debugPrint('✅ تم حذف الفاتورة بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في حذف الفاتورة: $e');
      throw Exception('خطأ في حذف الفاتورة: $e');
    }
  }

  // ==================== GET INVOICE WITH DETAILS ====================

  /// جلب الفاتورة مع كل التفاصيل
  Future<Invoice?> getInvoiceWithDetails(String invoiceId) async {
    try {
      return await _invoiceRepo.getInvoiceById(invoiceId);
    } catch (e) {
      debugPrint('❌ خطأ في جلب الفاتورة: $e');
      throw Exception('خطأ في جلب الفاتورة: $e');
    }
  }

  // ==================== GET INVOICES ====================

  /// جلب الفواتير مع فلترة
  Future<List<Invoice>> getInvoices({
    InvoiceStatus? status,
    String? customerId,
    String? userId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      return await _invoiceRepo.getAllInvoices(
        status: status,
        customerId: customerId,
        userId: userId,
        fromDate: fromDate,
        toDate: toDate,
      );
    } catch (e) {
      debugPrint('❌ خطأ في جلب الفواتير: $e');
      throw Exception('خطأ في جلب الفواتير: $e');
    }
  }

  // ==================== SEARCH INVOICES ====================

  /// البحث عن الفواتير
  Future<List<Invoice>> searchInvoices(String query) async {
    try {
      if (query.isEmpty) {
        return await getInvoices();
      }
      return await _invoiceRepo.searchInvoices(query);
    } catch (e) {
      debugPrint('❌ خطأ في البحث عن الفواتير: $e');
      throw Exception('خطأ في البحث عن الفواتير: $e');
    }
  }

  // ==================== GET INVOICE STATISTICS ====================

  /// جلب إحصائيات الفواتير
  Future<Map<String, dynamic>> getInvoiceStatistics() async {
    try {
      return await _invoiceRepo.getInvoiceStatistics();
    } catch (e) {
      debugPrint('❌ خطأ في جلب الإحصائيات: $e');
      throw Exception('خطأ في جلب إحصائيات الفواتير: $e');
    }
  }

  // ==================== GET INVOICE SUMMARY ====================

  /// جلب ملخص الفاتورة
  Future<Map<String, dynamic>> getInvoiceSummary(String invoiceId) async {
    try {
      final invoice = await _invoiceRepo.getInvoiceById(invoiceId);
      if (invoice == null) {
        throw Exception('الفاتورة غير موجودة');
      }

      final itemStats = await _itemRepo.getItemStatistics(invoiceId);

      return {
        'invoice': invoice,
        'item_stats': itemStats,
        'status': invoice.statusLabel,
        'payment_status': invoice.paymentStatusLabel,
        'total_items': itemStats['total_items'],
        'total_quantity': itemStats['total_quantity'],
        'total_amount': itemStats['total_amount'],
        'remaining_amount': invoice.remainingToPay,
        'is_overdue': invoice.isOverdue,
        'is_quotation_expired': invoice.isQuotationExpired,
        'days_remaining': invoice.quotationDaysRemaining,
      };
    } catch (e) {
      debugPrint('❌ خطأ في جلب ملخص الفاتورة: $e');
      throw Exception('خطأ في جلب ملخص الفاتورة: $e');
    }
  }

  // ==================== GET CUSTOMER INVOICE SUMMARY ====================

  /// جلب ملخص فواتير العميل
  Future<Map<String, dynamic>> getCustomerInvoiceSummary(
    String customerId,
  ) async {
    try {
      final invoices = await _invoiceRepo.getInvoicesByCustomer(customerId);

      int totalInvoices = invoices.length;
      double totalAmount = 0;
      double paidAmount = 0;
      double unpaidAmount = 0;
      int completedCount = 0;
      int pendingCount = 0;

      for (var invoice in invoices) {
        totalAmount += invoice.total;
        if (invoice.isPaid) {
          paidAmount += invoice.total;
          completedCount++;
        } else {
          unpaidAmount += invoice.total;
        }
        if (invoice.isPending) {
          pendingCount++;
        }
      }

      return {
        'customer_id': customerId,
        'customer_name': invoices.isNotEmpty
            ? invoices.first.customerName
            : 'غير معروف',
        'total_invoices': totalInvoices,
        'total_amount': totalAmount,
        'paid_amount': paidAmount,
        'unpaid_amount': unpaidAmount,
        'completed_count': completedCount,
        'pending_count': pendingCount,
        'average_invoice': totalInvoices > 0 ? totalAmount / totalInvoices : 0,
        'last_invoice_date': invoices.isNotEmpty ? invoices.first.date : null,
      };
    } catch (e) {
      debugPrint('❌ خطأ في جلب ملخص فواتير العميل: $e');
      throw Exception('خطأ في جلب ملخص فواتير العميل: $e');
    }
  }

  // ==================== GET DAILY SALES REPORT ====================

  /// جلب تقرير المبيعات اليومية
  Future<Map<String, dynamic>> getDailySalesReport(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // جلب فواتير اليوم
      final invoices = await _invoiceRepo.getInvoicesByDateRange(
        startOfDay,
        endOfDay,
      );

      // فلترة الفواتير المؤكدة والمكتملة فقط
      final salesInvoices = invoices
          .where((inv) => inv.isConfirmed || inv.isCompleted)
          .toList();

      int totalInvoices = salesInvoices.length;
      double totalAmount = 0;
      double totalDiscount = 0;
      double totalTax = 0;
      int totalItems = 0;

      for (var invoice in salesInvoices) {
        totalAmount += invoice.total;
        totalDiscount += invoice.calculatedDiscountAmount;
        totalTax += invoice.calculatedTaxAmount;
        totalItems += invoice.totalQuantity;
      }

      // جلب تفاصيل المنتجات
      final productSales = await _itemRepo.getDailySales(date: date);

      return {
        'date': date,
        'total_invoices': totalInvoices,
        'total_amount': totalAmount,
        'total_discount': totalDiscount,
        'total_tax': totalTax,
        'total_items': totalItems,
        'average_invoice': totalInvoices > 0 ? totalAmount / totalInvoices : 0,
        'product_sales': productSales,
        'invoices': salesInvoices,
      };
    } catch (e) {
      debugPrint('❌ خطأ في جلب تقرير المبيعات اليومية: $e');
      throw Exception('خطأ في جلب تقرير المبيعات اليومية: $e');
    }
  }

  // ==================== GET MONTHLY SALES REPORT ====================

  /// جلب تقرير المبيعات الشهرية
  Future<Map<String, dynamic>> getMonthlySalesReport({
    required int year,
    required int month,
  }) async {
    try {
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 1);

      final invoices = await _invoiceRepo.getInvoicesByDateRange(
        startDate,
        endDate,
      );

      // فلترة الفواتير المؤكدة والمكتملة
      final salesInvoices = invoices
          .where((inv) => inv.isConfirmed || inv.isCompleted)
          .toList();

      // إحصائيات يومية
      final Map<int, Map<String, dynamic>> dailyStats = {};

      for (var invoice in salesInvoices) {
        final day = invoice.date.day;
        if (!dailyStats.containsKey(day)) {
          dailyStats[day] = {
            'day': day,
            'count': 0,
            'amount': 0.0,
            'invoices': <Invoice>[],
          };
        }
        dailyStats[day]!['count'] = (dailyStats[day]!['count'] as int) + 1;
        dailyStats[day]!['amount'] =
            (dailyStats[day]!['amount'] as double) + invoice.total;
        (dailyStats[day]!['invoices'] as List<Invoice>).add(invoice);
      }

      // تحويل إلى قائمة مرتبة
      final dailyReport = dailyStats.values.toList()
        ..sort((a, b) => (a['day'] as int).compareTo(b['day'] as int));

      double totalAmount = salesInvoices.fold(0, (sum, inv) => sum + inv.total);
      int totalInvoices = salesInvoices.length;

      return {
        'year': year,
        'month': month,
        'month_name': _getMonthName(month),
        'total_invoices': totalInvoices,
        'total_amount': totalAmount,
        'average_invoice': totalInvoices > 0 ? totalAmount / totalInvoices : 0,
        'daily_report': dailyReport,
        'invoices': salesInvoices,
        'days_in_month': DateTime(year, month + 1, 0).day,
      };
    } catch (e) {
      debugPrint('❌ خطأ في جلب تقرير المبيعات الشهرية: $e');
      throw Exception('خطأ في جلب تقرير المبيعات الشهرية: $e');
    }
  }

  // ==================== GET INVOICE STATUS SUMMARY ====================

  /// جلب ملخص حالة الفواتير
  Future<Map<InvoiceStatus, int>> getInvoiceStatusSummary() async {
    try {
      final allInvoices = await _invoiceRepo.getAllInvoices();

      final summary = <InvoiceStatus, int>{};
      for (var status in InvoiceStatus.values) {
        summary[status] = 0;
      }

      for (var invoice in allInvoices) {
        summary[invoice.status] = (summary[invoice.status] ?? 0) + 1;
      }

      return summary;
    } catch (e) {
      debugPrint('❌ خطأ في جلب ملخص حالة الفواتير: $e');
      throw Exception('خطأ في جلب ملخص حالة الفواتير: $e');
    }
  }

  // ==================== GET PAYMENT STATUS SUMMARY ====================

  /// جلب ملخص حالة الدفع
  Future<Map<PaymentStatus, int>> getPaymentStatusSummary() async {
    try {
      final allInvoices = await _invoiceRepo.getAllInvoices();

      final summary = <PaymentStatus, int>{};
      for (var status in PaymentStatus.values) {
        summary[status] = 0;
      }

      for (var invoice in allInvoices) {
        summary[invoice.paymentStatus] =
            (summary[invoice.paymentStatus] ?? 0) + 1;
      }

      return summary;
    } catch (e) {
      debugPrint('❌ خطأ في جلب ملخص حالة الدفع: $e');
      throw Exception('خطأ في جلب ملخص حالة الدفع: $e');
    }
  }

  // ==================== GET EXPIRING QUOTATIONS ====================

  /// جلب عروض الأسعار المنتهية أو المنتهية صلاحيتها
  Future<List<Invoice>> getExpiringQuotations({int daysThreshold = 3}) async {
    try {
      final allInvoices = await _invoiceRepo.getAllInvoices(
        status: InvoiceStatus.quotation,
      );

      final now = DateTime.now();
      final threshold = now.add(Duration(days: daysThreshold));

      return allInvoices.where((inv) {
        if (inv.validUntil == null) return false;
        return inv.validUntil!.isBefore(threshold);
      }).toList();
    } catch (e) {
      debugPrint('❌ خطأ في جلب عروض الأسعار المنتهية: $e');
      throw Exception('خطأ في جلب عروض الأسعار المنتهية: $e');
    }
  }

  // ==================== GET OVERDUE INVOICES ====================

  /// جلب الفواتير المتأخرة
  Future<List<Invoice>> getOverdueInvoices() async {
    try {
      final allInvoices = await _invoiceRepo.getAllInvoices();

      return allInvoices.where((inv) => inv.isOverdue).toList();
    } catch (e) {
      debugPrint('❌ خطأ في جلب الفواتير المتأخرة: $e');
      throw Exception('خطأ في جلب الفواتير المتأخرة: $e');
    }
  }

  // ==================== VALIDATE INVOICE BEFORE CONFIRM ====================

  /// التحقق من صحة الفاتورة قبل التأكيد
  Future<List<String>> validateInvoiceBeforeConfirm(String invoiceId) async {
    final errors = <String>[];

    try {
      final invoice = await _invoiceRepo.getInvoiceById(invoiceId);
      if (invoice == null) {
        errors.add('الفاتورة غير موجودة');
        return errors;
      }

      // التحقق من الحالة
      if (!invoice.canBeConfirmed) {
        errors.add('لا يمكن تأكيد فاتورة بحالة: ${invoice.statusLabel}');
      }

      // التحقق من وجود منتجات
      if (invoice.items == null || invoice.items!.isEmpty) {
        errors.add('الفاتورة لا تحتوي على منتجات');
      }

      // التحقق من العميل
      if (invoice.customerId.isEmpty) {
        errors.add('الفاتورة لا تحتوي على عميل');
      }

      // التحقق من المخزون (للفواتير فقط وليس عروض الأسعار)
      if (!invoice.isQuotation &&
          invoice.items != null &&
          invoice.items!.isNotEmpty) {
        final stockErrors = await _itemRepo.validateItems(invoice.items!);
        errors.addAll(stockErrors);
      }

      // التحقق من الإجماليات
      if (invoice.total <= 0) {
        errors.add('إجمالي الفاتورة يجب أن يكون أكبر من صفر');
      }

      // التحقق من التاريخ
      if (invoice.dueDate != null && invoice.dueDate!.isBefore(invoice.date)) {
        errors.add('تاريخ الاستحقاق يجب أن يكون بعد تاريخ الفاتورة');
      }
    } catch (e) {
      errors.add('خطأ في التحقق من الفاتورة: $e');
    }

    return errors;
  }

  // ==================== HELPER METHODS ====================

  String _getMonthName(int month) {
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    return months[month - 1];
  }

  // ==================== BULK OPERATIONS ====================

  /// تأكيد عدة فواتير دفعة واحدة
  Future<List<Invoice>> confirmInvoices(List<String> invoiceIds) async {
    final results = <Invoice>[];
    final errors = <String>[];

    for (var id in invoiceIds) {
      try {
        final invoice = await confirmInvoice(id);
        results.add(invoice);
      } catch (e) {
        errors.add('خطأ في تأكيد الفاتورة $id: $e');
      }
    }

    if (errors.isNotEmpty) {
      throw Exception('بعض الفواتير لم يتم تأكيدها:\n${errors.join('\n')}');
    }

    return results;
  }

  /// إلغاء عدة فواتير دفعة واحدة
  Future<List<Invoice>> cancelInvoices(
    List<String> invoiceIds, {
    String? reason,
  }) async {
    final results = <Invoice>[];
    final errors = <String>[];

    for (var id in invoiceIds) {
      try {
        final invoice = await cancelInvoice(id, reason: reason);
        results.add(invoice);
      } catch (e) {
        errors.add('خطأ في إلغاء الفاتورة $id: $e');
      }
    }

    if (errors.isNotEmpty) {
      throw Exception('بعض الفواتير لم يتم إلغاؤها:\n${errors.join('\n')}');
    }

    return results;
  }

  /// حذف عدة فواتير دفعة واحدة
  Future<void> deleteInvoices(List<String> invoiceIds) async {
    final errors = <String>[];

    for (var id in invoiceIds) {
      try {
        await deleteInvoice(id);
      } catch (e) {
        errors.add('خطأ في حذف الفاتورة $id: $e');
      }
    }

    if (errors.isNotEmpty) {
      throw Exception('بعض الفواتير لم يتم حذفها:\n${errors.join('\n')}');
    }
  }

  /// إرجاع عدة فواتير دفعة واحدة
  Future<List<Invoice>> returnInvoices(
    List<String> invoiceIds, {
    String? reason,
  }) async {
    final results = <Invoice>[];
    final errors = <String>[];

    for (var id in invoiceIds) {
      try {
        final invoice = await returnInvoice(id, reason: reason);
        results.add(invoice);
      } catch (e) {
        errors.add('خطأ في إرجاع الفاتورة $id: $e');
      }
    }

    if (errors.isNotEmpty) {
      throw Exception('بعض الفواتير لم يتم إرجاعها:\n${errors.join('\n')}');
    }

    return results;
  }

  // ==================== PRINT INVOICE ====================

  /// تجهيز بيانات الفاتورة للطباعة
  Future<Map<String, dynamic>> prepareInvoiceForPrint(String invoiceId) async {
    try {
      final invoice = await _invoiceRepo.getInvoiceById(invoiceId);
      if (invoice == null) {
        throw Exception('الفاتورة غير موجودة');
      }

      return {
        'invoice': invoice,
        'items': invoice.items ?? [],
        'customer': invoice.customer,
        'company': {
          'name': 'Kiya System',
          'address': 'مصر',
          'phone': 'Yousef_Aborizk',
          'email': 'info@kiya-system.com',
        },
        'summary': {
          'subtotal': invoice.formattedSubtotal,
          'discount': invoice.formattedDiscount,
          'tax': invoice.formattedTax,
          'shipping': invoice.formattedShippingCost,
          'total': invoice.formattedTotal,
          'paid': invoice.formattedPaidAmount,
          'remaining': invoice.formattedRemaining,
        },
        'status': {
          'invoice_status': invoice.statusLabel,
          'payment_status': invoice.paymentStatusLabel,
          'payment_method': invoice.paymentMethod.label,
        },
      };
    } catch (e) {
      debugPrint('❌ خطأ في تجهيز الفاتورة للطباعة: $e');
      throw Exception('خطأ في تجهيز الفاتورة للطباعة: $e');
    }
  }
}
