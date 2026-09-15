// lib/data/repositories/warehouse_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/warehouse.dart';
import '../models/warehouse_stock.dart';
import '../models/stock_movement.dart';

class WarehouseRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ==================== المخازن ====================

  // جلب جميع المخازن
  Future<List<Warehouse>> getAllWarehouses() async {
    try {
      final response = await _supabase
          .from('warehouses')
          .select('*')
          .order('name');

      return List<Warehouse>.from(
        response.map((json) => Warehouse.fromJson(json)),
      );
    } catch (e) {
      throw Exception('خطأ في جلب المخازن: $e');
    }
  }

  // جلب المخازن النشطة
  Future<List<Warehouse>> getActiveWarehouses() async {
    try {
      final response = await _supabase
          .from('warehouses')
          .select('*')
          .eq('is_active', true)
          .order('name');

      return List<Warehouse>.from(
        response.map((json) => Warehouse.fromJson(json)),
      );
    } catch (e) {
      throw Exception('خطأ في جلب المخازن النشطة: $e');
    }
  }

  // جلب مخزن بالـ ID
  Future<Warehouse?> getWarehouseById(String id) async {
    try {
      final response = await _supabase
          .from('warehouses')
          .select('*')
          .eq('id', id)
          .maybeSingle();

      if (response != null) {
        return Warehouse.fromJson(response);
      }
      return null;
    } catch (e) {
      throw Exception('خطأ في جلب بيانات المخزن: $e');
    }
  }

  // إضافة مخزن جديد
  Future<Warehouse> createWarehouse(Warehouse warehouse) async {
    try {
      final response = await _supabase
          .from('warehouses')
          .insert(warehouse.toJson())
          .select()
          .single();

      return Warehouse.fromJson(response);
    } catch (e) {
      throw Exception('خطأ في إضافة المخزن: $e');
    }
  }

  // تحديث مخزن
  Future<Warehouse> updateWarehouse(Warehouse warehouse) async {
    try {
      if (warehouse.id == null) {
        throw Exception('معرف المخزن مطلوب للتحديث');
      }

      final response = await _supabase
          .from('warehouses')
          .update(warehouse.toJson())
          .eq('id', warehouse.id!)
          .select()
          .single();

      return Warehouse.fromJson(response);
    } catch (e) {
      throw Exception('خطأ في تحديث المخزن: $e');
    }
  }

  // حذف مخزن
  Future<void> deleteWarehouse(String id) async {
    try {
      await _supabase.from('warehouses').delete().eq('id', id);
    } catch (e) {
      throw Exception('خطأ في حذف المخزن: $e');
    }
  }

  // ==================== مخزون المنتجات ====================

  // جلب مخزون جميع المنتجات في مخزن معين
  Future<List<WarehouseStock>> getWarehouseStock(String warehouseId) async {
    try {
      final response = await _supabase
          .from('warehouse_stock')
          .select('''
            *,
            product:products(*),
            warehouse:warehouses(*)
          ''')
          .eq('warehouse_id', warehouseId)
          .order('quantity');

      return List<WarehouseStock>.from(
        response.map((json) => WarehouseStock.fromJson(json)),
      );
    } catch (e) {
      throw Exception('خطأ في جلب مخزون المخزن: $e');
    }
  }

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

  // جلب إجمالي مخزون منتج
  Future<int> getTotalProductStock(String productId) async {
    try {
      final response = await _supabase
          .from('warehouse_stock')
          .select('quantity')
          .eq('product_id', productId);

      int total = 0;
      for (var item in response) {
        total += (item['quantity'] ?? 0) as int;
      }
      return total;
    } catch (e) {
      throw Exception('خطأ في جلب إجمالي مخزون المنتج: $e');
    }
  }

  // تحديث كمية منتج في مخزن
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

  // ==================== حركات المخزون ====================

  // تسجيل حركة مخزون
  Future<StockMovement> createMovement(StockMovement movement) async {
    try {
      final response = await _supabase
          .from('stock_movements')
          .insert(movement.toJson())
          .select()
          .single();

      // تحديث الكمية في warehouse_stock
      final currentStock = await _supabase
          .from('warehouse_stock')
          .select('*')
          .eq('product_id', movement.productId)
          .eq('warehouse_id', movement.warehouseId)
          .maybeSingle();

      int newQuantity = 0;
      if (movement.type == 'in') {
        newQuantity = (currentStock?['quantity'] ?? 0) + movement.quantity;
      } else if (movement.type == 'out') {
        newQuantity = (currentStock?['quantity'] ?? 0) - movement.quantity;
        if (newQuantity < 0) {
          throw Exception('الكمية غير متوفرة في المخزون');
        }
      }

      await updateStock(movement.productId, movement.warehouseId, newQuantity);

      return StockMovement.fromJson(response);
    } catch (e) {
      throw Exception('خطأ في تسجيل حركة المخزون: $e');
    }
  }

  // جلب حركات المخزون لمنتج معين
  Future<List<StockMovement>> getProductMovements(String productId) async {
    try {
      final response = await _supabase
          .from('stock_movements')
          .select('*')
          .eq('product_id', productId)
          .order('created_at', ascending: false);

      return List<StockMovement>.from(
        response.map((json) => StockMovement.fromJson(json)),
      );
    } catch (e) {
      throw Exception('خطأ في جلب حركات المخزون: $e');
    }
  }

  // جلب حركات المخزون لمخزن معين
  Future<List<StockMovement>> getWarehouseMovements(String warehouseId) async {
    try {
      final response = await _supabase
          .from('stock_movements')
          .select('*')
          .eq('warehouse_id', warehouseId)
          .order('created_at', ascending: false);

      return List<StockMovement>.from(
        response.map((json) => StockMovement.fromJson(json)),
      );
    } catch (e) {
      throw Exception('خطأ في جلب حركات المخزون: $e');
    }
  }

  // ==================== إحصائيات ====================

  // جلب إحصائيات المخزن
  Future<Map<String, dynamic>> getWarehouseStats(String warehouseId) async {
    try {
      final stock = await getWarehouseStock(warehouseId);

      int totalItems = stock.length;
      int totalQuantity = 0;
      int lowStock = 0;
      int outOfStock = 0;

      for (var item in stock) {
        totalQuantity += item.quantity;
        if (item.isOutOfStock) outOfStock++;
        if (item.isLowStock) lowStock++;
      }

      return {
        'total_items': totalItems,
        'total_quantity': totalQuantity,
        'low_stock': lowStock,
        'out_of_stock': outOfStock,
      };
    } catch (e) {
      throw Exception('خطأ في جلب إحصائيات المخزن: $e');
    }
  }
}
