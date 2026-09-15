// lib/features/broadcast/screens/broadcast_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/services/whatsapp_service.dart';
import '../../../data/models/contact.dart';
import '../../../data/repositories/customer_repository.dart';
// ✅ FIX: Use broadcast_result with prefix to avoid conflict
import '../models/broadcast_result.dart' as broadcast;

// =============================================
// ✅ BROADCAST SCREEN
// =============================================

class BroadcastScreen extends StatefulWidget {
  const BroadcastScreen({super.key});

  @override
  State<BroadcastScreen> createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends State<BroadcastScreen>
    with TickerProviderStateMixin {
  // =============================================
  // ✅ CONTROLLERS
  // =============================================

  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  // =============================================
  // ✅ STATE VARIABLES
  // =============================================

  List<Contact> _selectedContacts = [];
  List<Contact> _filteredContacts = [];
  bool _isLoading = false;
  bool _isSending = false;
  bool _isPaused = false;
  int _currentProgress = 0;
  int _totalProgress = 0;
  broadcast.BroadcastResult? _result;

  // =============================================
  // ✅ REPOSITORIES
  // =============================================

  final CustomerRepository _customerRepository = CustomerRepository();

  // =============================================
  // ✅ ANIMATION
  // =============================================

  late AnimationController _progressAnimationController;
  late AnimationController _fadeAnimationController;

  // =============================================
  // ✅ TEMPLATES
  // =============================================

  final List<Map<String, String>> _templates = [
    {
      'name': 'ترحيب جديد',
      'message':
          'مرحباً بك! نحن سعداء بانضمامك إلينا. نتمنى لك يوماً سعيداً. 🎉',
    },
    {
      'name': 'عرض خاص',
      'message': 'خصم 20% على جميع المنتجات! العرض ساري حتى نهاية الشهر. لا تفوت الفرصة! 🛍️',
    },
    {
      'name': 'تذكير بموعد',
      'message': 'تذكير بموعدك غداً الساعة 10 صباحاً. ننتظرك! 📅',
    },
    {
      'name': 'شكر وتقدير',
      'message':
          'شكراً لثقتك بنا. نحن نقدر تعاملك معنا ونتطلع لخدمتك دائماً. 🙏',
    },
    {
      'name': 'عطلة رسمية',
      'message': 'نحيطكم علماً بأن غداً عطلة رسمية. سنعود للعمل يوم الأحد. إجازة سعيدة! 🌙',
    },
    {
      'name': 'تحديث جديد',
      'message': 'تم إضافة تحديثات جديدة على النظام. يمكنكم الآن الاستمتاع بمزايا أكثر. 🚀',
    },
  ];

  // =============================================
  // ✅ INIT STATE
  // =============================================

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadContacts();
    _checkPendingBroadcast();
  }

  void _initAnimations() {
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimationController.forward();
  }

  // =============================================
  // ✅ LOAD CUSTOMERS FROM DATABASE
  // =============================================

  Future<void> _loadContacts() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final customers = await _customerRepository.getAllCustomers();

      final contacts = customers.map((customer) {
        return Contact(
          id: customer.id,
          firstName: customer.name,
          lastName: '',
          email: customer.email,
          phone: customer.phone,
          mobile: customer.phone,
          whatsappNumber: customer.whatsapp,
          address: customer.address,
          country: customer.country,
          notes: customer.notes,
          company: '',
          jobTitle: '',
          category: 'عميل',
          isActive: true,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _filteredContacts = contacts;
          _selectedContacts = [];
          _isLoading = false;
        });
      }

      debugPrint('✅ Loaded ${contacts.length} customers');
    } catch (e) {
      debugPrint('❌ Error loading customers: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('فشل تحميل العملاء: $e');
      }
    }
  }

  Future<void> _checkPendingBroadcast() async {
    try {
      final whatsappService = Provider.of<WhatsAppService>(
        context,
        listen: false,
      );
      final hasPending = await whatsappService.hasPendingBroadcast();
      if (hasPending && mounted) {
        final details = await whatsappService.getPendingBroadcastDetails();
        if (details != null && mounted) {
          _showResumeDialog(details);
        }
      }
    } catch (e) {
      debugPrint('❌ Error checking pending broadcast: $e');
    }
  }

  // =============================================
  // ✅ DISPOSAL
  // =============================================

  @override
  void dispose() {
    _progressAnimationController.dispose();
    _fadeAnimationController.dispose();
    _messageController.dispose();
    _subjectController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // =============================================
  // ✅ BUILD
  // =============================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          if (_isSending || _result != null) _buildProgressSection(),
          if (_result != null && !_isSending) _buildResultCard(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildContactSelector(),
                        const SizedBox(height: 16),
                        _buildSubjectField(),
                        const SizedBox(height: 16),
                        _buildMessageField(),
                        const SizedBox(height: 16),
                        _buildTemplatesSection(),
                        const SizedBox(height: 16),
                        _buildAdvancedOptions(),
                        const SizedBox(height: 24),
                        _buildSendButton(),
                        const SizedBox(height: 16),
                        _buildInfoCard(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // =============================================
  // ✅ APP BAR
  // =============================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          const Icon(Icons.chat, color: Colors.white, size: 28),
          const SizedBox(width: 8),
          const Text(
            'إرسال رسائل واتساب للعملاء',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      backgroundColor: Colors.green.shade700,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          onPressed: _loadContacts,
          icon: const Icon(Icons.refresh),
          tooltip: 'تحديث العملاء',
        ),
        if (_isPaused)
          IconButton(
            onPressed: _resumeBroadcast,
            icon: const Icon(Icons.play_arrow),
            tooltip: 'استئناف الإرسال',
          ),
        if (_isSending)
          IconButton(
            onPressed: _cancelBroadcast,
            icon: const Icon(Icons.stop),
            tooltip: 'إلغاء الإرسال',
          ),
        IconButton(
          onPressed: () => _navigateToHistory(),
          icon: const Icon(Icons.history),
          tooltip: 'سجل الإرسال',
        ),
      ],
    );
  }

  // =============================================
  // ✅ PROGRESS SECTION
  // =============================================

  Widget _buildProgressSection() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _isPaused ? Colors.amber.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isPaused ? Colors.amber.shade300 : Colors.blue.shade300,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    _isPaused ? Icons.pause_circle : Icons.send,
                    color: _isPaused ? Colors.amber : Colors.blue,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isPaused ? '⏸️ متوقف مؤقتاً' : '📤 جاري الإرسال...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _isPaused
                          ? Colors.amber.shade800
                          : Colors.blue.shade800,
                    ),
                  ),
                ],
              ),
              Text(
                '$_currentProgress / $_totalProgress',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _isPaused
                      ? Colors.amber.shade800
                      : Colors.blue.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _totalProgress > 0 ? _currentProgress / _totalProgress : 0,
              backgroundColor: Colors.grey.shade200,
              color: _isPaused ? Colors.amber : Colors.blue,
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildProgressStat(
                icon: Icons.check_circle,
                label: 'نجح',
                value: '${_result?.success ?? 0}',
                color: Colors.green,
              ),
              _buildProgressStat(
                icon: Icons.cancel,
                label: 'فشل',
                value: '${_result?.failed ?? 0}',
                color: Colors.red,
              ),
              _buildProgressStat(
                icon: Icons.percent,
                label: 'نسبة',
                value: _totalProgress > 0
                    ? '${((_currentProgress / _totalProgress) * 100).toStringAsFixed(1)}%'
                    : '0%',
                color: Colors.blue,
              ),
            ],
          ),
          if (_isPaused) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _resumeBroadcast,
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('استئناف'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _cancelBroadcast,
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('إلغاء'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  // =============================================
  // ✅ RESULT CARD
  // =============================================

  Widget _buildResultCard() {
    if (_result == null) return const SizedBox.shrink();

    final isSuccess = _result!.failed == 0 && _result!.success > 0;
    final isPartial = _result!.success > 0 && _result!.failed > 0;
    final isFailed = _result!.success == 0 && _result!.failed > 0;

    Color backgroundColor;
    Color borderColor;
    IconData icon;
    String title;

    if (isSuccess) {
      backgroundColor = Colors.green.shade50;
      borderColor = Colors.green;
      icon = Icons.check_circle;
      title = '✅ تم الإرسال بنجاح';
    } else if (isPartial) {
      backgroundColor = Colors.orange.shade50;
      borderColor = Colors.orange;
      icon = Icons.warning;
      title = '⚠️ تم الإرسال جزئياً';
    } else if (isFailed) {
      backgroundColor = Colors.red.shade50;
      borderColor = Colors.red;
      icon = Icons.error;
      title = '❌ فشل الإرسال';
    } else {
      backgroundColor = Colors.grey.shade50;
      borderColor = Colors.grey;
      icon = Icons.info;
      title = 'ℹ️ لم يتم الإرسال';
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: borderColor, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: borderColor,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => setState(() => _result = null),
                icon: const Icon(Icons.close, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: Colors.grey.shade600,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildResultStat(
                label: '✅ نجح',
                count: _result!.success,
                color: Colors.green,
              ),
              _buildResultStat(
                label: '❌ فشل',
                count: _result!.failed,
                color: Colors.red,
              ),
              _buildResultStat(
                label: '📊 نسبة النجاح',
                count: '${_result!.successRate.toStringAsFixed(1)}%',
                color: Colors.blue,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_result!.failed > 0)
                ElevatedButton.icon(
                  onPressed: _resendFailed,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text('إعادة إرسال الفاشلة (${_result!.failed})'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _showDetailedReport,
                icon: const Icon(Icons.receipt_long, size: 18),
                label: const Text('تقرير مفصل'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultStat({
    required String label,
    required dynamic count,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  // =============================================
  // ✅ CONTACT SELECTOR
  // =============================================

  Widget _buildContactSelector() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.people, color: Colors.blue.shade700, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'العملاء (${_selectedContacts.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: _selectAllContacts,
                      icon: const Icon(Icons.select_all, size: 18),
                      label: const Text('الكل'),
                      style: TextButton.styleFrom(foregroundColor: Colors.blue),
                    ),
                    TextButton.icon(
                      onPressed: _clearSelectedContacts,
                      icon: const Icon(Icons.clear, size: 18),
                      label: const Text('مسح'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildSearchBar(),
            const SizedBox(height: 12),
            if (_selectedContacts.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedContacts.map((contact) {
                  return Chip(
                    label: Text(contact.fullName),
                    avatar: CircleAvatar(
                      backgroundColor: contact.avatarColor,
                      radius: 14,
                      child: Text(
                        contact.initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    onDeleted: () {
                      setState(() {
                        _selectedContacts.remove(contact);
                        _updateFilteredContacts();
                      });
                    },
                    deleteIcon: const Icon(Icons.close, size: 16),
                    deleteIconColor: Colors.grey.shade600,
                    backgroundColor: Colors.blue.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: Colors.blue.shade200),
                    ),
                  );
                }).toList(),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _filteredContacts.isEmpty
                          ? 'لا يوجد عملاء'
                          : 'لم يتم اختيار أي عميل',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                    ),
                    if (_filteredContacts.isEmpty) const SizedBox(height: 8),
                    if (_filteredContacts.isEmpty)
                      ElevatedButton.icon(
                        onPressed: _loadContacts,
                        icon: const Icon(Icons.refresh),
                        label: const Text('تحديث العملاء'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: _showContactPicker,
                        icon: const Icon(Icons.add),
                        label: const Text('اختيار عملاء'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: '🔍 بحث عن عميل...',
        prefixIcon: const Icon(Icons.search, color: Colors.grey),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  _searchController.clear();
                  _updateFilteredContacts();
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      onChanged: (value) => _updateFilteredContacts(),
    );
  }

  void _updateFilteredContacts() {
    final query = _searchController.text.toLowerCase().trim();

    if (query.isEmpty) {
      _loadContacts();
      return;
    }

    setState(() {
      _filteredContacts = _filteredContacts.where((contact) {
        return contact.fullName.toLowerCase().contains(query) ||
            (contact.email?.toLowerCase().contains(query) ?? false) ||
            (contact.phone?.contains(query) ?? false) ||
            (contact.mobile?.contains(query) ?? false);
      }).toList();
    });
  }

  // =============================================
  // ✅ SUBJECT FIELD
  // =============================================

  Widget _buildSubjectField() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.title, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'الموضوع (اختياري)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _subjectController,
              decoration: InputDecoration(
                hintText: 'أدخل موضوع الرسالة...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =============================================
  // ✅ MESSAGE FIELD
  // =============================================

  Widget _buildMessageField() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.message, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'الرسالة',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _messageController.text.length > 1000
                        ? Colors.red.shade100
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_messageController.text.length} حرف',
                    style: TextStyle(
                      fontSize: 12,
                      color: _messageController.text.length > 1000
                          ? Colors.red
                          : Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              maxLines: 6,
              minLines: 3,
              decoration: InputDecoration(
                hintText: 'اكتب رسالتك هنا...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.all(16),
              ),
              onChanged: (value) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_messageController.text.split('\n').length} سطر',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                if (_messageController.text.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => _messageController.clear(),
                    icon: const Icon(Icons.clear, size: 16),
                    label: const Text('مسح الرسالة'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: EdgeInsets.zero,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =============================================
  // ✅ TEMPLATES SECTION
  // =============================================

  Widget _buildTemplatesSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        leading: Icon(Icons.style, color: Colors.blue.shade700),
        title: const Text(
          '📋 قوالب الرسائل',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        childrenPadding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _templates.map((template) {
              return ActionChip(
                label: Text(template['name']!),
                onPressed: () {
                  setState(() {
                    _messageController.text = template['message']!;
                  });
                },
                backgroundColor: Colors.grey.shade100,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // =============================================
  // ✅ ADVANCED OPTIONS
  // =============================================

  Widget _buildAdvancedOptions() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.info, color: Colors.blue),
            SizedBox(width: 8),
            Text(
              'سيتم إرسال الرسائل عبر واتساب',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  // =============================================
  // ✅ SEND BUTTON
  // =============================================

  Widget _buildSendButton() {
    final canSend =
        _selectedContacts.isNotEmpty &&
        _messageController.text.trim().isNotEmpty &&
        !_isSending;

    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: canSend ? _sendMessages : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isSending
              ? Colors.grey.shade400
              : Colors.green.shade600,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: _isSending ? 0 : 4,
          shadowColor: Colors.green.shade300,
          disabledBackgroundColor: Colors.grey.shade300,
        ),
        child: _isSending
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    _isPaused
                        ? '⏸️ متوقف مؤقتاً'
                        : 'جاري الإرسال... $_currentProgress/$_totalProgress',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.send,
                    size: 26,
                    color: canSend ? Colors.white : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '📤 إرسال إلى ${_selectedContacts.length} شخص',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: canSend ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // =============================================
  // ✅ INFO CARD
  // =============================================

  Widget _buildInfoCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildInfoItem(
              icon: Icons.people,
              label: 'المختارين',
              value: '${_selectedContacts.length}',
              color: Colors.blue,
            ),
            _buildInfoItem(
              icon: Icons.message,
              label: 'الرسالة',
              value: '${_messageController.text.length} حرف',
              color: Colors.purple,
            ),
            _buildInfoItem(
              icon: Icons.chat,
              label: 'واتساب',
              value: _isWhatsAppInstalled() ? '✅ مثبت' : '❌ غير مثبت',
              color: _isWhatsAppInstalled() ? Colors.green : Colors.red,
            ),
            _buildInfoItem(
              icon: Icons.check_circle,
              label: 'الحالة',
              value: _isSending ? 'جاري الإرسال' : 'جاهز',
              color: _isSending ? Colors.blue : Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  bool _isWhatsAppInstalled() {
    final whatsappService = Provider.of<WhatsAppService>(
      context,
      listen: false,
    );
    return whatsappService.isWhatsAppInstalled;
  }

  // =============================================
  // ✅ CONTACT PICKER
  // =============================================

  void _showContactPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'اختيار عملاء',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('إغلاق'),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: '🔍 بحث عن عميل...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      onChanged: (query) {
                        if (query.isEmpty) {
                          _loadContacts();
                          setModalState(() {});
                          return;
                        }
                        setModalState(() {
                          _filteredContacts = _filteredContacts
                              .where(
                                (c) => c.fullName.toLowerCase().contains(
                                  query.toLowerCase(),
                                ),
                              )
                              .toList();
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: _filteredContacts.length,
                      itemBuilder: (context, index) {
                        final contact = _filteredContacts[index];
                        final isSelected = _selectedContacts.any(
                          (c) => c.id == contact.id,
                        );

                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (_) {
                            setState(() {
                              if (isSelected) {
                                _selectedContacts.removeWhere(
                                  (c) => c.id == contact.id,
                                );
                              } else {
                                _selectedContacts.add(contact);
                              }
                            });
                            setModalState(() {});
                          },
                          title: Text(contact.fullName),
                          subtitle: Text(
                            contact.primaryPhone ?? 'لا يوجد رقم',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                          secondary: CircleAvatar(
                            backgroundColor: contact.avatarColor,
                            child: Text(
                              contact.initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          dense: true,
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'مختار: ${_selectedContacts.length}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _selectedContacts = List.from(
                                    _filteredContacts,
                                  );
                                });
                                setModalState(() {});
                              },
                              child: const Text('تحديد الكل'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                setState(() {});
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                              child: Text(
                                'تأكيد (${_selectedContacts.length})',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _selectAllContacts() {
    setState(() {
      _selectedContacts = List.from(_filteredContacts);
    });
    _showSuccess('✅ تم اختيار جميع العملاء (${_selectedContacts.length})');
  }

  void _clearSelectedContacts() {
    setState(() {
      _selectedContacts.clear();
    });
  }

  // =============================================
  // ✅ ACTIONS - SEND
  // =============================================

  Future<void> _sendMessages() async {
    final phoneNumbers = _selectedContacts
        .map((c) => c.primaryPhone)
        .where((p) => p != null && p.isNotEmpty)
        .cast<String>()
        .toList();

    if (phoneNumbers.isEmpty) {
      if (mounted) {
        _showError('⚠️ لا توجد أرقام هاتف صالحة للإرسال');
      }
      return;
    }

    if (_messageController.text.trim().isEmpty) {
      if (mounted) {
        _showError('⚠️ الرجاء كتابة رسالة للإرسال');
      }
      return;
    }

    final whatsappService = Provider.of<WhatsAppService>(
      context,
      listen: false,
    );

    final confirmed = await _showSendConfirmation(phoneNumbers.length);

    if (!confirmed || !mounted) return;

    setState(() {
      _isSending = true;
      _currentProgress = 0;
      _totalProgress = phoneNumbers.length;
      _result = null;
      _isPaused = false;
    });

    try {
      String fullMessage = _messageController.text.trim();

      if (_subjectController.text.trim().isNotEmpty) {
        fullMessage = '📌 ${_subjectController.text.trim()}\n\n$fullMessage';
      }

      final result = await whatsappService.sendSmartMessage(
        phoneNumbers: phoneNumbers,
        message: fullMessage,
        onProgress: (current, total) {
          if (!mounted) return;

          setState(() {
            _currentProgress = current;
            _totalProgress = total;
          });
        },
      );

      if (!mounted) return;

      setState(() {
        _isSending = false;
        _result = result;
        _isPaused = result.isPaused;
      });

      _showResultDialog(result);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSending = false;
        _result = broadcast.BroadcastResult.failed('حدث خطأ: $e');
      });

      _showError('❌ حدث خطأ: $e');
    }
  }

  Future<bool> _showSendConfirmation(int count) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.send, color: Colors.green, size: 28),
            const SizedBox(width: 12),
            const Text('تأكيد الإرسال'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📤 عدد المستلمين: $count شخص'),
            const SizedBox(height: 4),
            Text('📝 طول الرسالة: ${_messageController.text.length} حرف'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_messageController.text.substring(0, _messageController.text.length > 100 ? 100 : _messageController.text.length)}${_messageController.text.length > 100 ? '...' : ''}',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('تأكيد الإرسال'),
          ),
        ],
      ),
    ).then((value) => value ?? false);
  }

  // =============================================
  // ✅ ACTIONS - RESUME
  // =============================================

  void _resumeBroadcast() async {
    setState(() {
      _isPaused = false;
      _isSending = true;
    });

    try {
      final whatsappService = Provider.of<WhatsAppService>(
        context,
        listen: false,
      );

      final result = await whatsappService.resumeBroadcast(
        message: _messageController.text.trim(),
        onProgress: (current, total) {
          if (!mounted) return;

          setState(() {
            _currentProgress = current;
            _totalProgress = total;
          });
        },
      );

      if (!mounted) return;

      setState(() {
        _isSending = false;
        _result = result;
      });

      _showResultDialog(result);
    } catch (e) {
      if (!mounted) return;

      setState(() => _isSending = false);
      _showError('❌ فشل استئناف الإرسال: $e');
    }
  }

  // =============================================
  // ✅ ACTIONS - CANCEL
  // =============================================

  void _cancelBroadcast() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إلغاء الإرسال'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('هل أنت متأكد من إلغاء عملية الإرسال؟'),
            const SizedBox(height: 8),
            Text(
              'تم إرسال $_currentProgress من $_totalProgress رسالة',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'سيتم فقدان التقدم',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('تراجع'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final whatsappService = Provider.of<WhatsAppService>(
                context,
                listen: false,
              );
              whatsappService.cancelBroadcast();
              setState(() {
                _isSending = false;
                _isPaused = false;
                _result = broadcast.BroadcastResult.failed(
                  'تم الإلغاء من قبل المستخدم',
                );
              });
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }

  // =============================================
  // ✅ ACTIONS - RESEND FAILED
  // =============================================

  void _resendFailed() {
    if (_result == null) return;

    final failedNumbers = _result!.results
        .where((r) => !r.success)
        .map((r) => r.phoneNumber)
        .toList();

    if (failedNumbers.isEmpty) {
      _showError('لا توجد رسائل فاشلة لإعادة الإرسال');
      return;
    }

    setState(() {
      _selectedContacts = _selectedContacts
          .where((c) => failedNumbers.contains(c.primaryPhone))
          .toList();
      _result = null;
    });

    _showSuccess(
      '✅ تم تحديد ${_selectedContacts.length} جهة اتصال لإعادة الإرسال',
    );
  }

  // =============================================
  // ✅ ACTIONS - NAVIGATION
  // =============================================

  void _navigateToHistory() {
    Navigator.pushNamed(context, '/broadcast-history');
  }

  // =============================================
  // ✅ ACTIONS - DIALOGS
  // =============================================

  void _showResumeDialog(Map<String, dynamic> details) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.play_arrow, color: Colors.blue, size: 28),
            SizedBox(width: 12),
            Text('استئناف الإرسال'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📊 تم إرسال ${details['sent']} من ${details['total']} رسالة'),
            Text('⏳ المتبقي: ${details['remaining']} رسالة'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final prefs = SharedPreferences.getInstance();
              prefs.then((p) => p.remove('broadcast_numbers'));
            },
            child: const Text('تجاهل'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _resumeBroadcast();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('استئناف'),
          ),
        ],
      ),
    );
  }

  void _showResultDialog(broadcast.BroadcastResult result) {
    if (result.isPaused) {
      _showSuccess('⏸️ تم إيقاف الإرسال مؤقتاً. يمكنك الاستئناف لاحقاً.');
      return;
    }

    String title;
    String message;
    IconData icon;
    Color color;

    if (result.failed == 0 && result.success > 0) {
      title = '✅ تم الإرسال بنجاح!';
      message = 'تم إرسال الرسالة إلى ${result.success} شخص';
      icon = Icons.check_circle;
      color = Colors.green;
    } else if (result.success > 0 && result.failed > 0) {
      title = '⚠️ تم الإرسال جزئياً';
      message = 'نجح: ${result.success} شخص\nفشل: ${result.failed} شخص';
      icon = Icons.warning;
      color = Colors.orange;
    } else {
      title = '❌ فشل الإرسال';
      message = 'لم يتم إرسال أي رسالة. حاول مرة أخرى.';
      icon = Icons.error;
      color = Colors.red;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(child: Text(title)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        '${result.success}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const Text('ناجح'),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        '${result.failed}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const Text('فاشل'),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        '${result.successRate.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: result.successRate > 70
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                      const Text('نسبة النجاح'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
          if (result.failed > 0)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _resendFailed();
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: Text('إعادة المحاولة (${result.failed})'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  void _showDetailedReport() {
    if (_result == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '📊 تقرير الإرسال المفصل',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildReportStat(
                      '✅ ناجح',
                      '${_result!.success}',
                      Colors.green,
                    ),
                    _buildReportStat(
                      '❌ فاشل',
                      '${_result!.failed}',
                      Colors.red,
                    ),
                    _buildReportStat(
                      '📊 نسبة',
                      '${_result!.successRate.toStringAsFixed(1)}%',
                      Colors.blue,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _result!.results.length,
                  itemBuilder: (context, index) {
                    final recipient = _result!.results[index];
                    return ListTile(
                      leading: Icon(
                        recipient.success ? Icons.check_circle : Icons.cancel,
                        color: recipient.success ? Colors.green : Colors.red,
                      ),
                      title: Text(recipient.phoneNumber),
                      subtitle: Text(
                        recipient.customerName ?? 'عميل غير معروف',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      trailing: Text(
                        recipient.success ? '✅ ناجح' : '❌ فاشل',
                        style: TextStyle(
                          color: recipient.success ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      dense: true,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildReportStat(String label, String value, Color color) {
    return Column(
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
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  // =============================================
  // ✅ HELPERS
  // =============================================

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
