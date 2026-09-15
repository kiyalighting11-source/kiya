// lib/presentation/screens/users/users_screen.dart

import 'package:flutter/material.dart';

import '../../../data/models/user.dart';
import '../../../data/repositories/user_repository.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final UserRepository _repository = UserRepository();
  List<AppUser> _users = [];
  List<AppUser> _filteredUsers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'الكل';
  AppUser? _currentUser;

  final List<String> _filters = ['الكل', 'مدير', 'موظف', 'نشط', 'غير نشط'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final users = await _repository.getAllUsers();
      final currentUser = await _repository.getCurrentUser();
      if (mounted) {
        setState(() {
          _users = users;
          _filteredUsers = users;
          _currentUser = currentUser;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في جلب المستخدمين: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterUsers() {
    setState(() {
      List<AppUser> filtered = List.from(_users);

      switch (_selectedFilter) {
        case 'مدير':
          filtered = filtered.where((u) => u.isAdmin).toList();
          break;
        case 'موظف':
          filtered = filtered.where((u) => u.isEmployee).toList();
          break;
        case 'نشط':
          filtered = filtered.where((u) => u.isActiveUser).toList();
          break;
        case 'غير نشط':
          filtered = filtered.where((u) => !(u.isActive ?? true)).toList();
          break;
        default:
          break;
      }

      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        filtered = filtered
            .where(
              (u) =>
                  u.email.toLowerCase().contains(query) ||
                  (u.name?.toLowerCase().contains(query) ?? false) ||
                  (u.phone?.toLowerCase().contains(query) ?? false),
            )
            .toList();
      }

      _filteredUsers = filtered;
    });
  }

  // ✅ دالة مساعدة لعرض SnackBar بأمان
  void _showSnackBar(String message, {Color backgroundColor = Colors.green}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: backgroundColor),
      );
    }
  }

  Future<void> _changeUserRole(AppUser user) async {
    if (_currentUser?.id == user.id) {
      _showSnackBar('❌ لا يمكن تغيير دورك بنفسك', backgroundColor: Colors.red);
      return;
    }

    final newRole = user.isAdmin ? 'employee' : 'admin';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.isAdmin ? 'تحويل إلى موظف' : 'ترقية إلى مدير'),
        content: Text(
          user.isAdmin
              ? 'هل أنت متأكد من تحويل "${user.displayName}" إلى موظف؟'
              : 'هل أنت متأكد من ترقية "${user.displayName}" إلى مدير؟',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: user.isAdmin ? Colors.orange : Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(user.isAdmin ? 'تحويل' : 'ترقية'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _repository.updateUserRole(user.id, newRole);
        if (mounted) {
          await _loadData();
          _showSnackBar(
            user.isAdmin
                ? '✅ تم تحويل ${user.displayName} إلى موظف'
                : '✅ تم ترقية ${user.displayName} إلى مدير',
          );
        }
      } catch (e) {
        _showSnackBar('❌ خطأ: $e', backgroundColor: Colors.red);
      }
    }
  }

  Future<void> _toggleUserStatus(AppUser user) async {
    if (_currentUser?.id == user.id) {
      _showSnackBar(
        '❌ لا يمكن تغيير حالة حسابك بنفسك',
        backgroundColor: Colors.red,
      );
      return;
    }

    try {
      final newStatus = !(user.isActive ?? true);
      await _repository.toggleUserStatus(user.id, newStatus);
      if (mounted) {
        await _loadData();
        _showSnackBar(
          newStatus
              ? '✅ تم تفعيل ${user.displayName}'
              : '✅ تم تعطيل ${user.displayName}',
        );
      }
    } catch (e) {
      _showSnackBar('❌ خطأ: $e', backgroundColor: Colors.red);
    }
  }

  Future<void> _deleteUser(AppUser user) async {
    if (_currentUser?.id == user.id) {
      _showSnackBar('❌ لا يمكن حذف حسابك بنفسك', backgroundColor: Colors.red);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف "${user.displayName}"؟'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _repository.deleteUser(user.id);
        if (mounted) {
          setState(() {
            _users.removeWhere((u) => u.id == user.id);
            _filterUsers();
          });
          _showSnackBar('✅ تم حذف المستخدم بنجاح');
        }
      } catch (e) {
        _showSnackBar('❌ خطأ في الحذف: $e', backgroundColor: Colors.red);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المستخدمين', style: TextStyle(fontSize: 18)),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: Column(
        children: [
          // ===== شريط البحث والفلتر =====
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // البحث
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'بحث عن مستخدم...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                setState(() {
                                  _searchQuery = '';
                                  _filterUsers();
                                });
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                      _filterUsers();
                    },
                  ),
                ),
                const SizedBox(height: 8),

                // الفلاتر
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: FilterChip(
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedFilter = filter;
                              _filterUsers();
                            });
                          },
                          backgroundColor: Colors.grey.shade200,
                          selectedColor: Colors.red.shade100,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.red.shade700
                                : Colors.black,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          avatar: isSelected
                              ? Icon(
                                  Icons.check_circle,
                                  size: 16,
                                  color: Colors.red.shade700,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // ===== قائمة المستخدمين =====
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('جاري تحميل المستخدمين...'),
                      ],
                    ),
                  )
                : _filteredUsers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'لا توجد نتائج بحث'
                              : 'لا يوجد مستخدمين',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      final isCurrentUser = _currentUser?.id == user.id;

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // الصورة
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: user.roleColor.withValues(
                                  alpha: 0.2,
                                ),
                                child: Text(
                                  user.initials,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: user.roleColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // المعلومات
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          user.displayName,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        if (isCurrentUser)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'أنت',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.blue.shade700,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      user.email,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 2,
                                      children: [
                                        // الدور
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: user.roleColor.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            user.roleLabel,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: user.roleColor,
                                            ),
                                          ),
                                        ),
                                        // الحالة
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: (user.isActive ?? true)
                                                ? Colors.green.shade100
                                                : Colors.red.shade100,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            (user.isActive ?? true)
                                                ? 'نشط'
                                                : 'غير نشط',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: (user.isActive ?? true)
                                                  ? Colors.green.shade700
                                                  : Colors.red.shade700,
                                            ),
                                          ),
                                        ),
                                        if (user.phone != null)
                                          Text(
                                            '📱 ${user.phone}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // قائمة الخيارات
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert),
                                onSelected: (value) {
                                  switch (value) {
                                    case 'role':
                                      _changeUserRole(user);
                                      break;
                                    case 'status':
                                      _toggleUserStatus(user);
                                      break;
                                    case 'delete':
                                      _deleteUser(user);
                                      break;
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'role',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.security,
                                          color: Colors.blue,
                                        ),
                                        SizedBox(width: 8),
                                        Text('تغيير الدور'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'status',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.power_settings_new,
                                          color: Colors.orange,
                                        ),
                                        SizedBox(width: 8),
                                        Text('تغيير الحالة'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('حذف'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
