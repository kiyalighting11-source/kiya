// lib/data/services/whatsapp_service.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:shared_preferences/shared_preferences.dart';

// ✅ Import BroadcastResult from the feature models
import '../../features/broadcast/models/broadcast_result.dart';

// =============================================
// ✅ WHATSAPP SERVICE
// =============================================

/// خدمة واتساب - لإدارة التواصل عبر واتساب
class WhatsAppService extends ChangeNotifier {
  // =============================================
  // ✅ PROPERTIES
  // =============================================

  // Existing properties
  String? _phoneNumber;
  bool _isWhatsAppInstalled = false;
  bool _isLoading = false;
  String? _errorMessage;

  // Hybrid solution properties
  bool _isSending = false;
  int _currentProgress = 0;
  int _totalProgress = 0;
  String? _currentBatchId;
  List<BroadcastRecipient> _batchResults = [];
  int _successCount = 0;
  int _failedCount = 0;
  bool _isPaused = false;

  // =============================================
  // ✅ GETTERS - Existing
  // =============================================

  String? get phoneNumber => _phoneNumber;
  bool get isWhatsAppInstalled => _isWhatsAppInstalled;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isPhoneLinked => _phoneNumber != null && _phoneNumber!.isNotEmpty;

  // =============================================
  // ✅ GETTERS - Hybrid Solution
  // =============================================

  bool get isSending => _isSending;
  int get currentProgress => _currentProgress;
  int get totalProgress => _totalProgress;
  double get progressPercentage =>
      _totalProgress > 0 ? _currentProgress / _totalProgress : 0;
  String? get currentBatchId => _currentBatchId;
  int get successCount => _successCount;
  int get failedCount => _failedCount;
  bool get isPaused => _isPaused;
  List<BroadcastRecipient> get batchResults => _batchResults;

  // =============================================
  // ✅ CONSTRUCTOR
  // =============================================

  WhatsAppService() {
    _loadPhoneNumber();
    _checkWhatsAppInstallation();
  }

  // =============================================
  // ✅ PRIVATE METHODS - Existing
  // =============================================

  Future<void> _loadPhoneNumber() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _phoneNumber = prefs.getString('whatsapp_phone');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading phone number: $e');
    }
  }

  Future<void> _savePhoneNumber(String phone) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('whatsapp_phone', phone);
      _phoneNumber = phone;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error saving phone number: $e');
    }
  }

  Future<void> _checkWhatsAppInstallation() async {
    try {
      final whatsappUrl = Uri.parse('whatsapp://send?phone=0');
      _isWhatsAppInstalled = await canLaunchUrl(whatsappUrl);
      notifyListeners();
      debugPrint('📱 WhatsApp installed: $_isWhatsAppInstalled');
    } catch (e) {
      debugPrint('❌ Error checking WhatsApp: $e');
      _isWhatsAppInstalled = false;
      notifyListeners();
    }
  }

  String _cleanPhoneNumber(String phone) {
    // إزالة المسافات والرموز غير الضرورية
    String cleaned = phone
        .replaceAll(' ', '')
        .replaceAll('-', '')
        .replaceAll('(', '')
        .replaceAll(')', '')
        .replaceAll('+', '')
        .trim();

    // إزالة الأصفار البادئة للرقم المصري
    if (cleaned.startsWith('0') && cleaned.length > 10) {
      cleaned = cleaned.substring(1);
    }

    // إضافة رمز الدولة المصري إذا لم يكن موجوداً
    if (!cleaned.startsWith('20') && cleaned.length == 10) {
      cleaned = '20$cleaned';
    }

    // إذا كان الرقم يبدأ بـ 0 وباقي الأرقام 10 أرقام
    if (cleaned.startsWith('0') && cleaned.length == 11) {
      cleaned = '20${cleaned.substring(1)}';
    }

    return cleaned;
  }

  bool _isValidPhoneNumber(String phone) {
    // التحقق من أن الرقم يحتوي على أرقام فقط
    if (!RegExp(r'^[0-9]+$').hasMatch(phone)) {
      return false;
    }
    // التحقق من طول الرقم
    return phone.length >= 10 && phone.length <= 15;
  }

  // =============================================
  // ✅ PRIVATE METHODS - Hybrid Solution
  // =============================================

  void _resetBatchState() {
    _currentProgress = 0;
    _totalProgress = 0;
    _successCount = 0;
    _failedCount = 0;
    _batchResults = [];
    _currentBatchId = null;
    _isPaused = false;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// إرسال رسالة لشخص واحد
  Future<bool> _sendSingleMessage(String phone, String message) async {
    try {
      final encodedMessage = Uri.encodeComponent(message);

      // محاولة فتح واتساب التطبيق أولاً
      final appUrl = Uri.parse(
        'whatsapp://send?phone=$phone&text=$encodedMessage',
      );

      if (await canLaunchUrl(appUrl)) {
        await launchUrl(appUrl);
        return true;
      } else {
        // محاولة واتساب ويب كحل بديل
        final webUrl = Uri.parse('https://wa.me/$phone?text=$encodedMessage');
        if (await canLaunchUrl(webUrl)) {
          await launchUrl(
            webUrl,
            mode: url_launcher.LaunchMode.externalApplication,
          );
          return true;
        }
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error sending to $phone: $e');
      return false;
    }
  }

  /// حفظ التقدم للاستئناف
  Future<void> _saveProgress(List<String> numbers, int currentIndex) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('broadcast_numbers', numbers.join(','));
      await prefs.setInt('broadcast_index', currentIndex);
      await prefs.setString('broadcast_date', DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('❌ Error saving progress: $e');
    }
  }

  /// حفظ نتائج الباتش
  Future<void> _saveBatchResults(
    String batchId,
    List<BroadcastRecipient> results,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final resultsJson = results.map((r) => r.toJson()).toList();
      await prefs.setString('batch_$batchId', resultsJson.toString());
    } catch (e) {
      debugPrint('❌ Error saving batch results: $e');
    }
  }

  /// إنشاء باتش جديد
  Future<void> _createBatch(
    String batchId,
    List<String> numbers,
    String message,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('batch_${batchId}_numbers', numbers.join(','));
      await prefs.setString('batch_${batchId}_message', message);
      await prefs.setString(
        'batch_${batchId}_date',
        DateTime.now().toIso8601String(),
      );
      await prefs.setInt('batch_${batchId}_progress', 0);
    } catch (e) {
      debugPrint('❌ Error creating batch: $e');
    }
  }

  /// تحديث تقدم الباتش
  Future<void> _updateBatchProgress(
    String batchId,
    int progress,
    bool success, {
    bool retry = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'batch_${batchId}_progress';
      final current = prefs.getInt(key) ?? 0;
      await prefs.setInt(key, current + 1);

      if (success) {
        final successKey = 'batch_${batchId}_success';
        final currentSuccess = prefs.getInt(successKey) ?? 0;
        await prefs.setInt(successKey, currentSuccess + 1);
      } else {
        final failedKey = 'batch_${batchId}_failed';
        final currentFailed = prefs.getInt(failedKey) ?? 0;
        await prefs.setInt(failedKey, currentFailed + 1);
      }
    } catch (e) {
      debugPrint('❌ Error updating batch progress: $e');
    }
  }

  /// إكمال الباتش
  Future<void> _completeBatch(String batchId, int success, int failed) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('batch_${batchId}_completed', true);
      await prefs.setInt('batch_${batchId}_success', success);
      await prefs.setInt('batch_${batchId}_failed', failed);
      await prefs.setString(
        'batch_${batchId}_completed_at',
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      debugPrint('❌ Error completing batch: $e');
    }
  }

  /// مسح التقدم المحفوظ
  Future<void> _clearProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('broadcast_numbers');
      await prefs.remove('broadcast_index');
      await prefs.remove('broadcast_date');
      await prefs.remove('broadcast_message');
    } catch (e) {
      debugPrint('❌ Error clearing progress: $e');
    }
  }

  // =============================================
  // ✅ METHOD 1: Direct Send (Small batches: 1-3)
  // =============================================

  Future<BroadcastResult> _sendDirectWithDelay(
    List<String> phoneNumbers,
    String message,
  ) async {
    int success = 0;
    int failed = 0;
    final results = <BroadcastRecipient>[];

    for (int i = 0; i < phoneNumbers.length; i++) {
      try {
        // فتح واتساب مباشر
        final url = Uri.parse(
          'whatsapp://send?phone=${phoneNumbers[i]}&text=${Uri.encodeComponent(message)}',
        );

        if (await canLaunchUrl(url)) {
          await launchUrl(url);
          success++;
          _successCount++;
          results.add(
            BroadcastRecipient(
              phoneNumber: phoneNumbers[i],
              success: true,
              sentAt: DateTime.now(),
            ),
          );

          // انتظار قصير فقط
          if (i < phoneNumbers.length - 1) {
            await Future.delayed(const Duration(milliseconds: 800));
          }
        } else {
          // محاولة ويب كبديل
          final webUrl = Uri.parse(
            'https://wa.me/${phoneNumbers[i]}?text=${Uri.encodeComponent(message)}',
          );
          if (await canLaunchUrl(webUrl)) {
            await launchUrl(
              webUrl,
              mode: url_launcher.LaunchMode.externalApplication,
            );
            success++;
            _successCount++;
          } else {
            failed++;
            _failedCount++;
            results.add(
              BroadcastRecipient(
                phoneNumber: phoneNumbers[i],
                success: false,
                errorMessage: 'فشل فتح واتساب',
              ),
            );
          }
        }

        _currentProgress = i + 1;
        notifyListeners();
      } catch (e) {
        failed++;
        _failedCount++;
        results.add(
          BroadcastRecipient(
            phoneNumber: phoneNumbers[i],
            success: false,
            errorMessage: e.toString(),
          ),
        );
      }
    }

    return BroadcastResult(
      success: success,
      failed: failed,
      results: results,
      isComplete: failed == 0,
    );
  }

  // =============================================
  // ✅ METHOD 2: Sequential Send (Medium: 4-10)
  // =============================================

  Future<BroadcastResult> _sendSequential(
    List<String> phoneNumbers,
    String message,
    Function(int, int)? onProgress,
  ) async {
    int success = 0;
    int failed = 0;
    final results = <BroadcastRecipient>[];

    // إنشاء Batch ID
    _currentBatchId = DateTime.now().millisecondsSinceEpoch.toString();

    for (int i = 0; i < phoneNumbers.length; i++) {
      // التحقق من الإيقاف المؤقت
      while (_isPaused) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (!_isSending) {
          return BroadcastResult(
            success: success,
            failed: failed,
            results: results,
            isComplete: false,
            batchId: _currentBatchId,
            isPaused: true,
          );
        }
      }

      if (!_isSending) break;

      try {
        // تحديث التقدم
        _currentProgress = i + 1;
        if (onProgress != null) {
          onProgress(i + 1, phoneNumbers.length);
        }
        notifyListeners();

        // محاولة إرسال مع إعادة المحاولة
        bool sent = false;
        for (int retry = 0; retry < 2; retry++) {
          sent = await _sendSingleMessage(phoneNumbers[i], message);
          if (sent) break;
          await Future.delayed(const Duration(seconds: 1));
        }

        if (sent) {
          success++;
          _successCount++;
          results.add(
            BroadcastRecipient(
              phoneNumber: phoneNumbers[i],
              success: true,
              sentAt: DateTime.now(),
            ),
          );
        } else {
          failed++;
          _failedCount++;
          results.add(
            BroadcastRecipient(
              phoneNumber: phoneNumbers[i],
              success: false,
              errorMessage: 'فشل بعد محاولتين',
            ),
          );
        }

        // تأخير مناسب
        if (i < phoneNumbers.length - 1) {
          await Future.delayed(const Duration(seconds: 2));
        }

        // حفظ التقدم (للاستئناف لاحقاً)
        await _saveProgress(phoneNumbers, i + 1);
      } catch (e) {
        failed++;
        _failedCount++;
        results.add(
          BroadcastRecipient(
            phoneNumber: phoneNumbers[i],
            success: false,
            errorMessage: e.toString(),
          ),
        );
      }
    }

    // حفظ النتائج النهائية
    _batchResults = results;
    await _saveBatchResults(_currentBatchId!, results);

    return BroadcastResult(
      success: success,
      failed: failed,
      results: results,
      isComplete: failed == 0,
      batchId: _currentBatchId,
    );
  }

  // =============================================
  // ✅ METHOD 3: Bulk Send with Retry (Large: >10)
  // =============================================

  Future<BroadcastResult> _sendBulkWithRetry(
    List<String> phoneNumbers,
    String message,
    Function(int, int)? onProgress,
  ) async {
    // تخزين الباتش في قاعدة البيانات
    _currentBatchId = DateTime.now().millisecondsSinceEpoch.toString();
    await _createBatch(_currentBatchId!, phoneNumbers, message);

    int success = 0;
    int failed = 0;
    final results = <BroadcastRecipient>[];
    final failedNumbers = <String>[];

    // تقسيم إلى مجموعات صغيرة (10 لكل مجموعة)
    const chunkSize = 10;
    for (int i = 0; i < phoneNumbers.length; i += chunkSize) {
      // التحقق من الإيقاف المؤقت
      while (_isPaused) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (!_isSending) {
          return BroadcastResult(
            success: success,
            failed: failed,
            results: results,
            isComplete: false,
            batchId: _currentBatchId,
            isPaused: true,
          );
        }
      }

      final chunk = phoneNumbers.sublist(
        i,
        i + chunkSize > phoneNumbers.length
            ? phoneNumbers.length
            : i + chunkSize,
      );

      // إرسال كل مجموعة
      for (int j = 0; j < chunk.length; j++) {
        if (!_isSending) break;

        final index = i + j;
        if (onProgress != null) {
          onProgress(index + 1, phoneNumbers.length);
        }
        _currentProgress = index + 1;
        notifyListeners();

        final sent = await _sendSingleMessage(chunk[j], message);
        if (sent) {
          success++;
          _successCount++;
          results.add(
            BroadcastRecipient(
              phoneNumber: chunk[j],
              success: true,
              sentAt: DateTime.now(),
            ),
          );
          await _updateBatchProgress(_currentBatchId!, index + 1, true);
        } else {
          failed++;
          _failedCount++;
          failedNumbers.add(chunk[j]);
          results.add(
            BroadcastRecipient(
              phoneNumber: chunk[j],
              success: false,
              errorMessage: 'فشل الإرسال',
            ),
          );
          await _updateBatchProgress(_currentBatchId!, index + 1, false);
        }

        // تأخير أطول للكميات الكبيرة
        if (j < chunk.length - 1) {
          await Future.delayed(const Duration(seconds: 3));
        }
      }

      // تأخير بين المجموعات
      if (i + chunkSize < phoneNumbers.length) {
        await Future.delayed(const Duration(seconds: 5));
      }
    }

    // محاولة إعادة إرسال الأرقام الفاشلة
    if (failedNumbers.isNotEmpty &&
        failedNumbers.length < phoneNumbers.length ~/ 2) {
      await Future.delayed(const Duration(seconds: 3));

      for (var number in failedNumbers) {
        if (!_isSending) break;

        final retrySuccess = await _sendSingleMessage(number, message);
        if (retrySuccess) {
          success++;
          _successCount++;
          failed--;
          _failedCount--;
          await _updateBatchProgress(_currentBatchId!, 0, true, retry: true);
        }
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    await _completeBatch(_currentBatchId!, success, failed);
    _batchResults = results;

    return BroadcastResult(
      success: success,
      failed: failed,
      results: results,
      isComplete: failed == 0,
      batchId: _currentBatchId,
    );
  }

  // =============================================
  // ✅ PUBLIC METHODS - Hybrid Solution
  // =============================================

  /// 🚀 إرسال رسائل ذكي - يختار أفضل طريقة حسب العدد
  Future<BroadcastResult> sendSmartMessage({
    required List<String> phoneNumbers,
    required String message,
    Function(int, int)? onProgress,
  }) async {
    // تنظيف الأرقام
    final cleanedNumbers = phoneNumbers
        .map((p) => _cleanPhoneNumber(p))
        .where((p) => p.isNotEmpty && p.length >= 10)
        .toList();

    if (cleanedNumbers.isEmpty) {
      return BroadcastResult(
        success: 0,
        failed: 0,
        results: [],
        isComplete: false,
        errorMessage: 'لا توجد أرقام صالحة',
      );
    }

    // Reset state
    _resetBatchState();
    _isSending = true;
    _totalProgress = cleanedNumbers.length;
    notifyListeners();

    BroadcastResult result;

    // إذا كان العدد صغير (1-3) → فتح واتساب مباشر
    if (cleanedNumbers.length <= 3) {
      result = await _sendDirectWithDelay(cleanedNumbers, message);
    }
    // إذا كان العدد متوسط (4-10) → متسلسل مع تأخير قصير
    else if (cleanedNumbers.length <= 10) {
      result = await _sendSequential(cleanedNumbers, message, onProgress);
    }
    // إذا كان العدد كبير (>10) → متسلسل مع حفظ الحالة
    else {
      result = await _sendBulkWithRetry(cleanedNumbers, message, onProgress);
    }

    _isSending = false;
    notifyListeners();
    return result;
  }

  /// ▶️ استئناف الإرسال المتوقف
  Future<BroadcastResult> resumeBroadcast({
    required String message,
    Function(int, int)? onProgress,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final numbersStr = prefs.getString('broadcast_numbers');
      final savedIndex = prefs.getInt('broadcast_index') ?? 0;

      if (numbersStr == null || numbersStr.isEmpty) {
        return BroadcastResult(
          success: 0,
          failed: 0,
          results: [],
          isComplete: false,
          errorMessage: 'لا توجد رسائل متوقفة',
        );
      }

      final numbers = numbersStr.split(',');
      final remaining = numbers.sublist(savedIndex);

      if (remaining.isEmpty) {
        return BroadcastResult(
          success: 0,
          failed: 0,
          results: [],
          isComplete: true,
          errorMessage: 'تم إرسال جميع الرسائل بالفعل',
        );
      }

      _isSending = true;
      _totalProgress = remaining.length;
      notifyListeners();

      final result = await _sendSequential(remaining, message, onProgress);
      _isSending = false;
      notifyListeners();

      // مسح التقدم المحفوظ بعد الانتهاء
      if (result.isComplete) {
        await _clearProgress();
      }

      return result;
    } catch (e) {
      debugPrint('❌ Error resuming broadcast: $e');
      return BroadcastResult(
        success: 0,
        failed: 0,
        results: [],
        isComplete: false,
        errorMessage: 'حدث خطأ: $e',
      );
    }
  }

  /// ⏸️ إيقاف مؤقت
  void pauseBroadcast() {
    _isPaused = true;
    notifyListeners();
  }

  /// ▶️ استئناف (من التحكم)
  void resumeBroadcastControl() {
    _isPaused = false;
    notifyListeners();
  }

  /// 🛑 إلغاء الإرسال
  void cancelBroadcast() {
    _isSending = false;
    _isPaused = false;
    _resetBatchState();
    notifyListeners();
  }

  /// ✅ التحقق من وجود رسالة متوقفة
  Future<bool> hasPendingBroadcast() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final numbersStr = prefs.getString('broadcast_numbers');
      return numbersStr != null && numbersStr.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// ✅ الحصول على تفاصيل الرسالة المتوقفة
  Future<Map<String, dynamic>?> getPendingBroadcastDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final numbersStr = prefs.getString('broadcast_numbers');
      final savedIndex = prefs.getInt('broadcast_index') ?? 0;
      final dateStr = prefs.getString('broadcast_date');

      if (numbersStr == null || numbersStr.isEmpty) {
        return null;
      }

      final numbers = numbersStr.split(',');
      return {
        'total': numbers.length,
        'sent': savedIndex,
        'remaining': numbers.length - savedIndex,
        'date': dateStr != null ? DateTime.parse(dateStr) : null,
        'numbers': numbers,
      };
    } catch (e) {
      return null;
    }
  }

  // =============================================
  // ✅ PUBLIC METHODS - Existing
  // =============================================

  /// ربط رقم الهاتف
  Future<bool> linkPhoneNumber(String phone) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final cleanedPhone = _cleanPhoneNumber(phone);

      if (cleanedPhone.isEmpty) {
        _errorMessage = 'الرجاء إدخال رقم هاتف صحيح';
        _setLoading(false);
        return false;
      }

      if (!_isValidPhoneNumber(cleanedPhone)) {
        _errorMessage = 'رقم الهاتف غير صحيح';
        _setLoading(false);
        return false;
      }

      final success = await _openWhatsApp(cleanedPhone);

      if (success) {
        await _savePhoneNumber(cleanedPhone);
        _errorMessage = null;
        _setLoading(false);
        return true;
      } else {
        _errorMessage = '⚠️ تأكد من تثبيت واتساب على جهازك';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error linking phone: $e');
      _errorMessage = 'حدث خطأ: $e';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> _openWhatsApp(String phone) async {
    try {
      final url = Uri.parse('whatsapp://send?phone=$phone');

      if (await canLaunchUrl(url)) {
        await launchUrl(url);
        return true;
      } else {
        final webUrl = Uri.parse('https://wa.me/$phone');
        if (await canLaunchUrl(webUrl)) {
          await launchUrl(webUrl);
          return true;
        }
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error opening WhatsApp: $e');
      return false;
    }
  }

  /// إرسال رسالة إلى رقم واحد
  Future<bool> sendMessageToNumber({
    required String phone,
    required String message,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final cleanedPhone = _cleanPhoneNumber(phone);

      if (cleanedPhone.isEmpty) {
        _errorMessage = 'رقم الهاتف غير صحيح';
        _setLoading(false);
        return false;
      }

      final encodedMessage = Uri.encodeComponent(message);
      final url = Uri.parse(
        'whatsapp://send?phone=$cleanedPhone&text=$encodedMessage',
      );

      if (await canLaunchUrl(url)) {
        await launchUrl(url);
        _setLoading(false);
        return true;
      } else {
        final webUrl = Uri.parse(
          'https://wa.me/$cleanedPhone?text=$encodedMessage',
        );
        if (await canLaunchUrl(webUrl)) {
          await launchUrl(
            webUrl,
            mode: url_launcher.LaunchMode.externalApplication,
          );
          _setLoading(false);
          return true;
        }
        _errorMessage = '⚠️ لا يمكن فتح واتساب';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error sending message: $e');
      _errorMessage = 'حدث خطأ: $e';
      _setLoading(false);
      return false;
    }
  }

  /// إرسال رسالة لمجموعة (الطريقة القديمة)
  Future<bool> sendMessageToGroup({
    required List<String> phoneNumbers,
    required String message,
    bool useWeb = false,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      if (phoneNumbers.isEmpty) {
        _errorMessage = '⚠️ يجب اختيار جهة اتصال واحدة على الأقل';
        _setLoading(false);
        return false;
      }

      if (message.trim().isEmpty) {
        _errorMessage = '⚠️ يجب كتابة رسالة للإرسال';
        _setLoading(false);
        return false;
      }

      final cleanedNumbers = phoneNumbers
          .map((p) => _cleanPhoneNumber(p))
          .where((p) => p.isNotEmpty)
          .toList();

      if (cleanedNumbers.isEmpty) {
        _errorMessage = '⚠️ لا توجد أرقام صالحة للإرسال';
        _setLoading(false);
        return false;
      }

      final encodedMessage = Uri.encodeComponent(message);

      if (useWeb) {
        return await _sendViaWeb(cleanedNumbers.first, encodedMessage);
      } else {
        return await _sendViaApp(cleanedNumbers, encodedMessage);
      }
    } catch (e) {
      debugPrint('❌ Error sending message: $e');
      _errorMessage = 'حدث خطأ أثناء الإرسال: $e';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> _sendViaApp(List<String> numbers, String encodedMessage) async {
    bool allSuccess = true;

    for (int i = 0; i < numbers.length; i++) {
      try {
        final url = Uri.parse(
          'whatsapp://send?phone=${numbers[i]}&text=$encodedMessage',
        );

        if (await canLaunchUrl(url)) {
          await launchUrl(url);
          if (i < numbers.length - 1) {
            await Future.delayed(const Duration(seconds: 1));
          }
        } else {
          allSuccess = false;
          _errorMessage = '⚠️ فشل الإرسال للرقم: ${numbers[i]}';
          break;
        }
      } catch (e) {
        allSuccess = false;
        _errorMessage = '⚠️ خطأ في الإرسال: $e';
        break;
      }
    }

    _setLoading(false);
    return allSuccess;
  }

  Future<bool> _sendViaWeb(String phone, String encodedMessage) async {
    try {
      final url = Uri.parse('https://wa.me/$phone?text=$encodedMessage');

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: url_launcher.LaunchMode.externalApplication);
        _setLoading(false);
        return true;
      } else {
        _errorMessage = '⚠️ لا يمكن فتح واتساب ويب';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = '⚠️ خطأ في الفتح: $e';
      _setLoading(false);
      return false;
    }
  }

  /// إرسال رسالة مخصصة
  Future<bool> sendCustomMessage({
    required String phone,
    required String message,
    bool useWeb = false,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final cleanedPhone = _cleanPhoneNumber(phone);

      if (cleanedPhone.isEmpty) {
        _errorMessage = 'رقم الهاتف غير صحيح';
        _setLoading(false);
        return false;
      }

      final encodedMessage = Uri.encodeComponent(message);

      if (useWeb) {
        final url = Uri.parse(
          'https://wa.me/$cleanedPhone?text=$encodedMessage',
        );
        if (await canLaunchUrl(url)) {
          await launchUrl(
            url,
            mode: url_launcher.LaunchMode.externalApplication,
          );
          _setLoading(false);
          return true;
        }
      } else {
        final url = Uri.parse(
          'whatsapp://send?phone=$cleanedPhone&text=$encodedMessage',
        );
        if (await canLaunchUrl(url)) {
          await launchUrl(url);
          _setLoading(false);
          return true;
        }
      }

      _errorMessage = '⚠️ لا يمكن فتح واتساب';
      _setLoading(false);
      return false;
    } catch (e) {
      debugPrint('❌ Error sending custom message: $e');
      _errorMessage = 'حدث خطأ: $e';
      _setLoading(false);
      return false;
    }
  }

  // =============================================
  // ✅ URL LAUNCHER METHODS
  // =============================================

  Future<bool> canLaunchUrl(Uri url) async {
    try {
      return await url_launcher.canLaunchUrl(url);
    } catch (e) {
      debugPrint('❌ Error checking URL: $e');
      return false;
    }
  }

  Future<bool> launchUrl(
    Uri url, {
    url_launcher.LaunchMode mode = url_launcher.LaunchMode.platformDefault,
  }) async {
    try {
      return await url_launcher.launchUrl(url, mode: mode);
    } catch (e) {
      debugPrint('❌ Error launching URL: $e');
      return false;
    }
  }

  // =============================================
  // ✅ UTILITY METHODS
  // =============================================

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> unlinkPhone() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('whatsapp_phone');
      _phoneNumber = null;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error unlinking phone: $e');
    }
  }

  String? getFormattedPhoneNumber() {
    if (_phoneNumber == null || _phoneNumber!.isEmpty) return null;
    return '+$_phoneNumber';
  }

  Future<bool> checkWhatsAppInstalled() async {
    await _checkWhatsAppInstallation();
    return _isWhatsAppInstalled;
  }

  // =============================================
  // ✅ STATIC HELPERS
  // =============================================

  static String cleanPhoneNumber(String phone) {
    String cleaned = phone
        .replaceAll(' ', '')
        .replaceAll('-', '')
        .replaceAll('(', '')
        .replaceAll(')', '')
        .replaceAll('+', '')
        .trim();

    if (cleaned.startsWith('0') && cleaned.length > 10) {
      cleaned = cleaned.substring(1);
    }

    if (!cleaned.startsWith('20') && cleaned.length == 10) {
      cleaned = '20$cleaned';
    }

    if (cleaned.startsWith('0') && cleaned.length == 11) {
      cleaned = '20${cleaned.substring(1)}';
    }

    return cleaned;
  }

  static bool isValidPhoneNumber(String phone) {
    if (!RegExp(r'^[0-9]+$').hasMatch(phone)) {
      return false;
    }
    return phone.length >= 10 && phone.length <= 15;
  }

  static String buildWhatsAppUrl(String phone, {String? message}) {
    final cleaned = cleanPhoneNumber(phone);
    if (message != null && message.isNotEmpty) {
      return 'https://wa.me/$cleaned?text=${Uri.encodeComponent(message)}';
    }
    return 'https://wa.me/$cleaned';
  }

  static String buildWhatsAppAppUrl(String phone, {String? message}) {
    final cleaned = cleanPhoneNumber(phone);
    if (message != null && message.isNotEmpty) {
      return 'whatsapp://send?phone=$cleaned&text=${Uri.encodeComponent(message)}';
    }
    return 'whatsapp://send?phone=$cleaned';
  }
}
