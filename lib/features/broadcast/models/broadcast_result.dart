// lib/features/broadcast/models/broadcast_result.dart

import 'package:flutter/material.dart';

// =============================================
// ✅ BROADCAST RESULT MODEL
// =============================================

/// نتيجة عملية البث الإجمالية
class BroadcastResult {
  /// عدد الرسائل التي تم إرسالها بنجاح
  final int success;

  /// عدد الرسائل التي فشل إرسالها
  final int failed;

  /// قائمة تفاصيل كل مستلم
  final List<BroadcastRecipient> results;

  /// هل اكتملت العملية بالكامل؟
  final bool isComplete;

  /// رسالة الخطأ (إن وجدت)
  final String? errorMessage;

  /// معرف الباتش (للاستئناف)
  final String? batchId;

  /// هل العملية موقفة مؤقتاً؟
  final bool isPaused;

  /// وقت بدء الإرسال
  final DateTime? startedAt;

  /// وقت انتهاء الإرسال
  final DateTime? completedAt;

  BroadcastResult({
    required this.success,
    required this.failed,
    required this.results,
    this.isComplete = false,
    this.errorMessage,
    this.batchId,
    this.isPaused = false,
    this.startedAt,
    this.completedAt,
  });

  // =============================================
  // ✅ GETTERS
  // =============================================

  /// إجمالي عدد المستلمين
  int get total => success + failed;

  /// نسبة النجاح (0-100)
  double get successRate => total > 0 ? (success / total) * 100 : 0;

  /// نسبة الفشل (0-100)
  double get failureRate => total > 0 ? (failed / total) * 100 : 0;

  /// هل العملية ناجحة بالكامل؟
  bool get isFullySuccessful => failed == 0 && success > 0;

  /// هل العملية فاشلة بالكامل؟
  bool get isFullyFailed => success == 0 && failed > 0;

  /// هل العملية مكتملة جزئياً؟
  bool get isPartial => success > 0 && failed > 0;

  /// الوقت المستغرق في العملية
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

  /// قائمة الأرقام الناجحة
  List<String> get successfulNumbers =>
      results.where((r) => r.success).map((r) => r.phoneNumber).toList();

  /// قائمة الأرقام الفاشلة
  List<String> get failedNumbers =>
      results.where((r) => !r.success).map((r) => r.phoneNumber).toList();

  /// نص ملخص النتيجة
  String get summary {
    if (isFullySuccessful) {
      return '✅ تم الإرسال بنجاح إلى $success شخص';
    } else if (isFullyFailed) {
      return '❌ فشل إرسال جميع الرسائل ($failed شخص)';
    } else if (isPartial) {
      return '⚠️ تم الإرسال جزئياً: نجح $success، فشل $failed';
    } else if (isPaused) {
      return '⏸️ متوقف مؤقتاً: أرسل $success، متبقي ${total - success - failed}';
    } else {
      return '📊 نجح: $success، فشل: $failed';
    }
  }

  /// لون ملخص النتيجة
  Color get summaryColor {
    if (isFullySuccessful) return Colors.green;
    if (isFullyFailed) return Colors.red;
    if (isPartial) return Colors.orange;
    if (isPaused) return Colors.amber;
    return Colors.blue;
  }

  /// أيقونة ملخص النتيجة
  IconData get summaryIcon {
    if (isFullySuccessful) return Icons.check_circle;
    if (isFullyFailed) return Icons.error;
    if (isPartial) return Icons.warning;
    if (isPaused) return Icons.pause_circle;
    return Icons.info;
  }

  // =============================================
  // ✅ FACTORY METHODS
  // =============================================

  /// إنشاء نتيجة فاشلة
  factory BroadcastResult.failed(String message) {
    return BroadcastResult(
      success: 0,
      failed: 0,
      results: [],
      isComplete: false,
      errorMessage: message,
    );
  }

  /// إنشاء نتيجة ناجحة بالكامل
  factory BroadcastResult.successful(List<BroadcastRecipient> results) {
    return BroadcastResult(
      success: results.where((r) => r.success).length,
      failed: results.where((r) => !r.success).length,
      results: results,
      isComplete: true,
    );
  }

  /// إنشاء نتيجة من قائمة الأرقام
  factory BroadcastResult.fromNumbers({
    required List<String> numbers,
    required List<String> successfulNumbers,
    String? batchId,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    final results = numbers.map((number) {
      return BroadcastRecipient(
        phoneNumber: number,
        success: successfulNumbers.contains(number),
        sentAt: successfulNumbers.contains(number) ? DateTime.now() : null,
      );
    }).toList();

    return BroadcastResult(
      success: successfulNumbers.length,
      failed: numbers.length - successfulNumbers.length,
      results: results,
      isComplete: true,
      batchId: batchId,
      startedAt: startedAt,
      completedAt: completedAt ?? DateTime.now(),
    );
  }

  // =============================================
  // ✅ JSON SERIALIZATION
  // =============================================

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'failed': failed,
      'results': results.map((r) => r.toJson()).toList(),
      'isComplete': isComplete,
      'errorMessage': errorMessage,
      'batchId': batchId,
      'isPaused': isPaused,
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory BroadcastResult.fromJson(Map<String, dynamic> json) {
    return BroadcastResult(
      success: json['success'] ?? 0,
      failed: json['failed'] ?? 0,
      results: json['results'] != null
          ? List<BroadcastRecipient>.from(
              json['results'].map((r) => BroadcastRecipient.fromJson(r)),
            )
          : [],
      isComplete: json['isComplete'] ?? false,
      errorMessage: json['errorMessage'],
      batchId: json['batchId'],
      isPaused: json['isPaused'] ?? false,
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'])
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
    );
  }

  // =============================================
  // ✅ COPY WITH
  // =============================================

  BroadcastResult copyWith({
    int? success,
    int? failed,
    List<BroadcastRecipient>? results,
    bool? isComplete,
    String? errorMessage,
    String? batchId,
    bool? isPaused,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return BroadcastResult(
      success: success ?? this.success,
      failed: failed ?? this.failed,
      results: results ?? this.results,
      isComplete: isComplete ?? this.isComplete,
      errorMessage: errorMessage ?? this.errorMessage,
      batchId: batchId ?? this.batchId,
      isPaused: isPaused ?? this.isPaused,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  // =============================================
  // ✅ OPERATOR OVERLOADS
  // =============================================

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BroadcastResult &&
        other.batchId == batchId &&
        other.success == success &&
        other.failed == failed;
  }

  @override
  int get hashCode => batchId.hashCode ^ success.hashCode ^ failed.hashCode;

  @override
  String toString() {
    // ✅ FIX: Remove unnecessary braces
    return 'BroadcastResult(success: $success, failed: $failed, total: $total, rate: ${successRate.toStringAsFixed(1)}%)';
  }
}

// =============================================
// ✅ BROADCAST RECIPIENT MODEL
// =============================================

/// تفاصيل مستلم الرسالة
class BroadcastRecipient {
  /// رقم الهاتف
  final String phoneNumber;

  /// هل تم الإرسال بنجاح؟
  final bool success;

  /// رسالة الخطأ (إن وجدت)
  final String? errorMessage;

  /// وقت الإرسال
  final DateTime? sentAt;

  /// اسم العميل (اختياري)
  final String? customerName;

  /// معرف العميل (اختياري)
  final String? customerId;

  /// عدد محاولات الإرسال
  final int attempts;

  BroadcastRecipient({
    required this.phoneNumber,
    this.success = false,
    this.errorMessage,
    this.sentAt,
    this.customerName,
    this.customerId,
    this.attempts = 1,
  });

  // =============================================
  // ✅ GETTERS
  // =============================================

  /// هل تم الإرسال بنجاح؟
  bool get isSuccessful => success;

  /// هل فشل الإرسال؟
  bool get isFailed => !success;

  /// نص الحالة
  String get statusText => success ? '✅ ناجح' : '❌ فاشل';

  /// لون الحالة
  Color get statusColor => success ? Colors.green : Colors.red;

  /// أيقونة الحالة
  IconData get statusIcon => success ? Icons.check_circle : Icons.cancel;

  /// الوقت المنسق
  String get formattedSentAt {
    if (sentAt == null) return 'لم يرسل بعد';
    return '${sentAt!.hour.toString().padLeft(2, '0')}:${sentAt!.minute.toString().padLeft(2, '0')}';
  }

  /// التاريخ الكامل المنسق
  String get formattedFullDate {
    if (sentAt == null) return 'لم يرسل بعد';
    // ✅ FIX: Remove unnecessary braces
    return '${sentAt!.year}-${sentAt!.month.toString().padLeft(2, '0')}-${sentAt!.day.toString().padLeft(2, '0')} $formattedSentAt';
  }

  // =============================================
  // ✅ JSON SERIALIZATION
  // =============================================

  Map<String, dynamic> toJson() {
    return {
      'phoneNumber': phoneNumber,
      'success': success,
      'errorMessage': errorMessage,
      'sentAt': sentAt?.toIso8601String(),
      'customerName': customerName,
      'customerId': customerId,
      'attempts': attempts,
    };
  }

  factory BroadcastRecipient.fromJson(Map<String, dynamic> json) {
    return BroadcastRecipient(
      phoneNumber: json['phoneNumber'] ?? '',
      success: json['success'] ?? false,
      errorMessage: json['errorMessage'],
      sentAt: json['sentAt'] != null ? DateTime.parse(json['sentAt']) : null,
      customerName: json['customerName'],
      customerId: json['customerId'],
      attempts: json['attempts'] ?? 1,
    );
  }

  // =============================================
  // ✅ COPY WITH
  // =============================================

  BroadcastRecipient copyWith({
    String? phoneNumber,
    bool? success,
    String? errorMessage,
    DateTime? sentAt,
    String? customerName,
    String? customerId,
    int? attempts,
  }) {
    return BroadcastRecipient(
      phoneNumber: phoneNumber ?? this.phoneNumber,
      success: success ?? this.success,
      errorMessage: errorMessage ?? this.errorMessage,
      sentAt: sentAt ?? this.sentAt,
      customerName: customerName ?? this.customerName,
      customerId: customerId ?? this.customerId,
      attempts: attempts ?? this.attempts,
    );
  }

  // =============================================
  // ✅ OPERATOR OVERLOADS
  // =============================================

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BroadcastRecipient && other.phoneNumber == phoneNumber;
  }

  @override
  int get hashCode => phoneNumber.hashCode;

  @override
  String toString() {
    // ✅ FIX: Remove unnecessary braces
    return 'BroadcastRecipient(phone: $phoneNumber, success: $success, attempts: $attempts)';
  }
}

// =============================================
// ✅ BROADCAST STATISTICS
// =============================================

/// إحصائيات البث
class BroadcastStatistics {
  /// إجمالي عدد الرسائل المرسلة
  final int totalSent;

  /// إجمالي عدد الرسائل الناجحة
  final int totalSuccessful;

  /// إجمالي عدد الرسائل الفاشلة
  final int totalFailed;

  /// متوسط نسبة النجاح
  final double averageSuccessRate;

  /// عدد البثوث المنفذة
  final int totalBroadcasts;

  /// آخر بث منفذ
  final BroadcastResult? lastBroadcast;

  BroadcastStatistics({
    this.totalSent = 0,
    this.totalSuccessful = 0,
    this.totalFailed = 0,
    this.averageSuccessRate = 0,
    this.totalBroadcasts = 0,
    this.lastBroadcast,
  });

  // =============================================
  // ✅ GETTERS
  // =============================================

  double get successRate =>
      totalSent > 0 ? (totalSuccessful / totalSent) * 100 : 0;

  double get failureRate => totalSent > 0 ? (totalFailed / totalSent) * 100 : 0;

  String get formattedSuccessRate => '${successRate.toStringAsFixed(1)}%';
  String get formattedFailureRate => '${failureRate.toStringAsFixed(1)}%';

  // =============================================
  // ✅ FACTORY METHODS
  // =============================================

  factory BroadcastStatistics.fromResults(List<BroadcastResult> results) {
    int totalSent = 0;
    int totalSuccessful = 0;
    int totalFailed = 0;
    double totalRate = 0;

    for (var result in results) {
      totalSent += result.total;
      totalSuccessful += result.success;
      totalFailed += result.failed;
      totalRate += result.successRate;
    }

    return BroadcastStatistics(
      totalSent: totalSent,
      totalSuccessful: totalSuccessful,
      totalFailed: totalFailed,
      averageSuccessRate: results.isNotEmpty ? totalRate / results.length : 0,
      totalBroadcasts: results.length,
      lastBroadcast: results.isNotEmpty ? results.last : null,
    );
  }

  // =============================================
  // ✅ JSON SERIALIZATION
  // =============================================

  Map<String, dynamic> toJson() {
    return {
      'totalSent': totalSent,
      'totalSuccessful': totalSuccessful,
      'totalFailed': totalFailed,
      'averageSuccessRate': averageSuccessRate,
      'totalBroadcasts': totalBroadcasts,
      'lastBroadcast': lastBroadcast?.toJson(),
    };
  }

  factory BroadcastStatistics.fromJson(Map<String, dynamic> json) {
    return BroadcastStatistics(
      totalSent: json['totalSent'] ?? 0,
      totalSuccessful: json['totalSuccessful'] ?? 0,
      totalFailed: json['totalFailed'] ?? 0,
      averageSuccessRate: json['averageSuccessRate'] ?? 0,
      totalBroadcasts: json['totalBroadcasts'] ?? 0,
      lastBroadcast: json['lastBroadcast'] != null
          ? BroadcastResult.fromJson(json['lastBroadcast'])
          : null,
    );
  }

  @override
  String toString() {
    // ✅ FIX: Remove unnecessary braces
    return 'BroadcastStatistics(sent: $totalSent, success: $totalSuccessful, failed: $totalFailed, rate: $formattedSuccessRate)';
  }
}

// =============================================
// ✅ BROADCAST FILTERS
// =============================================

/// فلترة نتائج البث
class BroadcastFilters {
  /// فلترة حسب النجاح
  final bool? onlySuccessful;

  /// فلترة حسب الفشل
  final bool? onlyFailed;

  /// فلترة حسب رقم الهاتف
  final String? phoneNumber;

  /// فلترة حسب اسم العميل
  final String? customerName;

  /// فلترة حسب التاريخ من
  final DateTime? fromDate;

  /// فلترة حسب التاريخ إلى
  final DateTime? toDate;

  /// عدد النتائج المطلوبة
  final int? limit;

  /// الإزاحة (للترقيم)
  final int? offset;

  BroadcastFilters({
    this.onlySuccessful,
    this.onlyFailed,
    this.phoneNumber,
    this.customerName,
    this.fromDate,
    this.toDate,
    this.limit,
    this.offset,
  });

  /// تطبيق الفلترة على قائمة النتائج
  List<BroadcastRecipient> apply(List<BroadcastRecipient> recipients) {
    var result = recipients;

    if (onlySuccessful == true) {
      result = result.where((r) => r.success).toList();
    }

    if (onlyFailed == true) {
      result = result.where((r) => !r.success).toList();
    }

    if (phoneNumber != null && phoneNumber!.isNotEmpty) {
      result = result
          .where((r) => r.phoneNumber.contains(phoneNumber!))
          .toList();
    }

    if (customerName != null && customerName!.isNotEmpty) {
      result = result
          .where((r) => r.customerName?.contains(customerName!) ?? false)
          .toList();
    }

    if (fromDate != null) {
      result = result
          .where((r) => r.sentAt != null && r.sentAt!.isAfter(fromDate!))
          .toList();
    }

    if (toDate != null) {
      result = result
          .where((r) => r.sentAt != null && r.sentAt!.isBefore(toDate!))
          .toList();
    }

    if (limit != null && limit! > 0) {
      final start = offset ?? 0;
      final end = start + limit!;
      if (start < result.length) {
        result = result.sublist(
          start,
          end > result.length ? result.length : end,
        );
      } else {
        result = [];
      }
    }

    return result;
  }

  bool get hasFilters {
    return onlySuccessful != null ||
        onlyFailed != null ||
        (phoneNumber != null && phoneNumber!.isNotEmpty) ||
        (customerName != null && customerName!.isNotEmpty) ||
        fromDate != null ||
        toDate != null;
  }

  BroadcastFilters copyWith({
    bool? onlySuccessful,
    bool? onlyFailed,
    String? phoneNumber,
    String? customerName,
    DateTime? fromDate,
    DateTime? toDate,
    int? limit,
    int? offset,
  }) {
    return BroadcastFilters(
      onlySuccessful: onlySuccessful ?? this.onlySuccessful,
      onlyFailed: onlyFailed ?? this.onlyFailed,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      customerName: customerName ?? this.customerName,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }
}

// =============================================
// ✅ EXTENSIONS
// =============================================

/// ملحقات لقائمة النتائج
extension BroadcastResultListExtension on List<BroadcastResult> {
  /// إجمالي الرسائل الناجحة
  int get totalSuccess => fold(0, (sum, r) => sum + r.success);

  /// إجمالي الرسائل الفاشلة
  int get totalFailed => fold(0, (sum, r) => sum + r.failed);

  /// إجمالي الرسائل
  int get totalSent => fold(0, (sum, r) => sum + r.total);

  /// متوسط نسبة النجاح
  double get averageSuccessRate {
    if (isEmpty) return 0;
    return fold(0.0, (sum, r) => sum + r.successRate) / length;
  }

  /// الحصول على جميع المستلمين
  List<BroadcastRecipient> getAllRecipients() {
    final List<BroadcastRecipient> allRecipients = [];
    for (var result in this) {
      allRecipients.addAll(result.results);
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

  /// إنشاء إحصائيات
  BroadcastStatistics get statistics {
    return BroadcastStatistics.fromResults(this);
  }
}
