// lib/data/repositories/attendance_repository.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/attendance.dart';

class AttendanceRepository {
  static final AttendanceRepository _instance =
      AttendanceRepository._internal();
  factory AttendanceRepository() => _instance;
  AttendanceRepository._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // ==================== HELPER: PARSE WORK DURATION ====================
  /// ✅ Safe parser for work_duration (DB stores as INTEGER seconds)
  int _parseWorkDurationToSeconds(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    return 0;
  }

  // ==================== REGISTER DEVICE ====================
  Future<EmployeeDevice> registerDevice({
    required String employeeId,
    required String deviceId,
    required double latitude,
    required double longitude,
    String? deviceName,
    String? deviceModel,
    String? locationName,
  }) async {
    try {
      debugPrint('📝 Registering device for employee: $employeeId');

      // ✅ التحقق من وجود المستخدم
      final userExists = await _supabase
          .from('users')
          .select('id, email, name, role')
          .eq('id', employeeId)
          .maybeSingle();

      debugPrint('🔍 User exists check: $userExists');

      if (userExists == null) {
        debugPrint('⚠️ User not found, attempting to create...');

        final user = Supabase.instance.client.auth.currentUser;
        if (user != null && user.id == employeeId) {
          final userName = user.email?.split('@').first ?? 'موظف';

          await _supabase.from('users').insert({
            'id': employeeId,
            'email': user.email,
            'name': userName,
            'role': 'employee',
            'is_active': true,
          });

          debugPrint('✅ User created automatically: $employeeId');
        } else {
          throw Exception('المستخدم غير موجود في قاعدة البيانات');
        }
      }

      // ✅ التحقق من أن الجهاز غير مسجل بالفعل
      final existingDevice = await _supabase
          .from('employee_devices')
          .select('id')
          .eq('employee_id', employeeId)
          .eq('device_id', deviceId)
          .maybeSingle();

      if (existingDevice != null) {
        debugPrint('⚠️ Device already registered, updating instead...');

        final updateData = {
          'device_name': deviceName ?? 'Unknown Device',
          'device_model': deviceModel ?? 'Unknown Model',
          'latitude': latitude,
          'longitude': longitude,
          'location_name': locationName,
          'is_active': true,
        };

        final updated = await _supabase
            .from('employee_devices')
            .update(updateData)
            .eq('id', existingDevice['id'])
            .select()
            .maybeSingle();

        if (updated == null) {
          throw Exception('فشل تحديث الجهاز');
        }

        return EmployeeDevice.fromJson(updated);
      }

      // ✅ تسجيل جهاز جديد
      final now = DateTime.now().toIso8601String();

      final data = {
        'employee_id': employeeId,
        'device_id': deviceId,
        'device_name': deviceName ?? 'Unknown Device',
        'device_model': deviceModel ?? 'Unknown Model',
        'latitude': latitude,
        'longitude': longitude,
        'location_name': locationName,
        'is_active': true,
        'registered_at': now,
      };

      debugPrint('📤 Inserting device data: $data');

      final response = await _supabase
          .from('employee_devices')
          .insert(data)
          .select()
          .maybeSingle();

      if (response == null) {
        throw Exception('فشل تسجيل الجهاز');
      }

      debugPrint('✅ Device registered successfully: ${response['id']}');
      return EmployeeDevice.fromJson(response);
    } catch (e) {
      debugPrint('❌ Error registering device: $e');
      throw Exception('Failed to register device: $e');
    }
  }

  // ==================== GET DEVICE ====================
  Future<EmployeeDevice?> getDevice(String employeeId, String deviceId) async {
    try {
      final response = await _supabase
          .from('employee_devices')
          .select()
          .eq('employee_id', employeeId)
          .eq('device_id', deviceId)
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) return null;
      return EmployeeDevice.fromJson(response);
    } catch (e) {
      debugPrint('❌ Error getting device: $e');
      return null;
    }
  }

  // ==================== GET DEVICE BY ID ====================
  Future<EmployeeDevice?> getDeviceById(String deviceId) async {
    try {
      final response = await _supabase
          .from('employee_devices')
          .select()
          .eq('id', deviceId)
          .maybeSingle();

      if (response == null) return null;
      return EmployeeDevice.fromJson(response);
    } catch (e) {
      debugPrint('❌ Error getting device by id: $e');
      return null;
    }
  }

  // ==================== CHECK TODAY ATTENDANCE ====================
  Future<Attendance?> getTodayAttendance(String employeeId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

      final response = await _supabase
          .from('attendance')
          .select()
          .eq('employee_id', employeeId)
          .gte('check_in', startOfDay.toIso8601String())
          .lte('check_in', endOfDay.toIso8601String())
          .order('check_in', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return Attendance.fromJson(response);
    } catch (e) {
      debugPrint('❌ Error getting today attendance: $e');
      return null;
    }
  }

  // ==================== CHECK IN ====================
  Future<Attendance> checkIn({
    required String employeeId,
    required String deviceId,
    required double latitude,
    required double longitude,
    String? notes,
  }) async {
    try {
      final now = DateTime.now().toUtc();

      // Check if already checked in today
      final existing = await getTodayAttendance(employeeId);
      if (existing != null) {
        throw Exception(
          '❌ You already checked in today at ${existing.formattedCheckIn}',
        );
      }

      final data = {
        'employee_id': employeeId,
        'device_id': deviceId,
        'check_in': now.toIso8601String(),
        'check_in_lat': latitude,
        'check_in_lng': longitude,
        'status': 'present',
        'notes': notes,
        // ✅ work_duration is NOT set here (will be set on check-out)
      };

      final response = await _supabase
          .from('attendance')
          .insert(data)
          .select()
          .maybeSingle();

      if (response == null) {
        throw Exception('فشل تسجيل الحضور');
      }

      return Attendance.fromJson(response);
    } catch (e) {
      debugPrint('❌ Error checking in: $e');
      rethrow;
    }
  }

  // ==================== CHECK OUT ====================
  Future<Attendance> checkOut({
    required String attendanceId,
    required double latitude,
    required double longitude,
    String? notes,
  }) async {
    try {
      final now = DateTime.now().toUtc();

      // Get current attendance
      final current = await _supabase
          .from('attendance')
          .select()
          .eq('id', attendanceId)
          .maybeSingle();

      if (current == null) {
        throw Exception('سجل الحضور غير موجود');
      }

      final checkInTime = DateTime.parse(current['check_in']);
      final duration = now.difference(checkInTime);

      final data = {
        'check_out': now.toIso8601String(),
        'check_out_lat': latitude,
        'check_out_lng': longitude,
        'work_duration': duration.inSeconds, // ✅ Store as integer (seconds)
        'notes': notes,
      };

      final response = await _supabase
          .from('attendance')
          .update(data)
          .eq('id', attendanceId)
          .select()
          .maybeSingle();

      if (response == null) {
        throw Exception('فشل تسجيل الانصراف');
      }

      return Attendance.fromJson(response);
    } catch (e) {
      debugPrint('❌ Error checking out: $e');
      rethrow;
    }
  }

  // ==================== GET ATTENDANCE HISTORY ====================
  Future<List<Attendance>> getAttendanceHistory({
    required String employeeId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 30,
  }) async {
    try {
      var query = _supabase
          .from('attendance')
          .select()
          .eq('employee_id', employeeId)
          .order('check_in', ascending: false)
          .limit(limit);

      if (startDate != null) {
        query = _supabase
            .from('attendance')
            .select()
            .eq('employee_id', employeeId)
            .gte('check_in', startDate.toIso8601String())
            .order('check_in', ascending: false)
            .limit(limit);
      }

      if (endDate != null) {
        final endOfDay = DateTime(
          endDate.year,
          endDate.month,
          endDate.day,
          23,
          59,
          59,
        );
        query = _supabase
            .from('attendance')
            .select()
            .eq('employee_id', employeeId)
            .lte('check_in', endOfDay.toIso8601String())
            .order('check_in', ascending: false)
            .limit(limit);
      }

      if (startDate != null && endDate != null) {
        final endOfDay = DateTime(
          endDate.year,
          endDate.month,
          endDate.day,
          23,
          59,
          59,
        );
        query = _supabase
            .from('attendance')
            .select()
            .eq('employee_id', employeeId)
            .gte('check_in', startDate.toIso8601String())
            .lte('check_in', endOfDay.toIso8601String())
            .order('check_in', ascending: false)
            .limit(limit);
      }

      final response = await query;

      return response
          .map<Attendance>((item) => Attendance.fromJson(item))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting attendance history: $e');
      return [];
    }
  }

  // ==================== GET ATTENDANCE BY DATE ====================
  Future<List<Attendance>> getAttendanceByDate({
    required DateTime date,
    String? employeeId,
  }) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      var query = _supabase
          .from('attendance')
          .select()
          .gte('check_in', startOfDay.toIso8601String())
          .lte('check_in', endOfDay.toIso8601String())
          .order('check_in', ascending: true);

      if (employeeId != null) {
        query = _supabase
            .from('attendance')
            .select()
            .eq('employee_id', employeeId)
            .gte('check_in', startOfDay.toIso8601String())
            .lte('check_in', endOfDay.toIso8601String())
            .order('check_in', ascending: true);
      }

      final response = await query;

      return response
          .map<Attendance>((item) => Attendance.fromJson(item))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting attendance by date: $e');
      return [];
    }
  }

  // ==================== GET ATTENDANCE SUMMARY ====================
  Future<AttendanceSummary> getAttendanceSummary({
    required DateTime date,
  }) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      // Get all employees
      final employees = await _supabase
          .from('users')
          .select('id')
          .eq('is_active', true)
          .eq('role', 'employee');

      final totalEmployees = employees.length;

      // Get attendance for the day
      final attendance = await _supabase
          .from('attendance')
          .select('status, employee_id')
          .gte('check_in', startOfDay.toIso8601String())
          .lte('check_in', endOfDay.toIso8601String());

      int present = 0;
      int late = 0;
      int onLeave = 0;

      // Track which employees attended
      final attendedIds = <String>{};

      for (var item in attendance) {
        final status = item['status'] ?? 'present';
        final employeeId = item['employee_id'] as String?;

        if (employeeId != null) {
          attendedIds.add(employeeId);
        }

        switch (status) {
          case 'present':
            present++;
            break;
          case 'late':
            late++;
            break;
          case 'on_leave':
            onLeave++;
            break;
        }
      }

      // Calculate absent (employees with no attendance)
      final absent = totalEmployees - attendedIds.length;

      return AttendanceSummary(
        date: date,
        present: present,
        absent: absent < 0 ? 0 : absent,
        late: late,
        onLeave: onLeave,
        totalEmployees: totalEmployees,
      );
    } catch (e) {
      debugPrint('❌ Error getting attendance summary: $e');
      return AttendanceSummary(
        date: date,
        present: 0,
        absent: 0,
        late: 0,
        onLeave: 0,
        totalEmployees: 0,
      );
    }
  }

  // ==================== GET MONTHLY SUMMARY ====================
  Future<Map<String, dynamic>> getMonthlySummary({
    required String employeeId,
    required int year,
    required int month,
  }) async {
    try {
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

      final response = await _supabase
          .from('attendance')
          .select()
          .eq('employee_id', employeeId)
          .gte('check_in', startDate.toIso8601String())
          .lte('check_in', endDate.toIso8601String());

      int present = 0;
      int late = 0;
      int onLeave = 0;
      int totalWorkSeconds = 0;

      for (var item in response) {
        final status = item['status'] ?? 'present';
        switch (status) {
          case 'present':
            present++;
            break;
          case 'late':
            late++;
            break;
          case 'on_leave':
            onLeave++;
            break;
        }

        // ✅ Safe parsing for work_duration (integer seconds)
        totalWorkSeconds += _parseWorkDurationToSeconds(item['work_duration']);
      }

      // Get total working days in month
      final workingDays = endDate.day;
      final absentCount = workingDays - (present + late + onLeave);

      return {
        'present': present,
        'absent': absentCount < 0 ? 0 : absentCount,
        'late': late,
        'onLeave': onLeave,
        'totalWorkingDays': workingDays,
        'totalWorkHours': (totalWorkSeconds / 3600).toStringAsFixed(1),
        'attendanceRate': workingDays > 0
            ? ((present / workingDays) * 100).toStringAsFixed(1)
            : '0',
      };
    } catch (e) {
      debugPrint('❌ Error getting monthly summary: $e');
      return {
        'present': 0,
        'absent': 0,
        'late': 0,
        'onLeave': 0,
        'totalWorkingDays': 0,
        'totalWorkHours': '0',
        'attendanceRate': '0',
      };
    }
  }

  // ==================== GET ALL EMPLOYEES ====================
  Future<List<Map<String, dynamic>>> getEmployees() async {
    try {
      final response = await _supabase
          .from('users')
          .select('id, name, email, avatar_url, phone, is_active')
          .eq('role', 'employee')
          .eq('is_active', true)
          .order('name');

      debugPrint('✅ Employees fetched: ${response.length}');
      return response;
    } catch (e) {
      debugPrint('❌ Error getting employees: $e');
      return [];
    }
  }

  // ==================== GET EMPLOYEE DEVICES ====================
  Future<List<EmployeeDevice>> getEmployeeDevices(String employeeId) async {
    try {
      final response = await _supabase
          .from('employee_devices')
          .select()
          .eq('employee_id', employeeId)
          .order('registered_at', ascending: false);

      return response
          .map<EmployeeDevice>((item) => EmployeeDevice.fromJson(item))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting employee devices: $e');
      return [];
    }
  }

  // ==================== DEACTIVATE DEVICE ====================
  Future<void> deactivateDevice(String deviceId) async {
    try {
      await _supabase
          .from('employee_devices')
          .update({'is_active': false})
          .eq('id', deviceId);
      debugPrint('✅ Device deactivated: $deviceId');
    } catch (e) {
      debugPrint('❌ Error deactivating device: $e');
      throw Exception('Failed to deactivate device: $e');
    }
  }

  // ==================== REACTIVATE DEVICE ====================
  Future<void> reactivateDevice(String deviceId) async {
    try {
      await _supabase
          .from('employee_devices')
          .update({'is_active': true})
          .eq('id', deviceId);
      debugPrint('✅ Device reactivated: $deviceId');
    } catch (e) {
      debugPrint('❌ Error reactivating device: $e');
      throw Exception('Failed to reactivate device: $e');
    }
  }

  // ==================== DELETE ATTENDANCE RECORD ====================
  Future<void> deleteAttendanceRecord(String attendanceId) async {
    try {
      await _supabase.from('attendance').delete().eq('id', attendanceId);
      debugPrint('✅ Attendance record deleted: $attendanceId');
    } catch (e) {
      debugPrint('❌ Error deleting attendance record: $e');
      throw Exception('Failed to delete attendance record: $e');
    }
  }

  // ==================== UPDATE ATTENDANCE STATUS ====================
  Future<void> updateAttendanceStatus({
    required String attendanceId,
    required String status,
  }) async {
    try {
      await _supabase
          .from('attendance')
          .update({'status': status})
          .eq('id', attendanceId);
      debugPrint('✅ Attendance status updated: $attendanceId -> $status');
    } catch (e) {
      debugPrint('❌ Error updating attendance status: $e');
      throw Exception('Failed to update attendance status: $e');
    }
  }

  // ==================== GET EMPLOYEE STATS ====================
  Future<Map<String, dynamic>> getEmployeeStats(String employeeId) async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      final response = await _supabase
          .from('attendance')
          .select()
          .eq('employee_id', employeeId)
          .gte('check_in', startOfMonth.toIso8601String())
          .lte('check_in', endOfMonth.toIso8601String());

      int totalDays = 0;
      int presentDays = 0;
      int lateDays = 0;
      int leaveDays = 0;
      int totalWorkSeconds = 0;

      for (var item in response) {
        totalDays++;
        final status = item['status'] ?? 'present';
        switch (status) {
          case 'present':
            presentDays++;
            break;
          case 'late':
            lateDays++;
            break;
          case 'on_leave':
            leaveDays++;
            break;
        }

        // ✅ Safe parsing for work_duration
        totalWorkSeconds += _parseWorkDurationToSeconds(item['work_duration']);
      }

      return {
        'totalDays': totalDays,
        'presentDays': presentDays,
        'lateDays': lateDays,
        'leaveDays': leaveDays,
        'absentDays': totalDays - (presentDays + lateDays + leaveDays),
        'totalWorkHours': (totalWorkSeconds / 3600).toStringAsFixed(1),
        'attendanceRate': totalDays > 0
            ? ((presentDays / totalDays) * 100).toStringAsFixed(1)
            : '0',
      };
    } catch (e) {
      debugPrint('❌ Error getting employee stats: $e');
      return {
        'totalDays': 0,
        'presentDays': 0,
        'lateDays': 0,
        'leaveDays': 0,
        'absentDays': 0,
        'totalWorkHours': '0',
        'attendanceRate': '0',
      };
    }
  }

  // ==================== CHECK LOCATION MATCH ====================
  bool isLocationMatch(
    double currentLat,
    double currentLng,
    double savedLat,
    double savedLng, {
    double toleranceMeters = 50.0,
  }) {
    final distance = _calculateDistance(
      currentLat,
      currentLng,
      savedLat,
      savedLng,
    );
    return distance <= toleranceMeters;
  }

  // ==================== CALCULATE DISTANCE (Haversine formula) ====================
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371000; // Earth's radius in meters
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a =
        _sin(dLat / 2) * _sin(dLat / 2) +
        _cos(_toRadians(lat1)) *
            _cos(_toRadians(lat2)) *
            _sin(dLon / 2) *
            _sin(dLon / 2);
    final c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));
    return R * c;
  }

  // ==================== PUBLIC DISTANCE HELPER ====================
  /// حساب المسافة بين نقطتين (public wrapper)
  double distanceBetween(double lat1, double lon1, double lat2, double lon2) {
    return _calculateDistance(lat1, lon1, lat2, lon2);
  }

  // ==================== MATH HELPERS ====================
  double _toRadians(double degrees) => degrees * 3.141592653589793 / 180;

  double _sin(double x) => x - x * x * x / 6 + x * x * x * x * x / 120;

  double _cos(double x) => 1 - x * x / 2 + x * x * x * x / 24;

  double _sqrt(double x) {
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 10; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  double _atan2(double y, double x) {
    if (x == 0) return y > 0 ? 3.141592653589793 / 2 : -3.141592653589793 / 2;
    final ratio = y / x;
    return ratio -
        ratio * ratio * ratio / 3 +
        ratio * ratio * ratio * ratio * ratio / 5;
  }
}
