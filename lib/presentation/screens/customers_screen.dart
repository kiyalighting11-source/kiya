import 'package:flutter/material.dart';
import '../../data/models/customer.dart';
import '../../data/repositories/customer_repository.dart';
import 'customer_form_screen.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final CustomerRepository _repository = CustomerRepository();
  List<Customer> _customers = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    try {
      final customers = await _repository.getAllCustomers();
      if (mounted) {
        setState(() {
          _customers = customers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في جلب العملاء: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteCustomer(Customer customer) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف "${customer.name}"؟'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'إلغاء',
              style: TextStyle(color: Colors.grey),
            ),
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
        await _repository.deleteCustomer(customer.id!);
        if (mounted) {
          setState(() => _customers.removeWhere((c) => c.id == customer.id));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ تم حذف العميل بنجاح'),
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

  void _showCustomerDetails(Customer customer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.blue.shade100,
                      child: Text(
                        customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 32,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (customer.country != null && customer.country!.isNotEmpty)
                            Text(
                              '🌍 ${customer.country}',
                              style: TextStyle(
                                fontSize: 14,
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

                // معلومات الاتصال
                _buildInfoTile(
                  icon: Icons.phone,
                  label: 'رقم الهاتف',
                  value: customer.phone,
                  color: Colors.green,
                ),
                _buildInfoTile(
                  icon: Icons.email,
                  label: 'البريد الإلكتروني',
                  value: customer.email,
                  color: Colors.blue,
                ),
                _buildInfoTile(
                  icon: Icons.location_on,
                  label: 'العنوان',
                  value: customer.address,
                  color: Colors.orange,
                ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),

                // وسائل التواصل الاجتماعي
                const Text(
                  'وسائل التواصل الاجتماعي',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildSocialTile(
                  icon: Icons.facebook,
                  label: 'فيسبوك',
                  value: customer.facebook,
                  color: Colors.blue,
                ),
                _buildSocialTile(
                  icon: Icons.camera_alt,
                  label: 'إنستغرام',
                  value: customer.instagram,
                  color: Colors.pink,
                ),
                _buildSocialTile(
                  icon: Icons.chat,
                  label: 'تويتر / X',
                  value: customer.twitter,
                  color: Colors.blue,
                ),
                _buildSocialTile(
                  icon: Icons.camera,
                  label: 'سناب شات',
                  value: customer.snapchat,
                  color: Colors.amber,
                ),
                _buildSocialTile(
                  icon: Icons.chat,
                  label: 'WeChat',
                  value: customer.wechat,
                  color: Colors.green,
                ),
                _buildSocialTile(
                  icon: Icons.message,
                  label: 'WhatsApp',
                  value: customer.whatsapp,
                  color: Colors.teal,
                ),
                _buildSocialTile(
                  icon: Icons.web,
                  label: 'الموقع الإلكتروني',
                  value: customer.website,
                  color: Colors.purple,
                ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),

                // الاحتياجات
                if (customer.needs != null && customer.needs!.isNotEmpty) ...[
                  const Text(
                    'احتياجات العميل',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Text(
                      customer.needs!,
                      style: const TextStyle(height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ملاحظات
                if (customer.notes != null && customer.notes!.isNotEmpty) ...[
                  const Text(
                    'ملاحظات',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      customer.notes!,
                      style: const TextStyle(height: 1.5),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String? value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value?.isNotEmpty == true ? value! : 'غير محدد',
              style: TextStyle(
                color: value?.isNotEmpty == true ? Colors.black : Colors.grey.shade500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialTile({
    required IconData icon,
    required String label,
    required String? value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          Expanded(
            child: value?.isNotEmpty == true
                ? GestureDetector(
                    onTap: () {
                      // يمكن إضافة فتح الرابط
                    },
                    child: Text(
                      value!,
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  )
                : Text(
                    'غير محدد',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'إدارة العملاء',
          style: TextStyle(fontSize: 18),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCustomers,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: Column(
        children: [
          // شريط البحث
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
                  hintText: 'بحث عن عميل...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            setState(() => _searchQuery = '');
                            _loadCustomers();
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                  if (value.isEmpty) {
                    _loadCustomers();
                  } else {
                    _repository.searchCustomers(value).then((results) {
                      if (mounted) {
                        setState(() => _customers = results);
                      }
                    });
                  }
                },
              ),
            ),
          ),

          // قائمة العملاء
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('جاري تحميل العملاء...'),
                      ],
                    ),
                  )
                : _customers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 80,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty ? 'لا يوجد عملاء' : 'لا توجد نتائج بحث',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            if (_searchQuery.isEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'اضغط على زر + لإضافة عميل جديد',
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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _customers.length,
                        itemBuilder: (context, index) {
                          final customer = _customers[index];
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _showCustomerDetails(customer),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 28,
                                      backgroundColor: Colors.blue.shade100,
                                      child: Text(
                                        customer.name.isNotEmpty
                                            ? customer.name[0].toUpperCase()
                                            : '?',
                                        style: TextStyle(
                                          fontSize: 18,
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
                                            customer.name,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          // عرض المعلومات المختصرة
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 2,
                                            children: [
                                              if (customer.phone != null &&
                                                  customer.phone!.isNotEmpty)
                                                Text(
                                                  '📱 ${customer.phone}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              if (customer.email != null &&
                                                  customer.email!.isNotEmpty)
                                                Text(
                                                  '📧 ${customer.email}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              if (customer.country != null &&
                                                  customer.country!.isNotEmpty)
                                                Text(
                                                  '🌍 ${customer.country}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          // أيقونات السوشيال ميديا
                                          Wrap(
                                            spacing: 4,
                                            children: [
                                              if (customer.facebook != null &&
                                                  customer.facebook!.isNotEmpty)
                                                const Icon(
                                                  Icons.facebook,
                                                  color: Colors.blue,
                                                  size: 16,
                                                ),
                                              if (customer.instagram != null &&
                                                  customer.instagram!.isNotEmpty)
                                                const Icon(
                                                  Icons.camera_alt,
                                                  color: Colors.pink,
                                                  size: 16,
                                                ),
                                              if (customer.twitter != null &&
                                                  customer.twitter!.isNotEmpty)
                                                const Icon(
                                                  Icons.chat,
                                                  color: Colors.blue,
                                                  size: 16,
                                                ),
                                              if (customer.snapchat != null &&
                                                  customer.snapchat!.isNotEmpty)
                                                const Icon(
                                                  Icons.camera,
                                                  color: Colors.amber,
                                                  size: 16,
                                                ),
                                              if (customer.wechat != null &&
                                                  customer.wechat!.isNotEmpty)
                                                const Icon(
                                                  Icons.chat,
                                                  color: Colors.green,
                                                  size: 16,
                                                ),
                                              if (customer.whatsapp != null &&
                                                  customer.whatsapp!.isNotEmpty)
                                                const Icon(
                                                  Icons.message,
                                                  color: Colors.teal,
                                                  size: 16,
                                                ),
                                              if (customer.website != null &&
                                                  customer.website!.isNotEmpty)
                                                const Icon(
                                                  Icons.web,
                                                  color: Colors.purple,
                                                  size: 16,
                                                ),
                                              if (customer.needs != null &&
                                                  customer.needs!.isNotEmpty)
                                                const Icon(
                                                  Icons.list_alt,
                                                  color: Colors.orange,
                                                  size: 16,
                                                ),
                                            ],
                                          ),
                                        ],
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
                                                  CustomerFormScreen(
                                                customer: customer,
                                                onSaved: () => _loadCustomers(),
                                              ),
                                            ),
                                          );
                                        } else if (value == 'delete') {
                                          _deleteCustomer(customer);
                                        } else if (value == 'details') {
                                          _showCustomerDetails(customer);
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'details',
                                          child: Row(
                                            children: [
                                              Icon(Icons.visibility,
                                                  color: Colors.blue),
                                              SizedBox(width: 8),
                                              Text('عرض التفاصيل'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit,
                                                  color: Colors.orange),
                                              SizedBox(width: 8),
                                              Text('تعديل'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete,
                                                  color: Colors.red),
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
              builder: (context) => CustomerFormScreen(
                onSaved: () => _loadCustomers(),
              ),
            ),
          );
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}