// lib/data/repositories/invoice_item_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/invoice.dart';

class InvoiceItemRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  final String _table = 'invoice_items';

  // ==================== GET ALL ITEMS FOR AN INVOICE ====================
  Future<List<InvoiceItem>> getItemsByInvoiceId(String invoiceId) async {
    try {
      final response = await _supabase
          .from(_table)
          .select('''
            *,
            product:products(*)
          ''')
          .eq('invoice_id', invoiceId)
          .order('created_at', ascending: true);

      return List<InvoiceItem>.from(
        response.map((json) => InvoiceItem.fromJson(json)),
      );
    } catch (e) {
      throw Exception('خطأ في جلب بنود الفاتورة: $e');
    }
  }

  // ==================== GET ITEM BY ID ====================
  Future<InvoiceItem?> getItemById(String id) async {
    try {
      final response = await _supabase
          .from(_table)
          .select('''
            *,
            product:products(*)
          ''')
          .eq('id', id)
          .maybeSingle();

      if (response != null) {
        return InvoiceItem.fromJson(response);
      }
      return null;
    } catch (e) {
      throw Exception('خطأ في جلب بيانات بند الفاتورة: $e');
    }
  }

  // ==================== CREATE INVOICE ITEM ====================
  Future<InvoiceItem> createItem(InvoiceItem item) async {
    try {
      // التحقق من صحة البيانات
      if (item.invoiceId.isEmpty) {
        throw Exception('معرف الفاتورة مطلوب');
      }
      if (item.productId.isEmpty) {
        throw Exception('معرف المنتج مطلوب');
      }
      if (item.quantity <= 0) {
        throw Exception('الكمية يجب أن تكون أكبر من صفر');
      }
      if (item.unitPrice < 0) {
        throw Exception('سعر الوحدة يجب أن يكون أكبر من أو يساوي صفر');
      }

      final response = await _supabase
          .from(_table)
          .insert(item.toJson())
          .select()
          .single();

      // جلب المنتج المرتبط
      final itemWithProduct = await getItemById(response['id']);
      if (itemWithProduct != null) {
        return itemWithProduct;
      }

      return InvoiceItem.fromJson(response);
    } catch (e) {
      throw Exception('خطأ في إضافة بند الفاتورة: $e');
    }
  }

  // ==================== CREATE MULTIPLE ITEMS ====================
  Future<List<InvoiceItem>> createItems(List<InvoiceItem> items) async {
    try {
      if (items.isEmpty) {
        return [];
      }

      final itemsJson = items.map((item) => item.toJson()).toList();

      final response = await _supabase.from(_table).insert(itemsJson).select();

      // جلب المنتجات المرتبطة
      final createdItems = <InvoiceItem>[];
      for (var json in response) {
        final item = await getItemById(json['id']);
        if (item != null) {
          createdItems.add(item);
        } else {
          createdItems.add(InvoiceItem.fromJson(json));
        }
      }

      return createdItems;
    } catch (e) {
      throw Exception('خطأ في إضافة بنود الفاتورة: $e');
    }
  }

  // ==================== UPDATE INVOICE ITEM ====================
  Future<InvoiceItem> updateItem(InvoiceItem item) async {
    try {
      if (item.id == null) {
        throw Exception('معرف البند مطلوب للتحديث');
      }

      // التحقق من صحة البيانات
      if (item.quantity <= 0) {
        throw Exception('الكمية يجب أن تكون أكبر من صفر');
      }
      if (item.unitPrice < 0) {
        throw Exception('سعر الوحدة يجب أن يكون أكبر من أو يساوي صفر');
      }

      final response = await _supabase
          .from(_table)
          .update(item.toJson())
          .eq('id', item.id!)
          .select()
          .single();

      // جلب المنتج المرتبط
      final updatedItem = await getItemById(response['id']);
      if (updatedItem != null) {
        return updatedItem;
      }

      return InvoiceItem.fromJson(response);
    } catch (e) {
      throw Exception('خطأ في تحديث بند الفاتورة: $e');
    }
  }

  // ==================== UPDATE ITEMS BULK ====================
  Future<List<InvoiceItem>> updateItems(List<InvoiceItem> items) async {
    try {
      if (items.isEmpty) {
        return [];
      }

      final updatedItems = <InvoiceItem>[];
      for (var item in items) {
        final updated = await updateItem(item);
        updatedItems.add(updated);
      }

      return updatedItems;
    } catch (e) {
      throw Exception('خطأ في تحديث بنود الفاتورة: $e');
    }
  }

  // ==================== DELETE INVOICE ITEM ====================
  Future<void> deleteItem(String id) async {
    try {
      // التحقق من وجود البند
      final item = await getItemById(id);
      if (item == null) {
        throw Exception('بند الفاتورة غير موجود');
      }

      await _supabase.from(_table).delete().eq('id', id);
    } catch (e) {
      throw Exception('خطأ في حذف بند الفاتورة: $e');
    }
  }

  // ==================== DELETE ALL ITEMS FOR AN INVOICE ====================
  Future<void> deleteItemsByInvoiceId(String invoiceId) async {
    try {
      await _supabase.from(_table).delete().eq('invoice_id', invoiceId);
    } catch (e) {
      throw Exception('خطأ في حذف بنود الفاتورة: $e');
    }
  }

  // ==================== DELETE MULTIPLE ITEMS ====================
  Future<void> deleteItems(List<String> ids) async {
    try {
      if (ids.isEmpty) return;

      await _supabase.from(_table).delete().inFilter('id', ids);
    } catch (e) {
      throw Exception('خطأ في حذف البنود المحددة: $e');
    }
  }

  // ==================== GET ITEMS BY PRODUCT ====================
  Future<List<InvoiceItem>> getItemsByProduct(String productId) async {
    try {
      final response = await _supabase
          .from(_table)
          .select('''
            *,
            product:products(*),
            invoice:invoices(*)
          ''')
          .eq('product_id', productId)
          .order('created_at', ascending: false);

      return List<InvoiceItem>.from(
        response.map((json) => InvoiceItem.fromJson(json)),
      );
    } catch (e) {
      throw Exception('خطأ في جلب بنود المنتج: $e');
    }
  }

  // ==================== CALCULATE ITEM TOTAL ====================
  double calculateItemTotal(InvoiceItem item) {
    double total = item.unitPrice * item.quantity;

    // تطبيق الخصم
    if (item.discountRate != null && item.discountRate! > 0) {
      total = total - (total * item.discountRate! / 100);
    } else if (item.discountAmount != null && item.discountAmount! > 0) {
      total = total - (item.discountAmount! * item.quantity);
    }

    // تطبيق الضريبة
    if (item.taxRate != null && item.taxRate! > 0) {
      total = total + (total * item.taxRate! / 100);
    } else if (item.taxAmount != null && item.taxAmount! > 0) {
      total = total + item.taxAmount!;
    }

    return total;
  }

  // ==================== CALCULATE INVOICE SUBTOTAL ====================
  Future<double> calculateInvoiceSubtotal(String invoiceId) async {
    try {
      final items = await getItemsByInvoiceId(invoiceId);

      double subtotal = 0;
      for (var item in items) {
        subtotal += item.total;
      }

      return subtotal;
    } catch (e) {
      throw Exception('خطأ في حساب المجموع الفرعي: $e');
    }
  }

  // ==================== CALCULATE INVOICE TOTAL ====================
  Future<double> calculateInvoiceTotal(String invoiceId) async {
    try {
      final items = await getItemsByInvoiceId(invoiceId);

      double total = 0;
      for (var item in items) {
        total += item.totalAfterTax;
      }

      return total;
    } catch (e) {
      throw Exception('خطأ في حساب الإجمالي: $e');
    }
  }

  // ==================== GET ITEMS COUNT ====================
  Future<int> getItemsCount(String invoiceId) async {
    try {
      final response = await _supabase
          .from(_table)
          .select('id')
          .eq('invoice_id', invoiceId);

      return response.length;
    } catch (e) {
      throw Exception('خطأ في جلب عدد البنود: $e');
    }
  }

  // ==================== GET TOTAL QUANTITY ====================
  Future<int> getTotalQuantity(String invoiceId) async {
    try {
      final response = await _supabase
          .from(_table)
          .select('quantity')
          .eq('invoice_id', invoiceId);

      int total = 0;
      for (var item in response) {
        total += (item['quantity'] ?? 0) as int;
      }

      return total;
    } catch (e) {
      throw Exception('خطأ في جلب الكمية الإجمالية: $e');
    }
  }

  // ==================== GET TOP SELLING PRODUCTS ====================
  Future<List<Map<String, dynamic>>> getTopSellingProducts({
    DateTime? fromDate,
    DateTime? toDate,
    int limit = 10,
  }) async {
    try {
      var query = _supabase.from(_table).select('''
            product_id,
            product:products(name, price, image_url),
            quantity,
            total
          ''');

      // فلترة حسب التاريخ إذا تم تحديده
      if (fromDate != null) {
        query = query.gte('created_at', fromDate.toIso8601String());
      }
      if (toDate != null) {
        query = query.lte('created_at', toDate.toIso8601String());
      }

      final response = await query;

      // تجميع البيانات حسب المنتج
      final Map<String, Map<String, dynamic>> productStats = {};

      for (var item in response) {
        final productId = item['product_id'] as String;
        final quantity = (item['quantity'] ?? 0) as int;
        final total = (item['total'] ?? 0) as double;
        final product = item['product'] as Map<String, dynamic>?;

        if (!productStats.containsKey(productId)) {
          productStats[productId] = {
            'product_id': productId,
            'product': product,
            'total_quantity': 0,
            'total_amount': 0.0,
          };
        }

        productStats[productId]!['total_quantity'] =
            (productStats[productId]!['total_quantity'] as int) + quantity;
        productStats[productId]!['total_amount'] =
            (productStats[productId]!['total_amount'] as double) + total;
      }

      // تحويل إلى قائمة وترتيب حسب الكمية
      final List<Map<String, dynamic>> result = productStats.values
          .map(
            (stats) => {
              'product_id': stats['product_id'],
              'product': stats['product'],
              'total_quantity': stats['total_quantity'],
              'total_amount': stats['total_amount'],
            },
          )
          .toList();

      result.sort(
        (a, b) =>
            (b['total_quantity'] as int).compareTo(a['total_quantity'] as int),
      );

      return result.take(limit).toList();
    } catch (e) {
      throw Exception('خطأ في جلب المنتجات الأكثر مبيعاً: $e');
    }
  }

  // ==================== GET BEST CUSTOMERS ====================
  Future<List<Map<String, dynamic>>> getBestCustomers({
    DateTime? fromDate,
    DateTime? toDate,
    int limit = 10,
  }) async {
    try {
      var query = _supabase.from(_table).select('''
            invoice:invoices(
              customer_id,
              customer:customers(name, phone, email)
            ),
            total
          ''');

      if (fromDate != null) {
        query = query.gte('created_at', fromDate.toIso8601String());
      }
      if (toDate != null) {
        query = query.lte('created_at', toDate.toIso8601String());
      }

      final response = await query;

      // تجميع البيانات حسب العميل
      final Map<String, Map<String, dynamic>> customerStats = {};

      for (var item in response) {
        final invoice = item['invoice'] as Map<String, dynamic>?;
        if (invoice == null) continue;

        final customerId = invoice['customer_id'] as String?;
        if (customerId == null) continue;

        final customer = invoice['customer'] as Map<String, dynamic>?;
        final total = (item['total'] ?? 0) as double;

        if (!customerStats.containsKey(customerId)) {
          customerStats[customerId] = {
            'customer_id': customerId,
            'customer': customer,
            'total_amount': 0.0,
            'invoice_count': 0,
          };
        }

        customerStats[customerId]!['total_amount'] =
            (customerStats[customerId]!['total_amount'] as double) + total;
        customerStats[customerId]!['invoice_count'] =
            (customerStats[customerId]!['invoice_count'] as int) + 1;
      }

      // تحويل إلى قائمة وترتيب حسب المبلغ
      final List<Map<String, dynamic>> result = customerStats.values
          .map(
            (stats) => {
              'customer_id': stats['customer_id'],
              'customer': stats['customer'],
              'total_amount': stats['total_amount'],
              'invoice_count': stats['invoice_count'],
            },
          )
          .toList();

      result.sort(
        (a, b) => (b['total_amount'] as double).compareTo(
          a['total_amount'] as double,
        ),
      );

      return result.take(limit).toList();
    } catch (e) {
      throw Exception('خطأ في جلب أفضل العملاء: $e');
    }
  }

  // ==================== GET DAILY SALES ====================
  Future<List<Map<String, dynamic>>> getDailySales({
    required DateTime date,
  }) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await _supabase
          .from(_table)
          .select('''
            product_id,
            product:products(name),
            quantity,
            total
          ''')
          .gte('created_at', startOfDay.toIso8601String())
          .lt('created_at', endOfDay.toIso8601String());

      // تجميع البيانات حسب المنتج
      final Map<String, Map<String, dynamic>> dailyStats = {};

      for (var item in response) {
        final productId = item['product_id'] as String;
        final quantity = (item['quantity'] ?? 0) as int;
        final total = (item['total'] ?? 0) as double;
        final product = item['product'] as Map<String, dynamic>?;

        if (!dailyStats.containsKey(productId)) {
          dailyStats[productId] = {
            'product_id': productId,
            'product_name': product?['name'] ?? 'منتج غير معروف',
            'total_quantity': 0,
            'total_amount': 0.0,
          };
        }

        dailyStats[productId]!['total_quantity'] =
            (dailyStats[productId]!['total_quantity'] as int) + quantity;
        dailyStats[productId]!['total_amount'] =
            (dailyStats[productId]!['total_amount'] as double) + total;
      }

      return dailyStats.values.toList();
    } catch (e) {
      throw Exception('خطأ في جلب المبيعات اليومية: $e');
    }
  }

  // ==================== CHECK PRODUCT STOCK AVAILABILITY ====================
  Future<bool> checkStockAvailability(
    String productId,
    int requiredQuantity,
    String? warehouseId,
  ) async {
    try {
      var query = _supabase
          .from('warehouse_stock')
          .select('quantity')
          .eq('product_id', productId);

      if (warehouseId != null && warehouseId.isNotEmpty) {
        query = query.eq('warehouse_id', warehouseId);
      }

      final response = await query;

      int totalStock = 0;
      for (var item in response) {
        totalStock += (item['quantity'] ?? 0) as int;
      }

      return totalStock >= requiredQuantity;
    } catch (e) {
      throw Exception('خطأ في التحقق من توفر المخزون: $e');
    }
  }

  // ==================== GET ITEM STATISTICS ====================
  Future<Map<String, dynamic>> getItemStatistics(String invoiceId) async {
    try {
      final items = await getItemsByInvoiceId(invoiceId);

      if (items.isEmpty) {
        return {
          'total_items': 0,
          'total_quantity': 0,
          'total_amount': 0.0,
          'average_price': 0.0,
          'max_price': 0.0,
          'min_price': 0.0,
        };
      }

      int totalQuantity = 0;
      double totalAmount = 0;
      double maxPrice = 0;
      double minPrice = double.infinity;

      for (var item in items) {
        totalQuantity += item.quantity;
        totalAmount += item.total;
        if (item.unitPrice > maxPrice) maxPrice = item.unitPrice;
        if (item.unitPrice < minPrice) minPrice = item.unitPrice;
      }

      return {
        'total_items': items.length,
        'total_quantity': totalQuantity,
        'total_amount': totalAmount,
        'average_price': totalAmount / totalQuantity,
        'max_price': maxPrice,
        'min_price': minPrice == double.infinity ? 0 : minPrice,
      };
    } catch (e) {
      throw Exception('خطأ في جلب إحصائيات البنود: $e');
    }
  }

  // ==================== VALIDATE ITEMS ====================
  Future<List<String>> validateItems(List<InvoiceItem> items) async {
    final List<String> errors = [];

    for (var i = 0; i < items.length; i++) {
      final item = items[i];

      if (item.productId.isEmpty) {
        errors.add('البند ${i + 1}: معرف المنتج مطلوب');
      }

      if (item.quantity <= 0) {
        errors.add('البند ${i + 1}: الكمية يجب أن تكون أكبر من صفر');
      }

      if (item.unitPrice < 0) {
        errors.add(
          'البند ${i + 1}: سعر الوحدة يجب أن يكون أكبر من أو يساوي صفر',
        );
      }

      // التحقق من المخزون
      if (item.quantity > 0) {
        final available = await checkStockAvailability(
          item.productId,
          item.quantity,
          null, // يمكن تمرير معرف المخزن إذا كان متاحاً
        );
        if (!available) {
          final productName = item.product?.name ?? 'منتج غير معروف';
          errors.add(
            'البند ${i + 1}: الكمية المطلوبة من $productName غير متوفرة في المخزون',
          );
        }
      }
    }

    return errors;
  }

  // ==================== SYNC ITEMS WITH INVOICE ====================
  Future<List<InvoiceItem>> syncItemsWithInvoice(
    String invoiceId,
    List<InvoiceItem> newItems,
  ) async {
    try {
      // جلب البنود الحالية
      final existingItems = await getItemsByInvoiceId(invoiceId);

      // حذف البنود المحذوفة
      final existingIds = existingItems
          .map((item) => item.id)
          .whereType<String>()
          .toList();
      final newIds = newItems
          .map((item) => item.id)
          .whereType<String>()
          .toList();

      final idsToDelete = existingIds
          .where((id) => !newIds.contains(id))
          .toList();
      if (idsToDelete.isNotEmpty) {
        await deleteItems(idsToDelete);
      }

      // تحديث أو إضافة البنود الجديدة
      final syncedItems = <InvoiceItem>[];
      for (var item in newItems) {
        final itemWithInvoice = item.copyWith(invoiceId: invoiceId);

        if (item.id != null && existingIds.contains(item.id)) {
          // تحديث بند موجود
          final updated = await updateItem(itemWithInvoice);
          syncedItems.add(updated);
        } else {
          // إضافة بند جديد
          final created = await createItem(itemWithInvoice);
          syncedItems.add(created);
        }
      }

      return syncedItems;
    } catch (e) {
      throw Exception('خطأ في مزامنة بنود الفاتورة: $e');
    }
  }

  // ==================== BULK OPERATIONS ====================

  // حذف جميع بنود فواتير متعددة
  Future<void> deleteItemsByInvoiceIds(List<String> invoiceIds) async {
    try {
      if (invoiceIds.isEmpty) return;

      await _supabase.from(_table).delete().inFilter('invoice_id', invoiceIds);
    } catch (e) {
      throw Exception('خطأ في حذف بنود الفواتير: $e');
    }
  }

  // نسخ بنود من فاتورة إلى أخرى
  Future<List<InvoiceItem>> copyItems(
    String sourceInvoiceId,
    String targetInvoiceId,
  ) async {
    try {
      final sourceItems = await getItemsByInvoiceId(sourceInvoiceId);

      if (sourceItems.isEmpty) {
        return [];
      }

      final newItems = sourceItems
          .map((item) => item.copyWith(id: null, invoiceId: targetInvoiceId))
          .toList();

      return await createItems(newItems);
    } catch (e) {
      throw Exception('خطأ في نسخ بنود الفاتورة: $e');
    }
  }

  // تحديث أسعار بنود الفاتورة
  Future<List<InvoiceItem>> updateItemsPrices(
    String invoiceId,
    double percentage,
  ) async {
    try {
      final items = await getItemsByInvoiceId(invoiceId);

      if (items.isEmpty) {
        return [];
      }

      final updatedItems = <InvoiceItem>[];
      for (var item in items) {
        final newPrice = item.unitPrice * (1 + percentage / 100);
        final newTotal = newPrice * item.quantity;

        final updated = await updateItem(
          item.copyWith(unitPrice: newPrice, total: newTotal),
        );
        updatedItems.add(updated);
      }

      return updatedItems;
    } catch (e) {
      throw Exception('خطأ في تحديث أسعار البنود: $e');
    }
  }

  // تطبيق خصم على جميع بنود الفاتورة
  Future<List<InvoiceItem>> applyDiscountToItems(
    String invoiceId,
    double discountRate,
  ) async {
    try {
      if (discountRate < 0 || discountRate > 100) {
        throw Exception('نسبة الخصم يجب أن تكون بين 0 و 100');
      }

      final items = await getItemsByInvoiceId(invoiceId);

      if (items.isEmpty) {
        return [];
      }

      final updatedItems = <InvoiceItem>[];
      for (var item in items) {
        final discountAmount = item.unitPrice * discountRate / 100;
        final newTotal = (item.unitPrice - discountAmount) * item.quantity;

        final updated = await updateItem(
          item.copyWith(
            discountRate: discountRate,
            discountAmount: discountAmount,
            total: newTotal,
          ),
        );
        updatedItems.add(updated);
      }

      return updatedItems;
    } catch (e) {
      throw Exception('خطأ في تطبيق الخصم على البنود: $e');
    }
  }
}
