import 'package:flutter/material.dart';
import '../../data/models/customer.dart';
import '../../data/repositories/customer_repository.dart';

class CustomerFormScreen extends StatefulWidget {
  final Customer? customer;
  final VoidCallback onSaved;

  const CustomerFormScreen({
    super.key,
    this.customer,
    required this.onSaved,
  });

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _countryController = TextEditingController();
  final _notesController = TextEditingController();
  final _facebookController = TextEditingController();
  final _instagramController = TextEditingController();
  final _twitterController = TextEditingController();
  final _websiteController = TextEditingController();
  final _snapchatController = TextEditingController();
  final _wechatController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _needsController = TextEditingController();

  final CustomerRepository _repository = CustomerRepository();
  bool _isLoading = false;
  bool _isPhoneValid = true;

  @override
  void initState() {
    super.initState();
    if (widget.customer != null) {
      _nameController.text = widget.customer!.name;
      _phoneController.text = widget.customer!.phone ?? '';
      _emailController.text = widget.customer!.email ?? '';
      _addressController.text = widget.customer!.address ?? '';
      _countryController.text = widget.customer!.country ?? '';
      _notesController.text = widget.customer!.notes ?? '';
      _facebookController.text = widget.customer!.facebook ?? '';
      _instagramController.text = widget.customer!.instagram ?? '';
      _twitterController.text = widget.customer!.twitter ?? '';
      _websiteController.text = widget.customer!.website ?? '';
      _snapchatController.text = widget.customer!.snapchat ?? '';
      _wechatController.text = widget.customer!.wechat ?? '';
      _whatsappController.text = widget.customer!.whatsapp ?? '';
      _needsController.text = widget.customer!.needs ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _countryController.dispose();
    _notesController.dispose();
    _facebookController.dispose();
    _instagramController.dispose();
    _twitterController.dispose();
    _websiteController.dispose();
    _snapchatController.dispose();
    _wechatController.dispose();
    _whatsappController.dispose();
    _needsController.dispose();
    super.dispose();
  }

  void _extractCountryFromPhone() {
    final phone = _phoneController.text.trim();
    final country = Customer.extractCountryFromPhone(phone);
    if (country != null && _countryController.text.isEmpty) {
      setState(() {
        _countryController.text = country;
      });
    }
  }

  void _validatePhone() {
    final phone = _phoneController.text.trim();
    if (phone.isNotEmpty) {
      final country = Customer.extractCountryFromPhone(phone);
      setState(() {
        _isPhoneValid = country != null;
      });
      if (country != null && _countryController.text.isEmpty) {
        setState(() {
          _countryController.text = country;
        });
      }
    } else {
      setState(() {
        _isPhoneValid = true;
      });
    }
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final customer = Customer(
        id: widget.customer?.id,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        country: _countryController.text.trim().isEmpty ? null : _countryController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        facebook: _facebookController.text.trim().isEmpty ? null : _facebookController.text.trim(),
        instagram: _instagramController.text.trim().isEmpty ? null : _instagramController.text.trim(),
        twitter: _twitterController.text.trim().isEmpty ? null : _twitterController.text.trim(),
        website: _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
        snapchat: _snapchatController.text.trim().isEmpty ? null : _snapchatController.text.trim(),
        wechat: _wechatController.text.trim().isEmpty ? null : _wechatController.text.trim(),
        whatsapp: _whatsappController.text.trim().isEmpty ? null : _whatsappController.text.trim(),
        needs: _needsController.text.trim().isEmpty ? null : _needsController.text.trim(),
      );

      if (widget.customer == null) {
        await _repository.createCustomer(customer);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ تم إضافة العميل بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await _repository.updateCustomer(customer);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ تم تحديث العميل بنجاح'),
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
          SnackBar(
            content: Text('❌ خطأ: $e'),
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
        title: Text(
          widget.customer == null ? 'إضافة عميل جديد' : 'تعديل بيانات العميل',
          style: const TextStyle(fontSize: 18),
        ),
        backgroundColor: Colors.blue,
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
                // ===== المعلومات الأساسية =====
                _buildSectionTitle('المعلومات الأساسية'),
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
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'الاسم *',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty ? 'الاسم مطلوب' : null,
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            labelText: 'رقم الهاتف',
                            prefixIcon: const Icon(Icons.phone),
                            border: const OutlineInputBorder(),
                            suffixIcon: _phoneController.text.isNotEmpty
                                ? Icon(
                                    _isPhoneValid ? Icons.check_circle : Icons.error,
                                    color: _isPhoneValid ? Colors.green : Colors.red,
                                  )
                                : null,
                            helperText: _phoneController.text.isNotEmpty
                                ? (_isPhoneValid 
                                    ? '✅ رقم هاتف صحيح' 
                                    : '❌ رقم هاتف غير صحيح أو غير معروف')
                                : 'أدخل رقم الهاتف مع مفتاح الدولة (مثال: +20123456789)',
                            helperStyle: TextStyle(
                              color: _phoneController.text.isNotEmpty
                                  ? (_isPhoneValid ? Colors.green : Colors.red)
                                  : Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          keyboardType: TextInputType.phone,
                          onChanged: (value) {
                            _validatePhone();
                            _extractCountryFromPhone();
                          },
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _countryController,
                          decoration: const InputDecoration(
                            labelText: 'البلد',
                            prefixIcon: Icon(Icons.public),
                            border: OutlineInputBorder(),
                            helperText: 'يتم تعبئته تلقائياً من رقم الهاتف',
                            helperStyle: TextStyle(fontSize: 12),
                          ),
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'البريد الإلكتروني',
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            labelText: 'العنوان',
                            prefixIcon: Icon(Icons.location_on),
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ===== وسائل التواصل الاجتماعي =====
                _buildSectionTitle('وسائل التواصل الاجتماعي'),
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
                        // فيسبوك
                        TextFormField(
                          controller: _facebookController,
                          decoration: const InputDecoration(
                            labelText: 'فيسبوك',
                            prefixIcon: Icon(Icons.facebook, color: Colors.blue),
                            border: OutlineInputBorder(),
                            hintText: 'https://facebook.com/username',
                          ),
                          keyboardType: TextInputType.url,
                        ),
                        const SizedBox(height: 12),

                        // إنستغرام
                        TextFormField(
                          controller: _instagramController,
                          decoration: const InputDecoration(
                            labelText: 'إنستغرام',
                            prefixIcon: Icon(Icons.camera_alt, color: Colors.pink),
                            border: OutlineInputBorder(),
                            hintText: 'https://instagram.com/username',
                          ),
                          keyboardType: TextInputType.url,
                        ),
                        const SizedBox(height: 12),

                        // تويتر
                        TextFormField(
                          controller: _twitterController,
                          decoration: const InputDecoration(
                            labelText: 'تويتر / X',
                            prefixIcon: Icon(Icons.chat, color: Colors.blue),
                            border: OutlineInputBorder(),
                            hintText: 'https://twitter.com/username',
                          ),
                          keyboardType: TextInputType.url,
                        ),
                        const SizedBox(height: 12),

                        // سناب شات
                        TextFormField(
                          controller: _snapchatController,
                          decoration: const InputDecoration(
                            labelText: 'سناب شات',
                            prefixIcon: Icon(Icons.camera, color: Colors.amber),
                            border: OutlineInputBorder(),
                            hintText: 'https://snapchat.com/username',
                          ),
                          keyboardType: TextInputType.url,
                        ),
                        const SizedBox(height: 12),

                        // WeChat
                        TextFormField(
                          controller: _wechatController,
                          decoration: const InputDecoration(
                            labelText: 'WeChat',
                            prefixIcon: Icon(Icons.chat, color: Colors.green),
                            border: OutlineInputBorder(),
                            hintText: 'معرف WeChat',
                          ),
                        ),
                        const SizedBox(height: 12),

                        // WhatsApp
                        TextFormField(
                          controller: _whatsappController,
                          decoration: const InputDecoration(
                            labelText: 'WhatsApp',
                            prefixIcon: Icon(Icons.message, color: Colors.teal),
                            border: OutlineInputBorder(),
                            hintText: 'https://wa.me/20123456789',
                          ),
                          keyboardType: TextInputType.url,
                        ),
                        const SizedBox(height: 12),

                        // ويبسايت
                        TextFormField(
                          controller: _websiteController,
                          decoration: const InputDecoration(
                            labelText: 'الموقع الإلكتروني',
                            prefixIcon: Icon(Icons.web, color: Colors.purple),
                            border: OutlineInputBorder(),
                            hintText: 'https://example.com',
                          ),
                          keyboardType: TextInputType.url,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ===== الاحتياجات والمتطلبات =====
                _buildSectionTitle('الاحتياجات والمتطلبات'),
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
                        TextFormField(
                          controller: _needsController,
                          decoration: const InputDecoration(
                            labelText: 'احتياجات العميل',
                            prefixIcon: Icon(Icons.list_alt, color: Colors.orange),
                            border: OutlineInputBorder(),
                            helperText: 'اذكر احتياجات العميل ومتطلباته',
                            helperStyle: TextStyle(fontSize: 12),
                          ),
                          maxLines: 4,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ===== ملاحظات إضافية =====
                _buildSectionTitle('ملاحظات إضافية'),
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
                        TextFormField(
                          controller: _notesController,
                          decoration: const InputDecoration(
                            labelText: 'ملاحظات',
                            prefixIcon: Icon(Icons.note),
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ===== زر الحفظ =====
                SizedBox(
                  width: double.infinity,
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _saveCustomer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          child: Text(
                            widget.customer == null ? 'إضافة العميل' : 'تحديث البيانات',
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
              color: Colors.blue.shade700,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }
}