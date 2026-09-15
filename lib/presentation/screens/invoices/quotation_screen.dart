// lib/presentation/screens/invoices/quotation_screen.dart

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

// ✅ استيراد الـ Widgets من المسار الصحيح
import '../../widgets/invoice_item_tile.dart';
import '../../widgets/invoice_status_badge.dart';

class QuotationScreen extends StatefulWidget {
  final String? quotationId; // إذا تم تمرير ID، يتم عرض عرض سعر موجود

  const QuotationScreen({super.key, this.quotationId});

  @override
  State<QuotationScreen> createState() => _QuotationScreenState();
}

class _QuotationScreenState extends State<QuotationScreen> {
  final InvoiceService _invoiceService = InvoiceService();
  final CustomerRepository _customerRepo = CustomerRepository();
  final ProductRepository _productRepo = ProductRepository();
  final WarehouseRepository _warehouseRepo = WarehouseRepository();

  // ===== CONTROLLERS =====
  final TextEditingController _quotationNumberController =
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
  bool _isSaving = false;
  String? _error;
  bool _isViewMode = false;

  // ===== QUOTATION DATA =====
  Invoice? _quotation;
  late String _quotationNumber;
  late DateTime _selectedDate;
  DateTime? _selectedValidUntil;

  // ===== CUSTOMER =====
  Customer? _selectedCustomer;
  List<Customer> _customers = [];
  bool _isSearchingCustomer = false;

  // ===== PRODUCTS =====
  List<InvoiceItem> _items = [];
  List<Product> _products = [];
  bool _isSearchingProduct = false;
  int _selectedQuantity = 1;

  // ===== WAREHOUSE =====
  Warehouse? _selectedWarehouse;
  List<Warehouse> _warehouses = [];

  // ===== DISCOUNT =====
  DiscountType _discountType = DiscountType.percentage;
  double _discountValue = 0;

  // ===== CALCULATED =====
  double _subtotal = 0;
  double _total = 0;

  @override
  void initState() {
    super.initState();
    _isViewMode = widget.quotationId != null;
    if (_isViewMode) {
      _loadQuotation();
    } else {
      _initializeNewQuotation();
      _loadInitialData();
    }
  }

  @override
  void dispose() {
    _quotationNumberController.dispose();
    _searchCustomerController.dispose();
    _searchProductController.dispose();
    _discountController.dispose();
    _taxController.dispose();
    _shippingController.dispose();
    _notesController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  // ==================== INITIALIZATION ====================

  Future<void> _initializeNewQuotation() async {
    setState(() => _isLoading = true);
    try {
      _selectedDate = DateTime.now();
      _selectedValidUntil = DateTime.now().add(const Duration(days: 7));
      final invoiceRepo = InvoiceRepository();
      _quotationNumber = await invoiceRepo.generateQuotationNumber();
      _quotationNumberController.text = _quotationNumber;
      _isLoading = false;
    } catch (e) {
      _quotationNumber =
          'Q-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().padLeft(4, '0')}';
      _quotationNumberController.text = _quotationNumber;
      _isLoading = false;
    }
  }

  Future<void> _loadQuotation() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final quotation = await _invoiceService.getInvoiceWithDetails(
        widget.quotationId!,
      );
      if (quotation == null) {
        throw Exception('عرض السعر غير موجود');
      }

      setState(() {
        _quotation = quotation;
        _quotationNumber = quotation.invoiceNumber;
        _quotationNumberController.text = _quotationNumber;
        _selectedDate = quotation.date;
        _selectedValidUntil = quotation.validUntil;
        _selectedCustomer = quotation.customer;
        if (_selectedCustomer != null) {
          _searchCustomerController.text = _selectedCustomer!.name;
        }
        _selectedWarehouse = quotation.warehouse;
        _items = List.from(quotation.items ?? []);
        _discountType = quotation.discountType;
        _discountValue = quotation.discountValue ?? 0;
        _discountController.text = _discountValue > 0
            ? _discountValue.toString()
            : '';
        _taxController.text = quotation.taxRate?.toString() ?? '';
        _shippingController.text = quotation.shippingCost?.toString() ?? '';
        _notesController.text = quotation.notes ?? '';
        _termsController.text = quotation.terms ?? '';
        _isLoading = false;
        _calculateTotals();
      });

      // تحميل المخازن
      final warehouses = await _warehouseRepo.getActiveWarehouses();
      setState(() {
        _warehouses = warehouses;
        if (_selectedWarehouse == null && warehouses.isNotEmpty) {
          _selectedWarehouse = warehouses.first;
        }
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadInitialData() async {
    try {
      final warehouses = await _warehouseRepo.getActiveWarehouses();
      setState(() {
        _warehouses = warehouses;
        if (warehouses.isNotEmpty) {
          _selectedWarehouse = warehouses.first;
        }
      });
    } catch (e) {
      // تجاهل الخطأ
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
        _customers = customers
            .where((c) => c.id != _selectedCustomer?.id)
            .toList();
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
      final existingProductIds = _items.map((item) => item.productId).toSet();
      final filteredProducts = products
          .where((p) => p.id != null && !existingProductIds.contains(p.id))
          .toList();
      setState(() {
        _products = filteredProducts;
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
      setState(() {
        final existing = _items[existingIndex];
        final newQuantity = existing.quantity + _selectedQuantity;
        _items[existingIndex] = existing.copyWith(
          quantity: newQuantity,
          total: newQuantity * existing.unitPrice,
        );
      });
    } else {
      final newItem = InvoiceItem(
        invoiceId: _quotation?.id ?? '',
        productId: product.id!,
        quantity: _selectedQuantity,
        unitPrice: product.price,
        total: product.price * _selectedQuantity,
        product: product,
      );
      setState(() {
        _items.add(newItem);
      });
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

    setState(() {
      final item = _items[index];
      _items[index] = item.copyWith(
        quantity: quantity,
        total: quantity * item.unitPrice,
      );
    });
    _calculateTotals();
  }

  void _updateItemPrice(int index, double price) {
    if (price < 0) return;

    setState(() {
      final item = _items[index];
      _items[index] = item.copyWith(
        unitPrice: price,
        total: price * item.quantity,
      );
    });
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

  // ==================== SAVE QUOTATION ====================

  Future<void> _saveQuotation() async {
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

    setState(() => _isSaving = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('المستخدم غير مسجل');
      }

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
      double taxAmount = 0;
      if (taxRate > 0) {
        taxAmount = (_subtotal - discountAmount) * taxRate / 100;
      }
      double shippingCost = double.tryParse(_shippingController.text) ?? 0;

      final quotation = Invoice(
        id: _quotation?.id,
        invoiceNumber: _quotationNumberController.text,
        customerId: _selectedCustomer!.id!,
        userId: user.id,
        warehouseId: _selectedWarehouse!.id,
        date: _selectedDate,
        validUntil: _selectedValidUntil,
        status: InvoiceStatus.quotation,
        paymentStatus: PaymentStatus.unpaid,
        paymentMethod: PaymentMethod.cash,
        subtotal: _subtotal,
        discountType: _discountType,
        discountValue: discountValue > 0 ? discountValue : null,
        discountAmount: discountAmount > 0 ? discountAmount : null,
        taxRate: taxRate > 0 ? taxRate : null,
        taxAmount: taxAmount > 0 ? taxAmount : null,
        shippingCost: shippingCost > 0 ? shippingCost : null,
        total: _total,
        terms: _termsController.text.isNotEmpty ? _termsController.text : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        items: _items.map((item) => item.copyWith(invoiceId: '')).toList(),
      );

      Invoice result;
      if (_quotation != null) {
        // تحديث عرض سعر موجود
        result = await _invoiceService.updateInvoice(quotation);
      } else {
        // إنشاء عرض سعر جديد
        result = await _invoiceService.createQuotation(quotation);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _quotation != null
                  ? '✅ تم تحديث عرض السعر بنجاح'
                  : '✅ تم إنشاء عرض السعر بنجاح',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, result);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      _showError(e.toString());
    }
  }

  // ==================== CONVERT TO INVOICE ====================

  Future<void> _convertToInvoice() async {
    if (_quotation == null) {
      _showError('عرض السعر غير موجود');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('تحويل عرض السعر'),
        content: Text(
          'هل أنت متأكد من تحويل عرض السعر رقم ${_quotation!.invoiceNumber} إلى فاتورة؟\n\n'
          'سيتم إنشاء فاتورة جديدة من هذا عرض السعر.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('تحويل'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSaving = true);

    try {
      final invoice = await _invoiceService.convertQuotationToInvoice(
        _quotation!.id!,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم تحويل عرض السعر إلى فاتورة بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, invoice);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      _showError(e.toString());
    }
  }

  // ==================== DELETE QUOTATION ====================

  Future<void> _deleteQuotation() async {
    if (_quotation == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('حذف عرض السعر'),
        content: Text(
          'هل أنت متأكد من حذف عرض السعر رقم ${_quotation!.invoiceNumber}؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSaving = true);

    try {
      await _invoiceService.deleteInvoice(_quotation!.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم حذف عرض السعر بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      _showError(e.toString());
    }
  }

  // ==================== SEND QUOTATION ====================

  Future<void> _sendQuotation() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📨 إرسال عرض السعر - سيتم إضافتها قريباً'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  // ==================== PRINT QUOTATION ====================

  Future<void> _printQuotation() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🖨️ طباعة عرض السعر - سيتم إضافتها قريباً'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  // ==================== HELPERS ====================

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

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _selectDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
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

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isViewMode
              ? 'عرض السعر ${_quotation?.invoiceNumber ?? ''}'
              : 'عرض سعر جديد',
        ),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isViewMode && _quotation != null) ...[
            if (_quotation!.isQuotationValid && !_quotation!.isExpired)
              IconButton(
                icon: const Icon(Icons.file_copy),
                onPressed: _isSaving ? null : _convertToInvoice,
                tooltip: 'تحويل إلى فاتورة',
              ),
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: _printQuotation,
              tooltip: 'طباعة',
            ),
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _sendQuotation,
              tooltip: 'إرسال',
            ),
          ],
          if (_isSaving)
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
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('جاري تحميل عرض السعر...'),
                ],
              ),
            )
          : _error != null
          ? _buildErrorWidget()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== حالة عرض السعر =====
                  if (_isViewMode && _quotation != null) _buildStatusCard(),

                  if (_isViewMode && _quotation != null)
                    const SizedBox(height: 16),

                  // ===== رقم عرض السعر =====
                  _buildQuotationNumber(),

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

                  // ===== بنود عرض السعر =====
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

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              'حدث خطأ',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (_isViewMode) {
                  _loadQuotation();
                } else {
                  _initializeNewQuotation();
                  _loadInitialData();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final quotation = _quotation!;
    final isExpired = quotation.isQuotationExpired;
    final daysRemaining = quotation.quotationDaysRemaining;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isExpired ? Colors.red.shade50 : Colors.purple.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpired ? Colors.red.shade200 : Colors.purple.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isExpired ? Icons.timer_off : Icons.timer,
            color: isExpired ? Colors.red : Colors.purple,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isExpired ? '⚠️ منتهي الصلاحية' : '✅ صالح',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isExpired ? Colors.red : Colors.purple,
                  ),
                ),
                if (!isExpired && daysRemaining != null)
                  Text(
                    'متبقي $daysRemaining يوم',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.purple.shade700,
                    ),
                  ),
                if (quotation.validUntil != null)
                  Text(
                    'صالح حتى: ${_formatDate(quotation.validUntil!)}',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
              ],
            ),
          ),
          InvoiceStatusBadge(status: quotation.status),
        ],
      ),
    );
  }

  Widget _buildQuotationNumber() {
    final isEditable = !_isViewMode || _quotation?.isEditable == true;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.numbers, color: Colors.purple),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _quotationNumberController,
              enabled: isEditable,
              decoration: const InputDecoration(
                labelText: 'رقم عرض السعر',
                border: InputBorder.none,
              ),
              onChanged: (_) {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSection() {
    final isEditable = !_isViewMode || _quotation?.isEditable == true;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: isEditable ? () => _selectDate(context) : null,
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.purple),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'التاريخ: ${_formatDate(_selectedDate)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                if (isEditable)
                  const Icon(Icons.arrow_drop_down, color: Colors.grey),
              ],
            ),
          ),
          const Divider(),
          InkWell(
            onTap: isEditable ? () => _selectValidUntil(context) : null,
            child: Row(
              children: [
                const Icon(Icons.timer, color: Colors.orange),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'صالح حتى: ${_selectedValidUntil != null ? _formatDate(_selectedValidUntil!) : 'غير محدد'}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                if (isEditable)
                  const Icon(Icons.arrow_drop_down, color: Colors.grey),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSection() {
    final isEditable = !_isViewMode || _quotation?.isEditable == true;

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
                  backgroundColor: Colors.purple.shade100,
                  child: Text(
                    _selectedCustomer!.name[0].toUpperCase(),
                    style: TextStyle(
                      color: Colors.purple.shade700,
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
                if (isEditable)
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
          ] else if (isEditable) ...[
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
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('لا يوجد عميل محدد'),
            ),
          ],
        ],
      ),
    );
  }

  // ==================== BUILD WAREHOUSE SECTION (المعدل) ====================

  Widget _buildWarehouseSection() {
    final isEditable = !_isViewMode || _quotation?.isEditable == true;

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
          if (isEditable)
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
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_selectedWarehouse?.displayName ?? 'غير محدد'),
            ),
        ],
      ),
    );
  }

  Widget _buildProductsSection() {
    final isEditable = !_isViewMode || _quotation?.isEditable == true;

    if (!isEditable) {
      return const SizedBox.shrink();
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
                        color: Colors.purple,
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

    final isEditable = !_isViewMode || _quotation?.isEditable == true;

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
                onQuantityChanged: isEditable
                    ? (quantity) => _updateItemQuantity(index, quantity)
                    : null,
                onPriceChanged: isEditable
                    ? (price) => _updateItemPrice(index, price)
                    : null,
                onRemove: isEditable ? () => _removeItem(index) : null,
                showControls: isEditable,
                showPriceControl: isEditable,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountTaxSection() {
    final isEditable = !_isViewMode || _quotation?.isEditable == true;

    if (!isEditable) {
      final discountValue = double.tryParse(_discountController.text) ?? 0;
      final taxRate = double.tryParse(_taxController.text) ?? 0;
      final shippingCost = double.tryParse(_shippingController.text) ?? 0;

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            _buildInfoRow(
              'الخصم',
              discountValue > 0
                  ? '$discountValue${_discountType == DiscountType.percentage ? '%' : '\$'}'
                  : '0',
            ),
            _buildInfoRow('الضريبة', taxRate > 0 ? '$taxRate%' : '0%'),
            _buildInfoRow('الشحن', shippingCost > 0 ? '\$$shippingCost' : '0'),
          ],
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
        children: [
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.shade200),
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
                  ? Colors.purple.shade700
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    final isEditable = !_isViewMode || _quotation?.isEditable == true;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          if (isEditable) ...[
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
            const SizedBox(height: 8),
          ] else if (_termsController.text.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.description, color: Colors.purple),
                const SizedBox(width: 8),
                Text(
                  'الشروط',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _termsController.text,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
          ],
          TextField(
            controller: _notesController,
            maxLines: 3,
            enabled: isEditable,
            decoration: InputDecoration(
              labelText: isEditable ? 'ملاحظات إضافية' : 'ملاحظات',
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
    final isEditable = !_isViewMode || _quotation?.isEditable == true;

    if (_isViewMode && _quotation != null) {
      // عرض الأزرار في وضع العرض
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (_quotation!.isQuotationValid && !_quotation!.isExpired)
            _buildActionButton(
              icon: Icons.file_copy,
              label: 'تحويل لفاتورة',
              color: Colors.green,
              onTap: _convertToInvoice,
            ),
          _buildActionButton(
            icon: Icons.print,
            label: 'طباعة',
            color: Colors.grey,
            onTap: _printQuotation,
          ),
          _buildActionButton(
            icon: Icons.share,
            label: 'إرسال',
            color: Colors.blue,
            onTap: _sendQuotation,
          ),
          if (_quotation!.isDeletable)
            _buildActionButton(
              icon: Icons.delete,
              label: 'حذف',
              color: Colors.red,
              onTap: _deleteQuotation,
            ),
          if (isEditable)
            _buildActionButton(
              icon: Icons.edit,
              label: 'تعديل',
              color: Colors.orange,
              onTap: () {
                setState(() {
                  _isViewMode = false;
                });
              },
            ),
        ],
      );
    }

    // أزرار في وضع التحرير
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              if (_isViewMode) {
                setState(() {
                  _isViewMode = true;
                });
              } else {
                Navigator.pop(context);
              }
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(_isViewMode ? 'إلغاء' : 'إلغاء'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveQuotation,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              disabledBackgroundColor: Colors.grey.shade400,
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                  )
                : Text(_isViewMode ? 'حفظ التعديلات' : 'حفظ عرض السعر'),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );
  }
}
