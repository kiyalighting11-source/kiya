// lib/main.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// =============================================
// ✅ CORE
// =============================================
import 'app/app_branding.dart';
import 'app/app_routes.dart';
import 'app/app_state.dart';

// =============================================
// ✅ REPOSITORIES
// =============================================
import 'data/repositories/attendance_repository.dart';
import 'data/repositories/customer_repository.dart';
import 'data/repositories/user_repository.dart';

// =============================================
// ✅ SERVICES
// =============================================
import 'data/services/contact_service.dart';
import 'data/services/device_service.dart';
import 'data/services/location_service.dart';
import 'data/services/whatsapp_service.dart';

// =============================================
// ✅ FEATURES
// =============================================
import 'features/broadcast/services/broadcast_service.dart';

// =============================================
// ✅ LOGGER
// =============================================
final Logger logger = Logger(
  printer: PrettyPrinter(
    methodCount: 2,
    errorMethodCount: 5,
    lineLength: 120,
    colors: true,
    printEmojis: true,
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
  ),
);

// =============================================
// ✅ MAIN
// =============================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ===== EasyLocalization =====
  await EasyLocalization.ensureInitialized();
  logger.i('✅ EasyLocalization initialized');

  // ===== Load .env =====
  bool supabaseInitialized = false;
  try {
    await dotenv.load(fileName: ".env");
    logger.i('✅ Environment variables loaded');

    final supabaseUrl = dotenv.get('SUPABASE_URL');
    final supabaseAnonKey = dotenv.get('SUPABASE_ANON_KEY');

    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw Exception('Missing Supabase credentials in .env file');
    }

    // ===== Init Supabase =====
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
    );
    supabaseInitialized = true;
    logger.i('✅ Supabase initialized successfully');
  } catch (e) {
    logger.e('❌ Failed to initialize: $e');
  }

  // ===== Run App =====
  runApp(
    EasyLocalization(
      // ✅ useOnlyLangCode = true عشان يدور على ar.json بدل ar-EG.json
      supportedLocales: const [Locale('ar'), Locale('en'), Locale('zh')],
      path: 'assets/translations',
      fallbackLocale: const Locale('ar'),
      startLocale: const Locale('ar'),
      useOnlyLangCode: true,
      child: MultiProvider(
        providers: [
          // ===== LOGGER =====
          Provider<Logger>(create: (_) => logger),

          // ===== REPOSITORIES =====
          Provider<UserRepository>(create: (_) => UserRepository()),
          Provider<AttendanceRepository>(create: (_) => AttendanceRepository()),
          Provider<CustomerRepository>(create: (_) => CustomerRepository()),

          // ===== SERVICES =====
          Provider<DeviceService>(create: (_) => DeviceService()),
          Provider<LocationService>(create: (_) => LocationService()),
          Provider<BroadcastService>(create: (_) => BroadcastService()),

          // ===== CHANGE NOTIFIERS =====
          ChangeNotifierProvider(
            create: (_) =>
                AppState()..setSupabaseInitialized(supabaseInitialized),
          ),
          ChangeNotifierProvider(create: (_) => WhatsAppService()),
          ChangeNotifierProvider(create: (_) => ContactService()),
        ],
        child: const KiyaApp(),
      ),
    ),
  );
}

// =============================================
// ✅ APP WIDGET
// =============================================
class KiyaApp extends StatelessWidget {
  const KiyaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return MaterialApp(
      title: AppBranding.appName,

      // ===== THEME =====
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,

      // ===== LOCALIZATION =====
      // ✅ EasyLocalization بيدير اللغة هنا
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,

      // ===== DEBUG =====
      debugShowCheckedModeBanner: false,

      // ===== ROUTING =====
      initialRoute: AppRoutes.root,
      routes: AppRoutes.routes,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      onUnknownRoute: AppRoutes.onUnknownRoute,

      // ===== SCROLL BEHAVIOR =====
      builder: (context, child) {
        return ScrollConfiguration(
          behavior: const ScrollBehavior().copyWith(
            physics: const BouncingScrollPhysics(),
          ),
          child: child!,
        );
      },
    );
  }

  // =============================================
  // ✅ LIGHT THEME
  // =============================================
  ThemeData _buildLightTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppBranding.primary,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      fontFamily: GoogleFonts.cairo().fontFamily,

      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppBranding.primary,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppBranding.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: TextStyle(color: Colors.grey.shade700),
        hintStyle: TextStyle(color: Colors.grey.shade400),
      ),

      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey.shade100,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        labelStyle: const TextStyle(fontSize: 13),
      ),

      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 6,
        contentTextStyle: const TextStyle(fontSize: 14),
      ),

      dividerTheme: DividerThemeData(
        color: Colors.grey.shade200,
        thickness: 1,
        space: 16,
      ),
    );
  }

  // =============================================
  // ✅ DARK THEME
  // =============================================
  ThemeData _buildDarkTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppBranding.primaryLight,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      fontFamily: GoogleFonts.cairo().fontFamily,

      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Color(0xFF0F172A),
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade800.withValues(alpha: 0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppBranding.primaryLight,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF87171), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey.shade800,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),

      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 6,
      ),
    );
  }
}
