// lib/data/models/user.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// ✅ Model for AppUser - represents a system user
class AppUser {
  // ==================== BASIC FIELDS ====================
  final String id;
  final String email;
  final String? name;
  final String? role;
  final String? phone;
  final String? avatarUrl;
  final bool? isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // ==================== ADDITIONAL FIELDS ====================
  final String? companyId;
  final String? department;
  final String? jobTitle;
  final DateTime? lastLogin;
  final String? preferedLanguage;
  final bool? emailVerified;
  final bool? phoneVerified;

  // ==================== CONSTRUCTOR ====================
  AppUser({
    required this.id,
    required this.email,
    this.name,
    this.role,
    this.phone,
    this.avatarUrl,
    this.isActive,
    this.createdAt,
    this.updatedAt,
    this.companyId,
    this.department,
    this.jobTitle,
    this.lastLogin,
    this.preferedLanguage,
    this.emailVerified,
    this.phoneVerified,
  });

  // ==================== FROM JSON ====================
  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'],
      role: json['role'] ?? 'employee',
      phone: json['phone'],
      avatarUrl: json['avatar_url'],
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      companyId: json['company_id'],
      department: json['department'],
      jobTitle: json['job_title'],
      lastLogin: json['last_login'] != null
          ? DateTime.parse(json['last_login'])
          : null,
      preferedLanguage: json['prefered_language'] ?? 'ar',
      emailVerified: json['email_verified'] ?? false,
      phoneVerified: json['phone_verified'] ?? false,
    );
  }

  // ==================== TO JSON ====================
  Map<String, dynamic> toJson() {
    final data = {
      'email': email,
      'name': name,
      'role': role,
      'phone': phone,
      'avatar_url': avatarUrl,
      'is_active': isActive,
      'company_id': companyId,
      'department': department,
      'job_title': jobTitle,
      'prefered_language': preferedLanguage,
      'email_verified': emailVerified,
      'phone_verified': phoneVerified,
    };

    // ✅ فقط أضف last_login إذا كان موجوداً
    if (lastLogin != null) {
      data['last_login'] = lastLogin!.toIso8601String();
    }

    return data;
  }

  // ==================== COPY WITH ====================
  AppUser copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
    String? phone,
    String? avatarUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? companyId,
    String? department,
    String? jobTitle,
    DateTime? lastLogin,
    String? preferedLanguage,
    bool? emailVerified,
    bool? phoneVerified,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      companyId: companyId ?? this.companyId,
      department: department ?? this.department,
      jobTitle: jobTitle ?? this.jobTitle,
      lastLogin: lastLogin ?? this.lastLogin,
      preferedLanguage: preferedLanguage ?? this.preferedLanguage,
      emailVerified: emailVerified ?? this.emailVerified,
      phoneVerified: phoneVerified ?? this.phoneVerified,
    );
  }

  // ==================== GETTERS ====================

  /// ✅ Check if user is admin
  bool get isAdmin => role == 'admin';

  /// ✅ Check if user is employee
  bool get isEmployee => role == 'employee';

  /// ✅ Check if user is active
  bool get isActiveUser => isActive ?? true;

  /// ✅ Check if user is blocked
  bool get isBlocked => !(isActive ?? true);

  /// ✅ Get display name (name or email)
  String get displayName {
    if (name != null && name!.isNotEmpty) {
      return name!;
    }
    return email.split('@').first;
  }

  /// ✅ Get full name with role
  String get fullNameWithRole => '$displayName ($roleLabel)';

  /// ✅ Get initials for avatar
  String get initials {
    if (name != null && name!.isNotEmpty) {
      final parts = name!.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return name![0].toUpperCase();
    }
    return email[0].toUpperCase();
  }

  /// ✅ Get role label in Arabic
  String get roleLabel {
    switch (role) {
      case 'admin':
        return 'مدير';
      case 'employee':
        return 'موظف';
      case 'manager':
        return 'مدير قسم';
      case 'supervisor':
        return 'مشرف';
      default:
        return 'غير محدد';
    }
  }

  /// ✅ Get role color
  Color get roleColor {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'manager':
        return Colors.purple;
      case 'supervisor':
        return Colors.orange;
      case 'employee':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  /// ✅ Get role icon
  IconData get roleIcon {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'manager':
        return Icons.manage_accounts;
      case 'supervisor':
        return Icons.supervisor_account;
      case 'employee':
        return Icons.person;
      default:
        return Icons.person_outline;
    }
  }

  /// ✅ Get avatar color
  Color get avatarColor {
    final colors = [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
      Colors.grey,
      Colors.blueGrey,
    ];

    final index = displayName.hashCode.abs() % colors.length;
    return colors[index];
  }

  /// ✅ Get avatar background color (with opacity)
  Color get avatarBackgroundColor {
    return avatarColor.withValues(alpha: 0.1);
  }

  /// ✅ Get formatted created date
  String get formattedCreatedAt {
    if (createdAt == null) return 'غير معروف';
    return DateFormat('d MMMM y، h:mm a', 'ar').format(createdAt!);
  }

  /// ✅ Get formatted last login - FIXED ✅
  String get formattedLastLogin {
    if (lastLogin == null) return 'لم يسجل الدخول بعد';

    final now = DateTime.now();
    final difference = now.difference(lastLogin!);
    final days = difference.inDays;
    final hours = difference.inHours;
    final minutes = difference.inMinutes;

    if (days > 0) {
      return 'منذ $days يوم';
    } else if (hours > 0) {
      return 'منذ $hours ساعة';
    } else if (minutes > 0) {
      return 'منذ $minutes دقيقة';
    } else {
      return 'الآن';
    }
  }

  /// ✅ Get user status text
  String get statusText {
    if (isBlocked) return 'محظور';
    if (!isActiveUser) return 'غير نشط';
    return 'نشط';
  }

  /// ✅ Get user status color
  Color get statusColor {
    if (isBlocked) return Colors.red;
    if (!isActiveUser) return Colors.orange;
    return Colors.green;
  }

  /// ✅ Get user status icon
  IconData get statusIcon {
    if (isBlocked) return Icons.block;
    if (!isActiveUser) return Icons.person_off;
    return Icons.check_circle;
  }

  /// ✅ Get email verified status
  String get emailVerifiedText {
    if (emailVerified == true) return '✅ مؤكد';
    return '❌ غير مؤكد';
  }

  /// ✅ Get phone verified status
  String get phoneVerifiedText {
    if (phoneVerified == true) return '✅ مؤكد';
    return '❌ غير مؤكد';
  }

  /// ✅ Check if user has complete profile
  bool get hasCompleteProfile {
    return name != null &&
        name!.isNotEmpty &&
        phone != null &&
        phone!.isNotEmpty;
  }

  /// ✅ Get profile completion percentage
  int get profileCompletion {
    int count = 0;
    final total = 6; // name, phone, avatar, company, department, jobTitle

    if (name != null && name!.isNotEmpty) count++;
    if (phone != null && phone!.isNotEmpty) count++;
    if (avatarUrl != null && avatarUrl!.isNotEmpty) count++;
    if (companyId != null && companyId!.isNotEmpty) count++;
    if (department != null && department!.isNotEmpty) count++;
    if (jobTitle != null && jobTitle!.isNotEmpty) count++;

    return (count / total * 100).round();
  }

  /// ✅ Get profile completion color
  Color get profileCompletionColor {
    final percentage = profileCompletion;
    if (percentage >= 80) return Colors.green;
    if (percentage >= 50) return Colors.orange;
    return Colors.red;
  }

  // ==================== VALIDATION ====================

  /// ✅ Check if user is valid
  bool get isValid {
    return id.isNotEmpty &&
        email.isNotEmpty &&
        email.contains('@') &&
        role != null &&
        role!.isNotEmpty;
  }

  /// ✅ Check if email is valid
  bool get hasValidEmail {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// ✅ Check if phone is valid (Egyptian format)
  bool get hasValidPhone {
    if (phone == null || phone!.isEmpty) return false;
    final cleaned = phone!.replaceAll(RegExp(r'[^0-9]'), '');
    return cleaned.length >= 10 && cleaned.length <= 15;
  }

  // ==================== OVERRIDES ====================

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppUser && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'AppUser(id: $id, email: $email, name: $name, role: $role, isActive: $isActive)';
  }
}

// =============================================
// ✅ USER ROLE ENUM
// =============================================
enum UserRole {
  admin('مدير', Icons.admin_panel_settings, Colors.red),
  manager('مدير قسم', Icons.manage_accounts, Colors.purple),
  supervisor('مشرف', Icons.supervisor_account, Colors.orange),
  employee('موظف', Icons.person, Colors.blue),
  guest('زائر', Icons.person_outline, Colors.grey);

  final String arabic;
  final IconData icon;
  final Color color;

  const UserRole(this.arabic, this.icon, this.color);

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase() || e.arabic == value,
      orElse: () => UserRole.employee,
    );
  }

  String get label => arabic;
}

// =============================================
// ✅ USER STATUS ENUM
// =============================================
enum UserStatus {
  active('نشط', Colors.green, Icons.check_circle),
  inactive('غير نشط', Colors.orange, Icons.person_off),
  blocked('محظور', Colors.red, Icons.block),
  pending('قيد الانتظار', Colors.blue, Icons.pending);

  final String arabic;
  final Color color;
  final IconData icon;

  const UserStatus(this.arabic, this.color, this.icon);

  static UserStatus fromString(String value) {
    return UserStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase() || e.arabic == value,
      orElse: () => UserStatus.active,
    );
  }

  String get label => arabic;
}

// =============================================
// ✅ USER FILTERS
// =============================================
class UserFilters {
  final String? searchQuery;
  final UserRole? role;
  final UserStatus? status;
  final bool? isActive;
  final bool? emailVerified;
  final bool? phoneVerified;
  final String? companyId;
  final String? department;
  final DateTime? createdAfter;
  final DateTime? createdBefore;
  final DateTime? lastLoginAfter;
  final DateTime? lastLoginBefore;
  final int? limit;
  final int? offset;
  final String? sortBy;
  final bool? sortAscending;

  UserFilters({
    this.searchQuery,
    this.role,
    this.status,
    this.isActive,
    this.emailVerified,
    this.phoneVerified,
    this.companyId,
    this.department,
    this.createdAfter,
    this.createdBefore,
    this.lastLoginAfter,
    this.lastLoginBefore,
    this.limit,
    this.offset,
    this.sortBy,
    this.sortAscending = true,
  });

  bool get hasFilters {
    return searchQuery != null ||
        role != null ||
        status != null ||
        isActive != null ||
        emailVerified != null ||
        phoneVerified != null ||
        companyId != null ||
        department != null ||
        createdAfter != null ||
        createdBefore != null ||
        lastLoginAfter != null ||
        lastLoginBefore != null;
  }

  UserFilters copyWith({
    String? searchQuery,
    UserRole? role,
    UserStatus? status,
    bool? isActive,
    bool? emailVerified,
    bool? phoneVerified,
    String? companyId,
    String? department,
    DateTime? createdAfter,
    DateTime? createdBefore,
    DateTime? lastLoginAfter,
    DateTime? lastLoginBefore,
    int? limit,
    int? offset,
    String? sortBy,
    bool? sortAscending,
  }) {
    return UserFilters(
      searchQuery: searchQuery ?? this.searchQuery,
      role: role ?? this.role,
      status: status ?? this.status,
      isActive: isActive ?? this.isActive,
      emailVerified: emailVerified ?? this.emailVerified,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      companyId: companyId ?? this.companyId,
      department: department ?? this.department,
      createdAfter: createdAfter ?? this.createdAfter,
      createdBefore: createdBefore ?? this.createdBefore,
      lastLoginAfter: lastLoginAfter ?? this.lastLoginAfter,
      lastLoginBefore: lastLoginBefore ?? this.lastLoginBefore,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};
    if (searchQuery != null && searchQuery!.isNotEmpty) {
      params['search'] = searchQuery;
    }
    if (role != null) {
      params['role'] = role!.name;
    }
    if (status != null) {
      params['status'] = status!.name;
    }
    if (isActive != null) {
      params['is_active'] = isActive;
    }
    if (emailVerified != null) {
      params['email_verified'] = emailVerified;
    }
    if (phoneVerified != null) {
      params['phone_verified'] = phoneVerified;
    }
    if (companyId != null) {
      params['company_id'] = companyId;
    }
    if (department != null) {
      params['department'] = department;
    }
    if (createdAfter != null) {
      params['created_after'] = createdAfter!.toIso8601String();
    }
    if (createdBefore != null) {
      params['created_before'] = createdBefore!.toIso8601String();
    }
    if (lastLoginAfter != null) {
      params['last_login_after'] = lastLoginAfter!.toIso8601String();
    }
    if (lastLoginBefore != null) {
      params['last_login_before'] = lastLoginBefore!.toIso8601String();
    }
    if (limit != null) {
      params['limit'] = limit;
    }
    if (offset != null) {
      params['offset'] = offset;
    }
    if (sortBy != null) {
      params['sort_by'] = sortBy;
    }
    if (sortAscending != null) {
      params['sort_ascending'] = sortAscending;
    }
    return params;
  }
}
