// lib/app/app_routes.dart
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import '../features/broadcast/screens/broadcast_history_screen.dart';
import '../features/broadcast/screens/broadcast_screen.dart';
import '../presentation/screens/attendance/admin_attendance.dart';
import '../presentation/screens/attendance/attendance_history.dart';
import '../presentation/screens/attendance/attendance_screen.dart';
import '../presentation/screens/attendance/setup_screen.dart';
import '../presentation/screens/auth/auth_gate.dart';
import '../presentation/screens/auth/modern_login_screen.dart';
import '../presentation/screens/dashboard_screen.dart';

class AppRoutes {
  // ===== CONSTANTS =====
  static const String root = '/';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String home = '/home';

  // ===== ATTENDANCE =====
  static const String attendance = '/attendance';
  static const String attendanceHistory = '/attendance-history';
  static const String adminAttendance = '/admin-attendance';
  static const String setup = '/setup';

  // ===== BROADCAST =====
  static const String broadcast = '/broadcast';
  static const String broadcastHistory = '/broadcast-history';

  const AppRoutes._();

  // ===== STATIC ROUTES =====
  static Map<String, WidgetBuilder> get routes => {
    root: (_) => const AuthGate(),
    login: (_) => const ModernLoginScreen(),
    dashboard: (_) => const DashboardScreen(),
    home: (_) => const DashboardScreen(),

    attendance: (_) => const AttendanceScreen(),
    attendanceHistory: (_) => const AttendanceHistoryScreen(),
    adminAttendance: (_) => const AdminAttendanceScreen(),
    setup: (_) => const SetupScreen(),

    broadcast: (_) => const BroadcastScreen(),
    broadcastHistory: (_) => const BroadcastHistoryScreen(),
  };

  // ===== DYNAMIC ROUTES =====
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    Logger().i('🔍 Generating route: ${settings.name}');

    // ===== Broadcast with ID =====
    if (settings.name?.startsWith('/broadcast/') ?? false) {
      return MaterialPageRoute(
        builder: (_) => const BroadcastScreen(),
        settings: settings,
      );
    }

    // ===== Attendance with ID =====
    if (settings.name?.startsWith('/attendance/') ?? false) {
      return MaterialPageRoute(
        builder: (_) => const AttendanceScreen(),
        settings: settings,
      );
    }

    // Return null → triggers onUnknownRoute
    return null;
  }

  // ===== UNKNOWN ROUTE =====
  static Route<dynamic> onUnknownRoute(RouteSettings settings) {
    Logger().w('⚠️ Unknown route: ${settings.name}');
    return MaterialPageRoute(
      builder: (_) => NotFoundScreen(routeName: settings.name),
      settings: settings,
    );
  }
}

// =============================================
// ✅ NOT FOUND SCREEN
// =============================================
class NotFoundScreen extends StatelessWidget {
  final String? routeName;
  const NotFoundScreen({super.key, this.routeName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الصفحة غير موجودة')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: Colors.grey.shade400),
              const SizedBox(height: 24),
              const Text(
                '404',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'الصفحة غير موجودة',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              if (routeName != null) ...[
                const SizedBox(height: 8),
                Text(
                  'المسار: $routeName',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.root,
                  (route) => false,
                ),
                icon: const Icon(Icons.home),
                label: const Text('العودة للرئيسية'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
