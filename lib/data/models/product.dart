// lib/data/models/product.dart

import 'package:flutter/material.dart';

class Product {
  final String? id;
  final String name;
  final String? description;
  final double price;
  final double? cost;
  final String? category;
  final String? sku;
  final String? barcode;
  final String? imageUrl;
  final List<String>? images;
  final String? brand;
  final bool? isActive;
  final bool? hasDiscount;
  final double? discountPercentage;
  final double? discountedPrice;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Product({
    this.id,
    required this.name,
    this.description,
    required this.price,
    this.cost,
    this.category,
    this.sku,
    this.barcode,
    this.imageUrl,
    this.images,
    this.brand,
    this.isActive,
    this.hasDiscount,
    this.discountPercentage,
    this.discountedPrice,
    this.createdAt,
    this.updatedAt,
  });

  // ==================== FROM JSON ====================
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'],
      price: (json['price'] ?? 0).toDouble(),
      cost: json['cost']?.toDouble(),
      category: json['category'],
      sku: json['sku'],
      barcode: json['barcode'],
      imageUrl: json['image_url'],
      images: json['images'] != null ? List<String>.from(json['images']) : null,
      brand: json['brand'],
      isActive: json['is_active'] ?? true,
      hasDiscount: json['has_discount'] ?? false,
      discountPercentage: json['discount_percentage']?.toDouble(),
      discountedPrice: json['discounted_price']?.toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  // ==================== TO JSON ====================
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'cost': cost,
      'category': category,
      'sku': sku,
      'barcode': barcode,
      'image_url': imageUrl,
      'images': images,
      'brand': brand,
      'is_active': isActive,
      'has_discount': hasDiscount,
      'discount_percentage': discountPercentage,
      'discounted_price': discountedPrice,
    };
  }

  // ==================== COPY WITH ====================
  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    double? cost,
    String? category,
    String? sku,
    String? barcode,
    String? imageUrl,
    List<String>? images,
    String? brand,
    bool? isActive,
    bool? hasDiscount,
    double? discountPercentage,
    double? discountedPrice,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      cost: cost ?? this.cost,
      category: category ?? this.category,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      imageUrl: imageUrl ?? this.imageUrl,
      images: images ?? this.images,
      brand: brand ?? this.brand,
      isActive: isActive ?? this.isActive,
      hasDiscount: hasDiscount ?? this.hasDiscount,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      discountedPrice: discountedPrice ?? this.discountedPrice,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ==================== GETTERS ====================

  // حساب السعر بعد الخصم
  double get finalPrice {
    if (hasDiscount == true && discountPercentage != null) {
      return price - (price * discountPercentage! / 100);
    }
    return price;
  }

  // تنسيق السعر الأصلي
  String get formattedPrice {
    return '\$${price.toStringAsFixed(2)}';
  }

  // تنسيق السعر بعد الخصم
  String get formattedFinalPrice {
    if (hasDiscount == true && discountPercentage != null) {
      return '\$${finalPrice.toStringAsFixed(2)}';
    }
    return formattedPrice;
  }

  // حساب قيمة الخصم
  double get discountAmount {
    if (hasDiscount == true && discountPercentage != null) {
      return price * discountPercentage! / 100;
    }
    return 0;
  }

  // تنسيق قيمة الخصم
  String get formattedDiscountAmount {
    return '\$${discountAmount.toStringAsFixed(2)}';
  }

  // حساب الربح
  double get profit {
    if (cost != null) {
      return finalPrice - cost!;
    }
    return 0;
  }

  // تنسيق الربح
  String get formattedProfit {
    return '\$${profit.toStringAsFixed(2)}';
  }

  // هامش الربح (نسبة مئوية)
  double get profitMargin {
    if (cost != null && cost! > 0) {
      return (profit / cost!) * 100;
    }
    return 0;
  }

  // تنسيق هامش الربح
  String get formattedProfitMargin {
    return '${profitMargin.toStringAsFixed(1)}%';
  }

  // التحقق من وجود مخزون (يتم حسابه من warehouse_stock)
  // ملاحظة: هذه الدوال أصبحت تعتمد على البيانات من warehouse_stock
  // ويتم استخدامها في الـ UI مع البيانات المجلوبة من warehouse_stock

  // ==================== STATIC METHODS ====================

  // قائمة التصنيفات المتاحة
  static List<String> getCategories() {
    return [
      'Beam Moving Head Light',
      'Led Screen (indoor)',
      'Led Screen (outdoor)',
      'truss',
      'COB',
      'Console',
      'Effect Light',
      'Laser Light',
      'LED Moving Head Light',
      'Outdoor Wall Washer',
      'Par Light',
      'Smoke Machine',
      'Strobe Light',
      'Theater Lighting',
      'Video Light',
    ];
  }

  // الماركة الافتراضية
  static String getDefaultBrand() {
    return 'Kiya Lighting';
  }

  // ==================== VALIDATION ====================

  // التحقق من صحة السعر
  static bool isValidPrice(double price) {
    return price > 0;
  }

  // التحقق من صحة نسبة الخصم
  static bool isValidDiscount(double? discount) {
    if (discount == null) return true;
    return discount >= 0 && discount <= 100;
  }

  // التحقق من صحة التصنيف
  static bool isValidCategory(String? category) {
    if (category == null) return true;
    return getCategories().contains(category);
  }

  // التحقق من صحة SKU
  static bool isValidSku(String? sku) {
    if (sku == null) return true;
    return sku.trim().isNotEmpty;
  }

  // التحقق من صحة الباركود
  static bool isValidBarcode(String? barcode) {
    if (barcode == null) return true;
    return barcode.trim().isNotEmpty;
  }

  // ==================== DISPLAY HELPERS ====================

  // الحصول على حالة المنتج كـ String
  String getStatusLabel() {
    if (isActive == true) {
      return 'نشط';
    } else {
      return 'غير نشط';
    }
  }

  // الحصول على لون حالة المنتج
  Color getStatusColor() {
    if (isActive == true) {
      return Colors.green;
    } else {
      return Colors.red;
    }
  }

  // الحصول على حالة الخصم كـ String
  String getDiscountLabel() {
    if (hasDiscount == true && discountPercentage != null) {
      return 'خصم ${discountPercentage!.toStringAsFixed(0)}%';
    }
    return 'بدون خصم';
  }

  // الحصول على لون حالة الخصم
  Color getDiscountColor() {
    if (hasDiscount == true) {
      return Colors.green;
    }
    return Colors.grey;
  }

  // ==================== STOCK HELPERS ====================

  // حساب حالة المخزون بناءً على الكمية
  static String getStockStatus(int quantity) {
    if (quantity <= 0) return 'نفذ المخزون';
    if (quantity <= 10) return 'مخزون منخفض';
    return 'متوفر';
  }

  // الحصول على لون حالة المخزون بناءً على الكمية
  static Color getStockStatusColor(int quantity) {
    if (quantity <= 0) return Colors.red;
    if (quantity <= 10) return Colors.orange;
    return Colors.green;
  }

  // تنسيق الكمية
  static String formatQuantity(int quantity) {
    if (quantity >= 1000) {
      return '${(quantity / 1000).toStringAsFixed(1)}k';
    }
    return quantity.toString();
  }

  // ==================== COMPARISON ====================

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Product(id: $id, name: $name, price: $price, category: $category)';
  }
}
