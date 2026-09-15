// lib/presentation/screens/dashboard_screen.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/app_branding.dart';
import '../../app/app_routes.dart';
import '../../app/app_state.dart';

// ===== SCREENS =====
import 'attendance/admin_attendance.dart';
import 'attendance/attendance_history.dart';
import 'attendance/attendance_screen.dart';
import 'customers_screen.dart';
import 'invoices/invoices_screen.dart';
import 'products/products_screen.dart';
import 'reports/reports_screen.dart'; // ✅ NEW
import 'settings/language_screen.dart';
import 'users/users_screen.dart';
import 'warehouses/warehouses_screen.dart';

// ===== BROADCAST =====
import '../../features/broadcast/screens/broadcast_screen.dart';

// =============================================
// ✅ DASHBOARD SCREEN
// =============================================
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  // =============================================
  // ✅ USER DATA
  // =============================================
  String _userEmail = '';
  String _userRole = 'employee';
  String _userName = '';
  String _userAvatar = '';
  bool _isLoading = true;
  bool _isDarkMode = false;

  // =============================================
  // ✅ STATISTICS
  // =============================================
  int _totalCustomers = 0;
  int _totalProducts = 0;
  int _totalInvoices = 0;
  int _totalUsers = 0;
  double _totalRevenue = 0;
  int _totalQuotations = 0;

  // =============================================
  // ✅ ATTENDANCE
  // =============================================
  int _totalAttendance = 0;
  int _totalAbsence = 0;
  String _attendanceRate = '0%';
  double _attendanceRateValue = 0;
  int _lateCount = 0;
  int _onLeaveCount = 0;

  // =============================================
  // ✅ CHART
  // =============================================
  List<double> _monthlyRevenue = List.filled(6, 0);

  // =============================================
  // ✅ RECENT ACTIVITIES
  // =============================================
  List<Map<String, dynamic>> _recentActivities = [];

  // =============================================
  // ✅ WHATSAPP
  // =============================================
  static const String _whatsappNumber = '+201026265026';

  // =============================================
  // ✅ ANIMATIONS
  // =============================================
  late AnimationController _animationController;
  late AnimationController _counterController;
  late Animation<double> _fadeAnimation;

  // =============================================
  // ✅ SCROLL
  // =============================================
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTop = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _counterController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPreferences();
      _loadData();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _counterController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 400 && !_showBackToTop) {
      setState(() => _showBackToTop = true);
    } else if (_scrollController.offset <= 400 && _showBackToTop) {
      setState(() => _showBackToTop = false);
    }
  }

  // =============================================
  // ✅ LOAD FUNCTIONS
  // =============================================
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _isDarkMode = prefs.getBool('dark_mode') ?? false;
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    await Future.wait([
      _loadUserData(),
      _loadCustomersCount(),
      _loadProductsCount(),
      _loadInvoicesCount(),
      _loadUsersCount(),
      _loadAttendanceStats(),
      _loadRevenueStats(),
      _loadMonthlyRevenue(),
      _loadRecentActivities(),
    ]);

    if (!mounted) return;
    setState(() => _isLoading = false);

    _animationController.forward(from: 0);
    _counterController.forward(from: 0);
  }

  Future<void> _loadUserData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      if (mounted) {
        setState(() => _userEmail = user.email ?? '');
      }

      final response = await Supabase.instance.client
          .from('users')
          .select('role, name, avatar_url')
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted || response == null) return;
      setState(() {
        _userRole = response['role'] ?? 'employee';
        _userName =
            response['name'] ?? user.email?.split('@').first ?? 'employee'.tr();
        _userAvatar = response['avatar_url'] ?? '';
      });
    } catch (e) {
      debugPrint('❌ Error loading user data: $e');
    }
  }

  Future<void> _loadCustomersCount() async {
    try {
      final response = await Supabase.instance.client
          .from('customers')
          .select('id');
      if (!mounted) return;
      setState(() => _totalCustomers = response.length);
    } catch (e) {
      debugPrint('❌ Error loading customers count: $e');
    }
  }

  Future<void> _loadProductsCount() async {
    try {
      final response = await Supabase.instance.client
          .from('products')
          .select('id');
      if (!mounted) return;
      setState(() => _totalProducts = response.length);
    } catch (e) {
      debugPrint('❌ Error loading products count: $e');
    }
  }

  Future<void> _loadInvoicesCount() async {
    try {
      final response = await Supabase.instance.client
          .from('invoices')
          .select('id, status');

      int invoices = 0;
      int quotations = 0;

      for (var item in response) {
        final status = item['status'] ?? 'draft';
        if (status == 'quotation' || status == 'expired') {
          quotations++;
        } else if (status != 'cancelled' && status != 'returned') {
          invoices++;
        }
      }

      if (!mounted) return;
      setState(() {
        _totalInvoices = invoices;
        _totalQuotations = quotations;
      });
    } catch (e) {
      debugPrint('❌ Error loading invoices count: $e');
    }
  }

  Future<void> _loadUsersCount() async {
    try {
      final response = await Supabase.instance.client
          .from('users')
          .select('id')
          .eq('is_active', true);
      if (!mounted) return;
      setState(() => _totalUsers = response.length);
    } catch (e) {
      debugPrint('❌ Error loading users count: $e');
    }
  }

  Future<void> _loadAttendanceStats() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      final response = await Supabase.instance.client
          .from('attendance')
          .select('status')
          .eq('employee_id', user.id)
          .gte('check_in', startOfMonth.toIso8601String())
          .lte('check_in', endOfMonth.toIso8601String());

      int present = 0;
      int absent = 0;
      int late = 0;
      int onLeave = 0;

      for (var item in response) {
        final status = item['status'] ?? 'present';
        switch (status) {
          case 'present':
            present++;
            break;
          case 'late':
            late++;
            present++;
            break;
          case 'on_leave':
            onLeave++;
            present++;
            break;
          default:
            absent++;
        }
      }

      final total = present + absent;
      final rate = total > 0 ? (present / total * 100) : 0.0;

      if (!mounted) return;
      setState(() {
        _totalAttendance = present;
        _totalAbsence = absent;
        _attendanceRateValue = rate;
        _attendanceRate = '${rate.toStringAsFixed(1)}%';
        _lateCount = late;
        _onLeaveCount = onLeave;
      });
    } catch (e) {
      debugPrint('❌ Error loading attendance stats: $e');
    }
  }

  Future<void> _loadRevenueStats() async {
    try {
      final response = await Supabase.instance.client
          .from('invoices')
          .select('total')
          .inFilter('status', ['confirmed', 'completed']);

      double total = 0;
      for (var item in response) {
        final amount = item['total'];
        if (amount is double) {
          total += amount;
        } else if (amount is int) {
          total += amount.toDouble();
        }
      }

      if (!mounted) return;
      setState(() => _totalRevenue = total);
    } catch (e) {
      debugPrint('❌ Error loading revenue stats: $e');
    }
  }

  Future<void> _loadMonthlyRevenue() async {
    try {
      final now = DateTime.now();
      final List<double> monthly = List.filled(6, 0);

      final firstMonth = DateTime(now.year, now.month - 5, 1);

      final response = await Supabase.instance.client
          .from('invoices')
          .select('total, date, status')
          .inFilter('status', ['confirmed', 'completed'])
          .gte('date', firstMonth.toIso8601String());

      for (var item in response) {
        final dateStr = item['date'];
        if (dateStr == null) continue;

        final date = DateTime.tryParse(dateStr.toString());
        if (date == null) continue;

        final monthsDiff =
            (now.year - date.year) * 12 + (now.month - date.month);
        if (monthsDiff < 0 || monthsDiff > 5) continue;

        final index = 5 - monthsDiff;
        final amount = item['total'];
        if (amount is double) {
          monthly[index] += amount;
        } else if (amount is int) {
          monthly[index] += amount.toDouble();
        }
      }

      if (!mounted) return;
      setState(() => _monthlyRevenue = monthly);
    } catch (e) {
      debugPrint('❌ Error loading monthly revenue: $e');
    }
  }

  Future<void> _loadRecentActivities() async {
    try {
      final List<Map<String, dynamic>> activities = [];

      // Latest invoices
      try {
        final invoices = await Supabase.instance.client
            .from('invoices')
            .select(
              'id, invoice_number, customer_id, total, status, created_at',
            )
            .order('created_at', ascending: false)
            .limit(3);

        for (var inv in invoices) {
          activities.add({
            'type': 'invoice',
            'title': 'dashboard.new_invoice'.tr(),
            'description':
                '${'invoices.invoice_number'.tr()} ${inv['invoice_number']} - \$${inv['total']?.toStringAsFixed(2) ?? 0}',
            'time': inv['created_at'],
            'icon': Icons.receipt_long,
            'color': AppBranding.success,
          });
        }
      } catch (e) {
        debugPrint('❌ Error loading invoices: $e');
      }

      // Latest customers
      try {
        final customers = await Supabase.instance.client
            .from('customers')
            .select('id, name, created_at')
            .order('created_at', ascending: false)
            .limit(3);

        for (var cust in customers) {
          activities.add({
            'type': 'customer',
            'title': 'dashboard.new_customer'.tr(),
            'description': cust['name'] ?? 'common.unknown'.tr(),
            'time': cust['created_at'],
            'icon': Icons.person_add,
            'color': AppBranding.primary,
          });
        }
      } catch (e) {
        debugPrint('❌ Error loading customers: $e');
      }

      activities.sort((a, b) {
        final timeA = a['time'] != null
            ? DateTime.parse(a['time'])
            : DateTime.now();
        final timeB = b['time'] != null
            ? DateTime.parse(b['time'])
            : DateTime.now();
        return timeB.compareTo(timeA);
      });

      if (!mounted) return;
      setState(() => _recentActivities = activities.take(6).toList());
    } catch (e) {
      debugPrint('❌ Error loading recent activities: $e');
    }
  }

  // =============================================
  // ✅ WHATSAPP
  // =============================================
  Future<void> _openWhatsApp() async {
    final cleanNumber = _whatsappNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final message = 'dashboard.whatsapp_message'.tr();
    final encodedMessage = Uri.encodeComponent(message);
    final whatsappUrl = 'https://wa.me/$cleanNumber?text=$encodedMessage';

    try {
      final Uri url = Uri.parse(whatsappUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        final webUrl =
            'https://web.whatsapp.com/send?phone=$cleanNumber&text=$encodedMessage';
        if (await canLaunchUrl(Uri.parse(webUrl))) {
          await launchUrl(
            Uri.parse(webUrl),
            mode: LaunchMode.externalApplication,
          );
        } else {
          if (!mounted) return;
          _showErrorDialog('dashboard.whatsapp_error'.tr());
        }
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('${'common.error'.tr()}: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('common.error'.tr()),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common.ok'.tr()),
          ),
        ],
      ),
    );
  }

  // =============================================
  // ✅ LOGOUT
  // =============================================
  Future<void> _logout() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('auth.logout'.tr()),
        content: Text('auth.logout_confirm'.tr()),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'common.cancel'.tr(),
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppBranding.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('auth.logout'.tr()),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    try {
      setState(() => _isLoading = true);

      await Supabase.instance.client.auth.signOut();

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      navigator.pushReplacementNamed(AppRoutes.login);
    } catch (e) {
      debugPrint('❌ Logout error: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text('${'common.error'.tr()}: $e'),
          backgroundColor: AppBranding.danger,
        ),
      );
    }
  }

  // =============================================
  // ✅ THEME
  // =============================================
  Future<void> _toggleTheme() async {
    final appState = Provider.of<AppState>(context, listen: false);

    await appState.toggleTheme();

    if (!mounted) return;
    setState(() => _isDarkMode = appState.isDarkMode);
  }

  // =============================================
  // ✅ NAVIGATION
  // =============================================
  void _navigateTo(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
    );
  }

  // =============================================
  // ✅ LANGUAGE CHANGE
  // =============================================
  Future<void> _handleLanguageChange(Locale locale) async {
    if (!mounted) return;

    final appState = Provider.of<AppState>(context, listen: false);

    try {
      debugPrint('🌍 Changing language to: ${locale.languageCode}');

      await context.setLocale(locale);
      await appState.setLocale(locale.languageCode);

      if (!mounted) return;
      setState(() {});

      debugPrint('✅ Language changed successfully');
    } catch (e) {
      debugPrint('❌ Error changing language: $e');
    }
  }

  // =============================================
  // ✅ BUILD
  // =============================================
  @override
  Widget build(BuildContext context) {
    final isAdmin = _userRole == 'admin';
    final isDark = _isDarkMode;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      appBar: _buildAppBar(isAdmin, isDark),
      body: _isLoading ? _buildLoading(isDark) : _buildBody(isAdmin, isDark),
    );
  }

  // =============================================
  // ✅ APP BAR
  // =============================================
  PreferredSizeWidget _buildAppBar(bool isAdmin, bool isDark) {
    return AppBar(
      elevation: 0,
      backgroundColor: AppBranding.primary,
      foregroundColor: Colors.white,
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.dashboard_rounded, size: 18),
          ),
          const SizedBox(width: 10),
          const Text(
            'Kiya System',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isAdmin
                  ? '👑 ${'dashboard.admin'.tr()}'
                  : '👤 ${'dashboard.employee'.tr()}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      actions: [
        // ===== REPORTS (ADMIN ONLY) =====
        if (isAdmin)
          _appBarIcon(
            icon: Icons.assessment,
            onTap: () => _navigateTo(const ReportsScreen()),
            tooltip: 'التقارير',
          ),

        // ===== LANGUAGE =====
        PopupMenuButton<Locale>(
          icon: const Icon(Icons.language, size: 20),
          tooltip: 'settings.language'.tr(),
          onSelected: _handleLanguageChange,
          itemBuilder: (context) => [
            _languageItem('ar', 'العربية', '🇪🇬'),
            _languageItem('en', 'English', '🇺🇸'),
            _languageItem('zh', '中文', '🇨🇳'),
          ],
        ),

        // ===== THEME =====
        _appBarIcon(
          icon: isDark ? Icons.light_mode : Icons.dark_mode,
          onTap: _toggleTheme,
          tooltip: 'settings.theme'.tr(),
        ),

        // ===== WHATSAPP =====
        _appBarIcon(
          icon: Icons.message_rounded,
          onTap: _openWhatsApp,
          tooltip: 'dashboard.whatsapp'.tr(),
        ),

        // ===== BROADCAST =====
        _appBarIcon(
          icon: Icons.send_and_archive,
          onTap: () => _navigateTo(const BroadcastScreen()),
          tooltip: 'dashboard.broadcast'.tr(),
        ),

        // ===== ATTENDANCE (Employee) =====
        if (!isAdmin)
          _appBarIcon(
            icon: Icons.access_time_rounded,
            onTap: () => _navigateTo(const AttendanceScreen()),
            tooltip: 'attendance.title'.tr(),
          ),

        // ===== ADMIN PANEL =====
        if (isAdmin)
          _appBarIcon(
            icon: Icons.admin_panel_settings,
            onTap: () => _navigateTo(const AdminAttendanceScreen()),
            tooltip: 'attendance.admin_panel'.tr(),
          ),

        // ===== REFRESH =====
        _appBarIcon(
          icon: Icons.refresh_rounded,
          onTap: _loadData,
          tooltip: 'common.refresh'.tr(),
        ),

        // ===== LOGOUT =====
        _appBarIcon(
          icon: Icons.logout_rounded,
          onTap: _logout,
          tooltip: 'auth.logout'.tr(),
        ),

        const SizedBox(width: 4),
      ],
    );
  }

  PopupMenuItem<Locale> _languageItem(String code, String name, String flag) {
    final isSelected = context.locale.languageCode == code;
    return PopupMenuItem<Locale>(
      value: Locale(code),
      child: Row(
        children: [
          Text(flag, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Text(name),
          if (isSelected) ...[
            const Spacer(),
            const Icon(Icons.check, color: AppBranding.success, size: 18),
          ],
        ],
      ),
    );
  }

  Widget _appBarIcon({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: IconButton(
        icon: Icon(icon, size: 20),
        onPressed: onTap,
        tooltip: tooltip,
        splashRadius: 20,
        padding: const EdgeInsets.all(6),
        constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
      ),
    );
  }

  // =============================================
  // ✅ LOADING
  // =============================================
  Widget _buildLoading(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppBranding.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppBranding.primary),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'common.loading'.tr(),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // =============================================
  // ✅ BODY
  // =============================================
  Widget _buildBody(bool isAdmin, bool isDark) {
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _loadData,
          color: AppBranding.primary,
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            physics: const AlwaysScrollableScrollPhysics(),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _animatedSection(0, _buildWelcomeCard(isDark)),
                  const SizedBox(height: 24),
                  _animatedSection(1, _buildStatsSection(isAdmin, isDark)),
                  const SizedBox(height: 24),
                  if (isAdmin) ...[
                    _animatedSection(2, _buildChartSection(isDark)),
                    const SizedBox(height: 24),
                  ],
                  _animatedSection(isAdmin ? 3 : 2, _buildQuickActions(isDark)),
                  const SizedBox(height: 24),
                  if (!isAdmin) ...[
                    _animatedSection(3, _buildAttendanceStatusCard(isDark)),
                    const SizedBox(height: 24),
                  ],
                  // ✅ Reports Section (Admin Only)
                  if (isAdmin) ...[
                    _animatedSection(4, _buildReportsSection(isDark)),
                    const SizedBox(height: 24),
                  ],
                  _animatedSection(
                    isAdmin ? 5 : 4,
                    _buildWhatsAppSupportCard(isDark),
                  ),
                  const SizedBox(height: 24),
                  _animatedSection(
                    isAdmin ? 6 : 5,
                    _buildMenuSection(isAdmin, isDark),
                  ),
                  if (_recentActivities.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _animatedSection(
                      isAdmin ? 7 : 6,
                      _buildRecentActivities(isDark),
                    ),
                  ],
                  const SizedBox(height: 24),
                  _animatedSection(isAdmin ? 8 : 7, _buildSystemInfo(isDark)),
                ],
              ),
            ),
          ),
        ),
        if (_showBackToTop)
          Positioned(
            bottom: 20,
            right: 20,
            child: ScaleTransition(
              scale: _fadeAnimation,
              child: FloatingActionButton(
                mini: true,
                onPressed: _scrollToTop,
                backgroundColor: AppBranding.primary,
                foregroundColor: Colors.white,
                elevation: 6,
                child: const Icon(Icons.arrow_upward, size: 20),
              ),
            ),
          ),
      ],
    );
  }

  Widget _animatedSection(int index, Widget child) {
    final start = (index * 0.08).clamp(0.0, 0.6);
    final end = (start + 0.4).clamp(0.0, 1.0);

    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _animationController,
        curve: Interval(start, end, curve: Curves.easeOut),
      ),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
            .animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Interval(start, end, curve: Curves.easeOutCubic),
              ),
            ),
        child: child,
      ),
    );
  }

  // =============================================
  // ✅ REPORTS SECTION (NEW)
  // =============================================
  Widget _buildReportsSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('📊', 'التقارير السريعة'),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.indigo.withValues(alpha: isDark ? 0.2 : 0.08),
                Colors.indigo.withValues(alpha: isDark ? 0.1 : 0.03),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.indigo.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.assessment,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'نظام التقارير المتقدم',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : Colors.indigo.shade900,
                          ),
                        ),
                        Text(
                          'تقارير مفصلة + تصدير PDF و Excel',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Report type shortcuts
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildReportChip('مبيعات', Icons.trending_up, Colors.green),
                  _buildReportChip('مخزون', Icons.warehouse, Colors.teal),
                  _buildReportChip('أرباح', Icons.attach_money, Colors.amber),
                  _buildReportChip('عملاء', Icons.people, Colors.purple),
                  _buildReportChip('حضور', Icons.access_time, Colors.indigo),
                  _buildReportChip('منتجات', Icons.inventory_2, Colors.orange),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _navigateTo(const ReportsScreen()),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text(
                    'فتح صفحة التقارير',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReportChip(String label, IconData icon, Color color) {
    return GestureDetector(
      onTap: () => _navigateTo(const ReportsScreen()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
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
  Widget _buildWelcomeCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppBranding.primaryDark,
            AppBranding.primary,
            AppBranding.primaryLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppBranding.primary.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: -40,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.9),
                      Colors.white.withValues(alpha: 0.4),
                    ],
                  ),
                ),
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white,
                  backgroundImage: _userAvatar.isNotEmpty
                      ? NetworkImage(_userAvatar)
                      : null,
                  child: _userAvatar.isEmpty
                      ? Text(
                          _userName.isNotEmpty
                              ? _userName[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            fontSize: 26,
                            color: AppBranding.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${'dashboard.welcome'.tr()} $_userName 👋',
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat(
                            'EEEE، d MMMM y',
                            context.locale.languageCode,
                          ).format(DateTime.now()),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _pillBadge(
                          icon: _userRole == 'admin'
                              ? Icons.admin_panel_settings
                              : Icons.person,
                          label: _userRole == 'admin'
                              ? 'dashboard.admin'.tr()
                              : 'dashboard.employee'.tr(),
                        ),
                        const SizedBox(width: 6),
                        _pillBadge(
                          icon: Icons.check_circle,
                          label: 'common.active'.tr(),
                          color: AppBranding.success,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pillBadge({
    required IconData icon,
    required String label,
    Color? color,
  }) {
    final bg = color ?? Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bg.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // =============================================
  // ✅ STATS SECTION
  // =============================================
  Widget _buildStatsSection(bool isAdmin, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          '📊',
          'dashboard.quick_stats'.tr(),
          trailing: _lastUpdatedChip(isDark),
        ),
        const SizedBox(height: 14),
        if (isAdmin) ...[
          Row(
            children: [
              _buildStatCard(
                title: 'dashboard.customers'.tr(),
                value: _totalCustomers.toDouble(),
                icon: Icons.people_alt,
                color: AppBranding.primary,
                isDark: isDark,
                onTap: () => _navigateTo(const CustomersScreen()),
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                title: 'dashboard.products'.tr(),
                value: _totalProducts.toDouble(),
                icon: Icons.inventory_2,
                color: AppBranding.success,
                isDark: isDark,
                onTap: () => _navigateTo(const ProductsScreen()),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatCard(
                title: 'dashboard.invoices'.tr(),
                value: _totalInvoices.toDouble(),
                icon: Icons.receipt_long,
                color: AppBranding.purple,
                isDark: isDark,
                onTap: () => _navigateTo(const InvoicesScreen()),
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                title: 'dashboard.revenue'.tr(),
                value: _totalRevenue,
                prefix: '\$',
                icon: Icons.attach_money,
                color: AppBranding.warning,
                isDark: isDark,
                onTap: () => _navigateTo(const InvoicesScreen()),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatCard(
                title: 'dashboard.users'.tr(),
                value: _totalUsers.toDouble(),
                icon: Icons.admin_panel_settings,
                color: AppBranding.pink,
                isDark: isDark,
                onTap: () => _navigateTo(const UsersScreen()),
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                title: 'dashboard.quotations'.tr(),
                value: _totalQuotations.toDouble(),
                icon: Icons.description,
                color: AppBranding.cyan,
                isDark: isDark,
                onTap: () => _navigateTo(const InvoicesScreen()),
              ),
            ],
          ),
        ] else ...[
          Row(
            children: [
              _buildStatCard(
                title: 'dashboard.customers'.tr(),
                value: _totalCustomers.toDouble(),
                icon: Icons.people_alt,
                color: AppBranding.primary,
                isDark: isDark,
                onTap: () => _navigateTo(const CustomersScreen()),
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                title: 'dashboard.attendance'.tr(),
                value: _totalAttendance.toDouble(),
                icon: Icons.access_time,
                color: AppBranding.cyan,
                isDark: isDark,
                onTap: () => _navigateTo(const AttendanceHistoryScreen()),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatCard(
                title: 'dashboard.attendance_rate'.tr(),
                value: _attendanceRateValue,
                suffix: '%',
                icon: Icons.trending_up,
                color: AppBranding.success,
                isDark: isDark,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                title: 'dashboard.absence'.tr(),
                value: _totalAbsence.toDouble(),
                icon: Icons.cancel,
                color: AppBranding.danger,
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatCard(
                title: 'dashboard.late'.tr(),
                value: _lateCount.toDouble(),
                icon: Icons.warning_amber_rounded,
                color: AppBranding.warning,
                isDark: isDark,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                title: 'dashboard.on_leave'.tr(),
                value: _onLeaveCount.toDouble(),
                icon: Icons.beach_access,
                color: AppBranding.primary,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _lastUpdatedChip(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule,
            size: 11,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
          const SizedBox(width: 4),
          Text(
            DateFormat('HH:mm').format(DateTime.now()),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required double value,
    required IconData icon,
    required Color color,
    required bool isDark,
    VoidCallback? onTap,
    String prefix = '',
    String suffix = '',
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.grey.shade800
                    : color.withValues(alpha: 0.15),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: isDark ? 0.05 : 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color.withValues(alpha: 0.18),
                            color.withValues(alpha: 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: color, size: 18),
                    ),
                    const Spacer(),
                    if (onTap != null)
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 10,
                        color: isDark
                            ? Colors.grey.shade600
                            : Colors.grey.shade400,
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                AnimatedBuilder(
                  animation: _counterController,
                  builder: (context, _) {
                    final t = Curves.easeOutCubic.transform(
                      _counterController.value,
                    );
                    final current = value * t;
                    String display;
                    if (prefix == '\$') {
                      display = '$prefix${current.toStringAsFixed(0)}';
                    } else if (suffix == '%') {
                      display = '${current.toStringAsFixed(1)}$suffix';
                    } else {
                      display = current.toStringAsFixed(0);
                    }
                    return Text(
                      display,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : color,
                        letterSpacing: -0.5,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =============================================
  // ✅ CHART
  // =============================================
  Widget _buildChartSection(bool isDark) {
    final now = DateTime.now();
    final monthLabels = List.generate(6, (i) {
      final d = DateTime(now.year, now.month - 5 + i);
      return DateFormat('MMM', context.locale.languageCode).format(d);
    });

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppBranding.primary.withValues(alpha: 0.18),
                      AppBranding.primary.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.show_chart,
                  color: AppBranding.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📈 ${'dashboard.sales_performance'.tr()}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'dashboard.last_6_months'.tr(),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppBranding.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '\$${_totalRevenue.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppBranding.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(height: 160, child: _buildBarChart(monthLabels, isDark)),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<String> labels, bool isDark) {
    final data = _monthlyRevenue;
    final maxValue = data.reduce((a, b) => a > b ? a : b);

    if (maxValue == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 40,
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
            ),
            const SizedBox(height: 8),
            Text(
              'dashboard.no_data'.tr(),
              style: TextStyle(
                color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    final safeMaxY = maxValue * 1.25;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: safeMaxY,
        minY: 0,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) =>
                isDark ? const Color(0xFF334155) : AppBranding.primary,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '\$${rod.toY.toStringAsFixed(0)}',
                const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        barGroups: List.generate(
          data.length,
          (index) => BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: data[index],
                gradient: const LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [AppBranding.primary, AppBranding.primaryLight],
                ),
                width: 22,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: safeMaxY,
                  color: isDark
                      ? Colors.grey.shade800.withValues(alpha: 0.4)
                      : Colors.grey.shade100,
                ),
              ),
            ],
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= labels.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    labels[index],
                    style: TextStyle(
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: safeMaxY / 4,
          getDrawingHorizontalLine: (value) => FlLine(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            strokeWidth: 1,
            dashArray: [4, 4],
          ),
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  // =============================================
  // ✅ QUICK ACTIONS
  // =============================================
  Widget _buildQuickActions(bool isDark) {
    final isAdmin = _userRole == 'admin';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('⚡', 'dashboard.quick_actions'.tr()),
        const SizedBox(height: 14),
        Row(
          children: [
            _buildQuickAction(
              icon: Icons.person_add_alt_1,
              label: 'dashboard.new_customer'.tr(),
              color: AppBranding.primary,
              isDark: isDark,
              onTap: () => _navigateTo(const CustomersScreen()),
            ),
            const SizedBox(width: 10),
            _buildQuickAction(
              icon: Icons.access_time_filled,
              label: 'dashboard.register_attendance'.tr(),
              color: AppBranding.success,
              isDark: isDark,
              onTap: () => _navigateTo(const AttendanceScreen()),
            ),
            const SizedBox(width: 10),
            _buildQuickAction(
              icon: Icons.send_rounded,
              label: 'dashboard.broadcast'.tr(),
              color: AppBranding.warning,
              isDark: isDark,
              onTap: () => _navigateTo(const BroadcastScreen()),
            ),
            if (isAdmin) ...[
              const SizedBox(width: 10),
              _buildQuickAction(
                icon: Icons.assessment,
                label: 'التقارير',
                color: Colors.indigo,
                isDark: isDark,
                onTap: () => _navigateTo(const ReportsScreen()),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: isDark ? 0.18 : 0.08),
                  color.withValues(alpha: isDark ? 0.08 : 0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.grey.shade200 : color,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =============================================
  // ✅ ATTENDANCE STATUS
  // =============================================
  Widget _buildAttendanceStatusCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: _attendanceRateValue / 100,
                    strokeWidth: 7,
                    backgroundColor: isDark
                        ? Colors.grey.shade800
                        : Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _attendanceRateValue >= 80
                          ? AppBranding.success
                          : _attendanceRateValue >= 50
                          ? AppBranding.warning
                          : AppBranding.danger,
                    ),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _attendanceRate,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'dashboard.rate'.tr(),
                      style: const TextStyle(fontSize: 9, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'dashboard.monthly_attendance'.tr(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _attendanceChip(
                      'attendance.present'.tr(),
                      _totalAttendance,
                      AppBranding.success,
                    ),
                    _attendanceChip(
                      'attendance.late_status'.tr(),
                      _lateCount,
                      AppBranding.warning,
                    ),
                    _attendanceChip(
                      'attendance.on_leave_status'.tr(),
                      _onLeaveCount,
                      AppBranding.primary,
                    ),
                    _attendanceChip(
                      'attendance.absent'.tr(),
                      _totalAbsence,
                      AppBranding.danger,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _navigateTo(const AttendanceScreen()),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppBranding.primary, AppBranding.primaryLight],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _attendanceChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // =============================================
  // ✅ WHATSAPP SUPPORT
  // =============================================
  Widget _buildWhatsAppSupportCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF25D366).withValues(alpha: 0.15),
                  const Color(0xFF128C7E).withValues(alpha: 0.08),
                ]
              : [
                  const Color(0xFF25D366).withValues(alpha: 0.1),
                  const Color(0xFF128C7E).withValues(alpha: 0.03),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF25D366).withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF25D366), Color(0xFF128C7E)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF25D366).withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.chat_bubble_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💬 ${'dashboard.support'.tr()}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'dashboard.have_question'.tr(),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _openWhatsApp,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'dashboard.contact'.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =============================================
  // ✅ MENU SECTION
  // =============================================
  Widget _buildMenuSection(bool isAdmin, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('📋', 'dashboard.main_menu'.tr()),
        const SizedBox(height: 14),
        if (isAdmin) ...[
          _buildMenuItem(
            icon: Icons.assessment,
            title: 'التقارير المتقدمة',
            subtitle: 'تقارير مفصلة مع تصدير PDF و Excel',
            color: Colors.indigo,
            isDark: isDark,
            onTap: () => _navigateTo(const ReportsScreen()),
          ),
          _buildMenuItem(
            icon: Icons.people_alt,
            title: 'customers.title'.tr(),
            subtitle: 'dashboard.menu_subtitle_customers'.tr(),
            color: AppBranding.primary,
            isDark: isDark,
            onTap: () => _navigateTo(const CustomersScreen()),
          ),
          _buildMenuItem(
            icon: Icons.inventory_2,
            title: 'products.title'.tr(),
            subtitle: 'dashboard.menu_subtitle_products'.tr(),
            color: AppBranding.success,
            isDark: isDark,
            onTap: () => _navigateTo(const ProductsScreen()),
          ),
          _buildMenuItem(
            icon: Icons.receipt_long,
            title: 'invoices.title'.tr(),
            subtitle: 'dashboard.menu_subtitle_invoices'.tr(),
            color: AppBranding.purple,
            isDark: isDark,
            onTap: () => _navigateTo(const InvoicesScreen()),
          ),
          _buildMenuItem(
            icon: Icons.warehouse,
            title: 'warehouses.title'.tr(),
            subtitle: 'dashboard.menu_subtitle_warehouses'.tr(),
            color: AppBranding.cyan,
            isDark: isDark,
            onTap: () => _navigateTo(const WarehousesScreen()),
          ),
          _buildMenuItem(
            icon: Icons.admin_panel_settings,
            title: 'users.title'.tr(),
            subtitle: 'dashboard.menu_subtitle_users'.tr(),
            color: AppBranding.danger,
            isDark: isDark,
            onTap: () => _navigateTo(const UsersScreen()),
          ),
          _buildMenuItem(
            icon: Icons.access_time_filled,
            title: 'attendance.title'.tr(),
            subtitle: 'dashboard.menu_subtitle_attendance'.tr(),
            color: AppBranding.primary,
            isDark: isDark,
            onTap: () => _navigateTo(const AdminAttendanceScreen()),
          ),
          _buildMenuItem(
            icon: Icons.language,
            title: 'settings.language'.tr(),
            subtitle: 'dashboard.menu_subtitle_language'.tr(),
            color: AppBranding.cyan,
            isDark: isDark,
            onTap: () => _navigateTo(const LanguageScreen()),
          ),
          _buildMenuItem(
            icon: Icons.send_and_archive,
            title: 'broadcast.title'.tr(),
            subtitle: 'dashboard.menu_subtitle_broadcast'.tr(),
            color: AppBranding.success,
            isDark: isDark,
            onTap: () => _navigateTo(const BroadcastScreen()),
          ),
        ] else ...[
          _buildMenuItem(
            icon: Icons.people_alt,
            title: 'customers.title'.tr(),
            subtitle: 'dashboard.menu_subtitle_customers'.tr(),
            color: AppBranding.primary,
            isDark: isDark,
            onTap: () => _navigateTo(const CustomersScreen()),
          ),
          _buildMenuItem(
            icon: Icons.access_time_filled,
            title: 'attendance.title'.tr(),
            subtitle: 'dashboard.menu_subtitle_attendance_employee'.tr(),
            color: AppBranding.success,
            isDark: isDark,
            onTap: () => _navigateTo(const AttendanceScreen()),
          ),
          _buildMenuItem(
            icon: Icons.history_rounded,
            title: 'attendance.history'.tr(),
            subtitle: 'dashboard.menu_subtitle_history'.tr(),
            color: AppBranding.warning,
            isDark: isDark,
            onTap: () => _navigateTo(const AttendanceHistoryScreen()),
          ),
          _buildMenuItem(
            icon: Icons.language,
            title: 'settings.language'.tr(),
            subtitle: 'dashboard.menu_subtitle_language'.tr(),
            color: AppBranding.cyan,
            isDark: isDark,
            onTap: () => _navigateTo(const LanguageScreen()),
          ),
          _buildMenuItem(
            icon: Icons.send_and_archive,
            title: 'broadcast.title'.tr(),
            subtitle: 'dashboard.menu_subtitle_broadcast'.tr(),
            color: AppBranding.success,
            isDark: isDark,
            onTap: () => _navigateTo(const BroadcastScreen()),
          ),
        ],
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.18),
                        color.withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =============================================
  // ✅ RECENT ACTIVITIES
  // =============================================
  Widget _buildRecentActivities(bool isDark) {
    if (_recentActivities.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          '🔄',
          'dashboard.recent_activities'.tr(),
          trailing: TextButton.icon(
            onPressed: _loadRecentActivities,
            icon: const Icon(Icons.refresh, size: 14),
            label: Text(
              'common.refresh'.tr(),
              style: const TextStyle(fontSize: 11),
            ),
            style: TextButton.styleFrom(
              foregroundColor: AppBranding.primary,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: const Size(0, 30),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: List.generate(_recentActivities.length, (index) {
              final activity = _recentActivities[index];
              final isLast = index == _recentActivities.length - 1;
              final time = activity['time'] != null
                  ? DateFormat('HH:mm').format(DateTime.parse(activity['time']))
                  : 'common.now'.tr();

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (activity['color'] as Color).withValues(
                              alpha: 0.15,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            activity['icon'] as IconData,
                            color: activity['color'] as Color,
                            size: 16,
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: 4,
                          bottom: isLast ? 0 : 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    activity['title'] ?? '',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                                Text(
                                  time,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isDark
                                        ? Colors.grey.shade500
                                        : Colors.grey.shade400,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              activity['description'] ?? '',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  // =============================================
  // ✅ SYSTEM INFO
  // =============================================
  Widget _buildSystemInfo(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppBranding.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: AppBranding.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'dashboard.system_info'.tr(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppBranding.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            'dashboard.role'.tr(),
            _userRole == 'admin'
                ? 'dashboard.admin'.tr()
                : 'dashboard.employee'.tr(),
            isDark,
          ),
          _buildInfoRow('dashboard.email'.tr(), _userEmail, isDark),
          _buildInfoRow(
            'dashboard.customers_count'.tr(),
            _totalCustomers.toString(),
            isDark,
          ),
          _buildInfoRow(
            'dashboard.revenue'.tr(),
            '\$${_totalRevenue.toStringAsFixed(2)}',
            isDark,
          ),
          _buildInfoRow('dashboard.version'.tr(), AppBranding.version, isDark),
          _buildInfoRow(
            'dashboard.mode'.tr(),
            _isDarkMode ? 'dashboard.dark'.tr() : 'dashboard.light'.tr(),
            isDark,
          ),
          if (_userRole != 'admin') ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppBranding.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppBranding.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: AppBranding.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'dashboard.employee_hint'.tr(),
                      style: TextStyle(
                        fontSize: 11,
                        color: AppBranding.primary.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.grey.shade800,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // =============================================
  // ✅ HELPERS
  // =============================================
  Widget _sectionHeader(String emoji, String title, {Widget? trailing}) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppBranding.primary, AppBranding.primaryLight],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$emoji $title',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2,
          ),
        ),
        const Spacer(),
        ?trailing,
      ],
    );
  }
}
