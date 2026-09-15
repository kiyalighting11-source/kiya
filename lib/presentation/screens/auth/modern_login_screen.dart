// lib/presentation/screens/auth/modern_login_screen.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/app_branding.dart';
import '../../../app/app_routes.dart';
import '../../../app/app_state.dart';
import '../../../data/models/user.dart';

class ModernLoginScreen extends StatefulWidget {
  const ModernLoginScreen({super.key});

  @override
  State<ModernLoginScreen> createState() => _ModernLoginScreenState();
}

class _ModernLoginScreenState extends State<ModernLoginScreen>
    with TickerProviderStateMixin {
  // =============================================
  // ✅ CONTROLLERS
  // =============================================
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // =============================================
  // ✅ STATE
  // =============================================
  bool _isLoading = false;
  String _errorMessage = '';
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isEmailFocused = false;
  bool _isPasswordFocused = false;

  final Logger _logger = Logger();

  // =============================================
  // ✅ ANIMATIONS
  // =============================================
  late AnimationController _animationController;
  late AnimationController _logoPulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoPulseAnimation;

  @override
  void initState() {
    super.initState();

    // Main entrance animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    _logoScaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    // Continuous pulse
    _logoPulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _logoPulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _logoPulseController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    _logoPulseController.dispose();
    super.dispose();
  }

  // =============================================
  // ✅ LOGIN
  // =============================================
  Future<void> _login() async {
    setState(() {
      _errorMessage = '';
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // ===== VALIDATION =====
    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'auth.email_required'.tr();
      });
      return;
    }

    if (!_isValidEmail(email)) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'auth.email_invalid'.tr();
      });
      return;
    }

    // ✅ احفظ المراجع قبل أي await
    final appState = Provider.of<AppState>(context, listen: false);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      if (!Supabase.instance.isInitialized) {
        throw Exception('Supabase is not initialized');
      }

      _logger.i('📧 Login attempt: $email');

      // ===== SIGN IN =====
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('فشل تسجيل الدخول');
      }

      _logger.i('✅ Logged in: ${response.user!.email}');

      // ===== FETCH USER FROM DB =====
      final userData = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', response.user!.id)
          .maybeSingle();

      if (userData == null) {
        await Supabase.instance.client.auth.signOut();
        throw Exception('المستخدم غير موجود في قاعدة البيانات');
      }

      // ✅ فحص mounted بعد await
      if (!mounted) return;

      // ===== UPDATE APP STATE =====
      await appState.setCurrentUser(AppUser.fromJson(userData));

      if (!mounted) return;
      setState(() => _isLoading = false);

      // ===== NAVIGATE =====
      navigator.pushReplacementNamed(AppRoutes.dashboard);
    } catch (e) {
      _logger.e('❌ Login error: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = _getErrorMessage(e.toString());
      });
      messenger.showSnackBar(
        SnackBar(
          content: Text(_errorMessage),
          backgroundColor: AppBranding.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  // =============================================
  // ✅ FORGOT PASSWORD
  // =============================================
  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showInfoDialog(
        'auth.forgot_password'.tr(),
        'auth.enter_email_first'.tr(),
      );
      return;
    }

    if (!_isValidEmail(email)) {
      _showInfoDialog('auth.forgot_password'.tr(), 'auth.email_invalid'.tr());
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (!Supabase.instance.isInitialized) {
        throw Exception('Supabase is not initialized');
      }

      await Supabase.instance.client.auth.resetPasswordForEmail(email);

      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSuccessDialog(
        'auth.email_sent'.tr(),
        'auth.email_sent_message'.tr(),
      );
    } catch (e) {
      _logger.e('❌ Reset password error: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showInfoDialog('common.error'.tr(), 'auth.reset_error'.tr());
    }
  }

  // =============================================
  // ✅ HELPERS
  // =============================================
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  String _getErrorMessage(String error) {
    if (error.contains('Invalid login credentials')) {
      return 'auth.credentials_invalid'.tr();
    } else if (error.contains('Email not confirmed')) {
      return 'auth.email_not_confirmed'.tr();
    } else if (error.contains('network')) {
      return 'errors.network'.tr();
    } else if (error.contains('not initialized')) {
      return 'auth.server_error'.tr();
    } else {
      return 'errors.generic'.tr();
    }
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              backgroundColor: AppBranding.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text('common.ok'.tr()),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue.shade600, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              backgroundColor: AppBranding.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text('common.ok'.tr()),
          ),
        ],
      ),
    );
  }

  // =============================================
  // ✅ CHANGE LANGUAGE - FIXED ✅
  // =============================================
  Future<void> _changeLanguage(Locale locale) async {
    if (!mounted) return;

    // ✅ احفظ المراجع قبل أي await
    final appState = Provider.of<AppState>(context, listen: false);

    try {
      _logger.i('🌍 Changing language to: ${locale.languageCode}');

      // ✅ 1. غير اللغة في EasyLocalization (ده هيعيد بناء الواجهة تلقائياً)
      await context.setLocale(locale);

      // ✅ 2. احفظ في AppState (للـ persistence)
      await appState.setLocale(locale.languageCode);

      // ✅ 3. تأكد إننا لسه mounted
      if (!mounted) return;

      // ✅ 4. إجبار إعادة البناء كإجراء احتياطي
      setState(() {});

      _logger.i('✅ Language changed successfully');
    } catch (e) {
      _logger.e('❌ Error changing language: $e');
    }
  }

  // =============================================
  // ✅ BUILD
  // =============================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppBranding.primaryDark,
              AppBranding.primary,
              AppBranding.primaryLight,
            ],
          ),
        ),
        child: Stack(
          children: [
            // ===== DECORATIVE CIRCLES =====
            Positioned(
              top: -80,
              right: -60,
              child: _buildDecorativeCircle(
                220,
                Colors.white.withValues(alpha: 0.05),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -80,
              child: _buildDecorativeCircle(
                260,
                Colors.white.withValues(alpha: 0.04),
              ),
            ),
            Positioned(
              top: 120,
              left: -50,
              child: _buildDecorativeCircle(
                120,
                Colors.white.withValues(alpha: 0.03),
              ),
            ),

            // ===== MAIN CONTENT =====
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ===== LOGO =====
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: ScaleTransition(
                          scale: _logoScaleAnimation,
                          child: _buildLogoSection(),
                        ),
                      ),

                      const SizedBox(height: 36),

                      // ===== LOGIN CARD =====
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: _buildLoginCard(),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ===== FOOTER =====
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildFooter(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =============================================
  // ✅ DECORATIVE CIRCLE
  // =============================================
  Widget _buildDecorativeCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  // =============================================
  // ✅ LOGO SECTION
  // =============================================
  Widget _buildLogoSection() {
    return Column(
      children: [
        // ===== PULSING GLOW =====
        AnimatedBuilder(
          animation: _logoPulseAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(
                      alpha: 0.20 * _logoPulseAnimation.value,
                    ),
                    blurRadius: 60,
                    spreadRadius: 5 * _logoPulseAnimation.value,
                  ),
                  BoxShadow(
                    color: AppBranding.primaryLight.withValues(
                      alpha: 0.25 * _logoPulseAnimation.value,
                    ),
                    blurRadius: 80,
                    spreadRadius: 10 * _logoPulseAnimation.value,
                  ),
                ],
              ),
              child: child,
            );
          },
          child: Image.asset(
            AppBranding.logoPath,
            width: 160,
            height: 160,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.business_center,
                size: 120,
                color: Colors.white,
              );
            },
          ),
        ),

        const SizedBox(height: 20),

        // ===== APP NAME =====
        Text(
          AppBranding.appName,
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 2,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
        ),

        const SizedBox(height: 6),

        // ===== TAGLINE =====
        Text(
          'tagline'.tr(),
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.75),
            fontWeight: FontWeight.w400,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  // =============================================
  // ✅ LOGIN CARD
  // =============================================
  Widget _buildLoginCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 40,
            offset: const Offset(0, 15),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ===== HEADER =====
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'auth.welcome_back'.tr(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppBranding.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'auth.login_subtitle'.tr(),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppBranding.primary.withValues(alpha: 0.15),
                        AppBranding.primary.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings,
                    color: AppBranding.primary,
                    size: 26,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ===== ERROR MESSAGE =====
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: _errorMessage.isEmpty
                  ? const SizedBox.shrink()
                  : Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.red.shade200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage,
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),

            // ===== EMAIL FIELD =====
            _buildTextField(
              controller: _emailController,
              label: 'auth.email'.tr(),
              hint: 'auth.email_hint'.tr(),
              icon: Icons.email_outlined,
              isFocused: _isEmailFocused,
              onFocusChange: (focused) {
                setState(() => _isEmailFocused = focused);
              },
              onChanged: (value) {
                if (_errorMessage.isNotEmpty) {
                  setState(() => _errorMessage = '');
                }
              },
              keyboardType: TextInputType.emailAddress,
            ),

            const SizedBox(height: 16),

            // ===== PASSWORD FIELD =====
            _buildTextField(
              controller: _passwordController,
              label: 'auth.password'.tr(),
              hint: 'auth.password_hint'.tr(),
              icon: Icons.lock_outline,
              isFocused: _isPasswordFocused,
              onFocusChange: (focused) {
                setState(() => _isPasswordFocused = focused);
              },
              onChanged: (value) {
                if (_errorMessage.isNotEmpty) {
                  setState(() => _errorMessage = '');
                }
              },
              isPassword: true,
              obscureText: _obscurePassword,
              onToggleVisibility: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
              onSubmitted: (_) => _login(),
            ),

            const SizedBox(height: 12),

            // ===== REMEMBER ME + FORGOT =====
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: Checkbox(
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() {
                            _rememberMe = value ?? false;
                          });
                        },
                        activeColor: AppBranding.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'auth.remember_me'.tr(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: _forgotPassword,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'auth.forgot_password'.tr(),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppBranding.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ===== LOGIN BUTTON =====
            SizedBox(
              width: double.infinity,
              height: 56,
              child: _isLoading
                  ? Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppBranding.primary,
                            AppBranding.primaryLight,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            strokeWidth: 3,
                          ),
                        ),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppBranding.primary,
                            AppBranding.primaryLight,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppBranding.primary.withValues(alpha: 0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          minimumSize: const Size(double.infinity, 56),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'auth.login'.tr(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.arrow_forward_rounded, size: 20),
                          ],
                        ),
                      ),
                    ),
            ),

            const SizedBox(height: 20),

            // ===== DIVIDER =====
            Row(
              children: [
                Expanded(
                  child: Divider(color: Colors.grey.shade300, thickness: 1),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'auth.or'.tr(),
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(color: Colors.grey.shade300, thickness: 1),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ===== LANGUAGE SWITCHER =====
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLanguageChip('ar', '🇪🇬', 'العربية'),
                const SizedBox(width: 8),
                _buildLanguageChip('en', '🇺🇸', 'English'),
                const SizedBox(width: 8),
                _buildLanguageChip('zh', '🇨🇳', '中文'),
              ],
            ),

            const SizedBox(height: 16),

            // ===== SUPPORT =====
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.support_agent,
                    color: AppBranding.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'auth.support'.tr(args: [AppBranding.support]),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =============================================
  // ✅ LANGUAGE CHIP - FIXED ✅
  // =============================================
  Widget _buildLanguageChip(String code, String flag, String name) {
    // ✅ استخدام context.locale مباشرة - بيتحدث تلقائياً مع EasyLocalization
    final isSelected = context.locale.languageCode == code;

    return GestureDetector(
      onTap: isSelected ? null : () => _changeLanguage(Locale(code)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppBranding.primary.withValues(alpha: 0.15)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppBranding.primary : Colors.transparent,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(flag, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppBranding.primary : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =============================================
  // ✅ FOOTER
  // =============================================
  Widget _buildFooter() {
    return Column(
      children: [
        Text(
          '${'settings.version'.tr()} ${AppBranding.version}',
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.6),
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '© ${DateTime.now().year} ${AppBranding.appName}',
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.5),
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }

  // =============================================
  // ✅ TEXT FIELD
  // =============================================
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isFocused,
    required Function(bool) onFocusChange,
    required Function(String) onChanged,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    Function(String)? onSubmitted,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isFocused ? AppBranding.primary : Colors.grey.shade300,
          width: isFocused ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: AppBranding.primary.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        textInputAction: isPassword
            ? TextInputAction.done
            : TextInputAction.next,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          labelStyle: TextStyle(
            color: isFocused ? AppBranding.primary : Colors.grey.shade600,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          prefixIcon: Icon(
            icon,
            color: isFocused ? AppBranding.primary : Colors.grey.shade400,
            size: 22,
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscureText ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                  onPressed: onToggleVisibility,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 20,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        onTap: () => onFocusChange(true),
        onEditingComplete: () => onFocusChange(false),
      ),
    );
  }
}
