// lib/presentation/screens/products/products_screen.dart

import 'package:flutter/material.dart';

import '../../../data/models/product.dart';
import '../../../data/repositories/product_repository.dart';
import 'product_form_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final ProductRepository _repository = ProductRepository();
  List<Map<String, dynamic>> _productsWithStock = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'الكل';

  final List<String> _filters = [
    'الكل',
    'نشط',
    'غير نشط',
    'مخفض',
    'مخزون منخفض',
    'نفذ المخزون',
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  // ==================== دالة مساعدة للـ SnackBar ====================
  void _showSnackBar(String message, {Color backgroundColor = Colors.green}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: backgroundColor),
      );
    }
  }

  // ==================== تحميل المنتجات ====================
  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await _repository.getAllProductsWithStock();
      if (mounted) {
        setState(() {
          _productsWithStock = products;
          _filteredProducts = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('خطأ في جلب المنتجات: $e', backgroundColor: Colors.red);
      }
    }
  }

  // ==================== تصفية المنتجات ====================
  void _filterProducts() {
    setState(() {
      List<Map<String, dynamic>> filtered = List.from(_productsWithStock);

      switch (_selectedFilter) {
        case 'نشط':
          filtered = filtered
              .where((item) => (item['product'] as Product).isActive == true)
              .toList();
          break;
        case 'غير نشط':
          filtered = filtered
              .where((item) => (item['product'] as Product).isActive == false)
              .toList();
          break;
        case 'مخفض':
          filtered = filtered
              .where((item) => (item['product'] as Product).hasDiscount == true)
              .toList();
          break;
        case 'مخزون منخفض':
          filtered = filtered
              .where(
                (item) =>
                    (item['total_quantity'] as int) <= 10 &&
                    (item['total_quantity'] as int) > 0,
              )
              .toList();
          break;
        case 'نفذ المخزون':
          filtered = filtered
              .where((item) => (item['total_quantity'] as int) == 0)
              .toList();
          break;
        default:
          break;
      }

      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        filtered = filtered.where((item) {
          final product = item['product'] as Product;
          return product.name.toLowerCase().contains(query) ||
              (product.category?.toLowerCase().contains(query) ?? false) ||
              (product.sku?.toLowerCase().contains(query) ?? false) ||
              (product.barcode?.toLowerCase().contains(query) ?? false);
        }).toList();
      }

      _filteredProducts = filtered;
    });
  }

  // ==================== حذف منتج ====================
  Future<void> _deleteProduct(Product product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف "${product.name}"؟'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

    if (confirm == true) {
      try {
        await _repository.deleteProduct(product.id!);
        if (mounted) {
          await _loadProducts();
          _showSnackBar('✅ تم حذف المنتج بنجاح');
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar('❌ خطأ في الحذف: $e', backgroundColor: Colors.red);
        }
      }
    }
  }

  // ==================== عرض تفاصيل المنتج والمخزون ====================
  void _showProductStock(
    Product product,
    int totalQuantity,
    List<Map<String, dynamic>> warehouseStock,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===== مؤشر السحب =====
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ===== رأس المنتج =====
                Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.inventory_2,
                        size: 40,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (product.category != null)
                            Text(
                              '📂 ${product.category}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          if (product.brand != null)
                            Text(
                              '🏷️ ${product.brand}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (product.hasDiscount == true) ...[
                                Text(
                                  product.formattedPrice,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade500,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  product.formattedFinalPrice,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ] else
                                Text(
                                  product.formattedPrice,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // ===== إجمالي الكمية =====
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: totalQuantity > 0
                            ? Colors.green.shade100
                            : Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            totalQuantity.toString(),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: totalQuantity > 0
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                            ),
                          ),
                          Text(
                            'إجمالي',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // ===== معلومات المنتج =====
                const Text(
                  'معلومات المنتج',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                _buildInfoTile(
                  icon: Icons.description,
                  label: 'الوصف',
                  value: product.description,
                ),
                _buildInfoTile(
                  icon: Icons.money_off,
                  label: 'التكلفة',
                  value: product.cost != null
                      ? '\$${product.cost!.toStringAsFixed(2)}'
                      : null,
                ),
                _buildInfoTile(
                  icon: Icons.category,
                  label: 'التصنيف',
                  value: product.category,
                ),
                _buildInfoTile(
                  icon: Icons.branding_watermark,
                  label: 'الماركة',
                  value: product.brand,
                ),
                _buildInfoTile(
                  icon: Icons.code,
                  label: 'SKU',
                  value: product.sku,
                ),
                _buildInfoTile(
                  icon: Icons.qr_code,
                  label: 'الباركود',
                  value: product.barcode,
                ),
                _buildInfoTile(
                  icon: Icons.check_circle,
                  label: 'الحالة',
                  value: product.isActive == true ? 'نشط' : 'غير نشط',
                ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),

                // ===== المخزون في المخازن =====
                const Text(
                  'المخزون في المخازن',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                if (warehouseStock.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: const Center(
                      child: Text(
                        'لا يوجد مخزون لهذا المنتج',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  // ✅ تم إزالة toList من الـ spread
                  ...warehouseStock.map((item) {
                    final warehouse = item['warehouse'] as Map<String, dynamic>;
                    final quantity = item['quantity'] as int;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warehouse,
                              color: quantity > 0 ? Colors.teal : Colors.grey,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    warehouse['name'] ?? 'مخزن غير معروف',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (warehouse['code'] != null)
                                    Text(
                                      '🔖 ${warehouse['code']}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  if (warehouse['location'] != null)
                                    Text(
                                      '📍 ${warehouse['location']}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: quantity > 0
                                    ? Colors.green.shade100
                                    : Colors.red.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    quantity.toString(),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: quantity > 0
                                          ? Colors.green.shade700
                                          : Colors.red.shade700,
                                    ),
                                  ),
                                  Text(
                                    'قطعة',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                // ===== الخصم =====
                if (product.hasDiscount == true) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    'الخصم',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_offer, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          'خصم ${product.discountPercentage?.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'السعر بعد الخصم: ${product.formattedFinalPrice}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  // ==================== بناء معلومات المنتج ====================
  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String? value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 20),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          Expanded(
            child: Text(
              value?.isNotEmpty == true ? value! : 'غير محدد',
              style: TextStyle(
                color: value?.isNotEmpty == true
                    ? Colors.black
                    : Colors.grey.shade500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المنتجات', style: TextStyle(fontSize: 18)),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProducts,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: Column(
        children: [
          // ===== شريط البحث والفلتر =====
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // ===== حقل البحث =====
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'بحث عن منتج...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                setState(() {
                                  _searchQuery = '';
                                  _filterProducts();
                                });
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                      _filterProducts();
                    },
                  ),
                ),
                const SizedBox(height: 8),

                // ===== الفلاتر =====
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: FilterChip(
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedFilter = filter;
                              _filterProducts();
                            });
                          },
                          backgroundColor: Colors.grey.shade200,
                          selectedColor: Colors.green.shade100,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.green.shade700
                                : Colors.black,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          avatar: isSelected
                              ? Icon(
                                  Icons.check_circle,
                                  size: 16,
                                  color: Colors.green.shade700,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // ===== قائمة المنتجات =====
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('جاري تحميل المنتجات...'),
                      ],
                    ),
                  )
                : _filteredProducts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_outlined,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'لا توجد نتائج بحث'
                              : 'لا يوجد منتجات',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (_searchQuery.isEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'اضغط على زر + لإضافة منتج جديد',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, index) {
                      final item = _filteredProducts[index];
                      final product = item['product'] as Product;
                      final totalQuantity = item['total_quantity'] as int;
                      final warehouseStock =
                          item['warehouse_stock'] as List<Map<String, dynamic>>;

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _showProductStock(
                            product,
                            totalQuantity,
                            warehouseStock,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                // ===== أيقونة المنتج =====
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.inventory_2,
                                    size: 32,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // ===== معلومات المنتج =====
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 2,
                                        children: [
                                          if (product.category != null)
                                            Text(
                                              '📂 ${product.category}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          if (product.brand != null)
                                            Text(
                                              '🏷️ ${product.brand}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          if (product.sku != null)
                                            Text(
                                              '🔖 ${product.sku}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          if (product.hasDiscount == true) ...[
                                            Text(
                                              product.formattedPrice,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey.shade500,
                                                decoration:
                                                    TextDecoration.lineThrough,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              product.formattedFinalPrice,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green,
                                              ),
                                            ),
                                          ] else
                                            Text(
                                              product.formattedPrice,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green,
                                              ),
                                            ),
                                          const Spacer(),

                                          // ===== الكمية =====
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: totalQuantity > 0
                                                  ? (totalQuantity <= 10
                                                        ? Colors.orange.shade100
                                                        : Colors.green.shade100)
                                                  : Colors.red.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  totalQuantity > 0
                                                      ? (totalQuantity <= 10
                                                            ? Icons
                                                                  .warning_amber_rounded
                                                            : Icons
                                                                  .check_circle)
                                                      : Icons.cancel,
                                                  size: 14,
                                                  color: totalQuantity > 0
                                                      ? (totalQuantity <= 10
                                                            ? Colors
                                                                  .orange
                                                                  .shade700
                                                            : Colors
                                                                  .green
                                                                  .shade700)
                                                      : Colors.red.shade700,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  totalQuantity.toString(),
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: totalQuantity > 0
                                                        ? (totalQuantity <= 10
                                                              ? Colors
                                                                    .orange
                                                                    .shade700
                                                              : Colors
                                                                    .green
                                                                    .shade700)
                                                        : Colors.red.shade700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),

                                          // ===== حالة المنتج =====
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: (product.isActive ?? true)
                                                  ? Colors.green.shade100
                                                  : Colors.red.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              (product.isActive ?? true)
                                                  ? 'نشط'
                                                  : 'غير نشط',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    (product.isActive ?? true)
                                                    ? Colors.green.shade700
                                                    : Colors.red.shade700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // ===== قائمة الخيارات =====
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert),
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ProductFormScreen(
                                                product: product,
                                                onSaved: () => _loadProducts(),
                                              ),
                                        ),
                                      );
                                    } else if (value == 'delete') {
                                      _deleteProduct(product);
                                    } else if (value == 'details') {
                                      _showProductStock(
                                        product,
                                        totalQuantity,
                                        warehouseStock,
                                      );
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'details',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.visibility,
                                            color: Colors.blue,
                                          ),
                                          SizedBox(width: 8),
                                          Text('عرض التفاصيل'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.edit,
                                            color: Colors.orange,
                                          ),
                                          SizedBox(width: 8),
                                          Text('تعديل'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('حذف'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ProductFormScreen(onSaved: () => _loadProducts()),
            ),
          );
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
