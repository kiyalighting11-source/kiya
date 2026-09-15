// lib/data/models/warehouse_stock.dart

import 'package:flutter/material.dart';

import 'product.dart';
import 'warehouse.dart';

class WarehouseStock {
  final String? id;
  final String productId;
  final String warehouseId;
  final int quantity;
  final int? minQuantity;
  final int? maxQuantity;
  final String? location;
  final Product? product;
  final Warehouse? warehouse;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  WarehouseStock({
    this.id,
    required this.productId,
    required this.warehouseId,
    required this.quantity,
    this.minQuantity,
    this.maxQuantity,
    this.location,
    this.product,
    this.warehouse,
    this.createdAt,
    this.updatedAt,
  });

  factory WarehouseStock.fromJson(Map<String, dynamic> json) {
    return WarehouseStock(
      id: json['id'],
      productId: json['product_id'] ?? '',
      warehouseId: json['warehouse_id'] ?? '',
      quantity: json['quantity'] ?? 0,
      minQuantity: json['min_quantity'],
      maxQuantity: json['max_quantity'],
      location: json['location'],
      product: json['product'] != null
          ? Product.fromJson(json['product'])
          : null,
      warehouse: json['warehouse'] != null
          ? Warehouse.fromJson(json['warehouse'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'warehouse_id': warehouseId,
      'quantity': quantity,
      'min_quantity': minQuantity,
      'max_quantity': maxQuantity,
      'location': location,
    };
  }

  WarehouseStock copyWith({
    String? id,
    String? productId,
    String? warehouseId,
    int? quantity,
    int? minQuantity,
    int? maxQuantity,
    String? location,
    Product? product,
    Warehouse? warehouse,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WarehouseStock(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      warehouseId: warehouseId ?? this.warehouseId,
      quantity: quantity ?? this.quantity,
      minQuantity: minQuantity ?? this.minQuantity,
      maxQuantity: maxQuantity ?? this.maxQuantity,
      location: location ?? this.location,
      product: product ?? this.product,
      warehouse: warehouse ?? this.warehouse,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ==================== GETTERS ====================

  bool get isLowStock => minQuantity != null && quantity <= minQuantity!;
  bool get isOutOfStock => quantity <= 0;
  bool get isOverStock => maxQuantity != null && quantity >= maxQuantity!;

  String get stockStatus {
    if (isOutOfStock) return 'نفذ المخزون';
    if (isLowStock) return 'مخزون منخفض';
    if (isOverStock) return 'مخزون زائد';
    return 'متوفر';
  }

  Color get stockStatusColor {
    if (isOutOfStock) return Colors.red;
    if (isLowStock) return Colors.orange;
    if (isOverStock) return Colors.purple;
    return Colors.green;
  }

  String get formattedQuantity {
    if (quantity >= 1000) {
      return '${(quantity / 1000).toStringAsFixed(1)}k';
    }
    return quantity.toString();
  }

  bool get hasStock => quantity > 0;
  bool get isAvailable => quantity > 0;

  // نسبة المخزون مقارنة بالحد الأقصى
  double get stockPercentage {
    if (maxQuantity == null || maxQuantity! <= 0) return 0;
    return (quantity / maxQuantity!) * 100;
  }

  // عدد الأيام المتوقعة لنفاذ المخزون (تقريبي)
  int get estimatedDaysToEmpty {
    // هذا مجرد تقدير، يحتاج إلى بيانات المبيعات الفعلية
    return 0;
  }
}
