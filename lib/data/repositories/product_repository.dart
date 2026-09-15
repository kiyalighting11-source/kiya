// lib/data/repositories/product_repository.dart

import 'package:flutter/foundation.dart'; // ✅ أضف هذا السطر
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product.dart';
import '../models/warehouse_stock.dart';

class ProductRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  final String _table = 'products';

  // ==================== GET PRODUCTS WITH STOCK ====================

  // جلب جميع المنتجات مع الكميات من المخازن
  Future<List<Map<String, dynamic>>> getAllProductsWithStock() async {
    try {
      // جلب المنتجات
      final products = await _supabase.from(_table).select('*').order('name');

      final List<Map<String, dynamic>> result = [];

      for (var product in products) {
        // جلب مخزون المنتج من warehouse_stock
        final stockResponse = await _supabase
            .from('warehouse_stock')
            .select('''
              quantity,
              warehouse:warehouses(id, name, code, location)
            ''')
            .eq('product_id', product['id']);

        // حساب إجمالي الكمية
        int totalQuantity = 0;
        final List<Map<String, dynamic>> warehouseStock = [];

        for (var stock in stockResponse) {
          final quantity = stock['quantity'] as int? ?? 0;
          totalQuantity += quantity;

          if (stock['warehouse'] != null) {
            warehouseStock.add({
              'quantity': quantity,
              'warehouse': stock['warehouse'],
            });
          }
        }

        result.add({
          'product': Product.fromJson(product),
          'total_quantity': totalQuantity,
          'warehouse_stock': warehouseStock,
        });
      }

      return result;
    } catch (e) {
      throw Exception('خطأ في جلب المنتجات مع المخزون: $e');
    }
  }

  // جلب منتج معين مع كمياته في المخازن
  Future<Map<String, dynamic>> getProductWithStock(String productId) async {
    try {
      // جلب المنتج
      final productResponse = await _supabase
          .from(_table)
          .select('*')
          .eq('id', productId)
          .maybeSingle();

      if (productResponse == null) {
        throw Exception('المنتج غير موجود');
      }

      // جلب مخزون المنتج
      final stockResponse = await _supabase
          .from('warehouse_stock')
          .select('''
            quantity,
            warehouse:warehouses(id, name, code, location)
          ''')
          .eq('product_id', productId);

      // حساب إجمالي الكمية
      int totalQuantity = 0;
      final List<Map<String, dynamic>> warehouseStock = [];

      for (var stock in stockResponse) {
        final quantity = stock['quantity'] as int? ?? 0;
        totalQuantity += quantity;

        if (stock['warehouse'] != null) {
          warehouseStock.add({
            'quantity': quantity,
            'warehouse': stock['warehouse'],
          });
        }
      }

      return {
        'product': Product.fromJson(productResponse),
        'total_quantity': totalQuantity,
        'warehouse_stock': warehouseStock,
      };
    } catch (e) {
      throw Exception('خطأ في جلب المنتج مع المخزون: $e');
    }
  }

  // ==================== BASIC CRUD ====================

  // جلب جميع المنتجات (بدون مخزون)
  Future<List<Product>> getAllProducts() async {
    try {
      final response = await _supabase.from(_table).select('*').order('name');

      return List<Product>.from(response.map((json) => Product.fromJson(json)));
    } catch (e) {
      throw Exception('خطأ في جلب المنتجات: $e');
    }
  }

  // جلب المنتجات النشطة فقط
  Future<List<Product>> getActiveProducts() async {
    try {
      final response = await _supabase
          .from(_table)
          .select('*')
          .eq('is_active', true)
          .order('name');

      return List<Product>.from(response.map((json) => Product.fromJson(json)));
    } catch (e) {
      throw Exception('خطأ في جلب المنتجات النشطة: $e');
    }
  }

  // جلب المنتجات حسب التصنيف
  Future<List<Product>> getProductsByCategory(String category) async {
    try {
      final response = await _supabase
          .from(_table)
          .select('*')
          .eq('category', category)
          .eq('is_active', true)
          .order('name');

      return List<Product>.from(response.map((json) => Product.fromJson(json)));
    } catch (e) {
      throw Exception('خطأ في جلب المنتجات حسب التصنيف: $e');
    }
  }

  // جلب المنتجات المخفضة
  Future<List<Product>> getDiscountedProducts() async {
    try {
      final response = await _supabase
          .from(_table)
          .select('*')
          .eq('has_discount', true)
          .eq('is_active', true)
          .order('name');

      return List<Product>.from(response.map((json) => Product.fromJson(json)));
    } catch (e) {
      throw Exception('خطأ في جلب المنتجات المخفضة: $e');
    }
  }

  // جلب منتج واحد بالـ ID
  Future<Product?> getProductById(String id) async {
    try {
      final response = await _supabase
          .from(_table)
          .select('*')
          .eq('id', id)
          .maybeSingle();

      if (response != null) {
        return Product.fromJson(response);
      }
      return null;
    } catch (e) {
      throw Exception('خطأ في جلب بيانات المنتج: $e');
    }
  }

  // إضافة منتج جديد
  Future<Product> createProduct(Product product) async {
    try {
      final response = await _supabase
          .from(_table)
          .insert(product.toJson())
          .select()
          .single();

      return Product.fromJson(response);
    } catch (e) {
      throw Exception('خطأ في إضافة المنتج: $e');
    }
  }

  // تحديث بيانات منتج
  Future<Product> updateProduct(Product product) async {
    try {
      if (product.id == null) {
        throw Exception('معرف المنتج مطلوب للتحديث');
      }

      final response = await _supabase
          .from(_table)
          .update(product.toJson())
          .eq('id', product.id!)
          .select()
          .single();

      return Product.fromJson(response);
    } catch (e) {
      throw Exception('خطأ في تحديث بيانات المنتج: $e');
    }
  }

  // حذف منتج
  Future<void> deleteProduct(String id) async {
    try {
      // حذف المنتج من warehouse_stock أولاً
      await _supabase.from('warehouse_stock').delete().eq('product_id', id);

      // ثم حذف المنتج
      await _supabase.from(_table).delete().eq('id', id);
    } catch (e) {
      throw Exception('خطأ في حذف المنتج: $e');
    }
  }

  // ==================== SEARCH ====================

  // البحث عن منتج
  Future<List<Product>> searchProducts(String query) async {
    try {
      final response = await _supabase
          .from(_table)
          .select('*')
          .ilike('name', '%$query%')
          .order('name');

      return List<Product>.from(response.map((json) => Product.fromJson(json)));
    } catch (e) {
      throw Exception('خطأ في البحث عن المنتجات: $e');
    }
  }

  // البحث عن منتج مع المخزون
  Future<List<Map<String, dynamic>>> searchProductsWithStock(
    String query,
  ) async {
    try {
      final products = await _supabase
          .from(_table)
          .select('*')
          .ilike('name', '%$query%')
          .order('name');

      final List<Map<String, dynamic>> result = [];

      for (var product in products) {
        final stockResponse = await _supabase
            .from('warehouse_stock')
            .select('''
              quantity,
              warehouse:warehouses(id, name, code, location)
            ''')
            .eq('product_id', product['id']);

        int totalQuantity = 0;
        final List<Map<String, dynamic>> warehouseStock = [];

        for (var stock in stockResponse) {
          final quantity = stock['quantity'] as int? ?? 0;
          totalQuantity += quantity;

          if (stock['warehouse'] != null) {
            warehouseStock.add({
              'quantity': quantity,
              'warehouse': stock['warehouse'],
            });
          }
        }

        result.add({
          'product': Product.fromJson(product),
          'total_quantity': totalQuantity,
          'warehouse_stock': warehouseStock,
        });
      }

      return result;
    } catch (e) {
      throw Exception('خطأ في البحث عن المنتجات مع المخزون: $e');
    }
  }

  // ==================== CATEGORIES ====================

  // جلب التصنيفات
  Future<List<String>> getCategories() async {
    try {
      final response = await _supabase
          .from(_table)
          .select('category')
          .eq('is_active', true)
          .not('category', 'is', null);

      final categories = <String>{};
      for (var item in response) {
        if (item['category'] != null) {
          categories.add(item['category'].toString());
        }
      }
      return categories.toList()..sort();
    } catch (e) {
      throw Exception('خطأ في جلب التصنيفات: $e');
    }
  }

  // ==================== STOCK OPERATIONS ====================

  // جلب إجمالي المخزون الكلي
  Future<int> getTotalStock() async {
    try {
      final response = await _supabase
          .from('warehouse_stock')
          .select('quantity');

      int total = 0;
      for (var item in response) {
        total += (item['quantity'] as int? ?? 0);
      }
      return total;
    } catch (e) {
      throw Exception('خطأ في جلب إجمالي المخزون: $e');
    }
  }

  // جلب المنتجات منخفضة المخزون (مع المخزون)
  Future<List<Map<String, dynamic>>> getLowStockProducts(int threshold) async {
    try {
      final allProducts = await getAllProductsWithStock();

      return allProducts
          .where((item) => (item['total_quantity'] as int) <= threshold)
          .toList();
    } catch (e) {
      throw Exception('خطأ في جلب المنتجات منخفضة المخزون: $e');
    }
  }

  // جلب المنتجات التي نفذ مخزونها
  Future<List<Map<String, dynamic>>> getOutOfStockProducts() async {
    try {
      final allProducts = await getAllProductsWithStock();

      return allProducts
          .where((item) => (item['total_quantity'] as int) == 0)
          .toList();
    } catch (e) {
      throw Exception('خطأ في جلب المنتجات منتهية المخزون: $e');
    }
  }

  // ==================== STOCK MOVEMENTS ====================

  // إضافة مخزون لمنتج في مخزن معين
  Future<void> addStock(
    String productId,
    String warehouseId,
    int quantity, {
    String? reason,
  }) async {
    try {
      debugPrint('📦 محاولة إضافة مخزون:');
      debugPrint('   المنتج: $productId');
      debugPrint('   المخزن: $warehouseId');
      debugPrint('   الكمية: $quantity');

      // جلب المخزون الحالي
      final existing = await _supabase
          .from('warehouse_stock')
          .select('*')
          .eq('product_id', productId)
          .eq('warehouse_id', warehouseId)
          .maybeSingle();

      debugPrint('🔍 المخزون الحالي: $existing');

      int newQuantity = quantity;
      if (existing != null) {
        newQuantity = (existing['quantity'] as int? ?? 0) + quantity;
        debugPrint('📝 تحديث الكمية إلى: $newQuantity');

        await _supabase
            .from('warehouse_stock')
            .update({'quantity': newQuantity})
            .eq('id', existing['id']);
      } else {
        debugPrint('📝 إضافة سجل جديد');

        await _supabase.from('warehouse_stock').insert({
          'product_id': productId,
          'warehouse_id': warehouseId,
          'quantity': quantity,
        });
      }

      // تسجيل حركة المخزون
      await _supabase.from('stock_movements').insert({
        'product_id': productId,
        'warehouse_id': warehouseId,
        'type': 'in',
        'quantity': quantity,
        'reason': reason ?? 'إضافة مخزون',
      });

      debugPrint('✅ تم إضافة المخزون بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في إضافة المخزون: $e');
      throw Exception('خطأ في إضافة المخزون: $e');
    }
  }

  // خصم مخزون من منتج في مخزن معين
  Future<void> removeStock(
    String productId,
    String warehouseId,
    int quantity, {
    String? reason,
  }) async {
    try {
      // جلب المخزون الحالي
      final existing = await _supabase
          .from('warehouse_stock')
          .select('*')
          .eq('product_id', productId)
          .eq('warehouse_id', warehouseId)
          .maybeSingle();

      if (existing == null) {
        throw Exception('المنتج غير موجود في هذا المخزن');
      }

      final currentQuantity = existing['quantity'] as int? ?? 0;
      if (currentQuantity < quantity) {
        throw Exception('الكمية غير متوفرة في المخزون');
      }

      final newQuantity = currentQuantity - quantity;
      await _supabase
          .from('warehouse_stock')
          .update({'quantity': newQuantity})
          .eq('id', existing['id']);

      // تسجيل حركة المخزون
      await _supabase.from('stock_movements').insert({
        'product_id': productId,
        'warehouse_id': warehouseId,
        'type': 'out',
        'quantity': quantity,
        'reason': reason ?? 'صرف مخزون',
      });
    } catch (e) {
      throw Exception('خطأ في خصم المخزون: $e');
    }
  }

  // تحويل مخزون بين مخازن
  Future<void> transferStock(
    String productId,
    String fromWarehouseId,
    String toWarehouseId,
    int quantity, {
    String? reason,
  }) async {
    try {
      // خصم من المخزن المصدر
      await removeStock(
        productId,
        fromWarehouseId,
        quantity,
        reason: 'تحويل إلى مخزن آخر',
      );

      // إضافة إلى المخزن الهدف
      await addStock(
        productId,
        toWarehouseId,
        quantity,
        reason: 'تحويل من مخزن آخر',
      );

      // تسجيل حركة التحويل
      await _supabase.from('stock_movements').insert({
        'product_id': productId,
        'warehouse_id': fromWarehouseId,
        'from_warehouse_id': fromWarehouseId,
        'to_warehouse_id': toWarehouseId,
        'type': 'transfer',
        'quantity': quantity,
        'reason': reason ?? 'تحويل بين المخازن',
      });
    } catch (e) {
      throw Exception('خطأ في تحويل المخزون: $e');
    }
  }

  // ==================== GET PRODUCT STOCK ====================
  // جلب مخزون منتج معين في جميع المخازن
  Future<List<WarehouseStock>> getProductStock(String productId) async {
    try {
      final response = await _supabase
          .from('warehouse_stock')
          .select('''
            *,
            product:products(*),
            warehouse:warehouses(*)
          ''')
          .eq('product_id', productId);

      return List<WarehouseStock>.from(
        response.map((json) => WarehouseStock.fromJson(json)),
      );
    } catch (e) {
      throw Exception('خطأ في جلب مخزون المنتج: $e');
    }
  }

  // ==================== UPDATE STOCK ====================
  // تحديث كمية منتج في مخزن معين
  Future<WarehouseStock> updateStock(
    String productId,
    String warehouseId,
    int quantity,
  ) async {
    try {
      // البحث عن السجل
      final existing = await _supabase
          .from('warehouse_stock')
          .select('*')
          .eq('product_id', productId)
          .eq('warehouse_id', warehouseId)
          .maybeSingle();

      if (existing != null) {
        // تحديث السجل الموجود
        final response = await _supabase
            .from('warehouse_stock')
            .update({'quantity': quantity})
            .eq('id', existing['id'])
            .select()
            .single();

        return WarehouseStock.fromJson(response);
      } else {
        // إنشاء سجل جديد
        final response = await _supabase
            .from('warehouse_stock')
            .insert({
              'product_id': productId,
              'warehouse_id': warehouseId,
              'quantity': quantity,
            })
            .select()
            .single();

        return WarehouseStock.fromJson(response);
      }
    } catch (e) {
      throw Exception('خطأ في تحديث المخزون: $e');
    }
  }
}
