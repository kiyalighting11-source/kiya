// lib/utils/permissions.dart

import 'package:flutter/foundation.dart'; // ✅ أضف هذا السطر
import 'package:supabase_flutter/supabase_flutter.dart';

class Permissions {
  static Future<String?> getUserRole() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return null;

      final response = await Supabase.instance.client
          .from('users')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();

      return response?['role'] as String?;
    } catch (e) {
      debugPrint('❌ خطأ في جلب دور المستخدم: $e');
      return null;
    }
  }

  static bool isAdmin(String? role) => role == 'admin';
  static bool isManager(String? role) => role == 'manager' || role == 'admin';
  static bool isEmployee(String? role) => role == 'employee';
  static bool canAccess(String? role, List<String> allowedRoles) {
    return allowedRoles.contains(role);
  }

  // صلاحيات محددة
  static bool canManageCustomers(String? role) {
    return ['admin', 'manager', 'employee'].contains(role);
  }

  static bool canManageInvoices(String? role) {
    return ['admin', 'manager'].contains(role);
  }

  static bool canManageQuotations(String? role) {
    return ['admin', 'manager'].contains(role);
  }

  static bool canManageProducts(String? role) {
    return ['admin', 'manager'].contains(role);
  }

  static bool canManageUsers(String? role) {
    return ['admin'].contains(role);
  }

  static bool canManageReports(String? role) {
    return ['admin', 'manager'].contains(role);
  }

  static bool canManageSettings(String? role) {
    return ['admin'].contains(role);
  }
}
