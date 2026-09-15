// lib/data/services/device_service.dart
import 'dart:io' show Platform;
import 'dart:ui' as ui;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeviceService {
  // ==================== SINGLETON ====================
  static final DeviceService _instance = DeviceService._internal();
  factory DeviceService() => _instance;
  DeviceService._internal();

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  // ==================== STORAGE KEYS ====================
  static const String _kWebDeviceIdKey = 'web_device_id';
  static const String _kFallbackDeviceIdKey = 'device_id_fallback';
  static const String _kDesktopDeviceIdKey = 'desktop_device_id';
  static const String _kRegisteredDeviceIdKey = 'registered_device_id';

  // =============================================
  // ✅ DEVICE ID
  // =============================================
  Future<String> getDeviceId() async {
    if (kIsWeb) {
      return await _getWebDeviceId();
    }

    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        // ✅ identifierForVendor عندك String? → نفحص null
        final identifier = iosInfo.identifierForVendor;

        if (identifier == null || identifier.isEmpty) {
          return await _getFallbackDeviceId();
        }
        return identifier;
      } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        return await _getDesktopDeviceId();
      }
      return await _getFallbackDeviceId();
    } catch (e) {
      debugPrint('❌ Error getting device ID: $e');
      return await _getFallbackDeviceId();
    }
  }

  // =============================================
  // ✅ DEVICE NAME
  // =============================================
  Future<String> getDeviceName() async {
    if (kIsWeb) {
      try {
        final webInfo = await _deviceInfo.webBrowserInfo;
        return webInfo.browserName.name;
      } catch (_) {
        return 'Web Browser';
      }
    }

    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return androidInfo.model;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.name;
      } else if (Platform.isWindows) {
        final windowsInfo = await _deviceInfo.windowsInfo;
        return windowsInfo.computerName;
      } else if (Platform.isMacOS) {
        final macInfo = await _deviceInfo.macOsInfo;
        return macInfo.computerName;
      } else if (Platform.isLinux) {
        final linuxInfo = await _deviceInfo.linuxInfo;
        return linuxInfo.prettyName;
      }
      return 'Unknown Device';
    } catch (e) {
      debugPrint('❌ Error getting device name: $e');
      return 'Unknown Device';
    }
  }

  // =============================================
  // ✅ DEVICE MODEL
  // =============================================
  Future<String> getDeviceModel() async {
    if (kIsWeb) return 'Web Platform';

    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return '${androidInfo.manufacturer} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return '${iosInfo.name} (${iosInfo.model})';
      } else if (Platform.isWindows) {
        final windowsInfo = await _deviceInfo.windowsInfo;
        return '${windowsInfo.productName} ${windowsInfo.releaseId}';
      } else if (Platform.isMacOS) {
        final macInfo = await _deviceInfo.macOsInfo;
        return '${macInfo.model} (${macInfo.arch})';
      } else if (Platform.isLinux) {
        final linuxInfo = await _deviceInfo.linuxInfo;
        return linuxInfo.prettyName;
      }
      return 'Unknown Model';
    } catch (e) {
      debugPrint('❌ Error getting device model: $e');
      return 'Unknown Model';
    }
  }

  // =============================================
  // ✅ DEVICE OS VERSION
  // =============================================
  Future<String> getDeviceOsVersion() async {
    if (kIsWeb) {
      try {
        final webInfo = await _deviceInfo.webBrowserInfo;
        return webInfo.platform ?? 'Web';
      } catch (_) {
        return 'Web';
      }
    }

    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return 'Android ${androidInfo.version.release}';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return 'iOS ${iosInfo.systemVersion}';
      } else if (Platform.isWindows) {
        final windowsInfo = await _deviceInfo.windowsInfo;
        return 'Windows ${windowsInfo.releaseId}';
      } else if (Platform.isMacOS) {
        final macInfo = await _deviceInfo.macOsInfo;
        return 'macOS ${macInfo.osRelease}';
      } else if (Platform.isLinux) {
        final linuxInfo = await _deviceInfo.linuxInfo;
        return 'Linux ${linuxInfo.version ?? ''}';
      }
      return 'Unknown OS';
    } catch (e) {
      debugPrint('❌ Error getting OS version: $e');
      return 'Unknown OS';
    }
  }

  // =============================================
  // ✅ FULL DEVICE INFO
  // =============================================
  Future<Map<String, String>> getDeviceInfo() async {
    // ===== Web =====
    if (kIsWeb) {
      try {
        final webInfo = await _deviceInfo.webBrowserInfo;
        return {
          'id': await _getWebDeviceId(),
          'name': webInfo.browserName.name,
          'model': 'Web Platform',
          'os': webInfo.platform ?? 'Web',
          'sdk': 'Web',
          'brand': 'Web',
          'device': 'Web',
          'product': webInfo.userAgent ?? 'Web',
        };
      } catch (e) {
        debugPrint('❌ Web device info error: $e');
        return {
          'id': await _getWebDeviceId(),
          'name': 'Web Browser',
          'model': 'Web Platform',
          'os': 'Web',
          'sdk': 'Web',
          'brand': 'Web',
          'device': 'Web',
          'product': 'Web',
        };
      }
    }

    try {
      // ===== Android =====
      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        return {
          'id': info.id,
          'name': info.model,
          'model': '${info.manufacturer} ${info.model}',
          'os': 'Android ${info.version.release}',
          'sdk': '${info.version.sdkInt}',
          'brand': info.brand,
          'device': info.device,
          'product': info.product,
        };
      }
      // ===== iOS =====
      else if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        // ✅ identifierForVendor عندك String? → نفحص null
        final identifier = info.identifierForVendor;
        final String deviceId;

        if (identifier == null || identifier.isEmpty) {
          deviceId = await _getFallbackDeviceId();
        } else {
          deviceId = identifier;
        }

        return {
          'id': deviceId,
          'name': info.name,
          'model': info.model,
          'os': 'iOS ${info.systemVersion}',
          'sdk': info.systemVersion,
          'brand': 'Apple',
          'device': info.utsname.machine,
          'product': info.name,
        };
      }
      // ===== Windows =====
      else if (Platform.isWindows) {
        final info = await _deviceInfo.windowsInfo;
        return {
          'id': await _getDesktopDeviceId(),
          'name': info.computerName,
          'model': '${info.productName} ${info.releaseId}',
          'os': 'Windows',
          'sdk': info.releaseId,
          'brand': 'Microsoft',
          'device': 'PC',
          'product': info.productName,
        };
      }
      // ===== macOS =====
      else if (Platform.isMacOS) {
        final info = await _deviceInfo.macOsInfo;
        return {
          'id': await _getDesktopDeviceId(),
          'name': info.computerName,
          'model': '${info.model} (${info.arch})',
          'os': 'macOS ${info.osRelease}',
          'sdk': info.osRelease,
          'brand': 'Apple',
          'device': info.model,
          'product': info.computerName,
        };
      }
      // ===== Linux =====
      else if (Platform.isLinux) {
        final info = await _deviceInfo.linuxInfo;
        return {
          'id': await _getDesktopDeviceId(),
          'name': info.prettyName,
          'model': info.prettyName,
          'os': 'Linux',
          'sdk': info.version ?? '',
          'brand': 'Linux',
          'device': info.id,
          'product': info.prettyName,
        };
      }
    } catch (e) {
      debugPrint('❌ Error getting device info: $e');
    }

    // ===== Fallback =====
    return {
      'id': await _getFallbackDeviceId(),
      'name': 'Unknown',
      'model': 'Unknown',
      'os': 'Unknown',
      'sdk': 'Unknown',
      'brand': 'Unknown',
      'device': 'Unknown',
      'product': 'Unknown',
    };
  }

  // =============================================
  // ✅ DEVICE TYPE
  // =============================================
  Future<String> getDeviceType() async {
    if (kIsWeb) return 'Web';

    try {
      if (Platform.isAndroid) {
        // ✅ استخدام MediaQuery من PlatformDispatcher
        final view = ui.PlatformDispatcher.instance.views.first;
        final physicalSize = view.physicalSize;

        final sizeInches = _calculateScreenSize(
          physicalSize.width,
          physicalSize.height,
        );

        return sizeInches > 7.0 ? 'Tablet' : 'Phone';
      }

      if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        return info.model.toLowerCase().contains('ipad') ? 'Tablet' : 'Phone';
      }

      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        return 'Desktop';
      }

      return 'Unknown';
    } catch (e) {
      debugPrint('❌ Error getting device type: $e');
      return 'Unknown';
    }
  }

  // =============================================
  // ✅ DEVICE REGISTRATION CHECK
  // =============================================
  Future<bool> isDeviceRegistered(String employeeId) async {
    try {
      final deviceId = await getDeviceId();
      final supabase = Supabase.instance.client;

      final response = await supabase
          .from('employee_devices')
          .select('id')
          .eq('employee_id', employeeId)
          .eq('device_id', deviceId)
          .eq('is_active', true);

      return response.isNotEmpty;
    } catch (e) {
      debugPrint('❌ Error checking device registration: $e');
      return false;
    }
  }

  // =============================================
  // ✅ DEVICE REGISTRATION STATUS
  // =============================================
  Future<Map<String, dynamic>> getDeviceRegistrationStatus(
    String employeeId,
  ) async {
    try {
      final deviceId = await getDeviceId();
      final supabase = Supabase.instance.client;

      final response = await supabase
          .from('employee_devices')
          .select()
          .eq('employee_id', employeeId)
          .eq('device_id', deviceId)
          .maybeSingle();

      if (response == null) {
        return {
          'isRegistered': false,
          'isActive': false,
          'deviceId': deviceId,
          'message': 'Device not registered',
        };
      }

      return {
        'isRegistered': true,
        'isActive': response['is_active'] ?? false,
        'deviceId': deviceId,
        'deviceName': response['device_name'],
        'deviceModel': response['device_model'],
        'latitude': response['latitude'],
        'longitude': response['longitude'],
        'locationName': response['location_name'],
        'registeredAt': response['registered_at'],
        'message': response['is_active'] == true
            ? 'Device is active and registered'
            : 'Device is deactivated',
      };
    } catch (e) {
      debugPrint('❌ Error getting device registration status: $e');
      return {
        'isRegistered': false,
        'isActive': false,
        'deviceId': await getDeviceId(),
        'message': 'Error checking device status',
      };
    }
  }

  // =============================================
  // ✅ SAVE DEVICE INFO TO SUPABASE
  // =============================================
  Future<void> saveDeviceInfo({
    required String employeeId,
    required double latitude,
    required double longitude,
    String? locationName,
  }) async {
    try {
      final deviceInfo = await getDeviceInfo();
      final deviceId = deviceInfo['id'] ?? await getDeviceId();
      final supabase = Supabase.instance.client;

      final existing = await supabase
          .from('employee_devices')
          .select('id')
          .eq('employee_id', employeeId)
          .eq('device_id', deviceId)
          .maybeSingle();

      if (existing != null) {
        await supabase
            .from('employee_devices')
            .update({
              'device_name': deviceInfo['name'] ?? 'Unknown Device',
              'device_model': deviceInfo['model'] ?? 'Unknown Model',
              'latitude': latitude,
              'longitude': longitude,
              'location_name': locationName,
              'is_active': true,
            })
            .eq('id', existing['id']);

        debugPrint('✅ Device info updated for employee: $employeeId');
      } else {
        await supabase.from('employee_devices').insert({
          'employee_id': employeeId,
          'device_id': deviceId,
          'device_name': deviceInfo['name'] ?? 'Unknown Device',
          'device_model': deviceInfo['model'] ?? 'Unknown Model',
          'latitude': latitude,
          'longitude': longitude,
          'location_name': locationName,
          'is_active': true,
          'registered_at': DateTime.now().toIso8601String(),
        });

        debugPrint('✅ New device registered for employee: $employeeId');
      }

      await storeDeviceLocally(deviceId);
    } catch (e) {
      debugPrint('❌ Error saving device info: $e');
      throw Exception('Failed to save device information: $e');
    }
  }

  // =============================================
  // ✅ GET EMPLOYEE DEVICES
  // =============================================
  Future<List<Map<String, dynamic>>> getEmployeeDevices(
    String employeeId,
  ) async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('employee_devices')
          .select()
          .eq('employee_id', employeeId)
          .order('registered_at', ascending: false);

      return response;
    } catch (e) {
      debugPrint('❌ Error getting employee devices: $e');
      return [];
    }
  }

  // =============================================
  // ✅ DEACTIVATE / REACTIVATE DEVICE
  // =============================================
  Future<void> deactivateDevice(String deviceId) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase
          .from('employee_devices')
          .update({'is_active': false})
          .eq('id', deviceId);
      debugPrint('✅ Device deactivated: $deviceId');
    } catch (e) {
      debugPrint('❌ Error deactivating device: $e');
      throw Exception('Failed to deactivate device: $e');
    }
  }

  Future<void> reactivateDevice(String deviceId) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase
          .from('employee_devices')
          .update({'is_active': true})
          .eq('id', deviceId);
      debugPrint('✅ Device reactivated: $deviceId');
    } catch (e) {
      debugPrint('❌ Error reactivating device: $e');
      throw Exception('Failed to reactivate device: $e');
    }
  }

  // =============================================
  // ✅ LOCAL STORAGE
  // =============================================
  Future<void> storeDeviceLocally(String deviceId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kRegisteredDeviceIdKey, deviceId);
      debugPrint('✅ Device ID stored locally: $deviceId');
    } catch (e) {
      debugPrint('❌ Error storing device locally: $e');
    }
  }

  Future<String?> getStoredDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_kRegisteredDeviceIdKey);
    } catch (e) {
      debugPrint('❌ Error getting stored device: $e');
      return null;
    }
  }

  Future<void> clearStoredDevice() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kRegisteredDeviceIdKey);
      debugPrint('✅ Stored device cleared');
    } catch (e) {
      debugPrint('❌ Error clearing stored device: $e');
    }
  }

  Future<bool> hasDeviceBeenRegistered() async {
    try {
      final storedId = await getStoredDeviceId();
      return storedId != null && storedId.isNotEmpty;
    } catch (e) {
      debugPrint('❌ Error checking device registration status: $e');
      return false;
    }
  }

  // =============================================
  // ✅ DEVICE FINGERPRINT
  // =============================================
  Future<String> generateDeviceFingerprint() async {
    try {
      final info = await getDeviceInfo();
      final id = await getDeviceId();
      final type = await getDeviceType();
      final os = info['os'] ?? 'Unknown';

      return '$id-$type-$os-${info['sdk'] ?? ''}';
    } catch (e) {
      debugPrint('❌ Error generating device fingerprint: $e');
      return await getDeviceId();
    }
  }

  // =============================================
  // ✅ PLATFORM PROPERTIES
  // =============================================
  bool get isWeb => kIsWeb;
  bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  bool get isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
  bool get isAndroid => !kIsWeb && Platform.isAndroid;
  bool get isIos => !kIsWeb && Platform.isIOS;
  bool get isWindows => !kIsWeb && Platform.isWindows;
  bool get isMacOs => !kIsWeb && Platform.isMacOS;
  bool get isLinux => !kIsWeb && Platform.isLinux;

  // =============================================
  // ✅ PRIVATE HELPERS
  // =============================================
  Future<String> _getWebDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? deviceId = prefs.getString(_kWebDeviceIdKey);

      if (deviceId == null || deviceId.isEmpty) {
        deviceId =
            'web_${DateTime.now().millisecondsSinceEpoch}_${(100000 + DateTime.now().microsecond % 900000)}';
        await prefs.setString(_kWebDeviceIdKey, deviceId);
      }

      return deviceId;
    } catch (e) {
      debugPrint('❌ Error getting web device ID: $e');
      return 'web_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  Future<String> _getDesktopDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? deviceId = prefs.getString(_kDesktopDeviceIdKey);

      if (deviceId == null || deviceId.isEmpty) {
        deviceId =
            'desktop_${DateTime.now().millisecondsSinceEpoch}_${(100000 + DateTime.now().microsecond % 900000)}';
        await prefs.setString(_kDesktopDeviceIdKey, deviceId);
      }

      return deviceId;
    } catch (e) {
      debugPrint('❌ Error getting desktop device ID: $e');
      return 'desktop_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  Future<String> _getFallbackDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? deviceId = prefs.getString(_kFallbackDeviceIdKey);

      if (deviceId == null || deviceId.isEmpty) {
        deviceId = 'fallback_${DateTime.now().millisecondsSinceEpoch}';
        await prefs.setString(_kFallbackDeviceIdKey, deviceId);
      }

      return deviceId;
    } catch (e) {
      debugPrint('❌ Error getting fallback device ID: $e');
      return 'fallback_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  double _calculateScreenSize(double widthPx, double heightPx) {
    const double dpi = 160;
    final widthInches = widthPx / dpi;
    final heightInches = heightPx / dpi;
    return _sqrt(widthInches * widthInches + heightInches * heightInches);
  }

  double _sqrt(double x) {
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 10; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }
}
