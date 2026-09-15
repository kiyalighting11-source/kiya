// lib/presentation/screens/warehouses/warehouse_detail_screen.dart

import 'package:flutter/material.dart';

import '../../../data/models/warehouse_stock.dart';
import '../../../data/repositories/warehouse_repository.dart';

class WarehouseDetailScreen extends StatefulWidget {
  final String warehouseId;
  final String warehouseName;

  const WarehouseDetailScreen({
    super.key,
    required this.warehouseId,
    required this.warehouseName,
  });

  @override
  State<WarehouseDetailScreen> createState() => _WarehouseDetailScreenState();
}

class _WarehouseDetailScreenState extends State<WarehouseDetailScreen> {
  final WarehouseRepository _repository = WarehouseRepository();
  List<WarehouseStock> _stock = [];
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final stock = await _repository.getWarehouseStock(widget.warehouseId);
      final stats = await _repository.getWarehouseStats(widget.warehouseId);
      if (mounted) {
        setState(() {
          _stock = stock;
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في جلب البيانات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.warehouseName, style: const TextStyle(fontSize: 18)),
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
            onPressed: _loadData,
            tooltip: 'تحديث',
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
                  Text('جاري تحميل البيانات...'),
                ],
              ),
            )
          : Column(
              children: [
                // ===== إحصائيات =====
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _buildStatCard(
                        title: 'المنتجات',
                        value: _stats['total_items']?.toString() ?? '0',
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      _buildStatCard(
                        title: 'إجمالي الكميات',
                        value: _stats['total_quantity']?.toString() ?? '0',
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                      _buildStatCard(
                        title: 'مخزون منخفض',
                        value: _stats['low_stock']?.toString() ?? '0',
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      _buildStatCard(
                        title: 'نفذ المخزون',
                        value: _stats['out_of_stock']?.toString() ?? '0',
                        color: Colors.red,
                      ),
                    ],
                  ),
                ),

                // ===== قائمة المنتجات =====
                Expanded(
                  child: _stock.isEmpty
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
                                'لا يوجد منتجات في هذا المخزن',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _stock.length,
                          itemBuilder: (context, index) {
                            final item = _stock[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.inventory_2,
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
                                            item.product?.name ?? 'غير معروف',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'الكمية: ${item.quantity}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                          if (item.location != null)
                                            Text(
                                              'الموقع: ${item.location}',
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
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: item.stockStatusColor.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        item.stockStatus,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: item.stockStatusColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
