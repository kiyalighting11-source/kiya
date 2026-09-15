// lib/presentation/screens/attendance/attendance_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import '../../../data/models/attendance.dart';
import '../../../data/models/company_location.dart';
import '../../../data/repositories/attendance_repository.dart';
import '../../../data/repositories/company_location_repository.dart';
import '../../../data/services/device_service.dart';
import '../../../data/services/location_service.dart';
import 'attendance_history.dart';
import 'admin_attendance.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    with SingleTickerProviderStateMixin {
  // =============================================
  // ✅ REPOSITORIES & SERVICES
  // =============================================
  final AttendanceRepository _attendanceRepo = AttendanceRepository();
  final CompanyLocationRepository _companyLocationRepo =
      CompanyLocationRepository();
  final DeviceService _deviceService = DeviceService();
  final LocationService _locationService = LocationService();

  // =============================================
  // ✅ STATE
  // =============================================
  bool _isLoading = true;
  bool _isCheckingIn = false;
  bool _isCheckingOut = false;
  bool _isCheckingRegistration = false;
  bool _isRefreshingLocation = false;
  String? _errorMessage;
  String? _userId;
  String? _userName;
  String? _userRole;
  Attendance? _todayAttendance;
  EmployeeDevice? _deviceInfo;
  CompanyLocation? _companyLocation;
  List<Attendance> _recentHistory = [];

  // ✅ حالة الموقع الحالي
  double? _currentDistance;
  double? _currentAccuracy;
  bool _isWithinRange = false;

  // ✅ Animation controller
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _checkDeviceAndLoad();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // =============================================
  // ✅ MAIN FUNCTION
  // =============================================
  Future<void> _checkDeviceAndLoad() async {
    setState(() {
      _isLoading = true;
      _isCheckingRegistration = true;
      _errorMessage = null;
    });

    try {
      // 1. Check login
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('يرجى تسجيل الدخول أولاً');
      }

      _userId = user.id;
      final userEmail = user.email ?? '';
      debugPrint('✅ User: $_userId ($userEmail)');

      // 2. Ensure user exists
      await _ensureUserExists(userEmail);

      // 3. Load company location
      debugPrint('🏢 Loading company location...');
      _companyLocation = await _companyLocationRepo.getDefaultLocation();

      if (_companyLocation == null) {
        debugPrint('❌ No company location found!');
        setState(() {
          _isLoading = false;
          _isCheckingRegistration = false;
          _errorMessage =
              '📍 لا يوجد موقع مسجل للشركة\n\n'
              'يرجى التواصل مع المدير لإضافة موقع العمل.';
        });
        return;
      }

      debugPrint(
        '✅ Company: ${_companyLocation!.name} '
        '(${_companyLocation!.latitude}, ${_companyLocation!.longitude}) '
        'R=${_companyLocation!.radiusMeters}m',
      );

      // 4. Load device info (optional)
      try {
        final deviceId = await _deviceService.getDeviceId();
        _deviceInfo = await _attendanceRepo.getDevice(_userId!, deviceId);
      } catch (e) {
        debugPrint('⚠️ Device info skipped: $e');
      }

      // 5. Load attendance data
      await _loadAttendanceData();

      // 6. ✅ احسب الموقع الحالي والمسافة
      await _updateCurrentLocation(showLoading: false);

      setState(() {
        _isLoading = false;
        _isCheckingRegistration = false;
      });
    } catch (e) {
      debugPrint('❌ Error: $e');
      setState(() {
        _isLoading = false;
        _isCheckingRegistration = false;
        _errorMessage = e.toString();
      });
    }
  }

  // =============================================
  // ✅ ENSURE USER EXISTS
  // =============================================
  Future<void> _ensureUserExists(String userEmail) async {
    try {
      var userData = await Supabase.instance.client
          .from('users')
          .select('id, name, role, email')
          .eq('id', _userId!)
          .maybeSingle();

      if (userData != null) {
        _userName = userData['name'] ?? 'موظف';
        _userRole = userData['role'] ?? 'employee';
        debugPrint('✅ User exists: $_userName ($_userRole)');
        return;
      }

      final emailUser = await Supabase.instance.client
          .from('users')
          .select('id, name, role, email')
          .eq('email', userEmail)
          .maybeSingle();

      if (emailUser != null) {
        await Supabase.instance.client
            .from('users')
            .update({
              'id': _userId!,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('email', userEmail);

        final updatedUser = await Supabase.instance.client
            .from('users')
            .select('id, name, role, email')
            .eq('id', _userId!)
            .maybeSingle();

        if (updatedUser != null) {
          _userName = updatedUser['name'] ?? 'موظف';
          _userRole = updatedUser['role'] ?? 'employee';
          return;
        }
      }

      // Create new user
      final userName = userEmail.split('@').first;
      await Supabase.instance.client.from('users').insert({
        'id': _userId!,
        'email': userEmail,
        'name': userName,
        'role': 'employee',
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      _userName = userName;
      _userRole = 'employee';
    } catch (e) {
      debugPrint('❌ Error in _ensureUserExists: $e');
      try {
        final userName = userEmail.split('@').first;
        await Supabase.instance.client.from('users').upsert({
          'id': _userId!,
          'email': userEmail,
          'name': userName,
          'role': 'employee',
          'is_active': true,
          'updated_at': DateTime.now().toIso8601String(),
        });
        _userName = userName;
        _userRole = 'employee';
      } catch (upsertError) {
        debugPrint('❌ UPSERT failed: $upsertError');
        _userName = userEmail.split('@').first;
        _userRole = 'employee';
      }
    }
  }

  // =============================================
  // ✅ LOAD ATTENDANCE DATA
  // =============================================
  Future<void> _loadAttendanceData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      _todayAttendance = await _attendanceRepo.getTodayAttendance(user.id);
      _recentHistory = await _attendanceRepo.getAttendanceHistory(
        employeeId: user.id,
        limit: 5,
      );

      debugPrint(
        '📋 Today: ${_todayAttendance != null ? "Found" : "Not found"} | '
        'History: ${_recentHistory.length}',
      );
    } catch (e) {
      debugPrint('❌ Error loading attendance: $e');
      rethrow;
    }
  }

  // =============================================
  // ✅ UPDATE CURRENT LOCATION + DISTANCE
  // =============================================
  Future<void> _updateCurrentLocation({bool showLoading = true}) async {
    if (_companyLocation == null) return;

    if (showLoading) {
      setState(() => _isRefreshingLocation = true);
    }

    try {
      final location = await _locationService.getLocationWithRetry(
        maxAttempts: 3,
        targetAccuracy: 100.0,
      );

      if (location == null ||
          location.latitude == null ||
          location.longitude == null) {
        debugPrint('⚠️ Could not get current location');
        return;
      }

      final distance = _attendanceRepo.distanceBetween(
        location.latitude!,
        location.longitude!,
        _companyLocation!.latitude,
        _companyLocation!.longitude,
      );

      setState(() {
        _currentDistance = distance;
        _currentAccuracy = location.accuracy;
        _isWithinRange = distance <= _companyLocation!.radiusMeters;
      });

      debugPrint(
        '📍 Distance: ${distance.toStringAsFixed(0)}m '
        '(accuracy: ${location.accuracy?.toStringAsFixed(0) ?? "?"}m) '
        '→ ${_isWithinRange ? "IN" : "OUT"} of ${_companyLocation!.radiusMeters}m',
      );
    } catch (e) {
      debugPrint('❌ Error updating location: $e');
    } finally {
      if (showLoading && mounted) {
        setState(() => _isRefreshingLocation = false);
      }
    }
  }

  // =============================================
  // ✅ REFRESH DATA
  // =============================================
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('يرجى تسجيل الدخول أولاً');

      _userId = user.id;

      final userData = await Supabase.instance.client
          .from('users')
          .select('name, role')
          .eq('id', user.id)
          .maybeSingle();

      if (userData != null) {
        _userName = userData['name'] ?? 'موظف';
        _userRole = userData['role'] ?? 'employee';
      }

      // Reload company
      _companyLocation = await _companyLocationRepo.getDefaultLocation();

      if (_companyLocation == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'لا يوجد موقع مسجل للشركة';
        });
        return;
      }

      // Reload device (optional)
      try {
        final deviceId = await _deviceService.getDeviceId();
        _deviceInfo = await _attendanceRepo.getDevice(user.id, deviceId);
      } catch (_) {}

      await _loadAttendanceData();
      await _updateCurrentLocation(showLoading: false);

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('❌ Error loading data: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  // =============================================
  // ✅ GET TARGET LOCATION
  // =============================================
  ({double lat, double lng, double tolerance, String label})?
  _getTargetLocation() {
    if (_companyLocation != null) {
      return (
        lat: _companyLocation!.latitude,
        lng: _companyLocation!.longitude,
        tolerance: _companyLocation!.radiusMeters.toDouble(),
        label: _companyLocation!.name,
      );
    }
    return null;
  }

  // =============================================
  // ✅ CHECK IN
  // =============================================
  Future<void> _checkIn() async {
    if (_todayAttendance != null) {
      _showSnackBar('❌ لقد سجلت حضورك بالفعل اليوم', Colors.orange);
      return;
    }

    if (_userId == null) {
      _showSnackBar('❌ يرجى تسجيل الدخول أولاً', Colors.red);
      return;
    }

    final target = _getTargetLocation();
    if (target == null) {
      _showSnackBar(
        '❌ لا يوجد موقع مسجل للشركة، يرجى التواصل مع المدير',
        Colors.red,
      );
      return;
    }

    setState(() {
      _isCheckingIn = true;
      _errorMessage = null;
    });

    try {
      // ✅ استخدام الإعدادات المحسّنة
      final location = await _locationService.getLocationWithRetry(
        maxAttempts: 3,
        targetAccuracy: 100.0,
      );

      if (location == null ||
          location.latitude == null ||
          location.longitude == null) {
        throw Exception('فشل الحصول على الموقع، تأكد من تفعيل GPS');
      }

      final isMatch = _attendanceRepo.isLocationMatch(
        location.latitude!,
        location.longitude!,
        target.lat,
        target.lng,
        toleranceMeters: target.tolerance,
      );

      if (!isMatch) {
        final distance = _attendanceRepo.distanceBetween(
          location.latitude!,
          location.longitude!,
          target.lat,
          target.lng,
        );
        throw Exception(
          '⚠️ أنت لست في موقع الشركة\n'
          '${target.label}\n'
          'المسافة: ${distance.toStringAsFixed(0)} م / '
          'المسموح: ${target.tolerance.toStringAsFixed(0)} م\n'
          'دقة GPS: ${location.accuracy?.toStringAsFixed(0) ?? "?"} م',
        );
      }

      final attendance = await _attendanceRepo.checkIn(
        employeeId: _userId!,
        deviceId: _deviceInfo?.deviceId ?? 'web_default',
        latitude: location.latitude!,
        longitude: location.longitude!,
        notes: 'تسجيل حضور تلقائي',
      );

      setState(() {
        _todayAttendance = attendance;
        _isCheckingIn = false;
      });

      _showSnackBar('✅ تم تسجيل الحضور بنجاح', Colors.green);
      await _loadData();
    } catch (e) {
      setState(() {
        _isCheckingIn = false;
        _errorMessage = e.toString();
      });
      _showSnackBar(_errorMessage!, Colors.red);
    }
  }

  // =============================================
  // ✅ CHECK OUT
  // =============================================
  Future<void> _checkOut() async {
    if (_todayAttendance == null) {
      _showSnackBar('❌ لم تسجل حضورك اليوم', Colors.orange);
      return;
    }

    if (_todayAttendance!.isCheckedOut) {
      _showSnackBar('❌ لقد سجلت انصرافك بالفعل', Colors.orange);
      return;
    }

    setState(() {
      _isCheckingOut = true;
      _errorMessage = null;
    });

    try {
      final location = await _locationService.getLocationWithRetry(
        maxAttempts: 3,
        targetAccuracy: 100.0,
      );

      if (location == null ||
          location.latitude == null ||
          location.longitude == null) {
        throw Exception('فشل الحصول على الموقع، تأكد من تفعيل GPS');
      }

      final attendance = await _attendanceRepo.checkOut(
        attendanceId: _todayAttendance!.id!,
        latitude: location.latitude!,
        longitude: location.longitude!,
        notes: 'تسجيل انصراف تلقائي',
      );

      setState(() {
        _todayAttendance = attendance;
        _isCheckingOut = false;
      });

      _showSnackBar('✅ تم تسجيل الانصراف بنجاح', Colors.green);
      await _loadData();
    } catch (e) {
      setState(() {
        _isCheckingOut = false;
        _errorMessage = e.toString();
      });
      _showSnackBar(_errorMessage!, Colors.red);
    }
  }

  // =============================================
  // ✅ HELPER - SHOW SNACKBAR
  // =============================================
  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // =============================================
  // ✅ SHOW ATTENDANCE DETAILS
  // =============================================
  void _showAttendanceDetails(Attendance item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildDetailsSheet(item),
    );
  }

  Widget _buildDetailsSheet(Attendance item) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: item.status.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  item.status.icon,
                  color: item.status.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'تفاصيل الحضور',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      item.status.arabic,
                      style: TextStyle(
                        fontSize: 13,
                        color: item.status.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),
          _buildDetailRow('الموظف', item.employeeName ?? 'غير معروف'),
          _buildDetailRow('التاريخ', item.formattedDate),
          _buildDetailRow('وقت الحضور', item.formattedCheckIn),
          _buildDetailRow('وقت الانصراف', item.formattedCheckOut),
          _buildDetailRow('مدة العمل', item.formattedDuration),
          if (item.notes != null && item.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.notes, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.notes!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('إغلاق'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  // =============================================
  // ✅ BUILD UI
  // =============================================
  @override
  Widget build(BuildContext context) {
    if (_isCheckingRegistration) {
      return _buildLoadingScreen('جاري التحقق من الموقع...');
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: _isLoading
          ? _buildLoadingScreen('جاري التحميل...')
          : _errorMessage != null
          ? _buildErrorWidget()
          : RefreshIndicator(
              onRefresh: _loadData,
              color: const Color(0xFF2563EB),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildUserCard(),
                    const SizedBox(height: 16),
                    _buildLocationCard(),
                    const SizedBox(height: 16),
                    _buildAttendanceStatus(),
                    const SizedBox(height: 16),
                    _buildActionButtons(),
                    const SizedBox(height: 16),
                    if (_recentHistory.isNotEmpty) _buildRecentHistory(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  // =============================================
  // ✅ APP BAR
  // =============================================
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'الحضور والانصراف',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      backgroundColor: const Color(0xFF2563EB),
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        if (_userRole == 'admin')
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminAttendanceScreen(),
                ),
              );
            },
            tooltip: 'لوحة تحكم الأدمن',
          ),
        IconButton(
          icon: const Icon(Icons.history),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AttendanceHistoryScreen(),
              ),
            );
          },
          tooltip: 'سجل الحضور',
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _isLoading ? null : _loadData,
          tooltip: 'تحديث',
        ),
      ],
    );
  }

  // =============================================
  // ✅ LOADING SCREEN
  // =============================================
  Widget _buildLoadingScreen(String message) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الحضور والانصراف'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =============================================
  // ✅ USER CARD
  // =============================================
  Widget _buildUserCard() {
    return _card(
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.1),
            child: Text(
              _userName?.substring(0, 1).toUpperCase() ?? 'م',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2563EB),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName ?? 'موظف',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                _chip(
                  text: _userRole == 'admin' ? '👑 أدمن' : '👤 موظف',
                  color: _userRole == 'admin' ? Colors.blue : Colors.grey,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =============================================
  // ✅ LOCATION CARD (مع حالة حية)
  // =============================================
  Widget _buildLocationCard() {
    if (_companyLocation == null) return const SizedBox.shrink();

    final hasLocation = _currentDistance != null;
    final isNear = _isWithinRange;
    final color = !hasLocation
        ? Colors.grey
        : isNear
        ? Colors.green
        : Colors.red;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.shade50, color.shade100.withValues(alpha: 0.5)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: hasLocation
                          ? [
                              BoxShadow(
                                color: color.withValues(
                                  alpha:
                                      0.3 *
                                      (0.5 + _pulseController.value * 0.5),
                                ),
                                blurRadius: 12,
                                spreadRadius: 4 * _pulseController.value,
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      isNear
                          ? Icons.check_circle
                          : hasLocation
                          ? Icons.location_off
                          : Icons.location_searching,
                      color: Colors.white,
                      size: 22,
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🏢 موقع الشركة',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color.shade700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _companyLocation!.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '🎯 نطاق مسموح: ${_companyLocation!.radiusMeters} م',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _isRefreshingLocation
                    ? null
                    : () => _updateCurrentLocation(),
                icon: _isRefreshingLocation
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location),
                tooltip: 'تحديث موقعي',
                color: color,
              ),
            ],
          ),
          if (hasLocation) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        isNear
                            ? Icons.check_circle
                            : Icons.warning_amber_rounded,
                        size: 16,
                        color: color.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isNear
                              ? '✅ أنت داخل النطاق — يمكنك تسجيل الحضور'
                              : '⚠️ أنت خارج النطاق — اقترب من ${_companyLocation!.name}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: color.shade800,
                          ),
                        ),
                      ),
                      Text(
                        '${_currentDistance!.toStringAsFixed(0)} م',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: color.shade800,
                        ),
                      ),
                    ],
                  ),
                  // ✅ عرض دقة GPS
                  if (_currentAccuracy != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          const SizedBox(width: 24),
                          Icon(
                            Icons.gps_fixed,
                            size: 12,
                            color: _currentAccuracy! <= 50
                                ? Colors.green.shade600
                                : _currentAccuracy! <= 200
                                ? Colors.orange.shade600
                                : Colors.red.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'دقة GPS: ${_currentAccuracy!.toStringAsFixed(0)} م',
                            style: TextStyle(
                              fontSize: 10,
                              color: _currentAccuracy! <= 50
                                  ? Colors.green.shade700
                                  : _currentAccuracy! <= 200
                                  ? Colors.orange.shade700
                                  : Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 10),
            Text(
              'اضغط على 📍 لتحديد موقعك الحالي',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ],
      ),
    );
  }

  // =============================================
  // ✅ ATTENDANCE STATUS
  // =============================================
  Widget _buildAttendanceStatus() {
    return _card(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'حالة اليوم',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              Text(
                DateFormat('EEEE، d MMMM', 'ar').format(DateTime.now()),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_todayAttendance != null)
            _buildStatusContent()
          else
            _buildEmptyStatus(),
        ],
      ),
    );
  }

  Widget _buildStatusContent() {
    final att = _todayAttendance!;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: att.status.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(att.status.icon, color: att.status.color, size: 30),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                att.status.arabic,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: att.status.color,
                ),
              ),
              const SizedBox(height: 4),
              _infoLine(Icons.login, 'الحضور: ${att.formattedCheckIn}'),
              if (att.isCheckedOut)
                _infoLine(Icons.logout, 'الانصراف: ${att.formattedCheckOut}')
              else
                _infoLine(
                  Icons.hourglass_empty,
                  'لم تنصرف بعد',
                  color: Colors.orange,
                ),
            ],
          ),
        ),
        if (att.isCheckedOut)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  '🕐 المدة',
                  style: TextStyle(fontSize: 10, color: Colors.green.shade700),
                ),
                Text(
                  att.formattedDuration,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyStatus() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.access_time, size: 36, color: Colors.grey.shade400),
        ),
        const SizedBox(height: 12),
        const Text(
          'لم تسجل حضورك اليوم',
          style: TextStyle(fontSize: 15, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          'اضغط على "تسجيل حضور" للبدء',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
      ],
    );
  }

  Widget _infoLine(IconData icon, String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(icon, size: 13, color: color ?? Colors.grey.shade600),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: color ?? Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  // =============================================
  // ✅ ACTION BUTTONS
  // =============================================
  Widget _buildActionButtons() {
    final isCheckedIn = _todayAttendance != null;
    final isCheckedOut = _todayAttendance?.isCheckedOut ?? false;

    final canCheckIn =
        !_isCheckingIn &&
        !isCheckedIn &&
        (_currentDistance == null || _isWithinRange);

    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: canCheckIn ? _checkIn : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: isCheckedIn
                  ? Colors.green
                  : const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
              disabledBackgroundColor: isCheckedIn
                  ? Colors.green.shade300
                  : Colors.grey.shade300,
            ),
            child: _isCheckingIn
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isCheckedIn ? Icons.check_circle : Icons.login_rounded,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isCheckedIn ? 'تم الحضور' : 'تسجيل حضور',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _isCheckingOut || !isCheckedIn || isCheckedOut
                ? null
                : _checkOut,
            style: ElevatedButton.styleFrom(
              backgroundColor: isCheckedOut ? Colors.grey : Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
              disabledBackgroundColor: isCheckedOut
                  ? Colors.grey
                  : Colors.orange.shade300,
            ),
            child: _isCheckingOut
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isCheckedOut
                            ? Icons.check_circle
                            : Icons.logout_rounded,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isCheckedOut ? 'تم الانصراف' : 'تسجيل انصراف',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  // =============================================
  // ✅ RECENT HISTORY
  // =============================================
  Widget _buildRecentHistory() {
    return _card(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.history, size: 18, color: Color(0xFF2563EB)),
                const SizedBox(width: 8),
                const Text(
                  'آخر 5 سجلات',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AttendanceHistoryScreen(),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF2563EB),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 30),
                  ),
                  child: const Text('عرض الكل', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          ..._recentHistory.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isLast = index == _recentHistory.length - 1;
            return Column(
              children: [
                ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: item.status.color.withValues(alpha: 0.1),
                    child: Icon(
                      item.status.icon,
                      color: item.status.color,
                      size: 16,
                    ),
                  ),
                  title: Text(
                    item.formattedDate,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    '${item.formattedCheckIn} → ${item.formattedCheckOut}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  trailing: _chip(
                    text: item.status.arabic,
                    color: item.status.color,
                    small: true,
                  ),
                  onTap: () => _showAttendanceDetails(item),
                ),
                if (!isLast)
                  Divider(height: 0, color: Colors.grey.shade200, indent: 56),
              ],
            );
          }),
        ],
      ),
    );
  }

  // =============================================
  // ✅ REUSABLE WIDGETS
  // =============================================
  Widget _card({required Widget child, EdgeInsets? padding}) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _chip({
    required String text,
    required Color color,
    bool small = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: small ? 10 : 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  // =============================================
  // ✅ ERROR WIDGET
  // =============================================
  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _errorMessage ?? 'حدث خطأ غير متوقع',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
