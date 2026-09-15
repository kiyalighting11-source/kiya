// lib/presentation/screens/invoices/invoices_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ===== IMPORT CORRECTED =====
import '../../../data/models/invoice.dart';
// ❌ لا تستورد invoice_status.dart
// import '../../../data/models/invoice_status.dart';
import '../../../data/services/invoice_service.dart';
// ✅ تم إزالة import غير المستخدم
// import '../../../data/repositories/invoice_repository.dart';

// ✅ استيراد الـ Widgets
import '../../widgets/invoice_card.dart';
import 'create_invoice_screen.dart';
import 'invoice_details_screen.dart';
import 'edit_invoice_screen.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen>
    with SingleTickerProviderStateMixin {
  final InvoiceService _invoiceService = InvoiceService();

  List<Invoice> _invoices = [];
  List<Invoice> _filteredInvoices = [];
  bool _isLoading = true;
  String _searchQuery = '';
  InvoiceStatus? _selectedStatus;
  String? _error;

  late TabController _tabController;
  final List<Tab> _tabs = [
    const Tab(text: 'الكل'),
    const Tab(text: 'عرض سعر'),
    const Tab(text: 'مسودة'),
    const Tab(text: 'مؤكدة'),
    const Tab(text: 'مكتملة'),
    const Tab(text: 'ملغية'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadInvoices();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() {
      switch (_tabController.index) {
        case 0:
          _selectedStatus = null;
          break;
        case 1:
          _selectedStatus = InvoiceStatus.quotation;
          break;
        case 2:
          _selectedStatus = InvoiceStatus.draft;
          break;
        case 3:
          _selectedStatus = InvoiceStatus.confirmed;
          break;
        case 4:
          _selectedStatus = InvoiceStatus.completed;
          break;
        case 5:
          _selectedStatus = InvoiceStatus.cancelled;
          break;
      }
      _applyFilters();
    });
  }

  Future<void> _loadInvoices() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('المستخدم غير مسجل');

      // جلب صلاحيات المستخدم
      final response = await Supabase.instance.client
          .from('users')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();

      final isAdmin = response?['role'] == 'admin';

      List<Invoice> invoices;
      if (isAdmin) {
        // المدير يرى كل الفواتير
        invoices = await _invoiceService.getInvoices();
      } else {
        // الموظف يرى فواتيره فقط
        invoices = await _invoiceService.getInvoices(userId: user.id);
      }

      setState(() {
        _invoices = invoices;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredInvoices = _invoices.where((invoice) {
        // فلترة حسب الحالة
        if (_selectedStatus != null && invoice.status != _selectedStatus) {
          return false;
        }

        // فلترة حسب البحث
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();

          return invoice.invoiceNumber.toLowerCase().contains(query) ||
              invoice.customerName.toLowerCase().contains(query) ||
              invoice.customerPhone.toLowerCase().contains(query) ||
              invoice.statusLabel.contains(query);
        }

        return true;
      }).toList();

      // ترتيب حسب التاريخ (الأحدث أولاً)
      _filteredInvoices.sort((a, b) => b.date.compareTo(a.date));
    });
  }

  Future<void> _refreshInvoices() async {
    await _loadInvoices();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الفواتير'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.blue,
            child: TabBar(
              controller: _tabController,
              tabs: _tabs,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              isScrollable: true,
              labelStyle: const TextStyle(fontSize: 14),
              unselectedLabelStyle: const TextStyle(fontSize: 13),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToCreateInvoice(),
            tooltip: 'فاتورة جديدة',
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
                  Text('جاري تحميل الفواتير...'),
                ],
              ),
            )
          : _error != null
          ? _buildErrorWidget()
          : Column(
              children: [
                _buildSearchBar(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refreshInvoices,
                    child: _filteredInvoices.isEmpty
                        ? _buildEmptyWidget()
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _filteredInvoices.length,
                            itemBuilder: (context, index) {
                              final invoice = _filteredInvoices[index];
                              return InvoiceCard(
                                invoice: invoice,
                                onTap: () =>
                                    _navigateToInvoiceDetails(invoice.id!),
                                onLongPress: () => _showInvoiceOptions(invoice),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreateInvoice(),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        tooltip: 'فاتورة جديدة',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'بحث عن فاتورة (رقم، عميل، هاتف)...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _applyFilters();
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
            _applyFilters();
          });
        },
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
              onPressed: _loadInvoices,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
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

  Widget _buildEmptyWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              _selectedStatus != null
                  ? 'لا توجد فواتير بهذه الحالة'
                  : 'لا توجد فواتير',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedStatus != null
                  ? 'لم يتم العثور على فواتير بحالة "${_selectedStatus!.arabic}"'
                  : 'قم بإنشاء فاتورة جديدة بالضغط على الزر أدناه',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (_selectedStatus != null)
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedStatus = null;
                    _tabController.animateTo(0);
                    _applyFilters();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.grey.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('عرض الكل'),
              ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _navigateToCreateInvoice(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('فاتورة جديدة'),
            ),
          ],
        ),
      ),
    );
  }

  void _showInvoiceOptions(Invoice invoice) {
    showModalBottomSheet(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.visibility, color: Colors.blue),
              title: const Text('عرض التفاصيل'),
              onTap: () {
                Navigator.pop(context);
                _navigateToInvoiceDetails(invoice.id!);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.orange),
              title: const Text('تعديل'),
              onTap: () {
                Navigator.pop(context);
                _navigateToEditInvoice(invoice);
              },
            ),
            if (invoice.isDraft || invoice.isQuotation)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('حذف'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteInvoice(invoice);
                },
              ),
            if (invoice.isQuotation && invoice.isQuotationValid)
              ListTile(
                leading: const Icon(Icons.file_copy, color: Colors.green),
                title: const Text('تحويل إلى فاتورة'),
                onTap: () {
                  Navigator.pop(context);
                  _convertQuotationToInvoice(invoice);
                },
              ),
            if (invoice.isDraft || invoice.isPending)
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('تأكيد الفاتورة'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmInvoice(invoice);
                },
              ),
            if (invoice.isCancellable)
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.red),
                title: const Text('إلغاء الفاتورة'),
                onTap: () {
                  Navigator.pop(context);
                  _cancelInvoice(invoice);
                },
              ),
            if (invoice.isConfirmed && !invoice.isPaid)
              ListTile(
                leading: const Icon(Icons.payments, color: Colors.green),
                title: const Text('إكمال الدفع'),
                onTap: () {
                  Navigator.pop(context);
                  _showPaymentDialog(invoice);
                },
              ),
            ListTile(
              leading: const Icon(Icons.print, color: Colors.grey),
              title: const Text('طباعة'),
              onTap: () {
                Navigator.pop(context);
                _printInvoice(invoice);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // ==================== NAVIGATION ====================

  void _navigateToCreateInvoice() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateInvoiceScreen()),
    ).then((_) => _loadInvoices());
  }

  void _navigateToInvoiceDetails(String invoiceId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvoiceDetailsScreen(invoiceId: invoiceId),
      ),
    ).then((_) => _loadInvoices());
  }

  void _navigateToEditInvoice(Invoice invoice) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditInvoiceScreen(invoice: invoice),
      ),
    ).then((_) => _loadInvoices());
  }

  // ==================== ACTIONS ====================

  Future<void> _confirmDeleteInvoice(Invoice invoice) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('حذف الفاتورة'),
        content: Text(
          'هل أنت متأكد من حذف الفاتورة رقم ${invoice.invoiceNumber}؟',
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

    try {
      await _invoiceService.deleteInvoice(invoice.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم حذف الفاتورة بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        _loadInvoices();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _confirmInvoice(Invoice invoice) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('تأكيد الفاتورة'),
        content: Text(
          'هل أنت متأكد من تأكيد الفاتورة رقم ${invoice.invoiceNumber}؟\n\n'
          'سيتم خصم المنتجات من المخزون.',
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
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final errors = await _invoiceService.validateInvoiceBeforeConfirm(
        invoice.id!,
      );
      if (errors.isNotEmpty) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('لا يمكن تأكيد الفاتورة'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: errors
                    .map(
                      (error) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error,
                              color: Colors.red,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(error)),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('حسناً'),
                ),
              ],
            ),
          );
        }
        return;
      }

      await _invoiceService.confirmInvoice(invoice.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم تأكيد الفاتورة بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        _loadInvoices();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _cancelInvoice(Invoice invoice) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('إلغاء الفاتورة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'هل أنت متأكد من إلغاء الفاتورة رقم ${invoice.invoiceNumber}؟',
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'سبب الإلغاء (اختياري)',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, ''),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('إلغاء الفاتورة'),
          ),
        ],
      ),
    );

    if (reason == null) return;

    try {
      await _invoiceService.cancelInvoice(
        invoice.id!,
        reason: reason.isNotEmpty ? reason : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم إلغاء الفاتورة بنجاح'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadInvoices();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _convertQuotationToInvoice(Invoice quotation) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('تحويل عرض السعر'),
        content: Text(
          'هل أنت متأكد من تحويل عرض السعر رقم ${quotation.invoiceNumber} إلى فاتورة؟',
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

    try {
      await _invoiceService.convertQuotationToInvoice(quotation.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم تحويل عرض السعر إلى فاتورة بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        _loadInvoices();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showPaymentDialog(Invoice invoice) async {
    final TextEditingController amountController = TextEditingController();
    amountController.text = invoice.remainingToPay.toStringAsFixed(2);

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('إكمال الدفع'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('المبلغ المتبقي: ${invoice.formattedRemaining}'),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'المبلغ المدفوع',
                border: OutlineInputBorder(),
                prefixText: '\$ ',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: 'cash',
              decoration: const InputDecoration(
                labelText: 'طريقة الدفع',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'cash', child: Text('نقدي')),
                DropdownMenuItem(value: 'card', child: Text('بطاقة')),
                DropdownMenuItem(value: 'bank', child: Text('تحويل بنكي')),
              ],
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text);
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('الرجاء إدخال مبلغ صحيح'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.pop(context, {'amount': amount, 'method': 'cash'});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('دفع'),
          ),
        ],
      ),
    );

    if (result == null) return;

    try {
      await _invoiceService.completePayment(
        invoice.id!,
        result['amount'] as double,
        paymentMethod: result['method'] as String,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم إكمال الدفع بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        _loadInvoices();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _printInvoice(Invoice invoice) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🖨️ طباعة الفاتورة - سيتم إضافتها قريباً'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
