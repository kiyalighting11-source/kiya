// lib/data/services/contact_service.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/contact.dart';
import '../repositories/customer_repository.dart';

// =============================================
// ✅ CONTACT SERVICE
// =============================================

/// خدمة إدارة جهات الاتصال - تستخدم العملاء من قاعدة البيانات
class ContactService extends ChangeNotifier {
  // =============================================
  // ✅ PRIVATE FIELDS
  // =============================================

  List<Contact> _contacts = [];
  List<Contact> _selectedContacts = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _searchQuery;

  // =============================================
  // ✅ REPOSITORIES
  // =============================================

  final CustomerRepository _customerRepository = CustomerRepository();

  // =============================================
  // ✅ GETTERS
  // =============================================

  /// قائمة جميع جهات الاتصال (العملاء)
  List<Contact> get contacts => _contacts;

  /// قائمة جهات الاتصال المختارة
  List<Contact> get selectedContacts => _selectedContacts;

  /// هل يتم التحميل؟
  bool get isLoading => _isLoading;

  /// رسالة الخطأ (إن وجدت)
  String? get errorMessage => _errorMessage;

  /// عدد جهات الاتصال المختارة
  int get selectedCount => _selectedContacts.length;

  /// إجمالي عدد جهات الاتصال
  int get totalCount => _contacts.length;

  /// نص البحث الحالي
  String? get searchQuery => _searchQuery;

  /// هل توجد جهات اتصال؟
  bool get hasContacts => _contacts.isNotEmpty;

  /// هل توجد جهات اتصال مختارة؟
  bool get hasSelectedContacts => _selectedContacts.isNotEmpty;

  // =============================================
  // ✅ CONSTRUCTOR
  // =============================================

  ContactService() {
    _loadContacts();
  }

  // =============================================
  // ✅ LOAD CONTACTS FROM DATABASE
  // =============================================

  /// تحميل العملاء من قاعدة البيانات وتحويلهم إلى جهات اتصال
  Future<void> _loadContacts() async {
    setLoading(true);
    _errorMessage = null;

    try {
      debugPrint('📥 Loading customers from database...');

      // ✅ جلب العملاء من قاعدة البيانات
      final customers = await _customerRepository.getAllCustomers();

      debugPrint('✅ Found ${customers.length} customers');

      // ✅ تحويل العملاء إلى جهات اتصال
      _contacts = customers.map((customer) {
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

      // ✅ تحميل المختارين المحفوظين
      await _loadSelectedContacts();

      debugPrint('✅ Loaded ${_contacts.length} contacts successfully');
      setLoading(false);
    } catch (e) {
      debugPrint('❌ Error loading customers: $e');
      _errorMessage = 'خطأ في تحميل العملاء: $e';
      setLoading(false);
    }
  }

  /// إعادة تحميل جهات الاتصال (تحديث)
  Future<void> refreshContacts() async {
    await _loadContacts();
  }

  // =============================================
  // ✅ SELECTED CONTACTS PERSISTENCE
  // =============================================

  /// تحميل المختارين المحفوظين من SharedPreferences
  Future<void> _loadSelectedContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList('selected_contacts') ?? [];

      _selectedContacts.clear();
      for (var contact in _contacts) {
        if (saved.contains(contact.id)) {
          _selectedContacts.add(contact);
        }
      }
      notifyListeners();
      debugPrint('✅ Loaded ${_selectedContacts.length} selected contacts');
    } catch (e) {
      debugPrint('❌ Error loading selected contacts: $e');
    }
  }

  /// حفظ المختارين في SharedPreferences
  Future<void> _saveSelectedContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = _selectedContacts.map((c) => c.id!).toList();
      await prefs.setStringList('selected_contacts', ids);
      debugPrint('✅ Saved ${ids.length} selected contacts');
    } catch (e) {
      debugPrint('❌ Error saving selected contacts: $e');
    }
  }

  // =============================================
  // ✅ SELECTION METHODS
  // =============================================

  /// تبديل اختيار جهة اتصال
  void toggleContact(String contactId) {
    final index = _contacts.indexWhere((c) => c.id == contactId);
    if (index == -1) return;

    final contact = _contacts[index];
    final isSelected = _selectedContacts.any((c) => c.id == contactId);

    if (isSelected) {
      _selectedContacts.removeWhere((c) => c.id == contactId);
    } else {
      _selectedContacts.add(contact);
    }

    _saveSelectedContacts();
    notifyListeners();
  }

  /// اختيار جهة اتصال
  void selectContact(String contactId) {
    final contact = getContactById(contactId);
    if (contact == null) return;

    if (!_selectedContacts.any((c) => c.id == contactId)) {
      _selectedContacts.add(contact);
      _saveSelectedContacts();
      notifyListeners();
    }
  }

  /// إلغاء اختيار جهة اتصال
  void deselectContact(String contactId) {
    _selectedContacts.removeWhere((c) => c.id == contactId);
    _saveSelectedContacts();
    notifyListeners();
  }

  /// اختيار الكل
  void selectAll() {
    _selectedContacts = List.from(_contacts);
    _saveSelectedContacts();
    notifyListeners();
  }

  /// إلغاء اختيار الكل
  void deselectAll() {
    _selectedContacts.clear();
    _saveSelectedContacts();
    notifyListeners();
  }

  /// اختيار جهات اتصال حسب القائمة
  void selectContacts(List<Contact> contacts) {
    for (var contact in contacts) {
      if (!_selectedContacts.any((c) => c.id == contact.id)) {
        _selectedContacts.add(contact);
      }
    }
    _saveSelectedContacts();
    notifyListeners();
  }

  /// إلغاء اختيار جهات اتصال حسب القائمة
  void deselectContacts(List<Contact> contacts) {
    for (var contact in contacts) {
      _selectedContacts.removeWhere((c) => c.id == contact.id);
    }
    _saveSelectedContacts();
    notifyListeners();
  }

  /// تبديل اختيار الكل
  void toggleSelectAll() {
    if (_selectedContacts.length == _contacts.length) {
      deselectAll();
    } else {
      selectAll();
    }
  }

  // =============================================
  // ✅ SEARCH METHODS
  // =============================================

  /// البحث في جهات الاتصال
  List<Contact> searchContacts(String query) {
    _searchQuery = query;

    if (query.isEmpty) {
      notifyListeners();
      return _contacts;
    }

    final lowerQuery = query.toLowerCase().trim();
    final results = _contacts.where((contact) {
      return contact.fullName.toLowerCase().contains(lowerQuery) ||
          (contact.email?.toLowerCase().contains(lowerQuery) ?? false) ||
          (contact.phone?.contains(lowerQuery) ?? false) ||
          (contact.mobile?.contains(lowerQuery) ?? false) ||
          (contact.company?.toLowerCase().contains(lowerQuery) ?? false) ||
          (contact.address?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();

    notifyListeners();
    return results;
  }

  /// البحث عن جهات اتصال مع فلترة
  List<Contact> searchContactsWithFilters({
    String? query,
    String? category,
    bool? isActive,
  }) {
    var results = List<Contact>.from(_contacts);

    if (query != null && query.isNotEmpty) {
      final lowerQuery = query.toLowerCase().trim();
      results = results.where((contact) {
        return contact.fullName.toLowerCase().contains(lowerQuery) ||
            (contact.email?.toLowerCase().contains(lowerQuery) ?? false) ||
            (contact.phone?.contains(lowerQuery) ?? false);
      }).toList();
    }

    if (category != null && category.isNotEmpty) {
      results = results.where((contact) {
        return contact.category == category;
      }).toList();
    }

    if (isActive != null) {
      results = results.where((contact) {
        return contact.isActive == isActive;
      }).toList();
    }

    return results;
  }

  // =============================================
  // ✅ GETTERS WITH FILTERS
  // =============================================

  /// الحصول على جهات الاتصال النشطة فقط
  List<Contact> getActiveContacts() {
    return _contacts.where((c) => c.isActive).toList();
  }

  /// الحصول على جهات الاتصال حسب التصنيف
  List<Contact> getContactsByCategory(String category) {
    return _contacts.where((c) => c.category == category).toList();
  }

  /// الحصول على جهات الاتصال التي لديها رقم هاتف
  List<Contact> getContactsWithPhone() {
    return _contacts.where((c) => c.hasPhone).toList();
  }

  /// الحصول على جهات الاتصال التي لديها واتساب
  List<Contact> getContactsWithWhatsApp() {
    return _contacts.where((c) => c.hasWhatsapp).toList();
  }

  /// الحصول على جهات الاتصال التي لديها بريد إلكتروني
  List<Contact> getContactsWithEmail() {
    return _contacts.where((c) => c.hasEmail).toList();
  }

  // =============================================
  // ✅ CONTACT MANAGEMENT
  // =============================================

  /// الحصول على جهة اتصال بالمعرف
  Contact? getContactById(String id) {
    try {
      return _contacts.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  /// الحصول على جهة اتصال بالرقم
  Contact? getContactByPhone(String phone) {
    try {
      return _contacts.firstWhere((c) => c.phone == phone || c.mobile == phone);
    } catch (_) {
      return null;
    }
  }

  /// الحصول على أرقام الهواتف المختارة
  List<String> getSelectedPhoneNumbers() {
    return _selectedContacts
        .map((c) => c.primaryPhone)
        .where((p) => p != null && p.isNotEmpty)
        .cast<String>()
        .toList();
  }

  /// الحصول على أرقام الهواتف المختارة مع رمز الدولة
  List<String> getSelectedPhoneNumbersWithCountryCode() {
    return _selectedContacts
        .map((c) => c.primaryPhone)
        .where((p) => p != null && p.isNotEmpty)
        .map((p) => p!.startsWith('+') ? p : '+$p')
        .toList();
  }

  /// التحقق من وجود جهة اتصال محددة
  bool isContactSelected(String contactId) {
    return _selectedContacts.any((c) => c.id == contactId);
  }

  /// التحقق من وجود جهة اتصال بالرقم
  bool isPhoneSelected(String phone) {
    return _selectedContacts.any((c) => c.phone == phone || c.mobile == phone);
  }

  // =============================================
  // ✅ COUNT METHODS
  // =============================================

  /// عدد جهات الاتصال النشطة
  int getActiveCount() {
    return _contacts.where((c) => c.isActive).toList().length;
  }

  /// عدد جهات الاتصال غير النشطة
  int getInactiveCount() {
    return _contacts.where((c) => !c.isActive).toList().length;
  }

  /// عدد جهات الاتصال التي لديها رقم هاتف
  int getContactsWithPhoneCount() {
    return _contacts.where((c) => c.hasPhone).toList().length;
  }

  /// عدد جهات الاتصال التي لديها واتساب
  int getContactsWithWhatsAppCount() {
    return _contacts.where((c) => c.hasWhatsapp).toList().length;
  }

  // =============================================
  // ✅ STATE MANAGEMENT
  // =============================================

  /// تعيين حالة التحميل
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// تنظيف الأخطاء
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// تنظيف المختارين
  void clearSelected() {
    _selectedContacts.clear();
    _saveSelectedContacts();
    notifyListeners();
  }

  /// إعادة تعيين الحالة بالكامل
  void reset() {
    _contacts.clear();
    _selectedContacts.clear();
    _errorMessage = null;
    _searchQuery = null;
    notifyListeners();
  }

  // =============================================
  // ✅ UTILITY METHODS
  // =============================================

  /// تصدير الأرقام المختارة كنص
  String getSelectedPhoneNumbersAsString({String separator = ', '}) {
    return getSelectedPhoneNumbers().join(separator);
  }

  /// تصدير أسماء المختارين كنص
  String getSelectedNamesAsString({String separator = ', '}) {
    return _selectedContacts.map((c) => c.fullName).join(separator);
  }

  /// الحصول على ملخص المختارين
  String getSelectedSummary() {
    if (_selectedContacts.isEmpty) {
      return 'لم يتم اختيار أي جهة اتصال';
    }
    return '${_selectedContacts.length} جهة اتصال مختارة';
  }

  // =============================================
  // ✅ DEBUG METHODS
  // =============================================

  /// طباعة معلومات جهات الاتصال (للتطوير)
  void debugPrintContacts() {
    debugPrint('📊 Contact Service Debug Info:');
    debugPrint('   Total contacts: ${_contacts.length}');
    debugPrint('   Selected contacts: ${_selectedContacts.length}');
    debugPrint('   Is loading: $_isLoading');
    debugPrint('   Error: $_errorMessage');
    debugPrint('   Search query: $_searchQuery');

    for (var contact in _contacts) {
      debugPrint('   - ${contact.fullName} (${contact.phone})');
    }
  }

  // =============================================
  // ✅ STATIC HELPERS
  // =============================================

  /// تحويل قائمة العملاء إلى جهات اتصال (Static)
  static List<Contact> customersToContacts(dynamic customers) {
    // هذه الدالة تستخدم في حالة الحاجة لتحويل خارجي
    // لكننا نقوم بالتحويل داخل الخدمة
    return [];
  }
}

// =============================================
// ✅ EXTENSIONS
// =============================================

/// ملحقات لـ ContactService
extension ContactServiceExtensions on ContactService {
  /// الحصول على المختارين مع فلترة حسب النشاط
  List<Contact> getSelectedContactsFiltered({bool? isActive}) {
    var result = List<Contact>.from(_selectedContacts);
    if (isActive != null) {
      result = result.where((c) => c.isActive == isActive).toList();
    }
    return result;
  }

  /// الحصول على المختارين مع فلترة حسب التصنيف
  List<Contact> getSelectedContactsByCategory(String category) {
    return _selectedContacts.where((c) => c.category == category).toList();
  }

  /// التحقق من وجود أرقام مختارة
  bool get hasSelectedPhoneNumbers {
    return getSelectedPhoneNumbers().isNotEmpty;
  }

  /// التحقق من وجود أرقام واتساب مختارة
  bool get hasSelectedWhatsAppNumbers {
    return _selectedContacts.where((c) => c.hasWhatsapp).toList().isNotEmpty;
  }
}
