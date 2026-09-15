// lib/presentation/screens/invoices/create_invoice_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ===== IMPORTS =====
import '../../../data/models/invoice.dart';
import '../../../data/models/customer.dart';
import '../../../data/models/product.dart';
import '../../../data/models/warehouse.dart';
import '../../../data/services/invoice_service.dart';
import '../../../data/repositories/customer_repository.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/repositories/warehouse_repository.dart';
import '../../../data/repositories/invoice_repository.dart';

// ✅ استيراد الـ Widget من المسار الصحيح
import '../../widgets/invoice_item_tile.dart';

class CreateInvoiceScreen extends StatefulWidget {
  final bool isQuotation;

  const CreateInvoiceScreen({super.key, this.isQuotation = false});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  final InvoiceService _invoiceService = InvoiceService();
  final CustomerRepository _customerRepo = CustomerRepository();
  final ProductRepository _productRepo = ProductRepository();
  final WarehouseRepository _warehouseRepo = WarehouseRepository();

  // ===== CONTROLLERS =====
  final TextEditingController _invoiceNumberController =
      TextEditingController();
  final TextEditingController _searchCustomerController =
      TextEditingController();
  final TextEditingController _searchProductController =
      TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _taxController = TextEditingController();
  final TextEditingController _shippingController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _termsController = TextEditingController();

  // ===== STATE =====
  bool _isLoading = false;

  // ===== CUSTOMER =====
  Customer? _selectedCustomer;
  List<Customer> _customers = [];
  bool _isSearchingCustomer = false;

  // ===== PRODUCTS =====
  final List<InvoiceItem> _items = [];
  List<Product> _products = [];
  bool _isSearchingProduct = false;
  int _selectedQuantity = 1;

  // ===== WAREHOUSE =====
  Warehouse? _selectedWarehouse;
  List<Warehouse> _warehouses = [];

  // ===== DISCOUNT =====
  DiscountType _discountType = DiscountType.percentage;

  // ===== DATE =====
  DateTime _selectedDate = DateTime.now();
  DateTime? _selectedDueDate;
  DateTime? _selectedValidUntil;

  // ===== CALCULATED =====
  double _subtotal = 0;
  double _total = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _generateInvoiceNumber();
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    _searchCustomerController.dispose();
    _searchProductController.dispose();
    _discountController.dispose();
    _taxController.dispose();
    _shippingController.dispose();
    _notesController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    try {
      final warehouses = await _warehouseRepo.getActiveWarehouses();
      setState(() {
        _warehouses = warehouses;
        if (warehouses.isNotEmpty) {
          _selectedWarehouse = warehouses.first;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _generateInvoiceNumber() async {
    try {
      final invoiceRepo = InvoiceRepository();
      final number = widget.isQuotation
          ? await invoiceRepo.generateQuotationNumber()
          : await invoiceRepo.generateInvoiceNumber();
      _invoiceNumberController.text = number;
    } catch (e) {
      _invoiceNumberController.text = widget.isQuotation
          ? 'Q-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().padLeft(4, '0')}'
          : 'INV-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().padLeft(4, '0')}';
    }
  }

  // ==================== CUSTOMER SEARCH ====================

  Future<void> _searchCustomers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _customers = [];
        _isSearchingCustomer = false;
      });
      return;
    }

    setState(() => _isSearchingCustomer = true);

    try {
      final customers = await _customerRepo.searchCustomers(query);
      setState(() {
        _customers = customers;
        _isSearchingCustomer = false;
      });
    } catch (e) {
      setState(() {
        _isSearchingCustomer = false;
      });
    }
  }

  void _selectCustomer(Customer customer) {
    setState(() {
      _selectedCustomer = customer;
      _searchCustomerController.text = customer.name;
      _customers = [];
    });
  }

  // ==================== PRODUCT SEARCH ====================

  Future<void> _searchProducts(String query) async {
    if (query.isEmpty) {
      setState(() {
        _products = [];
        _isSearchingProduct = false;
      });
      return;
    }

    setState(() => _isSearchingProduct = true);

    try {
      final products = await _productRepo.searchProducts(query);
      setState(() {
        _products = products;
        _isSearchingProduct = false;
      });
    } catch (e) {
      setState(() {
        _isSearchingProduct = false;
      });
    }
  }

  void _addProduct(Product product) {
    if (product.id == null) return;

    final existingIndex = _items.indexWhere(
      (item) => item.productId == product.id,
    );

    if (existingIndex != -1) {
      final existing = _items[existingIndex];
      final newQuantity = existing.quantity + _selectedQuantity;
      _items[existingIndex] = existing.copyWith(
        quantity: newQuantity,
        total: newQuantity * existing.unitPrice,
      );
    } else {
      final newItem = InvoiceItem(
        invoiceId: '',
        productId: product.id!,
        quantity: _selectedQuantity,
        unitPrice: product.price,
        total: product.price * _selectedQuantity,
        product: product,
      );
      _items.add(newItem);
    }

    _searchProductController.clear();
    setState(() {
      _products = [];
      _selectedQuantity = 1;
    });

    _calculateTotals();
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
    _calculateTotals();
  }

  void _updateItemQuantity(int index, int quantity) {
    if (quantity <= 0) {
      _removeItem(index);
      return;
    }

    final item = _items[index];
    _items[index] = item.copyWith(
      quantity: quantity,
      total: quantity * item.unitPrice,
    );
    _calculateTotals();
  }

  // ==================== CALCULATIONS ====================

  void _calculateTotals() {
    double subtotal = 0;
    for (var item in _items) {
      subtotal += item.total;
    }

    double discountAmount = 0;
    final discountValue = double.tryParse(_discountController.text) ?? 0;
    if (discountValue > 0) {
      if (_discountType == DiscountType.percentage) {
        discountAmount = subtotal * discountValue / 100;
      } else {
        discountAmount = discountValue;
      }
    }

    double taxAmount = 0;
    final taxRate = double.tryParse(_taxController.text) ?? 0;
    if (taxRate > 0) {
      taxAmount = (subtotal - discountAmount) * taxRate / 100;
    }

    double shippingCost = double.tryParse(_shippingController.text) ?? 0;
    double total = subtotal - discountAmount + taxAmount + shippingCost;

    setState(() {
      _subtotal = subtotal;
      _total = total;
    });
  }

  // ==================== CREATE INVOICE ====================

  Future<void> _createInvoice() async {
    if (_selectedCustomer == null) {
      _showError('الرجاء اختيار عميل');
      return;
    }

    if (_items.isEmpty) {
      _showError('الرجاء إضافة منتجات');
      return;
    }

    if (_selectedWarehouse == null) {
      _showError('الرجاء اختيار مخزن');
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _showError('المستخدم غير مسجل');
      return;
    }

    setState(() => _isLoading = true);

    try {
      double discountValue = double.tryParse(_discountController.text) ?? 0;
      double discountAmount = 0;
      if (discountValue > 0) {
        if (_discountType == DiscountType.percentage) {
          discountAmount = _subtotal * discountValue / 100;
        } else {
          discountAmount = discountValue;
        }
      }

      double taxRate = double.tryParse(_taxController.text) ?? 0;
      double shippingCost = double.tryParse(_shippingController.text) ?? 0;

      final invoice = Invoice(
        invoiceNumber: _invoiceNumberController.text,
        customerId: _selectedCustomer!.id!,
        userId: user.id,
        warehouseId: _selectedWarehouse!.id,
        date: _selectedDate,
        dueDate: _selectedDueDate,
        validUntil: widget.isQuotation ? _selectedValidUntil : null,
        status: widget.isQuotation
            ? InvoiceStatus.quotation
            : InvoiceStatus.draft,
        paymentStatus: PaymentStatus.unpaid,
        paymentMethod: PaymentMethod.cash,
        subtotal: _subtotal,
        discountType: _discountType,
        discountValue: discountValue,
        discountAmount: discountAmount,
        taxRate: taxRate,
        taxAmount: taxRate > 0
            ? (_subtotal - discountAmount) * taxRate / 100
            : 0,
        shippingCost: shippingCost,
        total: _total,
        terms: _termsController.text.isNotEmpty ? _termsController.text : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        items: _items.map((item) => item.copyWith(invoiceId: '')).toList(),
      );

      final created = widget.isQuotation
          ? await _invoiceService.createQuotation(invoice)
          : await _invoiceService.createInvoice(invoice, checkStock: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isQuotation
                  ? '✅ تم إنشاء عرض السعر بنجاح'
                  : '✅ تم إنشاء الفاتورة بنجاح',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, created);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError(e.toString());
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ $message'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isQuotation ? 'عرض سعر جديد' : 'فاتورة جديدة'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== رقم الفاتورة =====
                  _buildInvoiceNumber(),
                  const SizedBox(height: 16),
                  // ===== التاريخ =====
                  _buildDateSection(),
                  const SizedBox(height: 16),
                  // ===== العميل =====
                  _buildCustomerSection(),
                  const SizedBox(height: 16),
                  // ===== المخزن =====
                  _buildWarehouseSection(),
                  const SizedBox(height: 16),
                  // ===== المنتجات =====
                  _buildProductsSection(),
                  const SizedBox(height: 16),
                  // ===== بنود الفاتورة =====
                  _buildItemsList(),
                  const SizedBox(height: 16),
                  // ===== الخصم والضريبة =====
                  _buildDiscountTaxSection(),
                  const SizedBox(height: 16),
                  // ===== الإجماليات =====
                  _buildTotalsSection(),
                  const SizedBox(height: 16),
                  // ===== الشروط والملاحظات =====
                  _buildNotesSection(),
                  const SizedBox(height: 24),
                  // ===== أزرار الإجراءات =====
                  _buildActionButtons(),
                ],
              ),
            ),
    );
  }

  Widget _buildInvoiceNumber() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.numbers, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _invoiceNumberController,
              enabled: false,
              decoration: const InputDecoration(
                labelText: 'رقم الفاتورة',
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // تاريخ الفاتورة
          InkWell(
            onTap: () => _selectDate(context),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'التاريخ: ${_formatDate(_selectedDate)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.grey),
              ],
            ),
          ),
          // تاريخ الاستحقاق (للفواتير فقط)
          if (!widget.isQuotation) ...[
            const Divider(),
            InkWell(
              onTap: () => _selectDueDate(context),
              child: Row(
                children: [
                  const Icon(Icons.event, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'تاريخ الاستحقاق: ${_selectedDueDate != null ? _formatDate(_selectedDueDate!) : 'غير محدد'}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Colors.grey),
                ],
              ),
            ),
          ],
          // صلاحية عرض السعر
          if (widget.isQuotation) ...[
            const Divider(),
            InkWell(
              onTap: () => _selectValidUntil(context),
              child: Row(
                children: [
                  const Icon(Icons.timer, color: Colors.purple),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'صالح حتى: ${_selectedValidUntil != null ? _formatDate(_selectedValidUntil!) : 'غير محدد'}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Colors.grey),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomerSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'العميل',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          if (_selectedCustomer != null) ...[
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    _selectedCustomer!.name[0].toUpperCase(),
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedCustomer!.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_selectedCustomer!.phone != null)
                        Text(
                          _selectedCustomer!.phone!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _selectedCustomer = null;
                      _searchCustomerController.clear();
                    });
                  },
                ),
              ],
            ),
          ] else ...[
            TextField(
              controller: _searchCustomerController,
              decoration: InputDecoration(
                hintText: 'ابحث عن عميل...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _isSearchingCustomer
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _searchCustomers,
            ),
            if (_customers.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _customers.length,
                  itemBuilder: (context, index) {
                    final customer = _customers[index];
                    return ListTile(
                      title: Text(customer.name),
                      subtitle: customer.phone != null
                          ? Text(customer.phone!)
                          : null,
                      onTap: () => _selectCustomer(customer),
                    );
                  },
                ),
              ),
          ],
        ],
      ),
    );
  }

  // ==================== BUILD WAREHOUSE SECTION (المعدل) ====================

  Widget _buildWarehouseSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'المخزن',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedWarehouse?.id,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            items: _warehouses.map((warehouse) {
              return DropdownMenuItem<String>(
                key: ValueKey(warehouse.id),
                value: warehouse.id,
                child: Text(warehouse.displayName),
              );
            }).toList(),
            onChanged: (warehouseId) {
              setState(() {
                _selectedWarehouse = _warehouses.firstWhere(
                  (w) => w.id == warehouseId,
                  orElse: () => _warehouses.first,
                );
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductsSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'إضافة منتج',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _searchProductController,
                  decoration: InputDecoration(
                    hintText: 'ابحث عن منتج...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _isSearchingProduct
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: Padding(
                              padding: EdgeInsets.all(8),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onChanged: _searchProducts,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 80,
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'الكمية',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onChanged: (value) {
                    final qty = int.tryParse(value) ?? 1;
                    if (qty > 0) {
                      setState(() => _selectedQuantity = qty);
                    }
                  },
                ),
              ),
            ],
          ),
          if (_products.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _products.length,
                itemBuilder: (context, index) {
                  final product = _products[index];
                  return ListTile(
                    leading: product.imageUrl != null
                        ? Image.network(
                            product.imageUrl!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.image,
                              color: Colors.grey.shade400,
                              size: 40,
                            ),
                          )
                        : Icon(
                            Icons.inventory,
                            color: Colors.grey.shade400,
                            size: 40,
                          ),
                    title: Text(product.name),
                    subtitle: Text(
                      '${product.formattedPrice} | ${product.category ?? 'بدون تصنيف'}',
                    ),
                    trailing: Text(
                      '${product.price.toStringAsFixed(2)} × $_selectedQuantity = ${(product.price * _selectedQuantity).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    onTap: () => _addProduct(product),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    if (_items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.shopping_cart, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 8),
              Text(
                'لا توجد منتجات',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'المنتجات',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const Spacer(),
              Text(
                '${_items.length} منتج',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _items.length,
            itemBuilder: (context, index) {
              final item = _items[index];
              return InvoiceItemTile(
                item: item,
                onQuantityChanged: (quantity) =>
                    _updateItemQuantity(index, quantity),
                onRemove: () => _removeItem(index),
                showControls: true,
                showPriceControl: false,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountTaxSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // الخصم
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _discountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'الخصم',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onChanged: (_) => _calculateTotals(),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 120,
                child: DropdownButtonFormField<DiscountType>(
                  initialValue: _discountType,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: DiscountType.percentage,
                      child: Text('%'),
                    ),
                    DropdownMenuItem(
                      value: DiscountType.fixed,
                      child: Text('\$'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _discountType = value;
                      });
                      _calculateTotals();
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // الضريبة
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _taxController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'الضريبة (%)',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onChanged: (_) => _calculateTotals(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _shippingController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'الشحن',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onChanged: (_) => _calculateTotals(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsSection() {
    final discountValue = double.tryParse(_discountController.text) ?? 0;
    final taxRate = double.tryParse(_taxController.text) ?? 0;
    final shippingCost = double.tryParse(_shippingController.text) ?? 0;

    double discountAmount = 0;
    if (discountValue > 0) {
      if (_discountType == DiscountType.percentage) {
        discountAmount = _subtotal * discountValue / 100;
      } else {
        discountAmount = discountValue;
      }
    }

    double taxAmount = 0;
    if (taxRate > 0) {
      taxAmount = (_subtotal - discountAmount) * taxRate / 100;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        children: [
          _buildTotalRow('المجموع الفرعي', _subtotal),
          if (discountAmount > 0)
            _buildTotalRow('الخصم', -discountAmount, isNegative: true),
          if (taxAmount > 0) _buildTotalRow('الضريبة', taxAmount),
          if (shippingCost > 0) _buildTotalRow('الشحن', shippingCost),
          const Divider(),
          _buildTotalRow('الإجمالي', _total, isTotal: true),
        ],
      ),
    );
  }

  Widget _buildTotalRow(
    String label,
    double value, {
    bool isTotal = false,
    bool isNegative = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '${isNegative ? '-' : ''}\$${value.abs().toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isNegative
                  ? Colors.red
                  : isTotal
                  ? Colors.blue.shade700
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          if (widget.isQuotation)
            TextField(
              controller: _termsController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'شروط عرض السعر',
                hintText: 'مثل: السعر شامل الضريبة، التوصيل خلال 3 أيام...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
          if (widget.isQuotation) const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: widget.isQuotation ? 'ملاحظات إضافية' : 'ملاحظات',
              hintText: 'أي ملاحظات إضافية...',
              border: const OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('إلغاء'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _createInvoice,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              disabledBackgroundColor: Colors.grey.shade400,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                  )
                : Text(widget.isQuotation ? 'حفظ عرض السعر' : 'حفظ الفاتورة'),
          ),
        ),
      ],
    );
  }

  // ==================== HELPERS ====================

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _selectDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate:
          _selectedDueDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _selectedDueDate = date);
    }
  }

  Future<void> _selectValidUntil(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate:
          _selectedValidUntil ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _selectedValidUntil = date);
    }
  }
}
