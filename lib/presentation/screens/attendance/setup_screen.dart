// lib/presentation/screens/attendance/setup_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/services/device_service.dart';
import '../../../data/services/location_service.dart';
import '../../../data/repositories/attendance_repository.dart';
import 'attendance_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final DeviceService _deviceService = DeviceService();
  final LocationService _locationService = LocationService();
  final AttendanceRepository _attendanceRepo = AttendanceRepository();
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = false;
  String _statusMessage = 'جاري تجهيز الجهاز...';
  bool _isDeviceReady = false;
  bool _isLocationReady = false;
  bool _isRegistered = false;
  bool _isUserCreated = false;
  String? _userId;

  String? _deviceId;
  String? _deviceName;
  String? _deviceModel;
  double? _latitude;
  double? _longitude;
  String? _locationName;

  @override
  void initState() {
    super.initState();
    _startSetup();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _startSetup() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'جاري الحصول على معلومات الجهاز...';
    });

    try {
      // =============================================
      // 0. التحقق من تسجيل الدخول أولاً
      // =============================================
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        setState(() {
          _isLoading = false;
          _statusMessage = '❌ يرجى تسجيل الدخول أولاً';
        });
        return;
      }

      _userId = currentUser.id;
      final userEmail = currentUser.email ?? '';

      debugPrint('✅ User ID: $_userId');
      debugPrint('✅ User Email: $userEmail');

      // =============================================
      // 1. الحصول على معلومات الجهاز
      // =============================================
      setState(() {
        _statusMessage = 'جاري الحصول على معلومات الجهاز...';
      });

      _deviceId = await _deviceService.getDeviceId();
      _deviceName = await _deviceService.getDeviceName();
      _deviceModel = await _deviceService.getDeviceModel();

      debugPrint('📱 Device ID: $_deviceId');
      debugPrint('📱 Device Name: $_deviceName');
      debugPrint('📱 Device Model: $_deviceModel');

      setState(() {
        _isDeviceReady = true;
        _statusMessage = '✅ تم الحصول على معلومات الجهاز';
      });

      await Future.delayed(const Duration(milliseconds: 500));

      // =============================================
      // 2. الحصول على الموقع
      // =============================================
      setState(() {
        _statusMessage = 'جاري الحصول على الموقع...';
      });

      final location = await _locationService.getLocationWithRetry();
      if (location != null &&
          location.latitude != null &&
          location.longitude != null) {
        _latitude = location.latitude;
        _longitude = location.longitude;
        _locationName = await _locationService.getLocationName(
          location.latitude!,
          location.longitude!,
        );

        debugPrint('📍 Latitude: $_latitude');
        debugPrint('📍 Longitude: $_longitude');
        debugPrint('📍 Location Name: $_locationName');

        setState(() {
          _isLocationReady = true;
          _statusMessage = '✅ تم الحصول على الموقع';
        });
      } else {
        setState(() {
          _isLoading = false;
          _statusMessage = '❌ فشل الحصول على الموقع، تأكد من تفعيل GPS';
        });
        return;
      }

      await Future.delayed(const Duration(milliseconds: 500));

      // =============================================
      // 3. ✅ إنشاء/تحديث المستخدم في جدول users
      // =============================================
      await _ensureUserExists(userEmail);

      // =============================================
      // 4. تسجيل الجهاز
      // =============================================
      await _registerDevice();

      // ✅ حفظ الجهاز محلياً
      await _deviceService.storeDeviceLocally(_deviceId!);

      setState(() {
        _isRegistered = true;
        _statusMessage = '✅ تم إعداد الجهاز بنجاح!';
        _isLoading = false;
      });

      // ✅ الانتظار ثم الانتقال للشاشة الرئيسية
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AttendanceScreen()),
        );
      }
    } catch (e) {
      debugPrint('❌ خطأ في الإعداد: $e');
      setState(() {
        _isLoading = false;
        _statusMessage = '❌ حدث خطأ: $e';
      });
    }
  }

  // =============================================
  // ✅ دالة التأكد من وجود المستخدم
  // =============================================
  Future<void> _ensureUserExists(String userEmail) async {
    setState(() {
      _statusMessage = 'جاري التحقق من المستخدم...';
    });

    try {
      // ✅ STEP 1: التحقق من وجود المستخدم بالـ ID
      var userData = await _supabase
          .from('users')
          .select('id, name, role, email')
          .eq('id', _userId!)
          .maybeSingle();

      debugPrint('🔍 User Data by ID: $userData');

      if (userData != null) {
        // ✅ المستخدم موجود بالـ ID - كل شيء جيد
        debugPrint(
          '✅ User exists with ID: ${userData['name']} (${userData['role']})',
        );
        setState(() {
          _isUserCreated = true;
          _statusMessage = '✅ المستخدم موجود بالفعل';
        });
        return;
      }

      // ✅ STEP 2: المستخدم غير موجود بالـ ID - تحقق من البريد الإلكتروني
      final emailUser = await _supabase
          .from('users')
          .select('id, name, role, email')
          .eq('email', userEmail)
          .maybeSingle();

      debugPrint('🔍 User Data by Email: $emailUser');

      if (emailUser != null) {
        // ✅ STEP 3: المستخدم موجود بالبريد الإلكتروني ولكن بـ ID مختلف
        // نقوم بتحديث الـ ID ليطابق معرف المصادقة
        await _updateExistingUser(userEmail, emailUser);
        return;
      }

      // ✅ STEP 4: المستخدم غير موجود تماماً - قم بإنشائه
      await _createNewUser(userEmail);
    } catch (e) {
      debugPrint('❌ Error in _ensureUserExists: $e');
      // ✅ المحاولة النهائية: استخدام upsert
      await _upsertUser(userEmail);
    }
  }

  // =============================================
  // ✅ تحديث مستخدم موجود
  // =============================================
  Future<void> _updateExistingUser(
    String userEmail,
    Map<String, dynamic> emailUser,
  ) async {
    setState(() {
      _statusMessage = 'جاري تحديث بيانات المستخدم...';
    });

    debugPrint(
      '⚠️ User exists with email, updating ID from ${emailUser['id']} to $_userId',
    );

    try {
      // ✅ المحاولة الأولى: تحديث الـ ID مباشرة
      await _supabase
          .from('users')
          .update({
            'id': _userId!,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('email', userEmail);

      debugPrint('✅ User ID updated successfully!');

      // ✅ التحقق من التحديث
      final updatedUser = await _supabase
          .from('users')
          .select('id, name, role, email')
          .eq('id', _userId!)
          .maybeSingle();

      if (updatedUser != null) {
        setState(() {
          _isUserCreated = true;
          _statusMessage = '✅ تم تحديث بيانات المستخدم';
        });
        return;
      }

      // ✅ إذا فشل التحديث، استخدم حذف + إدراج
      await _recreateUser(userEmail, emailUser);
    } catch (updateError) {
      debugPrint('❌ Error updating user: $updateError');
      // ✅ إذا فشل التحديث، استخدم حذف + إدراج
      await _recreateUser(userEmail, emailUser);
    }
  }

  // =============================================
  // ✅ حذف وإعادة إنشاء المستخدم
  // =============================================
  Future<void> _recreateUser(
    String userEmail,
    Map<String, dynamic> emailUser,
  ) async {
    setState(() {
      _statusMessage = 'جاري إعادة إنشاء المستخدم...';
    });

    debugPrint('🔄 Recreating user with email: $userEmail');

    try {
      // ✅ حذف السجل القديم
      await _supabase.from('users').delete().eq('email', userEmail);

      debugPrint('✅ Old user deleted');

      // ✅ إدراج السجل الجديد بالـ ID الصحيح
      await _supabase.from('users').insert({
        'id': _userId!,
        'email': userEmail,
        'name': emailUser['name'] ?? userEmail.split('@').first,
        'role': emailUser['role'] ?? 'employee',
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ User recreated with correct ID!');

      setState(() {
        _isUserCreated = true;
        _statusMessage = '✅ تم إعادة إنشاء المستخدم';
      });
    } catch (e) {
      debugPrint('❌ Error recreating user: $e');
      // ✅ المحاولة النهائية: upsert
      await _upsertUser(userEmail);
    }
  }

  // =============================================
  // ✅ إنشاء مستخدم جديد
  // =============================================
  Future<void> _createNewUser(String userEmail) async {
    setState(() {
      _statusMessage = 'جاري إنشاء حساب المستخدم...';
    });

    final userName = userEmail.split('@').first;
    debugPrint('📝 Creating new user: $userEmail');

    try {
      // ✅ محاولة الإدراج المباشر
      await _supabase.from('users').insert({
        'id': _userId!,
        'email': userEmail,
        'name': userName,
        'role': 'employee',
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ User created successfully!');

      setState(() {
        _isUserCreated = true;
        _statusMessage = '✅ تم إنشاء حساب المستخدم';
      });
    } catch (insertError) {
      debugPrint('❌ Error creating user: $insertError');
      // ✅ إذا فشل الإدراج، حاول باستخدام upsert
      await _upsertUser(userEmail);
    }
  }

  // =============================================
  // ✅ Upsert المستخدم (الملاذ الأخير)
  // =============================================
  Future<void> _upsertUser(String userEmail) async {
    setState(() {
      _statusMessage = 'جاري حفظ بيانات المستخدم...';
    });

    final userName = userEmail.split('@').first;
    debugPrint('🔄 Upserting user: $userEmail');

    try {
      // ✅ استخدام upsert مع onConflict
      await _supabase.from('users').upsert({
        'id': _userId!,
        'email': userEmail,
        'name': userName,
        'role': 'employee',
        'is_active': true,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'email');

      debugPrint('✅ User upserted successfully!');

      // ✅ التحقق من النتيجة
      final finalCheck = await _supabase
          .from('users')
          .select('id, name, role, email')
          .eq('id', _userId!)
          .maybeSingle();

      if (finalCheck != null) {
        setState(() {
          _isUserCreated = true;
          _statusMessage = '✅ تم حفظ بيانات المستخدم';
        });
      } else {
        throw Exception('Failed to verify user creation');
      }
    } catch (e) {
      debugPrint('❌ Error upserting user: $e');

      // ✅ المحاولة الأخيرة: استخدام SQL الخام (RPC)
      try {
        await _supabase.rpc(
          'handle_user_upsert',
          params: {
            'p_id': _userId!,
            'p_email': userEmail,
            'p_name': userName,
            'p_role': 'employee',
          },
        );

        debugPrint('✅ User created via RPC!');

        setState(() {
          _isUserCreated = true;
          _statusMessage = '✅ تم إنشاء المستخدم';
        });
      } catch (rpcError) {
        debugPrint('❌ RPC failed: $rpcError');
        throw Exception('فشل إنشاء المستخدم: $rpcError');
      }
    }
  }

  // =============================================
  // ✅ تسجيل الجهاز
  // =============================================
  Future<void> _registerDevice() async {
    setState(() {
      _statusMessage = 'جاري تسجيل الجهاز...';
    });

    // ✅ تحقق نهائي من وجود المستخدم
    final checkUser = await _supabase
        .from('users')
        .select('id')
        .eq('id', _userId!)
        .maybeSingle();

    if (checkUser == null) {
      debugPrint('⚠️ User still not found, attempting final creation...');

      // ✅ المحاولة النهائية لإنشاء المستخدم
      await _upsertUser(Supabase.instance.client.auth.currentUser?.email ?? '');
    }

    // ✅ التحقق من أن الجهاز غير مسجل بالفعل
    final existingDevice = await _attendanceRepo.getDevice(
      _userId!,
      _deviceId!,
    );

    if (existingDevice != null) {
      // ✅ الجهاز مسجل بالفعل - تحديث معلوماته
      setState(() {
        _statusMessage = 'جاري تحديث معلومات الجهاز...';
      });

      await _deviceService.saveDeviceInfo(
        employeeId: _userId!,
        latitude: _latitude!,
        longitude: _longitude!,
        locationName: _locationName,
      );

      setState(() {
        _statusMessage = '✅ تم تحديث معلومات الجهاز';
      });
    } else {
      // ✅ تسجيل جهاز جديد
      setState(() {
        _statusMessage = 'جاري تسجيل الجهاز الجديد...';
      });

      await _attendanceRepo.registerDevice(
        employeeId: _userId!,
        deviceId: _deviceId!,
        latitude: _latitude!,
        longitude: _longitude!,
        deviceName: _deviceName,
        deviceModel: _deviceModel,
        locationName: _locationName,
      );

      setState(() {
        _statusMessage = '✅ تم تسجيل الجهاز بنجاح';
      });
    }
  }

  // =============================================
  // ✅ BUILD UI
  // =============================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: const [Color(0xFF1E3A5F), Color(0xFF2563EB)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ===== LOGO =====
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(60),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.business_center,
                    size: 60,
                    color: Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(height: 32),

                const Text(
                  'تسجيل الجهاز',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'يرجى الانتظار حتى اكتمال التسجيل',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 48),

                // ===== STATUS CARD =====
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Loading
                      if (_isLoading) ...[
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF2563EB),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Status Message
                      Text(
                        _statusMessage,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: _statusMessage.contains('✅')
                              ? Colors.green
                              : _statusMessage.contains('❌')
                              ? Colors.red
                              : Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),

                      // Steps
                      _buildStep('معلومات الجهاز', _isDeviceReady),
                      const SizedBox(height: 8),
                      _buildStep('الموقع الجغرافي', _isLocationReady),
                      const SizedBox(height: 8),
                      _buildStep('المستخدم', _isUserCreated),
                      const SizedBox(height: 8),
                      _buildStep('تسجيل الجهاز', _isRegistered),
                    ],
                  ),
                ),

                if (_statusMessage.contains('❌')) ...[
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _startSetup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =============================================
  // ✅ BUILD STEP WIDGET
  // =============================================
  Widget _buildStep(String label, bool isComplete) {
    return Row(
      children: [
        Icon(
          isComplete ? Icons.check_circle : Icons.circle_outlined,
          color: isComplete ? Colors.green : Colors.grey.shade400,
          size: 20,
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isComplete ? Colors.black87 : Colors.grey.shade500,
            fontWeight: isComplete ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        const Spacer(),
        if (isComplete) const Icon(Icons.check, color: Colors.green, size: 18),
      ],
    );
  }
}
