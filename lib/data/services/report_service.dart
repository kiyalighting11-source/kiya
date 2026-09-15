// lib/data/services/report_service.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/report.dart';

class ReportService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // =============================================
  // ✅ SALES REPORT
  // =============================================
  Future<ReportData> getSalesReport({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    try {
      debugPrint('📊 Generating sales report...');

      final response = await _supabase
          .from('invoices')
          .select('''
            id,
            invoice_number,
            date,
            total,
            subtotal,
            discount_amount,
            tax_amount,
            paid_amount,
            status,
            payment_status,
            customer:customers(name, phone),
            user:users(name)
          ''')
          .inFilter('status', ['confirmed', 'completed'])
          .gte('date', fromDate.toIso8601String())
          .lte('date', toDate.toIso8601String())
          .order('date', ascending: false);

      // Build rows
      final rows = <ReportRow>[];
      double totalSales = 0;
      double totalDiscount = 0;
      double totalTax = 0;
      double totalPaid = 0;
      int totalInvoices = 0;

      for (var item in response) {
        final total = _toDouble(item['total']);
        final discount = _toDouble(item['discount_amount']);
        final tax = _toDouble(item['tax_amount']);
        final paid = _toDouble(item['paid_amount']);

        totalSales += total;
        totalDiscount += discount;
        totalTax += tax;
        totalPaid += paid;
        totalInvoices++;

        final customer = item['customer'] as Map<String, dynamic>?;
        final user = item['user'] as Map<String, dynamic>?;

        rows.add(
          ReportRow({
            'invoice_number': item['invoice_number'] ?? '',
            'date': _formatDate(DateTime.parse(item['date'])),
            'customer_name': customer?['name'] ?? 'عميل غير معروف',
            'customer_phone': customer?['phone'] ?? '',
            'salesperson': user?['name'] ?? 'غير معروف',
            'subtotal': _toDouble(item['subtotal']),
            'discount': discount,
            'tax': tax,
            'total': total,
            'paid': paid,
            'remaining': total - paid,
            'status': _translateStatus(item['status'] ?? ''),
          }),
        );
      }

      return ReportData(
        type: ReportType.sales,
        fromDate: fromDate,
        toDate: toDate,
        data: {
          'invoices': response,
          'columns': [
            const ReportColumn(key: 'invoice_number', label: 'رقم الفاتورة'),
            const ReportColumn(key: 'date', label: 'التاريخ'),
            const ReportColumn(key: 'customer_name', label: 'العميل'),
            const ReportColumn(key: 'salesperson', label: 'البائع'),
            const ReportColumn(key: 'subtotal', label: 'المجموع الفرعي'),
            const ReportColumn(key: 'discount', label: 'الخصم'),
            const ReportColumn(key: 'tax', label: 'الضريبة'),
            const ReportColumn(key: 'total', label: 'الإجمالي'),
            const ReportColumn(key: 'paid', label: 'المدفوع'),
            const ReportColumn(key: 'remaining', label: 'المتبقي'),
            const ReportColumn(key: 'status', label: 'الحالة'),
          ],
        },
        rows: rows,
        summary: {
          'total_invoices': totalInvoices,
          'total_sales': totalSales,
          'total_discount': totalDiscount,
          'total_tax': totalTax,
          'total_paid': totalPaid,
          'total_remaining': totalSales - totalPaid,
          'average_invoice': totalInvoices > 0 ? totalSales / totalInvoices : 0,
        },
      );
    } catch (e) {
      debugPrint('❌ Error generating sales report: $e');
      throw Exception('خطأ في إنشاء تقرير المبيعات: $e');
    }
  }

  // =============================================
  // ✅ CUSTOMERS REPORT
  // =============================================
  Future<ReportData> getCustomersReport({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    try {
      debugPrint('📊 Generating customers report...');

      final customers = await _supabase
          .from('customers')
          .select('*')
          .order('name');

      final rows = <ReportRow>[];
      int totalCustomers = 0;
      int withPhone = 0;
      int withEmail = 0;

      for (var item in customers) {
        final id = item['id'];
        final phone = item['phone'] as String?;
        final email = item['email'] as String?;

        // Get customer's invoices in period
        final invoices = await _supabase
            .from('invoices')
            .select('total, status')
            .eq('customer_id', id)
            .inFilter('status', ['confirmed', 'completed'])
            .gte('date', fromDate.toIso8601String())
            .lte('date', toDate.toIso8601String());

        double totalPurchases = 0;
        for (var inv in invoices) {
          totalPurchases += _toDouble(inv['total']);
        }

        totalCustomers++;
        if (phone != null && phone.isNotEmpty) withPhone++;
        if (email != null && email.isNotEmpty) withEmail++;

        rows.add(
          ReportRow({
            'name': item['name'] ?? '',
            'phone': phone ?? '-',
            'email': email ?? '-',
            'country': item['country'] ?? '-',
            'address': item['address'] ?? '-',
            'invoices_count': invoices.length,
            'total_purchases': totalPurchases,
          }),
        );
      }

      return ReportData(
        type: ReportType.customers,
        fromDate: fromDate,
        toDate: toDate,
        data: {
          'customers': customers,
          'columns': [
            const ReportColumn(key: 'name', label: 'الاسم'),
            const ReportColumn(key: 'phone', label: 'الهاتف'),
            const ReportColumn(key: 'email', label: 'البريد'),
            const ReportColumn(key: 'country', label: 'البلد'),
            const ReportColumn(key: 'invoices_count', label: 'عدد الفواتير'),
            const ReportColumn(
              key: 'total_purchases',
              label: 'إجمالي المشتريات',
            ),
          ],
        },
        rows: rows,
        summary: {
          'total_customers': totalCustomers,
          'with_phone': withPhone,
          'with_email': withEmail,
        },
      );
    } catch (e) {
      debugPrint('❌ Error generating customers report: $e');
      throw Exception('خطأ في إنشاء تقرير العملاء: $e');
    }
  }

  // =============================================
  // ✅ INVENTORY REPORT
  // =============================================
  Future<ReportData> getInventoryReport({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    try {
      debugPrint('📊 Generating inventory report...');

      final products = await _supabase
          .from('products')
          .select('*')
          .order('name');

      final rows = <ReportRow>[];
      int totalProducts = 0;
      int lowStock = 0;
      int outOfStock = 0;
      double totalValue = 0;

      for (var product in products) {
        final id = product['id'];
        final price = _toDouble(product['price']);
        final cost = _toDouble(product['cost']);

        // Get stock
        final stockResponse = await _supabase
            .from('warehouse_stock')
            .select('quantity, warehouse:warehouses(name)')
            .eq('product_id', id);

        int totalQuantity = 0;
        final warehouseDetails = <String>[];

        for (var s in stockResponse) {
          final qty = (s['quantity'] ?? 0) as int;
          totalQuantity += qty;
          final wh = s['warehouse'] as Map<String, dynamic>?;
          if (wh != null && qty > 0) {
            warehouseDetails.add('${wh['name']}: $qty');
          }
        }

        if (totalQuantity == 0) outOfStock++;
        if (totalQuantity > 0 && totalQuantity <= 10) lowStock++;

        final stockValue = totalQuantity * (cost > 0 ? cost : price);
        totalValue += stockValue;
        totalProducts++;

        rows.add(
          ReportRow({
            'name': product['name'] ?? '',
            'category': product['category'] ?? '-',
            'brand': product['brand'] ?? '-',
            'price': price,
            'cost': cost,
            'quantity': totalQuantity,
            'stock_value': stockValue,
            'warehouses': warehouseDetails.join(' | '),
            'status': totalQuantity == 0
                ? 'نفذ المخزون'
                : totalQuantity <= 10
                ? 'مخزون منخفض'
                : 'متوفر',
          }),
        );
      }

      return ReportData(
        type: ReportType.inventory,
        fromDate: fromDate,
        toDate: toDate,
        data: {
          'products': products,
          'columns': [
            const ReportColumn(key: 'name', label: 'المنتج'),
            const ReportColumn(key: 'category', label: 'التصنيف'),
            const ReportColumn(key: 'brand', label: 'الماركة'),
            const ReportColumn(key: 'price', label: 'السعر'),
            const ReportColumn(key: 'cost', label: 'التكلفة'),
            const ReportColumn(key: 'quantity', label: 'الكمية'),
            const ReportColumn(key: 'stock_value', label: 'قيمة المخزون'),
            const ReportColumn(key: 'status', label: 'الحالة'),
          ],
        },
        rows: rows,
        summary: {
          'total_products': totalProducts,
          'low_stock': lowStock,
          'out_of_stock': outOfStock,
          'total_stock_value': totalValue,
        },
      );
    } catch (e) {
      debugPrint('❌ Error generating inventory report: $e');
      throw Exception('خطأ في إنشاء تقرير المخزون: $e');
    }
  }

  // =============================================
  // ✅ PRODUCTS REPORT (Best Sellers)
  // =============================================
  Future<ReportData> getProductsReport({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    try {
      debugPrint('📊 Generating products report...');

      final response = await _supabase
          .from('invoice_items')
          .select('''
            product_id,
            quantity,
            unit_price,
            total,
            product:products(name, category),
            invoice:invoices!inner(date, status)
          ''')
          .gte('invoice.date', fromDate.toIso8601String())
          .lte('invoice.date', toDate.toIso8601String())
          .inFilter('invoice.status', ['confirmed', 'completed']);

      // Aggregate by product
      final Map<String, Map<String, dynamic>> productStats = {};

      for (var item in response) {
        final productId = item['product_id'] as String;
        final quantity = (item['quantity'] ?? 0) as int;
        final total = _toDouble(item['total']);
        final product = item['product'] as Map<String, dynamic>?;

        productStats.putIfAbsent(
          productId,
          () => {
            'name': product?['name'] ?? 'غير معروف',
            'category': product?['category'] ?? '-',
            'quantity': 0,
            'revenue': 0.0,
            'orders': 0,
          },
        );

        productStats[productId]!['quantity'] =
            (productStats[productId]!['quantity'] as int) + quantity;
        productStats[productId]!['revenue'] =
            (productStats[productId]!['revenue'] as double) + total;
        productStats[productId]!['orders'] =
            (productStats[productId]!['orders'] as int) + 1;
      }

      // Sort by revenue
      final sortedProducts = productStats.values.toList()
        ..sort(
          (a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double),
        );

      final rows = sortedProducts.map((p) {
        return ReportRow({
          'name': p['name'],
          'category': p['category'],
          'quantity': p['quantity'],
          'orders': p['orders'],
          'revenue': p['revenue'],
          'average_price': (p['quantity'] as int) > 0
              ? (p['revenue'] as double) / (p['quantity'] as int)
              : 0.0,
        });
      }).toList();

      double totalRevenue = sortedProducts.fold(
        0.0,
        (sum, p) => sum + (p['revenue'] as double),
      );
      int totalQuantity = sortedProducts.fold(
        0,
        (sum, p) => sum + (p['quantity'] as int),
      );

      return ReportData(
        type: ReportType.products,
        fromDate: fromDate,
        toDate: toDate,
        data: {
          'products': sortedProducts,
          'columns': [
            const ReportColumn(key: 'name', label: 'المنتج'),
            const ReportColumn(key: 'category', label: 'التصنيف'),
            const ReportColumn(key: 'quantity', label: 'الكمية المباعة'),
            const ReportColumn(key: 'orders', label: 'عدد الطلبات'),
            const ReportColumn(key: 'average_price', label: 'متوسط السعر'),
            const ReportColumn(key: 'revenue', label: 'الإيرادات'),
          ],
        },
        rows: rows,
        summary: {
          'total_products': sortedProducts.length,
          'total_quantity': totalQuantity,
          'total_revenue': totalRevenue,
        },
      );
    } catch (e) {
      debugPrint('❌ Error generating products report: $e');
      throw Exception('خطأ في إنشاء تقرير المنتجات: $e');
    }
  }

  // =============================================
  // ✅ ATTENDANCE REPORT
  // =============================================
  Future<ReportData> getAttendanceReport({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    try {
      debugPrint('📊 Generating attendance report...');

      final response = await _supabase
          .from('attendance')
          .select('''
            *,
            user:users(name, email)
          ''')
          .gte('check_in', fromDate.toIso8601String())
          .lte('check_in', toDate.toIso8601String())
          .order('check_in', ascending: false);

      final rows = <ReportRow>[];
      int present = 0;
      int late = 0;
      int onLeave = 0;
      int totalMinutes = 0;

      for (var item in response) {
        final status = item['status'] ?? 'present';
        final user = item['user'] as Map<String, dynamic>?;

        final checkIn = item['check_in'] != null
            ? DateTime.parse(item['check_in'])
            : null;
        final checkOut = item['check_out'] != null
            ? DateTime.parse(item['check_out'])
            : null;

        int workMinutes = 0;
        if (checkIn != null && checkOut != null) {
          workMinutes = checkOut.difference(checkIn).inMinutes;
          totalMinutes += workMinutes;
        }

        if (status == 'present') present++;
        if (status == 'late') late++;
        if (status == 'on_leave') onLeave++;

        rows.add(
          ReportRow({
            'employee_name': user?['name'] ?? 'غير معروف',
            'employee_email': user?['email'] ?? '',
            'date': checkIn != null ? _formatDate(checkIn) : '-',
            'check_in': checkIn != null ? _formatTime(checkIn) : '-',
            'check_out': checkOut != null ? _formatTime(checkOut) : '-',
            'work_hours': workMinutes > 0
                ? '${(workMinutes / 60).toStringAsFixed(1)} س'
                : '-',
            'status': _translateAttendanceStatus(status),
          }),
        );
      }

      final total = response.length;
      final attendanceRate = total > 0 ? (present / total * 100) : 0.0;
      final avgHours = total > 0 ? (totalMinutes / total / 60) : 0.0;

      return ReportData(
        type: ReportType.attendance,
        fromDate: fromDate,
        toDate: toDate,
        data: {
          'attendance': response,
          'columns': [
            const ReportColumn(key: 'employee_name', label: 'الموظف'),
            const ReportColumn(key: 'date', label: 'التاريخ'),
            const ReportColumn(key: 'check_in', label: 'الحضور'),
            const ReportColumn(key: 'check_out', label: 'الانصراف'),
            const ReportColumn(key: 'work_hours', label: 'ساعات العمل'),
            const ReportColumn(key: 'status', label: 'الحالة'),
          ],
        },
        rows: rows,
        summary: {
          'total_records': total,
          'present': present,
          'late': late,
          'on_leave': onLeave,
          'attendance_rate': attendanceRate,
          'average_hours': avgHours,
        },
      );
    } catch (e) {
      debugPrint('❌ Error generating attendance report: $e');
      throw Exception('خطأ في إنشاء تقرير الحضور: $e');
    }
  }

  // =============================================
  // ✅ PROFIT REPORT
  // =============================================
  Future<ReportData> getProfitReport({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    try {
      debugPrint('📊 Generating profit report...');

      final response = await _supabase
          .from('invoice_items')
          .select('''
            quantity,
            unit_price,
            total,
            product:products(name, cost, price, category),
            invoice:invoices!inner(date, status, invoice_number)
          ''')
          .gte('invoice.date', fromDate.toIso8601String())
          .lte('invoice.date', toDate.toIso8601String())
          .inFilter('invoice.status', ['confirmed', 'completed']);

      final rows = <ReportRow>[];
      double totalRevenue = 0;
      double totalCost = 0;

      for (var item in response) {
        final quantity = (item['quantity'] ?? 0) as int;
        final total = _toDouble(item['total']);
        final product = item['product'] as Map<String, dynamic>?;
        final invoice = item['invoice'] as Map<String, dynamic>?;

        final cost = _toDouble(product?['cost']);
        final itemCost = cost * quantity;
        final profit = total - itemCost;

        totalRevenue += total;
        totalCost += itemCost;

        rows.add(
          ReportRow({
            'invoice_number': invoice?['invoice_number'] ?? '',
            'date': invoice?['date'] != null
                ? _formatDate(DateTime.parse(invoice!['date']))
                : '-',
            'product_name': product?['name'] ?? 'غير معروف',
            'category': product?['category'] ?? '-',
            'quantity': quantity,
            'revenue': total,
            'cost': itemCost,
            'profit': profit,
            'profit_margin': total > 0 ? (profit / total * 100) : 0.0,
          }),
        );
      }

      final totalProfit = totalRevenue - totalCost;
      final profitMargin = totalRevenue > 0
          ? (totalProfit / totalRevenue * 100)
          : 0.0;

      return ReportData(
        type: ReportType.profit,
        fromDate: fromDate,
        toDate: toDate,
        data: {
          'items': response,
          'columns': [
            const ReportColumn(key: 'invoice_number', label: 'الفاتورة'),
            const ReportColumn(key: 'date', label: 'التاريخ'),
            const ReportColumn(key: 'product_name', label: 'المنتج'),
            const ReportColumn(key: 'quantity', label: 'الكمية'),
            const ReportColumn(key: 'revenue', label: 'الإيرادات'),
            const ReportColumn(key: 'cost', label: 'التكلفة'),
            const ReportColumn(key: 'profit', label: 'الربح'),
            const ReportColumn(key: 'profit_margin', label: 'هامش الربح'),
          ],
        },
        rows: rows,
        summary: {
          'total_revenue': totalRevenue,
          'total_cost': totalCost,
          'total_profit': totalProfit,
          'profit_margin': profitMargin,
        },
      );
    } catch (e) {
      debugPrint('❌ Error generating profit report: $e');
      throw Exception('خطأ في إنشاء تقرير الأرباح: $e');
    }
  }

  // =============================================
  // ✅ QUOTATIONS REPORT
  // =============================================
  Future<ReportData> getQuotationsReport({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    try {
      debugPrint('📊 Generating quotations report...');

      final response = await _supabase
          .from('invoices')
          .select('''
            id,
            invoice_number,
            date,
            valid_until,
            total,
            status,
            customer:customers(name, phone)
          ''')
          .eq('status', 'quotation')
          .gte('date', fromDate.toIso8601String())
          .lte('date', toDate.toIso8601String())
          .order('date', ascending: false);

      final rows = <ReportRow>[];
      double totalValue = 0;
      int valid = 0;
      int expired = 0;

      for (var item in response) {
        final total = _toDouble(item['total']);
        final customer = item['customer'] as Map<String, dynamic>?;
        final validUntil = item['valid_until'] != null
            ? DateTime.parse(item['valid_until'])
            : null;

        final isExpired =
            validUntil != null && validUntil.isBefore(DateTime.now());
        if (isExpired) {
          expired++;
        } else {
          valid++;
        }

        totalValue += total;

        rows.add(
          ReportRow({
            'invoice_number': item['invoice_number'] ?? '',
            'date': _formatDate(DateTime.parse(item['date'])),
            'customer_name': customer?['name'] ?? 'غير معروف',
            'customer_phone': customer?['phone'] ?? '-',
            'total': total,
            'valid_until': validUntil != null ? _formatDate(validUntil) : '-',
            'status': isExpired ? 'منتهي' : 'صالح',
          }),
        );
      }

      return ReportData(
        type: ReportType.quotations,
        fromDate: fromDate,
        toDate: toDate,
        data: {
          'quotations': response,
          'columns': [
            const ReportColumn(key: 'invoice_number', label: 'الرقم'),
            const ReportColumn(key: 'date', label: 'التاريخ'),
            const ReportColumn(key: 'customer_name', label: 'العميل'),
            const ReportColumn(key: 'total', label: 'القيمة'),
            const ReportColumn(key: 'valid_until', label: 'صالح حتى'),
            const ReportColumn(key: 'status', label: 'الحالة'),
          ],
        },
        rows: rows,
        summary: {
          'total_quotations': response.length,
          'valid': valid,
          'expired': expired,
          'total_value': totalValue,
        },
      );
    } catch (e) {
      debugPrint('❌ Error generating quotations report: $e');
      throw Exception('خطأ في إنشاء تقرير عروض الأسعار: $e');
    }
  }

  // =============================================
  // ✅ HELPER METHODS
  // =============================================
  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _translateStatus(String status) {
    const map = {
      'quotation': 'عرض سعر',
      'draft': 'مسودة',
      'confirmed': 'مؤكدة',
      'completed': 'مكتملة',
      'cancelled': 'ملغية',
      'pending': 'معلقة',
      'returned': 'مرتجعة',
      'expired': 'منتهي',
    };
    return map[status.toLowerCase()] ?? status;
  }

  String _translateAttendanceStatus(String status) {
    const map = {
      'present': 'حاضر',
      'late': 'متأخر',
      'absent': 'غائب',
      'on_leave': 'في إجازة',
    };
    return map[status.toLowerCase()] ?? status;
  }
}
