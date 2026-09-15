// lib/data/models/invoice.dart

import 'package:flutter/material.dart';

import 'customer.dart';
import 'user.dart';
import 'warehouse.dart';
import 'product.dart';

// ==================== INVOICE STATUS ENUM ====================
enum InvoiceStatus {
  quotation('عرض سعر', 'Quotation'),
  draft('مسودة', 'Draft'),
  confirmed('مؤكدة', 'Confirmed'),
  completed('مكتملة', 'Completed'),
  cancelled('ملغية', 'Cancelled'),
  pending('معلقة', 'Pending'),
  returned('مرتجعة', 'Returned'),
  expired('منتهي', 'Expired');

  final String arabic;
  final String english;

  const InvoiceStatus(this.arabic, this.english);

  static InvoiceStatus fromString(String value) {
    return InvoiceStatus.values.firstWhere(
      (e) =>
          e.english.toLowerCase() == value.toLowerCase() || e.arabic == value,
      orElse: () => InvoiceStatus.draft,
    );
  }

  Color get color {
    switch (this) {
      case InvoiceStatus.quotation:
        return Colors.purple;
      case InvoiceStatus.draft:
        return Colors.grey;
      case InvoiceStatus.confirmed:
        return Colors.blue;
      case InvoiceStatus.completed:
        return Colors.green;
      case InvoiceStatus.cancelled:
        return Colors.red;
      case InvoiceStatus.pending:
        return Colors.orange;
      case InvoiceStatus.returned:
        return Colors.deepPurple;
      case InvoiceStatus.expired:
        return Colors.brown;
    }
  }

  IconData get icon {
    switch (this) {
      case InvoiceStatus.quotation:
        return Icons.description;
      case InvoiceStatus.draft:
        return Icons.edit;
      case InvoiceStatus.confirmed:
        return Icons.check_circle;
      case InvoiceStatus.completed:
        return Icons.done_all;
      case InvoiceStatus.cancelled:
        return Icons.cancel;
      case InvoiceStatus.pending:
        return Icons.hourglass_empty;
      case InvoiceStatus.returned:
        return Icons.undo;
      case InvoiceStatus.expired:
        return Icons.timer_off;
    }
  }

  // ==================== PERMISSIONS ====================

  // هل يمكن تعديل الفاتورة؟
  bool get isEditable {
    return this == InvoiceStatus.quotation ||
        this == InvoiceStatus.draft ||
        this == InvoiceStatus.pending ||
        this == InvoiceStatus.completed;
  }

  // هل يمكن إلغاء الفاتورة؟
  bool get isCancellable {
    return this == InvoiceStatus.quotation ||
        this == InvoiceStatus.draft ||
        this == InvoiceStatus.confirmed ||
        this == InvoiceStatus.pending;
  }

  // هل يمكن تحويل عرض السعر لفاتورة؟
  bool get canConvertToInvoice {
    return this == InvoiceStatus.quotation;
  }

  // هل الفاتورة مؤثرة على المخزون؟
  bool get affectsStock {
    return this == InvoiceStatus.confirmed || this == InvoiceStatus.completed;
  }

  // هل الفاتورة نشطة (غير ملغية أو مرتجعة أو منتهية)؟
  bool get isActive {
    return this != InvoiceStatus.cancelled &&
        this != InvoiceStatus.returned &&
        this != InvoiceStatus.expired;
  }

  // هل هي عرض سعر؟
  bool get isQuotation {
    return this == InvoiceStatus.quotation;
  }

  // هل يمكن إرسالها للعميل؟
  bool get canSendToCustomer {
    return this == InvoiceStatus.quotation ||
        this == InvoiceStatus.confirmed ||
        this == InvoiceStatus.completed;
  }

  // هل يمكن حذفها؟
  bool get isDeletable {
    return this == InvoiceStatus.quotation ||
        this == InvoiceStatus.draft ||
        this == InvoiceStatus.expired ||
        this == InvoiceStatus.completed;
  }

  // هل هي فاتورة مبيعات فعلية؟
  bool get isRealInvoice {
    return this == InvoiceStatus.confirmed || this == InvoiceStatus.completed;
  }

  // هل هي مجرد عرض سعر؟
  bool get isJustQuotation {
    return this == InvoiceStatus.quotation || this == InvoiceStatus.expired;
  }

  // هل تحتاج إلى موافقة؟
  bool get needsApproval {
    return this == InvoiceStatus.pending;
  }

  // هل يمكن تأكيدها؟
  bool get canBeConfirmed {
    return this == InvoiceStatus.quotation ||
        this == InvoiceStatus.draft ||
        this == InvoiceStatus.pending;
  }

  // هل يمكن دفعها؟
  bool get canBePaid {
    return this == InvoiceStatus.quotation || this == InvoiceStatus.confirmed;
  }

  // هل يمكن إرجاعها؟
  bool get canBeReturned {
    return this == InvoiceStatus.completed;
  }

  // هل يمكن طباعتها؟
  bool get isPrintable {
    return this != InvoiceStatus.draft;
  }

  // هل يمكن تعديلها من قبل الموظف؟
  bool get canBeEditedByEmployee {
    return this == InvoiceStatus.quotation ||
        this == InvoiceStatus.draft ||
        this == InvoiceStatus.completed;
  }

  String get statusLabel => arabic;
  String get statusCode => english;
}

// ==================== PAYMENT STATUS ENUM ====================
enum PaymentStatus {
  unpaid('غير مدفوع', 'Unpaid'),
  partial('مدفوع جزئياً', 'Partial'),
  paid('مدفوع', 'Paid'),
  due('مستحق', 'Due');

  final String arabic;
  final String english;

  const PaymentStatus(this.arabic, this.english);

  static PaymentStatus fromString(String value) {
    return PaymentStatus.values.firstWhere(
      (e) =>
          e.english.toLowerCase() == value.toLowerCase() || e.arabic == value,
      orElse: () => PaymentStatus.unpaid,
    );
  }

  Color get color {
    switch (this) {
      case PaymentStatus.unpaid:
        return Colors.red;
      case PaymentStatus.partial:
        return Colors.orange;
      case PaymentStatus.paid:
        return Colors.green;
      case PaymentStatus.due:
        return Colors.deepOrange;
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentStatus.unpaid:
        return Icons.money_off;
      case PaymentStatus.partial:
        return Icons.payment;
      case PaymentStatus.paid:
        return Icons.payments;
      case PaymentStatus.due:
        return Icons.warning;
    }
  }

  String get label => arabic;
  String get code => english;
}

// ==================== PAYMENT METHOD ENUM ====================
enum PaymentMethod {
  cash('نقدي', 'Cash'),
  card('بطاقة', 'Card'),
  bank('تحويل بنكي', 'Bank Transfer'),
  check('شيك', 'Check'),
  online('دفع إلكتروني', 'Online Payment');

  final String arabic;
  final String english;

  const PaymentMethod(this.arabic, this.english);

  static PaymentMethod fromString(String value) {
    return PaymentMethod.values.firstWhere(
      (e) =>
          e.english.toLowerCase() == value.toLowerCase() || e.arabic == value,
      orElse: () => PaymentMethod.cash,
    );
  }

  String get label => arabic;
  String get code => english;
}

// ==================== DISCOUNT TYPE ENUM ====================
enum DiscountType {
  percentage('نسبة مئوية', 'Percentage'),
  fixed('قيمة ثابتة', 'Fixed');

  final String arabic;
  final String english;

  const DiscountType(this.arabic, this.english);

  static DiscountType fromString(String value) {
    return DiscountType.values.firstWhere(
      (e) =>
          e.english.toLowerCase() == value.toLowerCase() || e.arabic == value,
      orElse: () => DiscountType.percentage,
    );
  }

  String get label => arabic;
  String get code => english;
}

// ==================== INVOICE ITEM MODEL ====================
class InvoiceItem {
  final String? id;
  final String invoiceId;
  final String productId;
  final int quantity;
  final double unitPrice;
  final double? discountRate;
  final double? discountAmount;
  final double? taxRate;
  final double? taxAmount;
  final double total;
  final String? notes;

  // Related data
  final Product? product;

  InvoiceItem({
    this.id,
    required this.invoiceId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    this.discountRate,
    this.discountAmount,
    this.taxRate,
    this.taxAmount,
    required this.total,
    this.notes,
    this.product,
  });

  // ==================== FROM JSON ====================
  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      id: json['id'],
      invoiceId: json['invoice_id'] ?? '',
      productId: json['product_id'] ?? '',
      quantity: json['quantity'] ?? 0,
      unitPrice: (json['unit_price'] ?? 0).toDouble(),
      discountRate: json['discount_rate']?.toDouble(),
      discountAmount: json['discount_amount']?.toDouble(),
      taxRate: json['tax_rate']?.toDouble(),
      taxAmount: json['tax_amount']?.toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      notes: json['notes'],
      product: json['product'] != null
          ? Product.fromJson(json['product'])
          : null,
    );
  }

  // ==================== TO JSON ====================
  Map<String, dynamic> toJson() {
    return {
      'invoice_id': invoiceId,
      'product_id': productId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'discount_rate': discountRate,
      'discount_amount': discountAmount,
      'tax_rate': taxRate,
      'tax_amount': taxAmount,
      'total': total,
      'notes': notes,
    };
  }

  // ==================== COPY WITH ====================
  InvoiceItem copyWith({
    String? id,
    String? invoiceId,
    String? productId,
    int? quantity,
    double? unitPrice,
    double? discountRate,
    double? discountAmount,
    double? taxRate,
    double? taxAmount,
    double? total,
    String? notes,
    Product? product,
  }) {
    return InvoiceItem(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      discountRate: discountRate ?? this.discountRate,
      discountAmount: discountAmount ?? this.discountAmount,
      taxRate: taxRate ?? this.taxRate,
      taxAmount: taxAmount ?? this.taxAmount,
      total: total ?? this.total,
      notes: notes ?? this.notes,
      product: product ?? this.product,
    );
  }

  // ==================== GETTERS ====================

  // السعر بعد الخصم
  double get priceAfterDiscount {
    if (discountRate != null && discountRate! > 0) {
      return unitPrice - (unitPrice * discountRate! / 100);
    }
    if (discountAmount != null && discountAmount! > 0) {
      return unitPrice - discountAmount!;
    }
    return unitPrice;
  }

  // السعر الإجمالي بعد الخصم
  double get totalAfterDiscount {
    return priceAfterDiscount * quantity;
  }

  // الإجمالي بعد الضريبة
  double get totalAfterTax {
    if (taxRate != null && taxRate! > 0) {
      return totalAfterDiscount + (totalAfterDiscount * taxRate! / 100);
    }
    if (taxAmount != null && taxAmount! > 0) {
      return totalAfterDiscount + taxAmount!;
    }
    return totalAfterDiscount;
  }

  // قيمة الخصم الإجمالية
  double get totalDiscount {
    if (discountRate != null && discountRate! > 0) {
      return (unitPrice * discountRate! / 100) * quantity;
    }
    if (discountAmount != null && discountAmount! > 0) {
      return discountAmount! * quantity;
    }
    return 0;
  }

  // قيمة الضريبة الإجمالية
  double get totalTax {
    if (taxRate != null && taxRate! > 0) {
      return (totalAfterDiscount * taxRate! / 100);
    }
    if (taxAmount != null && taxAmount! > 0) {
      return taxAmount!;
    }
    return 0;
  }

  // تنسيقات
  String get formattedUnitPrice => '\$${unitPrice.toStringAsFixed(2)}';
  String get formattedTotal => '\$${total.toStringAsFixed(2)}';
  String get formattedPriceAfterDiscount =>
      '\$${priceAfterDiscount.toStringAsFixed(2)}';
  String get formattedTotalAfterDiscount =>
      '\$${totalAfterDiscount.toStringAsFixed(2)}';
  String get formattedTotalAfterTax => '\$${totalAfterTax.toStringAsFixed(2)}';

  // اسم المنتج
  String get productName => product?.name ?? 'منتج غير معروف';
}

// ==================== INVOICE MODEL ====================
class Invoice {
  final String? id;
  final String invoiceNumber;
  final String customerId;
  final String userId;
  final String? warehouseId;
  final DateTime date;
  final DateTime? dueDate;
  final DateTime? validUntil; // صلاحية عرض السعر
  final InvoiceStatus status;
  final PaymentStatus paymentStatus;
  final PaymentMethod paymentMethod;
  final double subtotal;
  final DiscountType discountType;
  final double? discountValue;
  final double? discountAmount;
  final double? taxRate;
  final double? taxAmount;
  final double? shippingCost;
  final double total;
  final double? paidAmount;
  final double? remainingAmount;
  final String? terms; // شروط عرض السعر
  final String? notes;
  final String? quotationId; // رابط عرض السعر الأصلي
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Related data
  final Customer? customer;
  final AppUser? user;
  final Warehouse? warehouse;
  final List<InvoiceItem>? items;

  Invoice({
    this.id,
    required this.invoiceNumber,
    required this.customerId,
    required this.userId,
    this.warehouseId,
    required this.date,
    this.dueDate,
    this.validUntil,
    this.status = InvoiceStatus.draft,
    this.paymentStatus = PaymentStatus.unpaid,
    this.paymentMethod = PaymentMethod.cash,
    this.subtotal = 0,
    this.discountType = DiscountType.percentage,
    this.discountValue,
    this.discountAmount,
    this.taxRate,
    this.taxAmount,
    this.shippingCost,
    this.total = 0,
    this.paidAmount,
    this.remainingAmount,
    this.terms,
    this.notes,
    this.quotationId,
    this.createdAt,
    this.updatedAt,
    this.customer,
    this.user,
    this.warehouse,
    this.items,
  });

  // ==================== FROM JSON ====================
  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'],
      invoiceNumber: json['invoice_number'] ?? '',
      customerId: json['customer_id'] ?? '',
      userId: json['user_id'] ?? '',
      warehouseId: json['warehouse_id'],
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'])
          : null,
      validUntil: json['valid_until'] != null
          ? DateTime.parse(json['valid_until'])
          : null,
      status: InvoiceStatus.fromString(json['status'] ?? 'draft'),
      paymentStatus: PaymentStatus.fromString(
        json['payment_status'] ?? 'unpaid',
      ),
      paymentMethod: PaymentMethod.fromString(json['payment_method'] ?? 'cash'),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      discountType: DiscountType.fromString(
        json['discount_type'] ?? 'percentage',
      ),
      discountValue: json['discount_value']?.toDouble(),
      discountAmount: json['discount_amount']?.toDouble(),
      taxRate: json['tax_rate']?.toDouble(),
      taxAmount: json['tax_amount']?.toDouble(),
      shippingCost: json['shipping_cost']?.toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      paidAmount: json['paid_amount']?.toDouble(),
      remainingAmount: json['remaining_amount']?.toDouble(),
      terms: json['terms'],
      notes: json['notes'],
      quotationId: json['quotation_id'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      customer: json['customer'] != null
          ? Customer.fromJson(json['customer'])
          : null,
      user: json['user'] != null ? AppUser.fromJson(json['user']) : null,
      warehouse: json['warehouse'] != null
          ? Warehouse.fromJson(json['warehouse'])
          : null,
      items: json['items'] != null
          ? List<InvoiceItem>.from(
              json['items'].map((item) => InvoiceItem.fromJson(item)),
            )
          : null,
    );
  }

  // ==================== TO JSON ====================
  Map<String, dynamic> toJson() {
    return {
      'invoice_number': invoiceNumber,
      'customer_id': customerId,
      'user_id': userId,
      'warehouse_id': warehouseId,
      'date': date.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
      'valid_until': validUntil?.toIso8601String(),
      'status': status.english.toLowerCase(),
      'payment_status': paymentStatus.english.toLowerCase(),
      'payment_method': paymentMethod.english.toLowerCase(),
      'subtotal': subtotal,
      'discount_type': discountType.english.toLowerCase(),
      'discount_value': discountValue,
      'discount_amount': discountAmount,
      'tax_rate': taxRate,
      'tax_amount': taxAmount,
      'shipping_cost': shippingCost,
      'total': total,
      'paid_amount': paidAmount,
      'remaining_amount': remainingAmount,
      'terms': terms,
      'notes': notes,
      'quotation_id': quotationId,
    };
  }

  // ==================== COPY WITH ====================
  Invoice copyWith({
    String? id,
    String? invoiceNumber,
    String? customerId,
    String? userId,
    String? warehouseId,
    DateTime? date,
    DateTime? dueDate,
    DateTime? validUntil,
    InvoiceStatus? status,
    PaymentStatus? paymentStatus,
    PaymentMethod? paymentMethod,
    double? subtotal,
    DiscountType? discountType,
    double? discountValue,
    double? discountAmount,
    double? taxRate,
    double? taxAmount,
    double? shippingCost,
    double? total,
    double? paidAmount,
    double? remainingAmount,
    String? terms,
    String? notes,
    String? quotationId,
    DateTime? createdAt,
    DateTime? updatedAt,
    Customer? customer,
    AppUser? user,
    Warehouse? warehouse,
    List<InvoiceItem>? items,
  }) {
    return Invoice(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      customerId: customerId ?? this.customerId,
      userId: userId ?? this.userId,
      warehouseId: warehouseId ?? this.warehouseId,
      date: date ?? this.date,
      dueDate: dueDate ?? this.dueDate,
      validUntil: validUntil ?? this.validUntil,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      subtotal: subtotal ?? this.subtotal,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      discountAmount: discountAmount ?? this.discountAmount,
      taxRate: taxRate ?? this.taxRate,
      taxAmount: taxAmount ?? this.taxAmount,
      shippingCost: shippingCost ?? this.shippingCost,
      total: total ?? this.total,
      paidAmount: paidAmount ?? this.paidAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      terms: terms ?? this.terms,
      notes: notes ?? this.notes,
      quotationId: quotationId ?? this.quotationId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      customer: customer ?? this.customer,
      user: user ?? this.user,
      warehouse: warehouse ?? this.warehouse,
      items: items ?? this.items,
    );
  }

  // ==================== GETTERS ====================

  // ===== STATUS HELPERS =====
  bool get isDraft => status == InvoiceStatus.draft;
  bool get isConfirmed => status == InvoiceStatus.confirmed;
  bool get isCompleted => status == InvoiceStatus.completed;
  bool get isCancelled => status == InvoiceStatus.cancelled;
  bool get isPending => status == InvoiceStatus.pending;
  bool get isReturned => status == InvoiceStatus.returned;
  bool get isQuotation => status == InvoiceStatus.quotation;
  bool get isExpired => status == InvoiceStatus.expired;

  // ===== PAYMENT HELPERS =====
  bool get isPaid => paymentStatus == PaymentStatus.paid;
  bool get isUnpaid => paymentStatus == PaymentStatus.unpaid;
  bool get isPartial => paymentStatus == PaymentStatus.partial;
  bool get isDue => paymentStatus == PaymentStatus.due;

  // ===== PERMISSION HELPERS =====
  bool get isEditable => status.isEditable;
  bool get isCancellable => status.isCancellable;
  bool get isActive => status.isActive;
  bool get isDeletable => status.isDeletable;
  bool get isRealInvoice => status.isRealInvoice;
  bool get canBeConfirmed => status.canBeConfirmed;
  bool get canBePaid => status.canBePaid;
  bool get canBeReturned => status.canBeReturned;
  bool get isPrintable => status.isPrintable;
  bool get canBeEditedByEmployee => status.canBeEditedByEmployee;

  // ===== QUOTATION HELPERS =====
  bool get isQuotationValid {
    if (status != InvoiceStatus.quotation) return false;
    if (validUntil == null) return true;
    return validUntil!.isAfter(DateTime.now());
  }

  bool get isQuotationExpired {
    if (status != InvoiceStatus.quotation) return false;
    if (validUntil == null) return false;
    return validUntil!.isBefore(DateTime.now());
  }

  Duration? get quotationRemaining {
    if (validUntil == null) return null;
    return validUntil!.difference(DateTime.now());
  }

  int? get quotationDaysRemaining {
    if (validUntil == null) return null;
    return validUntil!.difference(DateTime.now()).inDays;
  }

  // ===== OVERDUE CHECK =====
  bool get isOverdue {
    if (dueDate == null) return false;
    if (isPaid) return false;
    return dueDate!.isBefore(DateTime.now());
  }

  // ===== AMOUNT HELPERS =====
  double get remainingToPay {
    if (isPaid) return 0;
    if (paidAmount != null) {
      return total - paidAmount!;
    }
    return total;
  }

  double get paymentPercentage {
    if (total == 0) return 0;
    if (paidAmount != null) {
      return (paidAmount! / total) * 100;
    }
    return 0;
  }

  // ===== ITEMS HELPERS =====
  int get itemCount => items?.length ?? 0;

  int get totalQuantity {
    if (items == null) return 0;
    return items!.fold(0, (sum, item) => sum + item.quantity);
  }

  // ===== DISCOUNT HELPERS =====
  double get calculatedDiscountAmount {
    if (discountType == DiscountType.percentage && discountValue != null) {
      return subtotal * discountValue! / 100;
    }
    if (discountType == DiscountType.fixed && discountValue != null) {
      return discountValue!;
    }
    return discountAmount ?? 0;
  }

  double get calculatedTaxAmount {
    if (taxRate != null && taxRate! > 0) {
      return (subtotal - calculatedDiscountAmount) * taxRate! / 100;
    }
    return taxAmount ?? 0;
  }

  // ===== FORMATTED STRINGS =====
  String get formattedSubtotal => '\$${subtotal.toStringAsFixed(2)}';
  String get formattedDiscount =>
      '\$${calculatedDiscountAmount.toStringAsFixed(2)}';
  String get formattedTax => '\$${calculatedTaxAmount.toStringAsFixed(2)}';
  String get formattedTotal => '\$${total.toStringAsFixed(2)}';
  String get formattedPaidAmount => '\$${(paidAmount ?? 0).toStringAsFixed(2)}';
  String get formattedRemaining => '\$${remainingToPay.toStringAsFixed(2)}';
  String get formattedShippingCost =>
      '\$${(shippingCost ?? 0).toStringAsFixed(2)}';

  // ===== PAYMENT STATUS LABELS =====
  String get paymentStatusLabel => paymentStatus.arabic;
  String get statusLabel => status.arabic;

  // ===== CUSTOMER INFO =====
  String get customerName => customer?.name ?? 'عميل غير معروف';
  String get customerPhone => customer?.phone ?? '';
  String get customerEmail => customer?.email ?? '';

  // ===== USER INFO =====
  String get userName => user?.name ?? user?.email ?? 'موظف غير معروف';

  // ===== WAREHOUSE INFO =====
  String get warehouseName => warehouse?.name ?? 'مخزن غير محدد';

  // ===== DATE FORMATTING =====
  String get formattedDate {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String get formattedDueDate {
    if (dueDate == null) return 'غير محدد';
    return '${dueDate!.year}-${dueDate!.month.toString().padLeft(2, '0')}-${dueDate!.day.toString().padLeft(2, '0')}';
  }

  String get formattedValidUntil {
    if (validUntil == null) return 'غير محدد';
    return '${validUntil!.year}-${validUntil!.month.toString().padLeft(2, '0')}-${validUntil!.day.toString().padLeft(2, '0')}';
  }

  String get formattedCreatedAt {
    if (createdAt == null) return '';
    return '${createdAt!.year}-${createdAt!.month.toString().padLeft(2, '0')}-${createdAt!.day.toString().padLeft(2, '0')}';
  }

  // ===== VALIDATION =====
  bool get isValid {
    if (customerId.isEmpty) return false;
    if (invoiceNumber.isEmpty) return false;
    if (subtotal < 0) return false;
    if (total < 0) return false;
    if (items == null || items!.isEmpty) return false;
    for (var item in items!) {
      if (item.quantity <= 0) return false;
      if (item.unitPrice < 0) return false;
    }
    return true;
  }

  // ===== CALCULATION =====
  Invoice calculateTotals() {
    if (items == null) return this;

    double newSubtotal = 0;
    for (var item in items!) {
      newSubtotal += item.total;
    }

    double newDiscountAmount = 0;
    if (discountType == DiscountType.percentage && discountValue != null) {
      newDiscountAmount = newSubtotal * discountValue! / 100;
    } else if (discountType == DiscountType.fixed && discountValue != null) {
      newDiscountAmount = discountValue!;
    }

    double newTaxAmount = 0;
    if (taxRate != null && taxRate! > 0) {
      newTaxAmount = (newSubtotal - newDiscountAmount) * taxRate! / 100;
    }

    double newTotal =
        newSubtotal - newDiscountAmount + newTaxAmount + (shippingCost ?? 0);

    return copyWith(
      subtotal: newSubtotal,
      discountAmount: newDiscountAmount,
      taxAmount: newTaxAmount,
      total: newTotal,
    );
  }

  // ==================== OVERRIDES ====================
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Invoice && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Invoice(id: $id, number: $invoiceNumber, customer: $customerName, total: $total, status: ${status.arabic})';
  }
}

// ==================== INVOICE PERMISSIONS CLASS ====================
class InvoicePermissions {
  // ===== QUOTATION PERMISSIONS =====
  static bool canCreateQuotation(AppUser user) {
    return user.isActiveUser;
  }

  static bool canConvertToInvoice(InvoiceStatus status, AppUser user) {
    if (!user.isActiveUser) return false;
    if (user.isAdmin) {
      return status == InvoiceStatus.quotation &&
          status != InvoiceStatus.expired;
    }
    return status == InvoiceStatus.quotation && status != InvoiceStatus.expired;
  }

  static bool canSendQuotation(InvoiceStatus status, AppUser user) {
    if (!user.isActiveUser) return false;
    return status == InvoiceStatus.quotation || status == InvoiceStatus.draft;
  }

  static bool canUpdateValidity(InvoiceStatus status, AppUser user) {
    return user.isAdmin &&
        user.isActiveUser &&
        status == InvoiceStatus.quotation;
  }

  // ===== GENERAL PERMISSIONS =====
  static bool canCreateInvoice(AppUser user) {
    return user.isActiveUser;
  }

  static bool canEdit(InvoiceStatus status, AppUser user) {
    if (!user.isActiveUser) return false;
    if (!status.isEditable) return false;

    if (user.isAdmin) {
      return status.isEditable;
    }
    // الموظف يمكنه تعديل عرض السعر والمسودة والمكتملة
    return status.canBeEditedByEmployee;
  }

  static bool canConfirm(InvoiceStatus status, AppUser user) {
    if (!user.isActiveUser) return false;
    // عرض السعر مسموح تأكيده
    return status.canBeConfirmed;
  }

  static bool canCancel(InvoiceStatus status, AppUser user) {
    if (!user.isActiveUser) return false;
    if (!status.isCancellable) return false;

    if (user.isAdmin) {
      return status.isCancellable;
    }
    // الموظف يمكنه إلغاء عرض السعر والمسودة فقط
    return status == InvoiceStatus.draft || status == InvoiceStatus.quotation;
  }

  static bool canComplete(
    InvoiceStatus status,
    PaymentStatus payment,
    AppUser user,
  ) {
    if (!user.isActiveUser) return false;
    return status == InvoiceStatus.confirmed && payment != PaymentStatus.paid;
  }

  static bool canPay(InvoiceStatus status, AppUser user) {
    if (!user.isActiveUser) return false;
    return status.canBePaid;
  }

  static bool canReturn(InvoiceStatus status, AppUser user) {
    if (!user.isActiveUser) return false;
    return user.isAdmin && status.canBeReturned;
  }

  static bool canDelete(InvoiceStatus status, AppUser user) {
    if (!user.isActiveUser) return false;
    return user.isAdmin && status.isDeletable;
  }

  static bool canPrint(InvoiceStatus status, AppUser user) {
    if (!user.isActiveUser) return false;
    return status.isPrintable;
  }

  static bool canSendToCustomer(InvoiceStatus status, AppUser user) {
    if (!user.isActiveUser) return false;
    return status.canSendToCustomer;
  }

  static bool canChangePaymentStatus(InvoiceStatus status, AppUser user) {
    if (!user.isActiveUser) return false;
    if (user.isAdmin) {
      return status == InvoiceStatus.confirmed ||
          status == InvoiceStatus.completed;
    }
    return status == InvoiceStatus.confirmed;
  }

  static bool canManageItems(InvoiceStatus status, AppUser user) {
    if (!user.isActiveUser) return false;
    if (user.isAdmin) {
      return status == InvoiceStatus.quotation ||
          status == InvoiceStatus.draft ||
          status == InvoiceStatus.pending ||
          status == InvoiceStatus.completed;
    }
    return status == InvoiceStatus.quotation ||
        status == InvoiceStatus.draft ||
        status == InvoiceStatus.completed;
  }
}
