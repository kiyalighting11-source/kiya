// lib/data/models/stock_movement.dart

import 'package:flutter/material.dart';

class StockMovement {
  final String? id;
  final String productId;
  final String warehouseId;
  final String? fromWarehouseId;
  final String? toWarehouseId;
  final String type; // 'in', 'out', 'transfer'
  final int quantity;
  final String? reason;
  final String? reference;
  final String? userId;
  final DateTime? createdAt;

  StockMovement({
    this.id,
    required this.productId,
    required this.warehouseId,
    this.fromWarehouseId,
    this.toWarehouseId,
    required this.type,
    required this.quantity,
    this.reason,
    this.reference,
    this.userId,
    this.createdAt,
  });

  factory StockMovement.fromJson(Map<String, dynamic> json) {
    return StockMovement(
      id: json['id'],
      productId: json['product_id'] ?? '',
      warehouseId: json['warehouse_id'] ?? '',
      fromWarehouseId: json['from_warehouse_id'],
      toWarehouseId: json['to_warehouse_id'],
      type: json['type'] ?? 'in',
      quantity: json['quantity'] ?? 0,
      reason: json['reason'],
      reference: json['reference'],
      userId: json['user_id'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'warehouse_id': warehouseId,
      'from_warehouse_id': fromWarehouseId,
      'to_warehouse_id': toWarehouseId,
      'type': type,
      'quantity': quantity,
      'reason': reason,
      'reference': reference,
      'user_id': userId,
    };
  }

  StockMovement copyWith({
    String? id,
    String? productId,
    String? warehouseId,
    String? fromWarehouseId,
    String? toWarehouseId,
    String? type,
    int? quantity,
    String? reason,
    String? reference,
    String? userId,
    DateTime? createdAt,
  }) {
    return StockMovement(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      warehouseId: warehouseId ?? this.warehouseId,
      fromWarehouseId: fromWarehouseId ?? this.fromWarehouseId,
      toWarehouseId: toWarehouseId ?? this.toWarehouseId,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      reason: reason ?? this.reason,
      reference: reference ?? this.reference,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ==================== GETTERS ====================

  String get typeLabel {
    switch (type) {
      case 'in':
        return 'وارد';
      case 'out':
        return 'صادر';
      case 'transfer':
        return 'تحويل';
      default:
        return type;
    }
  }

  Color get typeColor {
    switch (type) {
      case 'in':
        return Colors.green;
      case 'out':
        return Colors.red;
      case 'transfer':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData get typeIcon {
    switch (type) {
      case 'in':
        return Icons.arrow_downward;
      case 'out':
        return Icons.arrow_upward;
      case 'transfer':
        return Icons.swap_horiz;
      default:
        return Icons.circle;
    }
  }

  bool get isIn => type == 'in';
  bool get isOut => type == 'out';
  bool get isTransfer => type == 'transfer';

  String get quantityLabel {
    if (isIn) return '+$quantity';
    if (isOut) return '-$quantity';
    return quantity.toString();
  }

  Color get quantityColor {
    if (isIn) return Colors.green;
    if (isOut) return Colors.red;
    return Colors.blue;
  }

  String get movementDescription {
    switch (type) {
      case 'in':
        return 'إضافة إلى المخزون';
      case 'out':
        return 'صرف من المخزون';
      case 'transfer':
        return 'تحويل بين المخازن';
      default:
        return 'حركة مخزون';
    }
  }
}
