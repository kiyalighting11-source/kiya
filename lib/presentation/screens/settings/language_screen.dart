// lib/presentation/screens/settings/language_screen.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_branding.dart';
import '../../../app/app_state.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ استخدام watch عشان يتحدث تلقائياً عند تغيير اللغة
    final appState = Provider.of<AppState>(context);

    final languages = <_LanguageItem>[
      const _LanguageItem(
        code: 'ar',
        nativeName: 'العربية',
        englishName: 'Arabic',
        chineseName: '阿拉伯语',
        flag: '🇪🇬',
        locale: Locale('ar'),
      ),
      const _LanguageItem(
        code: 'en',
        nativeName: 'English',
        englishName: 'English',
        chineseName: '英语',
        flag: '🇺🇸',
        locale: Locale('en'),
      ),
      const _LanguageItem(
        code: 'zh',
        nativeName: '中文',
        englishName: 'Chinese',
        chineseName: '中文',
        flag: '🇨🇳',
        locale: Locale('zh'),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('settings.language'.tr()),
        backgroundColor: AppBranding.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ===== HEADER =====
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppBranding.primary.withValues(alpha: 0.1),
                  AppBranding.primaryLight.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppBranding.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.translate,
                    color: AppBranding.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'settings.choose_language'.tr(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppBranding.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'settings.language_hint'.tr(),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ===== LANGUAGE LIST =====
          ...languages.map((lang) {
            // ✅ استخدام context.locale مباشرة - بيتحدث تلقائياً
            final isSelected = context.locale.languageCode == lang.code;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _LanguageTile(
                language: lang,
                isSelected: isSelected,
                onTap: () => _handleLanguageChange(context, lang, appState),
              ),
            );
          }),

          const SizedBox(height: 24),

          // ===== INFO BOX =====
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'settings.language_info'.tr(),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue.shade800,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =============================================
  // ✅ HANDLE LANGUAGE CHANGE - FIXED ✅
  // =============================================
  Future<void> _handleLanguageChange(
    BuildContext context,
    _LanguageItem lang,
    AppState appState,
  ) async {
    // ✅ احفظ المراجع قبل أي await
    final messenger = ScaffoldMessenger.of(context);

    try {
      debugPrint('🌍 Changing language to: ${lang.code}');

      // ✅ 1. غيّر اللغة (EasyLocalization) — ده هيعيد بناء الواجهة تلقائياً
      await context.setLocale(lang.locale);

      // ✅ 2. احفظ في SharedPreferences (AppState) — للـ persistence
      await appState.setLocale(lang.code);

      // ✅ 3. فحص mounted
      if (!context.mounted) return;

      debugPrint('✅ Language changed successfully');

      // ✅ 4. SnackBar باستخدام المرجع المحفوظ
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '✅ ${'settings.language_changed'.tr()} — ${lang.nativeName}',
          ),
          backgroundColor: AppBranding.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint('❌ Error changing language: $e');
      messenger.showSnackBar(
        SnackBar(
          content: Text('${'common.error'.tr()}: $e'),
          backgroundColor: AppBranding.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// =============================================
// ✅ LANGUAGE ITEM MODEL
// =============================================
class _LanguageItem {
  final String code;
  final String nativeName;
  final String englishName;
  final String chineseName;
  final String flag;
  final Locale locale;

  const _LanguageItem({
    required this.code,
    required this.nativeName,
    required this.englishName,
    required this.chineseName,
    required this.flag,
    required this.locale,
  });
}

// =============================================
// ✅ LANGUAGE TILE
// =============================================
class _LanguageTile extends StatelessWidget {
  final _LanguageItem language;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.language,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          // ✅ أنيميشن ناعم عند التغيير
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? AppBranding.primary.withValues(alpha: 0.08)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppBranding.primary : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // ===== FLAG =====
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppBranding.primary.withValues(alpha: 0.1)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  language.flag,
                  style: const TextStyle(fontSize: 32),
                ),
              ),

              const SizedBox(width: 16),

              // ===== NAME =====
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      language.nativeName,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? AppBranding.primary
                            : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${language.englishName} • ${language.chineseName}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              // ===== CHECK ICON =====
              if (isSelected)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppBranding.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 18),
                )
              else
                Icon(
                  Icons.radio_button_unchecked,
                  color: Colors.grey.shade400,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
