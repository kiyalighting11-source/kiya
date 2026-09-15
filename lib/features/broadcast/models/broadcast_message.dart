// lib/features/broadcast/models/broadcast_message.dart

import 'package:flutter/material.dart';

// ✅ FIX: Import BroadcastResult and BroadcastRecipient from broadcast_result
// (BroadcastRecipient is now ONLY defined in broadcast_result.dart)
import 'broadcast_result.dart';

// =============================================
// ✅ BROADCAST STATUS ENUM
// =============================================

/// حالة رسالة البث
enum BroadcastStatus {
  /// قيد الانتظار
  pending('قيد الانتظار', 'pending', Colors.grey),

  /// جاري الإرسال
  sending('جاري الإرسال', 'sending', Colors.blue),

  /// متوقف مؤقتاً
  paused('متوقف مؤقتاً', 'paused', Colors.amber),

  /// مكتمل
  completed('مكتمل', 'completed', Colors.green),

  /// فشل كلي
  failed('فشل', 'failed', Colors.red),

  /// نجح جزئياً
  partial('نجح جزئياً', 'partial', Colors.purple),

  /// ملغي
  cancelled('ملغي', 'cancelled', Colors.orange);

  final String label;
  final String code;
  final Color color;

  const BroadcastStatus(this.label, this.code, this.color);

  // =============================================
  // ✅ FACTORY METHODS
  // =============================================

  static BroadcastStatus fromString(String value) {
    return BroadcastStatus.values.firstWhere(
      (e) => e.code == value || e.label == value,
      orElse: () => BroadcastStatus.pending,
    );
  }

  static BroadcastStatus fromResult(int success, int failed, bool isPaused) {
    if (isPaused) return BroadcastStatus.paused;
    if (success == 0 && failed == 0) return BroadcastStatus.pending;
    if (success == 0 && failed > 0) return BroadcastStatus.failed;
    if (failed == 0 && success > 0) return BroadcastStatus.completed;
    return BroadcastStatus.partial;
  }

  // =============================================
  // ✅ GETTERS
  // =============================================

  bool get isPending => this == BroadcastStatus.pending;
  bool get isSending => this == BroadcastStatus.sending;
  bool get isPaused => this == BroadcastStatus.paused;
  bool get isCompleted => this == BroadcastStatus.completed;
  bool get isFailed => this == BroadcastStatus.failed;
  bool get isPartial => this == BroadcastStatus.partial;
  bool get isCancelled => this == BroadcastStatus.cancelled;
  bool get isActive =>
      this == BroadcastStatus.sending || this == BroadcastStatus.pending;
  bool get isFinished =>
      this == BroadcastStatus.completed ||
      this == BroadcastStatus.failed ||
      this == BroadcastStatus.cancelled;

  String get statusLabel => label;
  String get statusCode => code;
  Color get statusColor => color;

  IconData get icon {
    switch (this) {
      case BroadcastStatus.pending:
        return Icons.hourglass_empty;
      case BroadcastStatus.sending:
        return Icons.send;
      case BroadcastStatus.paused:
        return Icons.pause;
      case BroadcastStatus.completed:
        return Icons.check_circle;
      case BroadcastStatus.failed:
        return Icons.error;
      case BroadcastStatus.partial:
        return Icons.warning;
      case BroadcastStatus.cancelled:
        return Icons.cancel;
    }
  }
}

// =============================================
// ❌ BroadcastRecipient REMOVED FROM HERE
// ✅ It's now ONLY in broadcast_result.dart
// =============================================

// =============================================
// ✅ BROADCAST MESSAGE MODEL
// =============================================

/// نموذج رسالة البث
class BroadcastMessage {
  /// معرف الرسالة
  final String? id;

  /// نص الرسالة
  final String message;

  /// معرفات العملاء المستهدفين
  final List<String> customerIds;

  /// أرقام الهواتف المستهدفة
  final List<String> phoneNumbers;

  /// وقت الإرسال
  final DateTime sentAt;

  /// عدد الرسائل الناجحة
  final int successCount;

  /// عدد الرسائل الفاشلة
  final int failedCount;

  /// معرف المستخدم المرسل
  final String? userId;

  /// اسم المستخدم المرسل
  final String? userName;

  /// حالة البث
  final BroadcastStatus status;

  /// قائمة المستلمين (التفاصيل)
  final List<BroadcastRecipient>? recipients;

  /// معرف الباتش (للاستئناف)
  final String? batchId;

  /// إجمالي عدد المستلمين
  final int? totalCount;

  /// وقت الانتهاء
  final DateTime? completedAt;

  /// وقت بدء الإرسال
  final DateTime? startedAt;

  /// ملاحظات إضافية
  final String? notes;

  /// هل تم إرسالها؟
  final bool isSent;

  BroadcastMessage({
    this.id,
    required this.message,
    required this.customerIds,
    required this.phoneNumbers,
    required this.sentAt,
    this.successCount = 0,
    this.failedCount = 0,
    this.userId,
    this.userName,
    this.status = BroadcastStatus.pending,
    this.recipients,
    this.batchId,
    this.totalCount,
    this.completedAt,
    this.startedAt,
    this.notes,
    this.isSent = false,
  });

  // =============================================
  // ✅ GETTERS
  // =============================================

  /// إجمالي عدد المستلمين
  int get totalCountValue => totalCount ?? (successCount + failedCount);

  /// إجمالي عدد المحاولات
  int get totalAttempts => successCount + failedCount;

  /// نسبة النجاح (0-100)
  double get successRate {
    if (totalCountValue == 0) return 0;
    return (successCount / totalCountValue) * 100;
  }

  /// نسبة الفشل (0-100)
  double get failureRate {
    if (totalCountValue == 0) return 0;
    return (failedCount / totalCountValue) * 100;
  }

  /// هل اكتمل البث؟
  bool get isCompleted => status == BroadcastStatus.completed;

  /// هل فشل البث؟
  bool get isFailed => status == BroadcastStatus.failed;

  /// هل البث قيد الانتظار؟
  bool get isPending => status == BroadcastStatus.pending;

  /// هل البث جاري؟
  bool get isSending => status == BroadcastStatus.sending;

  /// هل البث متوقف مؤقتاً؟
  bool get isPaused => status == BroadcastStatus.paused;

  /// هل البث ملغي؟
  bool get isCancelled => status == BroadcastStatus.cancelled;

  /// هل البث نجح جزئياً؟
  bool get isPartial => status == BroadcastStatus.partial;

  /// هل البث نشط (قيد الإرسال أو انتظار)؟
  bool get isActive => status.isActive;

  /// هل البث منتهي (مكتمل، فاشل، ملغي)؟
  bool get isFinished => status.isFinished;

  /// الوقت المستغرق في الإرسال
  Duration? get duration {
    if (startedAt == null || completedAt == null) return null;
    return completedAt!.difference(startedAt!);
  }

  /// الوقت المستغرق بالثواني
  int? get durationInSeconds => duration?.inSeconds;

  /// الوقت المستغرق بالدقائق
  int? get durationInMinutes => duration?.inMinutes;

  /// نص الوقت المستغرق
  String get formattedDuration {
    if (duration == null) return '--:--';
    final minutes = duration!.inMinutes;
    final seconds = duration!.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// نص وقت الإرسال
  String get formattedSentAt {
    return '${sentAt.year}-${sentAt.month.toString().padLeft(2, '0')}-${sentAt.day.toString().padLeft(2, '0')} ${sentAt.hour.toString().padLeft(2, '0')}:${sentAt.minute.toString().padLeft(2, '0')}';
  }

  /// نص وقت الانتهاء
  String get formattedCompletedAt {
    if (completedAt == null) return 'لم ينته بعد';
    return '${completedAt!.year}-${completedAt!.month.toString().padLeft(2, '0')}-${completedAt!.day.toString().padLeft(2, '0')} ${completedAt!.hour.toString().padLeft(2, '0')}:${completedAt!.minute.toString().padLeft(2, '0')}';
  }

  /// نص الحالة
  String get statusLabel => status.label;

  /// لون الحالة
  Color get statusColor => status.color;

  /// أيقونة الحالة
  IconData get statusIcon => status.icon;

  /// عدد المستلمين الناجحين
  List<BroadcastRecipient> get successfulRecipients {
    return recipients?.where((r) => r.success).toList() ?? [];
  }

  /// عدد المستلمين الفاشلين
  List<BroadcastRecipient> get failedRecipients {
    return recipients?.where((r) => !r.success).toList() ?? [];
  }

  /// الأرقام الناجحة
  List<String> get successfulPhoneNumbers {
    return successfulRecipients.map((r) => r.phoneNumber).toList();
  }

  /// الأرقام الفاشلة
  List<String> get failedPhoneNumbers {
    return failedRecipients.map((r) => r.phoneNumber).toList();
  }

  /// ملخص البث
  String get summary {
    if (isCompleted) {
      return '✅ تم إرسال $successCount رسالة بنجاح';
    } else if (isFailed) {
      return '❌ فشل إرسال جميع الرسائل ($failedCount)';
    } else if (isPartial) {
      return '⚠️ نجح $successCount، فشل $failedCount';
    } else if (isPaused) {
      return '⏸️ متوقف مؤقتاً: أرسل $successCount، متبقي ${totalCountValue - successCount - failedCount}';
    } else if (isSending) {
      return '📤 جاري الإرسال... $successCount من $totalCountValue';
    } else {
      return '📊 نجح: $successCount، فشل: $failedCount';
    }
  }

  // =============================================
  // ✅ FACTORY METHODS
  // =============================================

  /// إنشاء رسالة جديدة
  factory BroadcastMessage.create({
    required String message,
    required List<String> customerIds,
    required List<String> phoneNumbers,
    String? userId,
    String? userName,
    String? notes,
  }) {
    return BroadcastMessage(
      message: message,
      customerIds: customerIds,
      phoneNumbers: phoneNumbers,
      sentAt: DateTime.now(),
      totalCount: phoneNumbers.length,
      userId: userId,
      userName: userName,
      status: BroadcastStatus.pending,
      notes: notes,
    );
  }

  /// إنشاء رسالة من نتيجة البث
  factory BroadcastMessage.fromResult({
    required String message,
    required BroadcastResult result,
    required List<String> customerIds,
    required List<String> phoneNumbers,
    String? userId,
    String? userName,
    String? notes,
  }) {
    final recipients = result.results.map((r) {
      final customerIndex = phoneNumbers.indexOf(r.phoneNumber);
      return BroadcastRecipient(
        phoneNumber: r.phoneNumber,
        customerId: customerIndex != -1 ? customerIds[customerIndex] : null,
        success: r.success,
        errorMessage: r.errorMessage,
        sentAt: r.sentAt,
      );
    }).toList();

    final status = BroadcastStatus.fromResult(
      result.success,
      result.failed,
      result.isPaused,
    );

    return BroadcastMessage(
      message: message,
      customerIds: customerIds,
      phoneNumbers: phoneNumbers,
      sentAt: DateTime.now(),
      successCount: result.success,
      failedCount: result.failed,
      userId: userId,
      userName: userName,
      status: status,
      recipients: recipients,
      batchId: result.batchId,
      totalCount: phoneNumbers.length,
      completedAt: result.isComplete ? DateTime.now() : null,
      startedAt: result.startedAt,
      notes: notes,
    );
  }

  // =============================================
  // ✅ JSON SERIALIZATION
  // =============================================

  factory BroadcastMessage.fromJson(Map<String, dynamic> json) {
    return BroadcastMessage(
      id: json['id'],
      message: json['message'] ?? '',
      customerIds: json['customer_ids'] != null
          ? List<String>.from(json['customer_ids'])
          : [],
      phoneNumbers: json['phone_numbers'] != null
          ? List<String>.from(json['phone_numbers'])
          : [],
      sentAt: json['sent_at'] != null
          ? DateTime.parse(json['sent_at'])
          : DateTime.now(),
      successCount: json['success_count'] ?? 0,
      failedCount: json['failed_count'] ?? 0,
      userId: json['user_id'],
      userName: json['user_name'],
      status: BroadcastStatus.fromString(json['status'] ?? 'pending'),
      recipients: json['recipients'] != null
          ? List<BroadcastRecipient>.from(
              json['recipients'].map((r) => BroadcastRecipient.fromJson(r)),
            )
          : null,
      batchId: json['batch_id'],
      totalCount: json['total_count'],
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'])
          : null,
      notes: json['notes'],
      isSent: json['is_sent'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'customer_ids': customerIds,
      'phone_numbers': phoneNumbers,
      'sent_at': sentAt.toIso8601String(),
      'success_count': successCount,
      'failed_count': failedCount,
      'user_id': userId,
      'user_name': userName,
      'status': status.code,
      'recipients': recipients?.map((r) => r.toJson()).toList(),
      'batch_id': batchId,
      'total_count': totalCount,
      'completed_at': completedAt?.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'notes': notes,
      'is_sent': isSent,
    };
  }

  // =============================================
  // ✅ COPY WITH
  // =============================================

  BroadcastMessage copyWith({
    String? id,
    String? message,
    List<String>? customerIds,
    List<String>? phoneNumbers,
    DateTime? sentAt,
    int? successCount,
    int? failedCount,
    String? userId,
    String? userName,
    BroadcastStatus? status,
    List<BroadcastRecipient>? recipients,
    String? batchId,
    int? totalCount,
    DateTime? completedAt,
    DateTime? startedAt,
    String? notes,
    bool? isSent,
  }) {
    return BroadcastMessage(
      id: id ?? this.id,
      message: message ?? this.message,
      customerIds: customerIds ?? this.customerIds,
      phoneNumbers: phoneNumbers ?? this.phoneNumbers,
      sentAt: sentAt ?? this.sentAt,
      successCount: successCount ?? this.successCount,
      failedCount: failedCount ?? this.failedCount,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      status: status ?? this.status,
      recipients: recipients ?? this.recipients,
      batchId: batchId ?? this.batchId,
      totalCount: totalCount ?? this.totalCount,
      completedAt: completedAt ?? this.completedAt,
      startedAt: startedAt ?? this.startedAt,
      notes: notes ?? this.notes,
      isSent: isSent ?? this.isSent,
    );
  }

  // =============================================
  // ✅ HELPER METHODS
  // =============================================

  /// تحديث الحالة بناءً على نتيجة البث
  BroadcastMessage updateStatusFromResult(BroadcastResult result) {
    final newStatus = BroadcastStatus.fromResult(
      result.success,
      result.failed,
      result.isPaused,
    );

    final recipients = result.results.map((r) {
      final customerIndex = phoneNumbers.indexOf(r.phoneNumber);
      return BroadcastRecipient(
        phoneNumber: r.phoneNumber,
        customerId: customerIndex != -1 ? customerIds[customerIndex] : null,
        success: r.success,
        errorMessage: r.errorMessage,
        sentAt: r.sentAt,
      );
    }).toList();

    return copyWith(
      successCount: result.success,
      failedCount: result.failed,
      status: newStatus,
      recipients: recipients,
      batchId: result.batchId ?? batchId,
      completedAt: result.isComplete ? DateTime.now() : null,
      startedAt: result.startedAt ?? startedAt,
    );
  }

  // =============================================
  // ✅ OPERATOR OVERLOADS
  // =============================================

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BroadcastMessage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'BroadcastMessage(id: $id, status: ${status.label}, success: $successCount, failed: $failedCount)';
  }
}

// =============================================
// ✅ BROADCAST MESSAGE GROUP
// =============================================

/// مجموعة رسائل البث (للتجميع حسب التاريخ أو المستخدم)
class BroadcastMessageGroup {
  /// عنوان المجموعة
  final String title;

  /// تاريخ المجموعة
  final DateTime? date;

  /// قائمة الرسائل
  final List<BroadcastMessage> messages;

  BroadcastMessageGroup({
    required this.title,
    this.date,
    required this.messages,
  });

  // =============================================
  // ✅ GETTERS
  // =============================================

  int get totalMessages => messages.length;
  int get totalSent => messages.fold(0, (sum, m) => sum + m.successCount);
  int get totalFailed => messages.fold(0, (sum, m) => sum + m.failedCount);
  int get totalAttempts => totalSent + totalFailed;

  double get averageSuccessRate {
    if (totalAttempts == 0) return 0;
    return (totalSent / totalAttempts) * 100;
  }

  String get formattedAverageRate =>
      '${averageSuccessRate.toStringAsFixed(1)}%';

  // =============================================
  // ✅ FACTORY METHODS
  // =============================================

  /// تجميع الرسائل حسب اليوم
  static List<BroadcastMessageGroup> groupByDay(
    List<BroadcastMessage> messages,
  ) {
    final Map<DateTime, List<BroadcastMessage>> groups = {};

    for (var message in messages) {
      final date = DateTime(
        message.sentAt.year,
        message.sentAt.month,
        message.sentAt.day,
      );
      groups.putIfAbsent(date, () => []).add(message);
    }

    return groups.entries.map((entry) {
      return BroadcastMessageGroup(
        title: _formatDate(entry.key),
        date: entry.key,
        messages: entry.value,
      );
    }).toList()..sort((a, b) => b.date!.compareTo(a.date!));
  }

  /// تجميع الرسائل حسب المستخدم
  static List<BroadcastMessageGroup> groupByUser(
    List<BroadcastMessage> messages,
  ) {
    final Map<String, List<BroadcastMessage>> groups = {};

    for (var message in messages) {
      final key = message.userId ?? 'unknown';
      groups.putIfAbsent(key, () => []).add(message);
    }

    return groups.entries.map((entry) {
      final userName = entry.value.first.userName ?? 'مستخدم غير معروف';
      return BroadcastMessageGroup(title: userName, messages: entry.value);
    }).toList();
  }

  /// تجميع الرسائل حسب الشهر
  static List<BroadcastMessageGroup> groupByMonth(
    List<BroadcastMessage> messages,
  ) {
    final Map<String, List<BroadcastMessage>> groups = {};

    for (var message in messages) {
      final key =
          '${message.sentAt.year}-${message.sentAt.month.toString().padLeft(2, '0')}';
      groups.putIfAbsent(key, () => []).add(message);
    }

    return groups.entries.map((entry) {
      final parts = entry.key.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final date = DateTime(year, month, 1);
      return BroadcastMessageGroup(
        title: _formatMonth(date),
        date: date,
        messages: entry.value,
      );
    }).toList()..sort((a, b) => b.date!.compareTo(a.date!));
  }

  static String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) return 'اليوم';
    if (date == yesterday) return 'أمس';

    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  static String _formatMonth(DateTime date) {
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

// =============================================
// ✅ EXTENSIONS
// =============================================

/// ملحقات لقائمة رسائل البث
extension BroadcastMessageListExtension on List<BroadcastMessage> {
  /// إجمالي الرسائل الناجحة
  int get totalSuccess => fold(0, (sum, m) => sum + m.successCount);

  /// إجمالي الرسائل الفاشلة
  int get totalFailed => fold(0, (sum, m) => sum + m.failedCount);

  /// إجمالي المحاولات
  int get totalAttempts => totalSuccess + totalFailed;

  /// متوسط نسبة النجاح
  double get averageSuccessRate {
    if (totalAttempts == 0) return 0;
    return (totalSuccess / totalAttempts) * 100;
  }

  /// الحصول على الرسائل الناجحة بالكامل
  List<BroadcastMessage> get completedMessages {
    return where((m) => m.isCompleted).toList();
  }

  /// الحصول على الرسائل الفاشلة بالكامل
  List<BroadcastMessage> get failedMessages {
    return where((m) => m.isFailed).toList();
  }

  /// الحصول على الرسائل الجزئية
  List<BroadcastMessage> get partialMessages {
    return where((m) => m.isPartial).toList();
  }

  /// الحصول على الرسائل النشطة
  List<BroadcastMessage> get activeMessages {
    return where((m) => m.isActive).toList();
  }

  /// الحصول على جميع المستلمين
  List<BroadcastRecipient> getAllRecipients() {
    final List<BroadcastRecipient> allRecipients = [];
    for (var message in this) {
      if (message.recipients != null) {
        allRecipients.addAll(message.recipients!);
      }
    }
    return allRecipients;
  }

  /// الحصول على المستلمين الناجحين
  List<BroadcastRecipient> getSuccessfulRecipients() {
    return getAllRecipients().where((r) => r.success).toList();
  }

  /// الحصول على المستلمين الفاشلين
  List<BroadcastRecipient> getFailedRecipients() {
    return getAllRecipients().where((r) => !r.success).toList();
  }

  /// ترتيب حسب التاريخ (الأحدث أولاً)
  List<BroadcastMessage> sortedByDate() {
    return toList()..sort((a, b) => b.sentAt.compareTo(a.sentAt));
  }

  /// ترتيب حسب الحالة
  List<BroadcastMessage> sortedByStatus() {
    return toList()..sort((a, b) => a.status.index.compareTo(b.status.index));
  }

  /// تجميع حسب اليوم
  List<BroadcastMessageGroup> groupByDay() {
    return BroadcastMessageGroup.groupByDay(this);
  }

  /// تجميع حسب المستخدم
  List<BroadcastMessageGroup> groupByUser() {
    return BroadcastMessageGroup.groupByUser(this);
  }

  /// تجميع حسب الشهر
  List<BroadcastMessageGroup> groupByMonth() {
    return BroadcastMessageGroup.groupByMonth(this);
  }

  /// فلترة حسب النطاق الزمني
  List<BroadcastMessage> filterByDateRange(DateTime from, DateTime to) {
    return where((m) => m.sentAt.isAfter(from) && m.sentAt.isBefore(to))
        .toList();
  }

  /// فلترة حسب المستخدم
  List<BroadcastMessage> filterByUser(String userId) {
    return where((m) => m.userId == userId).toList();
  }

  /// فلترة حسب الحالة
  List<BroadcastMessage> filterByStatus(BroadcastStatus status) {
    return where((m) => m.status == status).toList();
  }

  /// فلترة حسب النص
  List<BroadcastMessage> filterByText(String query) {
    if (query.isEmpty) return this;
    final lowerQuery = query.toLowerCase();
    return where(
      (m) =>
          m.message.toLowerCase().contains(lowerQuery) ||
          m.userName?.toLowerCase().contains(lowerQuery) == true,
    ).toList();
  }

  /// الحصول على الإحصائيات
  Map<String, dynamic> getStatistics() {
    return {
      'total': length,
      'completed': completedMessages.length,
      'failed': failedMessages.length,
      'partial': partialMessages.length,
      'active': activeMessages.length,
      'totalSuccess': totalSuccess,
      'totalFailed': totalFailed,
      'totalAttempts': totalAttempts,
      'averageSuccessRate': averageSuccessRate,
      'formattedSuccessRate': '${averageSuccessRate.toStringAsFixed(1)}%',
    };
  }
}
