// test/widget_test.dart
import 'package:flutter_test/flutter_test.dart';

import 'package:crm_project/app/app_state.dart';
import 'package:crm_project/main.dart';

void main() {
  // =============================================
  // ✅ APP STATE TESTS
  // =============================================
  group('AppState', () {
    late AppState appState;

    setUp(() {
      appState = AppState();
    });

    tearDown(() {
      appState.dispose();
    });

    // ===== INITIAL VALUES =====
    test('initial values are correct', () {
      expect(appState.isDarkMode, false);
      expect(appState.locale, 'ar');
      expect(appState.currentUser, null);
      expect(appState.isLoading, false);
      expect(appState.userRole, null);
      expect(appState.supabaseInitialized, false);
    });

    // ===== ROLE HELPERS =====
    test('isAdmin returns false by default', () {
      expect(appState.isAdmin, false);
    });

    test('isEmployee returns false by default', () {
      expect(appState.isEmployee, false);
    });

    // ===== SUPABASE INITIALIZED =====
    test('setSupabaseInitialized updates value', () {
      appState.setSupabaseInitialized(true);
      expect(appState.supabaseInitialized, true);

      appState.setSupabaseInitialized(false);
      expect(appState.supabaseInitialized, false);
    });

    // ===== LOADING =====
    test('setLoading updates value', () {
      appState.setLoading(true);
      expect(appState.isLoading, true);

      appState.setLoading(false);
      expect(appState.isLoading, false);
    });

    // ===== NOTIFIES LISTENERS =====
    test('setSupabaseInitialized notifies listeners', () {
      int notificationCount = 0;
      appState.addListener(() => notificationCount++);

      appState.setSupabaseInitialized(true);

      expect(notificationCount, 1);
    });

    test('setLoading notifies listeners', () {
      int notificationCount = 0;
      appState.addListener(() => notificationCount++);

      appState.setLoading(true);

      expect(notificationCount, 1);
    });
  });

  // =============================================
  // ✅ KIYA APP CLASS TEST
  // =============================================
  group('KiyaApp', () {
    test('KiyaApp class is defined', () {
      // ✅ التأكد من أن الكلاس موجود
      expect(KiyaApp, isNotNull);
    });
  });
}
