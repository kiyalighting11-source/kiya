// lib/presentation/screens/auth/auth_gate.dart
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/app_branding.dart';
import '../../../app/app_routes.dart';
import '../../../app/app_state.dart';
import '../../../data/repositories/user_repository.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final Logger _logger = Logger();
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAuth());
  }

  Future<void> _checkAuth() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (!Supabase.instance.isInitialized) {
        throw Exception('Supabase غير مهيأ');
      }

      final session = Supabase.instance.client.auth.currentSession;

      if (session == null) {
        _logger.i('❌ No active session');
        _navigateToLogin();
        return;
      }

      _logger.i('🔍 Session found: ${session.user.email}');

      final userRepo = UserRepository();
      final user = await userRepo.getUserById(session.user.id);

      if (!mounted) return;

      if (user == null) {
        _logger.w('⚠️ User not found in DB, signing out...');
        await Supabase.instance.client.auth.signOut();
        _navigateToLogin();
        return;
      }

      final appState = Provider.of<AppState>(context, listen: false);
      await appState.setCurrentUser(user);
      await appState.loadPreferences();

      _logger.i('✅ Authenticated: ${user.email} (${user.role})');
      _navigateToDashboard();
    } catch (e) {
      _logger.e('❌ AuthGate error: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToLogin() {
    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  void _navigateToDashboard() {
    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const _LoadingScreen();
    if (_error != null) {
      return _ErrorScreen(
        error: _error!,
        onRetry: _checkAuth,
        onLogout: () async {
          await Supabase.instance.client.auth.signOut();
          if (mounted) _checkAuth();
        },
      );
    }
    return const SizedBox.shrink();
  }
}

// =============================================
// ✅ LOADING
// =============================================
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppBranding.primary),
            ),
            SizedBox(height: 16),
            Text(
              'جاري التحقق من الجلسة...',
              style: TextStyle(
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
}

// =============================================
// ✅ ERROR
// =============================================
class _ErrorScreen extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  final Future<void> Function() onLogout;

  const _ErrorScreen({
    required this.error,
    required this.onRetry,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
              const SizedBox(height: 16),
              const Text(
                'خطأ في التحقق',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: onRetry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppBranding.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('إعادة المحاولة'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: onLogout,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppBranding.primary),
                      foregroundColor: AppBranding.primary,
                    ),
                    child: const Text('تسجيل الخروج'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
