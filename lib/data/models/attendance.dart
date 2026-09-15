// lib/data/models/attendance.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ==================== HELPER: PARSE WORK DURATION ====================
/// ✅ Safe parser for work_duration
/// Handles: int, double, String (numeric string), null
/// Note: DB stores work_duration as INTEGER (seconds)
int _parseWorkDurationToSeconds(dynamic value) {
  if (value == null) return 0;

  // If it's already a number (int/double)
  if (value is num) {
    return value.toInt();
  }

  // If it's a String (numeric only — DB stores integer)
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 0;
    return int.tryParse(trimmed) ?? 0;
  }

  return 0;
}

/// ✅ Safe parser for Duration (handles int, double, String, null)
Duration? _parseWorkDuration(dynamic value) {
  if (value == null) return null;
  final seconds = _parseWorkDurationToSeconds(value);
  return seconds > 0 ? Duration(seconds: seconds) : null;
}

/// ✅ Format Duration as "HH:MM" for UI display
String _formatDurationForDisplay(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  return '${hours.toString().padLeft(2, '0')}:'
      '${minutes.toString().padLeft(2, '0')}';
}

// ==================== ATTENDANCE STATUS ENUM ====================
enum AttendanceStatus {
  present('حاضر', 'Present', Colors.green, Icons.check_circle),
  late('متأخر', 'Late', Colors.orange, Icons.warning),
  absent('غائب', 'Absent', Colors.red, Icons.cancel),
  onLeave('في إجازة', 'On Leave', Colors.blue, Icons.beach_access),
  earlyLeave('منصرف مبكراً', 'Early Leave', Colors.purple, Icons.logout);

  final String arabic;
  final String english;
  final Color color;
  final IconData icon;

  const AttendanceStatus(this.arabic, this.english, this.color, this.icon);

  static AttendanceStatus fromString(String value) {
    return AttendanceStatus.values.firstWhere(
      (e) =>
          e.english.toLowerCase() == value.toLowerCase() || e.arabic == value,
      orElse: () => AttendanceStatus.present,
    );
  }

  String get label => arabic;
  String get code => english;
}

// ==================== ATTENDANCE MODEL ====================
class Attendance {
  final String? id;
  final String employeeId;
  final String? deviceId; // ⚠️ nullable in DB
  final DateTime checkIn;
  final DateTime? checkOut;
  final double checkInLat;
  final double checkInLng;
  final double? checkOutLat;
  final double? checkOutLng;
  final AttendanceStatus status;
  final Duration? workDuration;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Related data (from joins)
  final String? employeeName;
  final String? employeeEmail;
  final String? employeeAvatar;

  Attendance({
    this.id,
    required this.employeeId,
    this.deviceId,
    required this.checkIn,
    this.checkOut,
    required this.checkInLat,
    required this.checkInLng,
    this.checkOutLat,
    this.checkOutLng,
    this.status = AttendanceStatus.present,
    this.workDuration,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.employeeName,
    this.employeeEmail,
    this.employeeAvatar,
  });

  // ==================== FROM JSON ====================
  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'] as String?,
      employeeId: (json['employee_id'] as String?) ?? '',
      deviceId: json['device_id'] as String?,

      // Dates
      checkIn: _parseDateTime(json['check_in']) ?? DateTime.now(),
      checkOut: _parseDateTime(json['check_out']),
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),

      // Location
      checkInLat: _parseDouble(json['check_in_lat']),
      checkInLng: _parseDouble(json['check_in_lng']),
      checkOutLat: _parseNullableDouble(json['check_out_lat']),
      checkOutLng: _parseNullableDouble(json['check_out_lng']),

      // Status & duration
      status: AttendanceStatus.fromString(
        (json['status'] as String?) ?? 'present',
      ),
      workDuration: _parseWorkDuration(json['work_duration']),
      notes: json['notes'] as String?,

      // Joined data
      employeeName: json['employee_name'] as String?,
      employeeEmail: json['employee_email'] as String?,
      employeeAvatar: json['employee_avatar'] as String?,
    );
  }

  // ==================== TO JSON ====================
  /// ✅ For inserting/updating in Supabase
  /// Note: `work_duration` is stored as INTEGER (seconds) in DB
  Map<String, dynamic> toJson() {
    return {
      'employee_id': employeeId,
      'device_id': deviceId,
      'check_in': checkIn.toUtc().toIso8601String(),
      'check_out': checkOut?.toUtc().toIso8601String(),
      'check_in_lat': checkInLat,
      'check_in_lng': checkInLng,
      'check_out_lat': checkOutLat,
      'check_out_lng': checkOutLng,
      'status': status.english.toLowerCase(),
      // ✅ Convert Duration → integer (seconds)
      'work_duration': workDuration?.inSeconds,
      'notes': notes,
    };
  }

  // ==================== COPY WITH ====================
  Attendance copyWith({
    String? id,
    String? employeeId,
    String? deviceId,
    DateTime? checkIn,
    DateTime? checkOut,
    double? checkInLat,
    double? checkInLng,
    double? checkOutLat,
    double? checkOutLng,
    AttendanceStatus? status,
    Duration? workDuration,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? employeeName,
    String? employeeEmail,
    String? employeeAvatar,
    bool clearCheckOut = false,
    bool clearWorkDuration = false,
  }) {
    return Attendance(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      deviceId: deviceId ?? this.deviceId,
      checkIn: checkIn ?? this.checkIn,
      checkOut: clearCheckOut ? null : (checkOut ?? this.checkOut),
      checkInLat: checkInLat ?? this.checkInLat,
      checkInLng: checkInLng ?? this.checkInLng,
      checkOutLat: clearCheckOut ? null : (checkOutLat ?? this.checkOutLat),
      checkOutLng: clearCheckOut ? null : (checkOutLng ?? this.checkOutLng),
      status: status ?? this.status,
      workDuration: clearWorkDuration
          ? null
          : (workDuration ?? this.workDuration),
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      employeeName: employeeName ?? this.employeeName,
      employeeEmail: employeeEmail ?? this.employeeEmail,
      employeeAvatar: employeeAvatar ?? this.employeeAvatar,
    );
  }

  // ==================== GETTERS ====================

  /// حساب مدة العمل تلقائياً (إذا لم تكن مخزنة)
  Duration? get duration {
    if (checkOut == null) return null;
    return checkOut!.difference(checkIn);
  }

  /// المدة الفعلية: من DB إن وُجدت، وإلا احتسبها
  Duration? get effectiveDuration {
    if (workDuration != null && workDuration!.inSeconds > 0) {
      return workDuration;
    }
    return duration;
  }

  /// هل تم الخروج؟
  bool get isCheckedOut => checkOut != null;

  /// هل تم الحضور؟
  bool get isCheckedIn => true;

  /// هل اليوم هو اليوم؟
  bool get isToday {
    final now = DateTime.now();
    final local = checkIn.toLocal();
    return local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
  }

  // ==================== FORMATTED STRINGS ====================

  String get formattedCheckIn {
    return DateFormat('hh:mm a').format(checkIn.toLocal());
  }

  String get formattedCheckOut {
    if (checkOut == null) return '--:--';
    return DateFormat('hh:mm a').format(checkOut!.toLocal());
  }

  String get formattedDate {
    return DateFormat('EEEE، d MMMM y', 'ar').format(checkIn.toLocal());
  }

  String get formattedShortDate {
    return DateFormat('d/M/y').format(checkIn.toLocal());
  }

  String get formattedCheckInFull {
    return DateFormat('hh:mm a • d/M/y').format(checkIn.toLocal());
  }

  String get formattedCheckOutFull {
    if (checkOut == null) return '--:--';
    return DateFormat('hh:mm a • d/M/y').format(checkOut!.toLocal());
  }

  /// ✅ Formatted duration "HH:MM"
  String get formattedDuration {
    final dur = effectiveDuration;
    if (dur == null) return '--:--';
    return _formatDurationForDisplay(dur);
  }

  /// ✅ Formatted duration with seconds "HH:MM:SS"
  String get formattedDurationFull {
    final dur = effectiveDuration;
    if (dur == null) return '--:--:--';
    final hours = dur.inHours;
    final minutes = dur.inMinutes.remainder(60);
    final seconds = dur.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  /// ✅ Duration in hours as double (for stats)
  double get durationInHours {
    final dur = effectiveDuration;
    if (dur == null) return 0;
    return dur.inSeconds / 3600;
  }

  // ==================== LOCATION ====================

  String get locationDisplay {
    return '(${checkInLat.toStringAsFixed(6)}, ${checkInLng.toStringAsFixed(6)})';
  }

  String get checkOutLocationDisplay {
    if (checkOutLat == null || checkOutLng == null) return '--';
    return '(${checkOutLat!.toStringAsFixed(6)}, ${checkOutLng!.toStringAsFixed(6)})';
  }

  // ==================== VALIDATION ====================

  bool get isValid {
    return employeeId.isNotEmpty && checkInLat != 0 && checkInLng != 0;
  }

  bool get hasValidCheckoutLocation {
    return checkOutLat != null &&
        checkOutLng != null &&
        checkOutLat != 0 &&
        checkOutLng != 0;
  }

  // ==================== OVERRIDES ====================

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Attendance && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Attendance(id: $id, employee: $employeeId, '
        'checkIn: $formattedCheckIn, status: ${status.arabic})';
  }
}

// ==================== ATTENDANCE SUMMARY ====================
class AttendanceSummary {
  final DateTime date;
  final int present;
  final int absent;
  final int late;
  final int onLeave;
  final int totalEmployees;

  AttendanceSummary({
    required this.date,
    required this.present,
    required this.absent,
    required this.late,
    required this.onLeave,
    required this.totalEmployees,
  });

  double get attendancePercentage {
    if (totalEmployees == 0) return 0;
    final attended = present + late;
    return (attended / totalEmployees) * 100;
  }

  String get formattedPercentage {
    return '${attendancePercentage.toStringAsFixed(1)}%';
  }

  int get totalAttended => present + late;

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceSummary(
      date: _parseDateTime(json['date']) ?? DateTime.now(),
      present: (json['present'] as num?)?.toInt() ?? 0,
      absent: (json['absent'] as num?)?.toInt() ?? 0,
      late: (json['late'] as num?)?.toInt() ?? 0,
      onLeave: (json['on_leave'] as num?)?.toInt() ?? 0,
      totalEmployees: (json['total_employees'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'present': present,
      'absent': absent,
      'late': late,
      'on_leave': onLeave,
      'total_employees': totalEmployees,
    };
  }

  AttendanceSummary copyWith({
    DateTime? date,
    int? present,
    int? absent,
    int? late,
    int? onLeave,
    int? totalEmployees,
  }) {
    return AttendanceSummary(
      date: date ?? this.date,
      present: present ?? this.present,
      absent: absent ?? this.absent,
      late: late ?? this.late,
      onLeave: onLeave ?? this.onLeave,
      totalEmployees: totalEmployees ?? this.totalEmployees,
    );
  }
}

// ==================== EMPLOYEE DEVICE MODEL ====================
class EmployeeDevice {
  final String? id;
  final String employeeId;
  final String deviceId;
  final String? deviceName;
  final String? deviceModel;
  final double latitude;
  final double longitude;
  final String? locationName;
  final bool isActive;
  final DateTime? registeredAt;
  final DateTime? updatedAt;
  final DateTime? createdAt;

  EmployeeDevice({
    this.id,
    required this.employeeId,
    required this.deviceId,
    this.deviceName,
    this.deviceModel,
    required this.latitude,
    required this.longitude,
    this.locationName,
    this.isActive = true,
    this.registeredAt,
    this.updatedAt,
    this.createdAt,
  });

  // ==================== FROM JSON ====================
  factory EmployeeDevice.fromJson(Map<String, dynamic> json) {
    return EmployeeDevice(
      id: json['id'] as String?,
      employeeId: (json['employee_id'] as String?) ?? '',
      deviceId: (json['device_id'] as String?) ?? '',
      deviceName: json['device_name'] as String?,
      deviceModel: json['device_model'] as String?,
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      locationName: json['location_name'] as String?,
      isActive: (json['is_active'] as bool?) ?? true,
      registeredAt: _parseDateTime(json['registered_at']),
      updatedAt: _parseDateTime(json['updated_at']),
      createdAt: _parseDateTime(json['created_at']),
    );
  }

  // ==================== TO JSON ====================
  Map<String, dynamic> toJson() {
    return {
      'employee_id': employeeId,
      'device_id': deviceId,
      'device_name': deviceName,
      'device_model': deviceModel,
      'latitude': latitude,
      'longitude': longitude,
      'location_name': locationName,
      'is_active': isActive,
    };
  }

  // ==================== COPY WITH ====================
  EmployeeDevice copyWith({
    String? id,
    String? employeeId,
    String? deviceId,
    String? deviceName,
    String? deviceModel,
    double? latitude,
    double? longitude,
    String? locationName,
    bool? isActive,
    DateTime? registeredAt,
    DateTime? updatedAt,
    DateTime? createdAt,
  }) {
    return EmployeeDevice(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      deviceModel: deviceModel ?? this.deviceModel,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
      isActive: isActive ?? this.isActive,
      registeredAt: registeredAt ?? this.registeredAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ==================== GETTERS ====================

  String get locationDisplay {
    return '(${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)})';
  }

  bool get isRegistered => id != null && id!.isNotEmpty;

  bool get hasLocation => latitude != 0 && longitude != 0;

  String get displayName {
    if (deviceName != null && deviceName!.isNotEmpty) {
      return deviceName!;
    }
    return deviceId;
  }

  String get formattedRegisteredAt {
    if (registeredAt == null) return '--';
    return DateFormat('d/M/y hh:mm a').format(registeredAt!.toLocal());
  }

  // ==================== VALIDATION ====================

  bool get isValid {
    return employeeId.isNotEmpty &&
        deviceId.isNotEmpty &&
        latitude != 0 &&
        longitude != 0;
  }

  @override
  String toString() {
    return 'EmployeeDevice(employee: $employeeId, device: $deviceId, '
        'location: $locationDisplay)';
  }
}

// ==================== ATTENDANCE STATS ====================
class AttendanceStats {
  final int totalDays;
  final int presentDays;
  final int lateDays;
  final int leaveDays;
  final int absentDays;
  final double totalWorkHours;
  final double attendanceRate;

  AttendanceStats({
    required this.totalDays,
    required this.presentDays,
    required this.lateDays,
    required this.leaveDays,
    required this.absentDays,
    required this.totalWorkHours,
    required this.attendanceRate,
  });

  factory AttendanceStats.fromJson(Map<String, dynamic> json) {
    return AttendanceStats(
      totalDays: (json['totalDays'] as num?)?.toInt() ?? 0,
      presentDays: (json['presentDays'] as num?)?.toInt() ?? 0,
      lateDays: (json['lateDays'] as num?)?.toInt() ?? 0,
      leaveDays: (json['leaveDays'] as num?)?.toInt() ?? 0,
      absentDays: (json['absentDays'] as num?)?.toInt() ?? 0,
      totalWorkHours: _parseDouble(json['totalWorkHours']),
      attendanceRate: _parseDouble(json['attendanceRate']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalDays': totalDays,
      'presentDays': presentDays,
      'lateDays': lateDays,
      'leaveDays': leaveDays,
      'absentDays': absentDays,
      'totalWorkHours': totalWorkHours,
      'attendanceRate': attendanceRate,
    };
  }

  String get formattedAttendanceRate => '${attendanceRate.toStringAsFixed(1)}%';
  String get formattedWorkHours => totalWorkHours.toStringAsFixed(1);

  /// Empty stats
  static AttendanceStats empty() {
    return AttendanceStats(
      totalDays: 0,
      presentDays: 0,
      lateDays: 0,
      leaveDays: 0,
      absentDays: 0,
      totalWorkHours: 0,
      attendanceRate: 0,
    );
  }
}

// ==================== MONTHLY SUMMARY ====================
class MonthlySummary {
  final int year;
  final int month;
  final int present;
  final int absent;
  final int late;
  final int onLeave;
  final int totalWorkingDays;
  final double totalWorkHours;
  final double attendanceRate;

  MonthlySummary({
    required this.year,
    required this.month,
    required this.present,
    required this.absent,
    required this.late,
    required this.onLeave,
    required this.totalWorkingDays,
    required this.totalWorkHours,
    required this.attendanceRate,
  });

  factory MonthlySummary.fromJson(Map<String, dynamic> json) {
    return MonthlySummary(
      year: (json['year'] as num?)?.toInt() ?? DateTime.now().year,
      month: (json['month'] as num?)?.toInt() ?? DateTime.now().month,
      present: (json['present'] as num?)?.toInt() ?? 0,
      absent: (json['absent'] as num?)?.toInt() ?? 0,
      late: (json['late'] as num?)?.toInt() ?? 0,
      onLeave: (json['onLeave'] as num?)?.toInt() ?? 0,
      totalWorkingDays: (json['totalWorkingDays'] as num?)?.toInt() ?? 0,
      totalWorkHours: _parseDouble(json['totalWorkHours']),
      attendanceRate: _parseDouble(json['attendanceRate']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'month': month,
      'present': present,
      'absent': absent,
      'late': late,
      'onLeave': onLeave,
      'totalWorkingDays': totalWorkingDays,
      'totalWorkHours': totalWorkHours,
      'attendanceRate': attendanceRate,
    };
  }

  String get formattedAttendanceRate => '${attendanceRate.toStringAsFixed(1)}%';
  String get formattedWorkHours => totalWorkHours.toStringAsFixed(1);
  String get monthName =>
      DateFormat('MMMM', 'ar').format(DateTime(year, month));
  String get yearMonth => '$monthName $year';

  /// Empty summary
  static MonthlySummary empty({int? year, int? month}) {
    final now = DateTime.now();
    return MonthlySummary(
      year: year ?? now.year,
      month: month ?? now.month,
      present: 0,
      absent: 0,
      late: 0,
      onLeave: 0,
      totalWorkingDays: 0,
      totalWorkHours: 0,
      attendanceRate: 0,
    );
  }
}

// ==================== PRIVATE PARSING HELPERS ====================

/// ✅ Safe DateTime parser
DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;

  if (value is DateTime) return value;

  if (value is String) {
    if (value.isEmpty) return null;
    try {
      return DateTime.parse(value);
    } catch (e) {
      debugPrint('⚠️ Failed to parse DateTime: $value - $e');
      return null;
    }
  }

  return null;
}

/// ✅ Safe double parser (returns 0.0 for null/invalid)
double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) {
    return double.tryParse(value) ?? 0.0;
  }
  return 0.0;
}

/// ✅ Safe nullable double parser
double? _parseNullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) {
    if (value.isEmpty) return null;
    return double.tryParse(value);
  }
  return null;
}
