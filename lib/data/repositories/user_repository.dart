// lib/data/repositories/user_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user.dart';

class UserRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  final String _table = 'users';

  // ==================== GET ALL USERS ====================
  Future<List<AppUser>> getAllUsers() async {
    try {
      final response = await _supabase.from(_table).select('*').order('email');

      return List<AppUser>.from(response.map((json) => AppUser.fromJson(json)));
    } catch (e) {
      throw Exception('خطأ في جلب المستخدمين: $e');
    }
  }

  // ==================== GET USER BY ID ====================
  Future<AppUser?> getUserById(String id) async {
    try {
      final response = await _supabase
          .from(_table)
          .select('*')
          .eq('id', id)
          .maybeSingle();

      if (response != null) {
        return AppUser.fromJson(response);
      }
      return null;
    } catch (e) {
      throw Exception('خطأ في جلب بيانات المستخدم: $e');
    }
  }

  // ==================== GET CURRENT USER ====================
  Future<AppUser?> getCurrentUser() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from(_table)
          .select('*')
          .eq('id', user.id)
          .maybeSingle();

      if (response != null) {
        return AppUser.fromJson(response);
      }
      return null;
    } catch (e) {
      throw Exception('خطأ في جلب المستخدم الحالي: $e');
    }
  }

  // ==================== UPDATE USER ROLE ====================
  Future<AppUser> updateUserRole(String userId, String role) async {
    try {
      // التحقق من صحة الدور
      if (!['admin', 'employee'].contains(role)) {
        throw Exception('دور غير صحيح. الأدوار المتاحة: admin, employee');
      }

      final response = await _supabase
          .from(_table)
          .update({'role': role})
          .eq('id', userId)
          .select()
          .single();

      return AppUser.fromJson(response);
    } catch (e) {
      throw Exception('خطأ في تحديث دور المستخدم: $e');
    }
  }

  // ==================== UPDATE USER ====================
  Future<AppUser> updateUser(AppUser user) async {
    try {
      final response = await _supabase
          .from(_table)
          .update(user.toJson())
          .eq('id', user.id)
          .select()
          .single();

      return AppUser.fromJson(response);
    } catch (e) {
      throw Exception('خطأ في تحديث بيانات المستخدم: $e');
    }
  }

  // ==================== TOGGLE USER STATUS ====================
  Future<AppUser> toggleUserStatus(String userId, bool isActive) async {
    try {
      final response = await _supabase
          .from(_table)
          .update({'is_active': isActive})
          .eq('id', userId)
          .select()
          .single();

      return AppUser.fromJson(response);
    } catch (e) {
      throw Exception('خطأ في تغيير حالة المستخدم: $e');
    }
  }

  // ==================== DELETE USER ====================
  Future<void> deleteUser(String userId) async {
    try {
      // منع حذف الـ Admin الأخير
      final users = await getAllUsers();
      final admins = users.where((u) => u.isAdmin).toList();

      if (admins.length <= 1) {
        final user = await getUserById(userId);
        if (user != null && user.isAdmin) {
          throw Exception('لا يمكن حذف المدير الأخير في النظام');
        }
      }

      await _supabase.from(_table).delete().eq('id', userId);
    } catch (e) {
      throw Exception('خطأ في حذف المستخدم: $e');
    }
  }

  // ==================== SEARCH USERS ====================
  Future<List<AppUser>> searchUsers(String query) async {
    try {
      if (query.isEmpty) {
        return await getAllUsers();
      }

      final response = await _supabase
          .from(_table)
          .select('*')
          .or('email.ilike.%$query%,name.ilike.%$query%,phone.ilike.%$query%')
          .order('email');

      return List<AppUser>.from(response.map((json) => AppUser.fromJson(json)));
    } catch (e) {
      throw Exception('خطأ في البحث عن المستخدمين: $e');
    }
  }

  // ==================== GET USERS COUNT ====================
  Future<int> getUsersCount() async {
    try {
      final response = await _supabase.from(_table).select('id');

      return response.length;
    } catch (e) {
      throw Exception('خطأ في جلب عدد المستخدمين: $e');
    }
  }

  // ==================== GET ADMINS COUNT ====================
  Future<int> getAdminsCount() async {
    try {
      final response = await _supabase
          .from(_table)
          .select('id')
          .eq('role', 'admin');

      return response.length;
    } catch (e) {
      throw Exception('خطأ في جلب عدد المديرين: $e');
    }
  }

  // ==================== GET EMPLOYEES COUNT ====================
  Future<int> getEmployeesCount() async {
    try {
      final response = await _supabase
          .from(_table)
          .select('id')
          .eq('role', 'employee');

      return response.length;
    } catch (e) {
      throw Exception('خطأ في جلب عدد الموظفين: $e');
    }
  }

  // ==================== GET ACTIVE USERS COUNT ====================
  Future<int> getActiveUsersCount() async {
    try {
      final response = await _supabase
          .from(_table)
          .select('id')
          .eq('is_active', true);

      return response.length;
    } catch (e) {
      throw Exception('خطأ في جلب عدد المستخدمين النشطين: $e');
    }
  }

  // ==================== GET USERS BY ROLE ====================
  Future<List<AppUser>> getUsersByRole(String role) async {
    try {
      if (!['admin', 'employee'].contains(role)) {
        throw Exception('دور غير صحيح. الأدوار المتاحة: admin, employee');
      }

      final response = await _supabase
          .from(_table)
          .select('*')
          .eq('role', role)
          .order('email');

      return List<AppUser>.from(response.map((json) => AppUser.fromJson(json)));
    } catch (e) {
      throw Exception('خطأ في جلب المستخدمين حسب الدور: $e');
    }
  }

  // ==================== GET ACTIVE USERS ====================
  Future<List<AppUser>> getActiveUsers() async {
    try {
      final response = await _supabase
          .from(_table)
          .select('*')
          .eq('is_active', true)
          .order('email');

      return List<AppUser>.from(response.map((json) => AppUser.fromJson(json)));
    } catch (e) {
      throw Exception('خطأ في جلب المستخدمين النشطين: $e');
    }
  }

  // ==================== CHECK IF USER IS ADMIN ====================
  Future<bool> isUserAdmin(String userId) async {
    try {
      final user = await getUserById(userId);
      return user?.isAdmin ?? false;
    } catch (e) {
      throw Exception('خطأ في التحقق من صلاحيات المستخدم: $e');
    }
  }

  // ==================== UPDATE PROFILE ====================
  Future<AppUser> updateProfile({
    required String userId,
    String? name,
    String? phone,
    String? avatarUrl,
  }) async {
    try {
      final Map<String, dynamic> data = {};
      if (name != null) data['name'] = name;
      if (phone != null) data['phone'] = phone;
      if (avatarUrl != null) data['avatar_url'] = avatarUrl;

      if (data.isEmpty) {
        throw Exception('لا توجد بيانات للتحديث');
      }

      final response = await _supabase
          .from(_table)
          .update(data)
          .eq('id', userId)
          .select()
          .single();

      return AppUser.fromJson(response);
    } catch (e) {
      throw Exception('خطأ في تحديث الملف الشخصي: $e');
    }
  }

  // ==================== CREATE USER (ADMIN ONLY) ====================
  Future<AppUser> createUser({
    required String email,
    required String password,
    String? name,
    String? role,
    String? phone,
  }) async {
    try {
      // إنشاء المستخدم في Auth
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name, 'role': role ?? 'employee', 'phone': phone},
      );

      if (authResponse.user == null) {
        throw Exception('فشل في إنشاء المستخدم');
      }

      // جلب المستخدم من جدول users
      final user = await getUserById(authResponse.user!.id);
      if (user == null) {
        throw Exception('فشل في جلب بيانات المستخدم');
      }

      return user;
    } catch (e) {
      throw Exception('خطأ في إنشاء المستخدم: $e');
    }
  }

  // ==================== RESET PASSWORD ====================
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw Exception('خطأ في إرسال رابط إعادة تعيين كلمة المرور: $e');
    }
  }

  // ==================== BULK OPERATIONS ====================

  // تفعيل عدة مستخدمين
  Future<void> activateUsers(List<String> userIds) async {
    try {
      for (var id in userIds) {
        await toggleUserStatus(id, true);
      }
    } catch (e) {
      throw Exception('خطأ في تفعيل المستخدمين: $e');
    }
  }

  // تعطيل عدة مستخدمين
  Future<void> deactivateUsers(List<String> userIds) async {
    try {
      for (var id in userIds) {
        await toggleUserStatus(id, false);
      }
    } catch (e) {
      throw Exception('خطأ في تعطيل المستخدمين: $e');
    }
  }

  // حذف عدة مستخدمين
  Future<void> deleteUsers(List<String> userIds) async {
    try {
      for (var id in userIds) {
        await deleteUser(id);
      }
    } catch (e) {
      throw Exception('خطأ في حذف المستخدمين: $e');
    }
  }

  // ==================== STATISTICS ====================

  // جلب إحصائيات المستخدمين
  Future<Map<String, dynamic>> getUserStatistics() async {
    try {
      final total = await getUsersCount();
      final admins = await getAdminsCount();
      final employees = await getEmployeesCount();
      final active = await getActiveUsersCount();

      return {
        'total': total,
        'admins': admins,
        'employees': employees,
        'active': active,
        'inactive': total - active,
      };
    } catch (e) {
      throw Exception('خطأ في جلب إحصائيات المستخدمين: $e');
    }
  }
}
