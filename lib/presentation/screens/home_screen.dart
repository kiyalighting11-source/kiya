// lib/presentation/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import '../../data/models/attendance.dart';
import '../../data/models/user.dart';
import '../../data/repositories/attendance_repository.dart';
import '../../data/repositories/user_repository.dart';

// ✅ تم إزالة الاستيرادات غير المستخدمة:
// import './attendance/attendance_screen.dart';
// import './attendance/attendance_history.dart';
// import './attendance/admin_attendance.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // =============================================
  // ✅ STATE VARIABLES
  // =============================================
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;

  // User Data
  AppUser? _currentUser;
  String? _userRole;
  String? _userName;
  String? _userAvatar;

  // Attendance Data
  Attendance? _todayAttendance;
  List<Attendance> _recentAttendance = [];
  AttendanceSummary? _todaySummary;

  // Stats
  Map<String, dynamic> _stats = {};

  // Services
  final AttendanceRepository _attendanceRepo = AttendanceRepository();
  final UserRepository _userRepo = UserRepository();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // =============================================
  // ✅ LOAD DATA
  // =============================================
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('يرجى تسجيل الدخول أولاً');
      }

      await _loadUserData(user.id);
      await _loadAttendanceData(user.id);
      await _loadStatistics();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading home data: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _loadUserData(String userId) async {
    try {
      final userData = await _userRepo.getUserById(userId);
      if (userData != null) {
        _currentUser = userData;
        _userRole = userData.role;
        _userName = userData.name;
        _userAvatar = userData.avatarUrl;
      }
    } catch (e) {
      debugPrint('❌ Error loading user data: $e');
    }
  }

  Future<void> _loadAttendanceData(String userId) async {
    try {
      _todayAttendance = await _attendanceRepo.getTodayAttendance(userId);
      _recentAttendance = await _attendanceRepo.getAttendanceHistory(
        employeeId: userId,
        limit: 5,
      );

      if (_userRole == 'admin') {
        _todaySummary = await _attendanceRepo.getAttendanceSummary(
          date: DateTime.now(),
        );
      }
    } catch (e) {
      debugPrint('❌ Error loading attendance data: $e');
    }
  }

  Future<void> _loadStatistics() async {
    try {
      if (_currentUser != null) {
        _stats = await _attendanceRepo.getEmployeeStats(_currentUser!.id);
      }
    } catch (e) {
      debugPrint('❌ Error loading statistics: $e');
    }
  }

  // =============================================
  // ✅ REFRESH DATA
  // =============================================
  Future<void> _refreshData() async {
    setState(() {
      _isRefreshing = true;
      _errorMessage = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await _loadUserData(user.id);
        await _loadAttendanceData(user.id);
        await _loadStatistics();
      }
    } catch (e) {
      debugPrint('❌ Error refreshing data: $e');
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  // =============================================
  // ✅ LOGOUT
  // =============================================
  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await Supabase.instance.client.auth.signOut();
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      } catch (e) {
        debugPrint('❌ Logout error: $e');
        _showSnackBar('حدث خطأ أثناء تسجيل الخروج', Colors.red);
      }
    }
  }

  // =============================================
  // ✅ SHOW SNACKBAR
  // =============================================
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // =============================================
  // ✅ BUILD UI
  // =============================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: _isLoading
          ? _buildLoadingWidget()
          : _errorMessage != null
          ? _buildErrorWidget()
          : RefreshIndicator(
              onRefresh: _refreshData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildWelcomeCard(),
                    const SizedBox(height: 16),
                    _buildQuickActionsGrid(),
                    const SizedBox(height: 16),
                    if (_userRole == 'admin') _buildSummaryCard(),
                    const SizedBox(height: 16),
                    _buildAttendanceStatus(),
                    const SizedBox(height: 16),
                    _buildRecentHistory(),
                    const SizedBox(height: 16),
                    _buildStatsCard(),
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
      title: const Text('الرئيسية'),
      backgroundColor: const Color(0xFF2563EB),
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {
            _showSnackBar('قريباً - صفحة الإشعارات', Colors.blue);
          },
        ),
        IconButton(
          icon: _isRefreshing
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.refresh),
          onPressed: _isRefreshing ? null : _refreshData,
        ),
      ],
    );
  }

  // =============================================
  // ✅ LOADING WIDGET
  // =============================================
  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
          ),
          SizedBox(height: 16),
          Text(
            'جاري تحميل البيانات...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // =============================================
  // ✅ ERROR WIDGET
  // =============================================
  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              'حدث خطأ',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
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

  // =============================================
  // ✅ WELCOME CARD
  // =============================================
  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF2563EB), const Color(0xFF3B82F6)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: _userAvatar != null
                ? ClipOval(
                    child: Image.network(
                      _userAvatar!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildAvatarText();
                      },
                    ),
                  )
                : _buildAvatarText(),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مرحباً، $_userName',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _userRole == 'admin' ? 'مدير النظام' : 'موظف',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('EEEE، d MMMM y', 'ar').format(DateTime.now()),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarText() {
    return Center(
      child: Text(
        _userName?.substring(0, 1).toUpperCase() ?? 'م',
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  // =============================================
  // ✅ QUICK ACTIONS GRID
  // =============================================
  Widget _buildQuickActionsGrid() {
    final List<QuickAction> actions = [
      QuickAction(
        icon: Icons.access_time,
        label: 'الحضور والانصراف',
        color: Colors.blue,
        route: '/attendance',
        onTap: () => Navigator.pushNamed(context, '/attendance'),
      ),
      QuickAction(
        icon: Icons.history,
        label: 'سجل الحضور',
        color: Colors.orange,
        route: '/attendance-history',
        onTap: () => Navigator.pushNamed(context, '/attendance-history'),
      ),
    ];

    if (_userRole == 'admin') {
      actions.addAll([
        QuickAction(
          icon: Icons.admin_panel_settings,
          label: 'لوحة الإدارة',
          color: Colors.purple,
          route: '/admin-attendance',
          onTap: () => Navigator.pushNamed(context, '/admin-attendance'),
        ),
        QuickAction(
          icon: Icons.people,
          label: 'إدارة الموظفين',
          color: Colors.teal,
          route: '/employees',
          onTap: () => _showSnackBar('قريباً - إدارة الموظفين', Colors.blue),
        ),
      ]);
    }

    actions.addAll([
      QuickAction(
        icon: Icons.settings,
        label: 'الإعدادات',
        color: Colors.grey,
        route: '/settings',
        onTap: () => _showSnackBar('قريباً - الإعدادات', Colors.blue),
      ),
      QuickAction(
        icon: Icons.logout,
        label: 'تسجيل الخروج',
        color: Colors.red,
        route: '/logout',
        onTap: _logout,
      ),
    ]);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return _buildQuickAction(action);
      },
    );
  }

  Widget _buildQuickAction(QuickAction action) {
    return InkWell(
      onTap: action.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: action.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(action.icon, color: action.color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              action.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // =============================================
  // ✅ SUMMARY CARD (ADMIN)
  // =============================================
  Widget _buildSummaryCard() {
    if (_todaySummary == null) return const SizedBox.shrink();

    final summary = _todaySummary!;

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.today, color: Color(0xFF2563EB), size: 20),
              SizedBox(width: 8),
              Text(
                'ملخص اليوم',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildSummaryItem('✅ حاضر', '${summary.present}', Colors.green),
              _buildSummaryItem('⚠️ متأخر', '${summary.late}', Colors.orange),
              _buildSummaryItem('❌ غائب', '${summary.absent}', Colors.red),
              _buildSummaryItem('📅 إجازة', '${summary.onLeave}', Colors.blue),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'إجمالي الموظفين: ${summary.totalEmployees}',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              Text(
                'نسبة الحضور: ${summary.formattedPercentage}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: summary.attendancePercentage >= 80
                      ? Colors.green
                      : summary.attendancePercentage >= 50
                      ? Colors.orange
                      : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // =============================================
  // ✅ ATTENDANCE STATUS
  // =============================================
  Widget _buildAttendanceStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.fingerprint, color: Color(0xFF2563EB), size: 20),
              SizedBox(width: 8),
              Text(
                'حالة الحضور اليوم',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_todayAttendance != null) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _todayAttendance!.status.color.withValues(
                      alpha: 0.1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _todayAttendance!.status.icon,
                    color: _todayAttendance!.status.color,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _todayAttendance!.status.arabic,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _todayAttendance!.status.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '⏰ الحضور: ${_todayAttendance!.formattedCheckIn}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      if (_todayAttendance!.isCheckedOut)
                        Text(
                          '⏰ الانصراف: ${_todayAttendance!.formattedCheckOut}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        )
                      else
                        Text(
                          '⏳ لم تنصرف بعد',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.orange.shade700,
                          ),
                        ),
                    ],
                  ),
                ),
                if (_todayAttendance!.isCheckedOut)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '🕐 المدة',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.green.shade700,
                          ),
                        ),
                        Text(
                          _todayAttendance!.formattedDuration,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.access_time,
                    color: Colors.grey,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'لم تسجل حضورك اليوم',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'اضغط على "الحضور والانصراف" للتسجيل',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // =============================================
  // ✅ RECENT HISTORY
  // =============================================
  Widget _buildRecentHistory() {
    if (_recentAttendance.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
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
        child: const Column(
          children: [
            Icon(Icons.history, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'لا يوجد سجل حضور',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.history, color: Color(0xFF2563EB), size: 20),
                SizedBox(width: 8),
                Text(
                  'آخر 5 سجلات حضور',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          ..._recentAttendance.map((item) {
            return ListTile(
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: item.status.color.withValues(alpha: 0.1),
                child: Icon(
                  item.status.icon,
                  color: item.status.color,
                  size: 18,
                ),
              ),
              title: Text(
                item.formattedDate,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                '${item.formattedCheckIn} - ${item.formattedCheckOut}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: item.status.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.status.arabic,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: item.status.color,
                  ),
                ),
              ),
              onTap: () {
                _showAttendanceDetails(item);
              },
            );
          }),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Center(
              child: TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/attendance-history');
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF2563EB),
                ),
                child: const Text('عرض كل السجلات'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =============================================
  // ✅ STATS CARD
  // =============================================
  Widget _buildStatsCard() {
    final totalDays = _stats['totalDays'] ?? 0;
    final presentDays = _stats['presentDays'] ?? 0;
    final attendanceRate = _stats['attendanceRate'] ?? '0';
    final totalWorkHours = _stats['totalWorkHours'] ?? '0';

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 إحصائيات الشهر',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatItem('أيام العمل', '$totalDays', Colors.blue),
              _buildStatItem('أيام الحضور', '$presentDays', Colors.green),
              _buildStatItem(
                'نسبة الحضور',
                '$attendanceRate%',
                _getAttendanceRateColor(attendanceRate),
              ),
              _buildStatItem('ساعات العمل', '$totalWorkHours س', Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  Color _getAttendanceRateColor(String rate) {
    try {
      final value = double.parse(rate);
      if (value >= 80) return Colors.green;
      if (value >= 50) return Colors.orange;
      return Colors.red;
    } catch (_) {
      return Colors.grey;
    }
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
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
      builder: (context) {
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
                    padding: const EdgeInsets.all(8),
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
                  Text(
                    'تفاصيل الحضور',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: item.status.color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDetailRow('الموظف', item.employeeName ?? 'غير معروف'),
              _buildDetailRow('التاريخ', item.formattedDate),
              _buildDetailRow('وقت الحضور', item.formattedCheckIn),
              _buildDetailRow('وقت الانصراف', item.formattedCheckOut),
              _buildDetailRow('مدة العمل', item.formattedDuration),
              _buildDetailRow('الحالة', item.status.arabic),
              _buildDetailRow('الموقع', item.locationDisplay),
              if (item.notes != null && item.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '📝 ملاحظات: ${item.notes}',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
              ],
              const SizedBox(height: 16),
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
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// =============================================
// ✅ QUICK ACTION MODEL
// =============================================
class QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final String route;
  final VoidCallback onTap;

  QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.route,
    required this.onTap,
  });
}
