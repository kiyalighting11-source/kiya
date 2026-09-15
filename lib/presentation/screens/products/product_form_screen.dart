// lib/presentation/screens/products/product_form_screen.dart

import 'package:flutter/material.dart';

import '../../../data/models/product.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/repositories/warehouse_repository.dart';
import '../../../data/models/warehouse.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product;
  final VoidCallback onSaved;

  const ProductFormScreen({super.key, this.product, required this.onSaved});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _costController = TextEditingController();
  final _skuController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _discountPercentageController = TextEditingController();

  final ProductRepository _productRepository = ProductRepository();
  final WarehouseRepository _warehouseRepository = WarehouseRepository();
  bool _isLoading = false;
  bool _isActive = true;
  bool _hasDiscount = false;

  static const String _brand = 'Kiya Lighting';

  final List<String> _categories = [
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

  String? _selectedCategory;

  // متغيرات المخازن المتعددة
  List<Warehouse> _warehouses = [];
  List<Map<String, dynamic>> _selectedWarehouses = [];
  String? _tempWarehouseId;
  final _tempQuantityController = TextEditingController();
  bool _isLoadingStock = false;

  @override
  void initState() {
    super.initState();
    _loadWarehouses();

    if (widget.product != null) {
      _loadProductWithStock();
    }
  }

  // جلب المنتج مع المخزون
  Future<void> _loadProductWithStock() async {
    setState(() => _isLoadingStock = true);

    try {
      final data = await _productRepository.getProductWithStock(
        widget.product!.id!,
      );

      if (mounted) {
        final product = data['product'] as Product;
        final warehouseStock =
            data['warehouse_stock'] as List<Map<String, dynamic>>;

        // تعبئة بيانات المنتج
        _nameController.text = product.name;
        _descriptionController.text = product.description ?? '';
        _priceController.text = product.price.toString();
        _costController.text = product.cost?.toString() ?? '';
        _selectedCategory = product.category;
        _skuController.text = product.sku ?? '';
        _barcodeController.text = product.barcode ?? '';
        _isActive = product.isActive ?? true;
        _hasDiscount = product.hasDiscount ?? false;
        _discountPercentageController.text =
            product.discountPercentage?.toString() ?? '';

        // تعبئة المخازن المتعددة
        _selectedWarehouses = [];
        for (var stock in warehouseStock) {
          final warehouse = stock['warehouse'] as Map<String, dynamic>;
          final quantity = stock['quantity'] as int;
          _selectedWarehouses.add({
            'warehouse_id': warehouse['id'],
            'warehouse_name': warehouse['name'],
            'quantity': quantity,
          });
        }

        setState(() {});
      }
    } catch (e) {
      debugPrint('❌ خطأ في جلب بيانات المنتج مع المخزون: $e');
      _loadProductBasicData();
    } finally {
      if (mounted) {
        setState(() => _isLoadingStock = false);
      }
    }
  }

  // جلب البيانات الأساسية فقط (بدون مخزون)
  void _loadProductBasicData() {
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _descriptionController.text = widget.product!.description ?? '';
      _priceController.text = widget.product!.price.toString();
      _costController.text = widget.product!.cost?.toString() ?? '';
      _selectedCategory = widget.product!.category;
      _skuController.text = widget.product!.sku ?? '';
      _barcodeController.text = widget.product!.barcode ?? '';
      _isActive = widget.product!.isActive ?? true;
      _hasDiscount = widget.product!.hasDiscount ?? false;
      _discountPercentageController.text =
          widget.product!.discountPercentage?.toString() ?? '';
    }
  }

  // جلب المخازن
  Future<void> _loadWarehouses() async {
    try {
      final warehouses = await _warehouseRepository.getActiveWarehouses();
      if (mounted) {
        setState(() {
          _warehouses = warehouses;
        });
      }
    } catch (e) {
      debugPrint('❌ خطأ في جلب المخازن: $e');
    }
  }

  // إضافة مخزن جديد
  void _addWarehouse() {
    if (_tempWarehouseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ الرجاء اختيار المخزن'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final quantity = int.tryParse(_tempQuantityController.text.trim());
    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ الرجاء إدخال كمية صحيحة أكبر من 0'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // التأكد من عدم تكرار المخزن
    final exists = _selectedWarehouses.any(
      (item) => item['warehouse_id'] == _tempWarehouseId,
    );

    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ هذا المخزن مضاف بالفعل'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final warehouse = _warehouses.firstWhere((w) => w.id == _tempWarehouseId);

    setState(() {
      _selectedWarehouses.add({
        'warehouse_id': warehouse.id!,
        'warehouse_name': warehouse.name,
        'quantity': quantity,
      });
      _tempWarehouseId = null;
      _tempQuantityController.clear();
    });
  }

  // حذف مخزن من القائمة
  void _removeWarehouse(int index) {
    setState(() {
      _selectedWarehouses.removeAt(index);
    });
  }

  // تحديث كمية مخزن
  void _updateWarehouseQuantity(int index, int newQuantity) {
    setState(() {
      _selectedWarehouses[index]['quantity'] = newQuantity;
    });
  }

  // حساب إجمالي الكمية
  int get _totalQuantity {
    int total = 0;
    for (var item in _selectedWarehouses) {
      total += (item['quantity'] as int);
    }
    return total;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _costController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _discountPercentageController.dispose();
    _tempQuantityController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      debugPrint('🔄 بدء حفظ المنتج...');

      // إنشاء المنتج
      final product = Product(
        id: widget.product?.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        cost: _costController.text.trim().isEmpty
            ? null
            : double.parse(_costController.text.trim()),
        category: _selectedCategory,
        sku: _skuController.text.trim().isEmpty
            ? null
            : _skuController.text.trim(),
        barcode: _barcodeController.text.trim().isEmpty
            ? null
            : _barcodeController.text.trim(),
        brand: _brand,
        isActive: _isActive,
        hasDiscount: _hasDiscount,
        discountPercentage:
            _hasDiscount && _discountPercentageController.text.trim().isNotEmpty
            ? double.parse(_discountPercentageController.text.trim())
            : null,
      );

      Product savedProduct;

      if (widget.product == null) {
        // ===== إضافة منتج جديد =====
        debugPrint('➕ إضافة منتج جديد...');

        savedProduct = await _productRepository.createProduct(product);
        debugPrint('✅ تم إضافة المنتج: ${savedProduct.id}');

        // إضافة الكمية إلى كل المخازن المختارة
        for (var item in _selectedWarehouses) {
          final warehouseId = item['warehouse_id'] as String;
          final quantity = item['quantity'] as int;

          if (quantity > 0) {
            await _productRepository.addStock(
              savedProduct.id!,
              warehouseId,
              quantity,
              reason: 'إضافة منتج جديد',
            );
            debugPrint('✅ تم إضافة المخزون للمخزن: $warehouseId');
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ تم إضافة المنتج بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // ===== تحديث منتج موجود =====
        debugPrint('✏️ تحديث منتج موجود...');

        savedProduct = await _productRepository.updateProduct(product);
        debugPrint('✅ تم تحديث المنتج: ${savedProduct.id}');

        // جلب المخزون الحالي
        final existingStock = await _productRepository.getProductStock(
          savedProduct.id!,
        );
        final existingMap = <String, int>{};
        for (var stock in existingStock) {
          existingMap[stock.warehouseId] = stock.quantity;
        }

        // تحديث كل مخزن
        final selectedMap = <String, int>{};
        for (var item in _selectedWarehouses) {
          final warehouseId = item['warehouse_id'] as String;
          final quantity = item['quantity'] as int;
          selectedMap[warehouseId] = quantity;
        }

        // حذف المخازن التي تم إزالتها
        for (var entry in existingMap.entries) {
          if (!selectedMap.containsKey(entry.key)) {
            await _productRepository.removeStock(
              savedProduct.id!,
              entry.key,
              entry.value,
              reason: 'إزالة من المخزن',
            );
            debugPrint('✅ تم حذف المخزون من المخزن: ${entry.key}');
          }
        }

        // تحديث أو إضافة المخازن
        for (var entry in selectedMap.entries) {
          final warehouseId = entry.key;
          final newQuantity = entry.value;
          final oldQuantity = existingMap[warehouseId] ?? 0;

          if (newQuantity == 0) {
            // حذف المخزن إذا كانت الكمية 0
            if (oldQuantity > 0) {
              await _productRepository.removeStock(
                savedProduct.id!,
                warehouseId,
                oldQuantity,
                reason: 'حذف المخزون',
              );
              debugPrint('✅ تم حذف المخزون من المخزن: $warehouseId');
            }
          } else if (oldQuantity > 0) {
            // تحديث الكمية
            await _productRepository.updateStock(
              savedProduct.id!,
              warehouseId,
              newQuantity,
            );
            debugPrint('✅ تم تحديث المخزون للمخزن: $warehouseId');
          } else {
            // إضافة مخزن جديد
            await _productRepository.addStock(
              savedProduct.id!,
              warehouseId,
              newQuantity,
              reason: 'إضافة مخزن جديد',
            );
            debugPrint('✅ تم إضافة المخزون للمخزن الجديد: $warehouseId');
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ تم تحديث المنتج بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      widget.onSaved();
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('❌ خطأ كامل: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.product == null ? 'إضافة منتج جديد' : 'تعديل بيانات المنتج',
          style: const TextStyle(fontSize: 18),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_selectedWarehouses.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.inventory, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'إجمالي: $_totalQuantity',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: _isLoadingStock
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('جاري تحميل بيانات المنتج...'),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ===== المعلومات الأساسية =====
                      _buildSectionTitle(
                        'المعلومات الأساسية',
                        Icons.info_outline,
                      ),
                      const SizedBox(height: 12),

                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              // الاسم
                              TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: 'اسم المنتج *',
                                  prefixIcon: Icon(
                                    Icons.production_quantity_limits,
                                  ),
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                    ? 'اسم المنتج مطلوب'
                                    : null,
                              ),
                              const SizedBox(height: 12),

                              // الوصف
                              TextFormField(
                                controller: _descriptionController,
                                decoration: const InputDecoration(
                                  labelText: 'الوصف',
                                  prefixIcon: Icon(Icons.description),
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: 3,
                              ),
                              const SizedBox(height: 12),

                              // السعر والتكلفة
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _priceController,
                                      decoration: const InputDecoration(
                                        labelText: 'السعر *',
                                        prefixIcon: Icon(Icons.attach_money),
                                        border: OutlineInputBorder(),
                                      ),
                                      keyboardType: TextInputType.number,
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'السعر مطلوب';
                                        }
                                        if (double.tryParse(value) == null) {
                                          return 'الرجاء إدخال رقم صحيح';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _costController,
                                      decoration: const InputDecoration(
                                        labelText: 'التكلفة',
                                        prefixIcon: Icon(Icons.money_off),
                                        border: OutlineInputBorder(),
                                      ),
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // التصنيف
                              DropdownButtonFormField<String>(
                                decoration: const InputDecoration(
                                  labelText: 'التصنيف *',
                                  prefixIcon: Icon(Icons.category),
                                  border: OutlineInputBorder(),
                                ),
                                initialValue: _selectedCategory,
                                hint: const Text('اختر التصنيف'),
                                isExpanded: true,
                                items: _categories.map((category) {
                                  return DropdownMenuItem(
                                    value: category,
                                    child: Text(
                                      category,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedCategory = value;
                                  });
                                },
                                validator: (value) =>
                                    value == null || value.isEmpty
                                    ? 'الرجاء اختيار التصنيف'
                                    : null,
                              ),
                              const SizedBox(height: 12),

                              // الماركة ثابتة
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.branding_watermark,
                                      color: Colors.green,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'الماركة:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _brand,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'ثابت',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.green,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),

                              // SKU والباركود
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _skuController,
                                      decoration: const InputDecoration(
                                        labelText: 'SKU',
                                        prefixIcon: Icon(Icons.code),
                                        border: OutlineInputBorder(),
                                        hintText: 'رمز المنتج',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _barcodeController,
                                      decoration: const InputDecoration(
                                        labelText: 'الباركود',
                                        prefixIcon: Icon(Icons.qr_code),
                                        border: OutlineInputBorder(),
                                        hintText: 'باركود المنتج',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ===== المخازن والكميات =====
                      _buildSectionTitle('المخازن والكميات', Icons.warehouse),
                      const SizedBox(height: 12),

                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              if (_selectedWarehouses.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.green.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.inventory,
                                        color: Colors.green,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'إجمالي الكمية: $_totalQuantity قطعة',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        'في ${_selectedWarehouses.length} مخزن',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              if (_selectedWarehouses.isNotEmpty)
                                Column(
                                  children: [
                                    const Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'المخزن',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'الكمية',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        SizedBox(width: 60),
                                      ],
                                    ),
                                    const Divider(),
                                    ..._selectedWarehouses.asMap().entries.map((
                                      entry,
                                    ) {
                                      final index = entry.key;
                                      final item = entry.value;
                                      final warehouseName =
                                          item['warehouse_name'] as String;
                                      final quantity = item['quantity'] as int;

                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 4,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                warehouseName,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            SizedBox(
                                              width: 80,
                                              child: TextFormField(
                                                initialValue: quantity
                                                    .toString(),
                                                keyboardType:
                                                    TextInputType.number,
                                                decoration:
                                                    const InputDecoration(
                                                      border:
                                                          OutlineInputBorder(),
                                                      contentPadding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 4,
                                                          ),
                                                    ),
                                                onChanged: (value) {
                                                  final newQty = int.tryParse(
                                                    value,
                                                  );
                                                  if (newQty != null &&
                                                      newQty >= 0) {
                                                    _updateWarehouseQuantity(
                                                      index,
                                                      newQty,
                                                    );
                                                  }
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.remove_circle,
                                                color: Colors.red,
                                              ),
                                              onPressed: () =>
                                                  _removeWarehouse(index),
                                              tooltip: 'حذف المخزن',
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                    const SizedBox(height: 12),
                                  ],
                                ),

                              if (_selectedWarehouses.isEmpty)
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'لم يتم إضافة أي مخزن حتى الآن',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                ),

                              // إضافة مخزن جديد
                              const Text(
                                'إضافة مخزن جديد',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      decoration: const InputDecoration(
                                        labelText: 'اختر المخزن',
                                        prefixIcon: Icon(Icons.warehouse),
                                        border: OutlineInputBorder(),
                                      ),
                                      initialValue: _tempWarehouseId,
                                      hint: const Text('اختر المخزن'),
                                      isExpanded: true,
                                      items: _warehouses
                                          .where(
                                            (w) => !_selectedWarehouses.any(
                                              (item) =>
                                                  item['warehouse_id'] == w.id,
                                            ),
                                          )
                                          .map((warehouse) {
                                            return DropdownMenuItem(
                                              value: warehouse.id,
                                              child: Text(
                                                warehouse.displayName,
                                              ),
                                            );
                                          })
                                          // ✅ تم إزالة toList() من هنا
                                          .toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _tempWarehouseId = value;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 80,
                                    child: TextFormField(
                                      controller: _tempQuantityController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        hintText: 'الكمية',
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.add_circle,
                                      color: Colors.green,
                                      size: 32,
                                    ),
                                    onPressed: _addWarehouse,
                                    tooltip: 'إضافة المخزن',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ===== الخصومات =====
                      _buildSectionTitle('الخصومات والعروض', Icons.local_offer),
                      const SizedBox(height: 12),

                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              SwitchListTile(
                                title: const Text(
                                  'تفعيل الخصم',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: const Text('إضافة خصم على المنتج'),
                                value: _hasDiscount,
                                trackColor:
                                    WidgetStateProperty.resolveWith<Color>((
                                      Set<WidgetState> states,
                                    ) {
                                      if (states.contains(
                                        WidgetState.selected,
                                      )) {
                                        return Colors.green;
                                      }
                                      return Colors.grey.shade300;
                                    }),
                                thumbColor:
                                    WidgetStateProperty.resolveWith<Color>((
                                      Set<WidgetState> states,
                                    ) {
                                      if (states.contains(
                                        WidgetState.selected,
                                      )) {
                                        return Colors.green;
                                      }
                                      return Colors.grey.shade50;
                                    }),
                                onChanged: (value) {
                                  setState(() {
                                    _hasDiscount = value;
                                    if (!value) {
                                      _discountPercentageController.clear();
                                    }
                                  });
                                },
                              ),

                              if (_hasDiscount) ...[
                                const Divider(),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _discountPercentageController,
                                  decoration: const InputDecoration(
                                    labelText: 'نسبة الخصم %',
                                    prefixIcon: Icon(Icons.percent),
                                    border: OutlineInputBorder(),
                                    helperText: 'أدخل نسبة الخصم (مثال: 10)',
                                    helperStyle: TextStyle(fontSize: 12),
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value != null &&
                                        value.trim().isNotEmpty) {
                                      final discount = double.tryParse(value);
                                      if (discount == null) {
                                        return 'الرجاء إدخال رقم صحيح';
                                      }
                                      if (discount < 0 || discount > 100) {
                                        return 'النسبة بين 0 و 100';
                                      }
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 8),
                                if (_priceController.text.trim().isNotEmpty &&
                                    _discountPercentageController.text
                                        .trim()
                                        .isNotEmpty)
                                  _buildDiscountPreview(),
                              ],
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ===== الحالة =====
                      _buildSectionTitle('حالة المنتج', Icons.check_circle),
                      const SizedBox(height: 12),

                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: SwitchListTile(
                            title: const Text(
                              'المنتج نشط',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: const Text('إظهار المنتج في القائمة'),
                            value: _isActive,
                            trackColor: WidgetStateProperty.resolveWith<Color>((
                              Set<WidgetState> states,
                            ) {
                              if (states.contains(WidgetState.selected)) {
                                return Colors.green;
                              }
                              return Colors.grey.shade300;
                            }),
                            thumbColor: WidgetStateProperty.resolveWith<Color>((
                              Set<WidgetState> states,
                            ) {
                              if (states.contains(WidgetState.selected)) {
                                return Colors.green;
                              }
                              return Colors.grey.shade50;
                            }),
                            onChanged: (value) {
                              setState(() {
                                _isActive = value;
                              });
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ===== زر الحفظ =====
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: _isLoading
                            ? Container(
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                      strokeWidth: 3,
                                    ),
                                  ),
                                ),
                              )
                            : ElevatedButton(
                                onPressed: _saveProduct,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 4,
                                ),
                                child: Text(
                                  widget.product == null
                                      ? 'إضافة المنتج'
                                      : 'تحديث البيانات',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // ===== عرض معاينة السعر بعد الخصم =====
  Widget _buildDiscountPreview() {
    final price = double.tryParse(_priceController.text.trim());
    final discount = double.tryParse(_discountPercentageController.text.trim());

    if (price == null || discount == null) {
      return const SizedBox.shrink();
    }

    final discountedPrice = price - (price * discount / 100);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.calculate, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'السعر بعد الخصم',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                  '\$${discountedPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade200,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'وفر ${discount.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.green.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== بناء عنوان القسم مع أيقونة =====
  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.green.shade700,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Icon(icon, color: Colors.green.shade700, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
