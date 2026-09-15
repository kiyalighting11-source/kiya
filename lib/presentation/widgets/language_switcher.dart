// lib/presentation/widgets/language_switcher.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final currentCode = context.locale.languageCode;

    return PopupMenuButton<Locale>(
      icon: const Icon(Icons.language),
      tooltip: 'settings.language'.tr(),
      onSelected: (locale) async {
        await context.setLocale(locale);
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: const Locale('ar', 'EG'),
          child: Row(
            children: [
              const Text('🇪🇬', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              const Text('العربية'),
              if (currentCode == 'ar') ...[
                const Spacer(),
                const Icon(Icons.check, color: Colors.green, size: 18),
              ],
            ],
          ),
        ),
        PopupMenuItem(
          value: const Locale('en', 'US'),
          child: Row(
            children: [
              const Text('🇺🇸', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              const Text('English'),
              if (currentCode == 'en') ...[
                const Spacer(),
                const Icon(Icons.check, color: Colors.green, size: 18),
              ],
            ],
          ),
        ),
        PopupMenuItem(
          value: const Locale('zh', 'CN'),
          child: Row(
            children: [
              const Text('🇨🇳', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              const Text('中文'),
              if (currentCode == 'zh') ...[
                const Spacer(),
                const Icon(Icons.check, color: Colors.green, size: 18),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
