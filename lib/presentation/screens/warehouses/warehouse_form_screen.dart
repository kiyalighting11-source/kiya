// lib/presentation/screens/warehouses/warehouse_form_screen.dart

import 'package:flutter/material.dart';

import '../../../data/models/warehouse.dart';
import '../../../data/repositories/warehouse_repository.dart';

class WarehouseFormScreen extends StatefulWidget {
  final Warehouse? warehouse;
  final VoidCallback onSaved;

  const WarehouseFormScreen({super.key, this.warehouse, required this.onSaved});

  @override
  State<WarehouseFormScreen> createState() => _WarehouseFormScreenState();
}

class _WarehouseFormScreenState extends State<WarehouseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _locationController = TextEditingController();
  final _managerController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();

  final WarehouseRepository _repository = WarehouseRepository();
  bool _isLoading = false;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    if (widget.warehouse != null) {
      _nameController.text = widget.warehouse!.name;
      _codeController.text = widget.warehouse!.code ?? '';
      _locationController.text = widget.warehouse!.location ?? '';
      _managerController.text = widget.warehouse!.manager ?? '';
      _phoneController.text = widget.warehouse!.phone ?? '';
      _descriptionController.text = widget.warehouse!.description ?? '';
      _isActive = widget.warehouse!.isActive ?? true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _locationController.dispose();
    _managerController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveWarehouse() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final warehouse = Warehouse(
        id: widget.warehouse?.id,
        name: _nameController.text.trim(),
        code: _codeController.text.trim().isEmpty
            ? null
            : _codeController.text.trim(),
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        manager: _managerController.text.trim().isEmpty
            ? null
            : _managerController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        isActive: _isActive,
      );

      if (widget.warehouse == null) {
        await _repository.createWarehouse(warehouse);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ تم إضافة المخزن بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await _repository.updateWarehouse(warehouse);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ تم تحديث المخزن بنجاح'),
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
          widget.warehouse == null ? 'إضافة مخزن جديد' : 'تعديل بيانات المخزن',
          style: const TextStyle(fontSize: 18),
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('معلومات المخزن'),
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
                            labelText: 'اسم المخزن *',
                            prefixIcon: Icon(Icons.warehouse),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'اسم المخزن مطلوب'
                              : null,
                        ),
                        const SizedBox(height: 12),

                        // الكود
                        TextFormField(
                          controller: _codeController,
                          decoration: const InputDecoration(
                            labelText: 'كود المخزن',
                            prefixIcon: Icon(Icons.code),
                            border: OutlineInputBorder(),
                            hintText: 'مثال: WH-001',
                          ),
                        ),
                        const SizedBox(height: 12),

                        // الموقع
                        TextFormField(
                          controller: _locationController,
                          decoration: const InputDecoration(
                            labelText: 'الموقع',
                            prefixIcon: Icon(Icons.location_on),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // المدير
                        TextFormField(
                          controller: _managerController,
                          decoration: const InputDecoration(
                            labelText: 'مدير المخزن',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // الهاتف
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'رقم الهاتف',
                            prefixIcon: Icon(Icons.phone),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.phone,
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
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                _buildSectionTitle('حالة المخزن'),
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
                        'المخزن نشط',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text('إظهار المخزن في القائمة'),
                      value: _isActive,
                      trackColor: WidgetStateProperty.resolveWith<Color>((
                        Set<WidgetState> states,
                      ) {
                        if (states.contains(WidgetState.selected)) {
                          return Colors.teal;
                        }
                        return Colors.grey.shade300;
                      }),
                      thumbColor: WidgetStateProperty.resolveWith<Color>((
                        Set<WidgetState> states,
                      ) {
                        if (states.contains(WidgetState.selected)) {
                          return Colors.teal;
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

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _saveWarehouse,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          child: Text(
                            widget.warehouse == null
                                ? 'إضافة المخزن'
                                : 'تحديث البيانات',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.teal.shade700,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.teal.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
