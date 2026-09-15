// lib/presentation/screens/warehouses/warehouses_screen.dart

import 'package:flutter/material.dart';

import '../../../data/models/warehouse.dart';
import '../../../data/repositories/warehouse_repository.dart';
import 'warehouse_form_screen.dart';
import 'warehouse_detail_screen.dart';

class WarehousesScreen extends StatefulWidget {
  const WarehousesScreen({super.key});

  @override
  State<WarehousesScreen> createState() => _WarehousesScreenState();
}

class _WarehousesScreenState extends State<WarehousesScreen> {
  final WarehouseRepository _repository = WarehouseRepository();
  List<Warehouse> _warehouses = [];
  List<Warehouse> _filteredWarehouses = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadWarehouses();
  }

  Future<void> _loadWarehouses() async {
    setState(() => _isLoading = true);
    try {
      final warehouses = await _repository.getAllWarehouses();
      if (mounted) {
        setState(() {
          _warehouses = warehouses;
          _filteredWarehouses = warehouses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في جلب المخازن: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterWarehouses() {
    setState(() {
      if (_searchQuery.isEmpty) {
        _filteredWarehouses = _warehouses;
      } else {
        final query = _searchQuery.toLowerCase();
        _filteredWarehouses = _warehouses
            .where(
              (w) =>
                  w.name.toLowerCase().contains(query) ||
                  (w.code?.toLowerCase().contains(query) ?? false) ||
                  (w.location?.toLowerCase().contains(query) ?? false) ||
                  (w.manager?.toLowerCase().contains(query) ?? false),
            )
            .toList();
      }
    });
  }

  Future<void> _deleteWarehouse(Warehouse warehouse) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف "${warehouse.name}"؟'),
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
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _repository.deleteWarehouse(warehouse.id!);
        if (mounted) {
          setState(() {
            _warehouses.removeWhere((w) => w.id == warehouse.id);
            _filterWarehouses();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ تم حذف المخزن بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ خطأ في الحذف: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المخازن', style: TextStyle(fontSize: 18)),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWarehouses,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: Column(
        children: [
          // ===== شريط البحث =====
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
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
                  hintText: 'بحث عن مخزن...',
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
                              _filterWarehouses();
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
                  _filterWarehouses();
                },
              ),
            ),
          ),

          // ===== قائمة المخازن =====
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('جاري تحميل المخازن...'),
                      ],
                    ),
                  )
                : _filteredWarehouses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.warehouse_outlined,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'لا توجد نتائج بحث'
                              : 'لا يوجد مخازن',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (_searchQuery.isEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'اضغط على زر + لإضافة مخزن جديد',
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
                    itemCount: _filteredWarehouses.length,
                    itemBuilder: (context, index) {
                      final warehouse = _filteredWarehouses[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => WarehouseDetailScreen(
                                  warehouseId: warehouse.id!,
                                  warehouseName: warehouse.name,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.teal.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.warehouse,
                                    size: 32,
                                    color: Colors.teal.shade700,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        warehouse.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 2,
                                        children: [
                                          if (warehouse.code != null)
                                            Text(
                                              '🔖 ${warehouse.code}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          if (warehouse.location != null)
                                            Text(
                                              '📍 ${warehouse.location}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          if (warehouse.manager != null)
                                            Text(
                                              '👤 ${warehouse.manager}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: (warehouse.isActive ?? true)
                                        ? Colors.green.shade100
                                        : Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    (warehouse.isActive ?? true)
                                        ? 'نشط'
                                        : 'غير نشط',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: (warehouse.isActive ?? true)
                                          ? Colors.green.shade700
                                          : Colors.red.shade700,
                                    ),
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert),
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              WarehouseFormScreen(
                                                warehouse: warehouse,
                                                onSaved: () =>
                                                    _loadWarehouses(),
                                              ),
                                        ),
                                      );
                                    } else if (value == 'delete') {
                                      _deleteWarehouse(warehouse);
                                    }
                                  },
                                  itemBuilder: (context) => [
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
                  WarehouseFormScreen(onSaved: () => _loadWarehouses()),
            ),
          );
        },
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
