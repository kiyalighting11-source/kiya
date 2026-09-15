// lib/data/services/location_service.dart
import 'package:flutter/foundation.dart';
import 'package:location/location.dart' as location_package;
import 'package:geocoding/geocoding.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final location_package.Location _location = location_package.Location();

  // =============================================
  // ✅ PERMISSION
  // =============================================
  Future<bool> requestPermission() async {
    try {
      location_package.PermissionStatus permission = await _location
          .hasPermission();
      if (permission == location_package.PermissionStatus.denied) {
        permission = await _location.requestPermission();
      }
      return permission == location_package.PermissionStatus.granted ||
          permission == location_package.PermissionStatus.grantedLimited;
    } catch (e) {
      debugPrint('❌ Error requesting location permission: $e');
      return false;
    }
  }

  // =============================================
  // ✅ CHECK GPS ENABLED
  // =============================================
  Future<bool> isGpsEnabled() async {
    try {
      return await _location.serviceEnabled();
    } catch (e) {
      debugPrint('❌ Error checking GPS: $e');
      return false;
    }
  }

  // =============================================
  // ✅ REQUEST GPS ENABLE
  // =============================================
  Future<bool> requestEnableGps() async {
    try {
      return await _location.requestService();
    } catch (e) {
      debugPrint('❌ Error requesting GPS: $e');
      return false;
    }
  }

  // =============================================
  // ✅ GET CURRENT LOCATION (HIGH ACCURACY)
  // =============================================
  Future<location_package.LocationData?> getCurrentLocation() async {
    try {
      // 1. Check permission
      final hasPermission = await requestPermission();
      if (!hasPermission) {
        debugPrint('❌ Location permission denied');
        return null;
      }

      // 2. Check GPS
      final gpsEnabled = await isGpsEnabled();
      if (!gpsEnabled) {
        debugPrint('⚠️ GPS is disabled, requesting...');
        final enabled = await requestEnableGps();
        if (!enabled) {
          debugPrint('❌ GPS not enabled');
          return null;
        }
      }

      // 3. Configure high accuracy settings
      try {
        await _location.changeSettings(
          accuracy: location_package.LocationAccuracy.high,
          interval: 1000,
          distanceFilter: 0,
        );
      } catch (e) {
        debugPrint('⚠️ Could not change settings: $e');
      }

      // 4. Get location (no parameters)
      final locationData = await _location.getLocation();

      debugPrint(
        '🌐 Location: (${locationData.latitude}, ${locationData.longitude}) '
        'accuracy=${locationData.accuracy}m '
        'source=${_detectSource(locationData.accuracy)}',
      );

      return locationData;
    } catch (e) {
      debugPrint('❌ Error getting location: $e');
      return null;
    }
  }

  // =============================================
  // ✅ GET LOCATION WITH RETRY (SMART)
  // =============================================
  Future<location_package.LocationData?> getLocationWithRetry({
    int maxAttempts = 3,
    Duration delay = const Duration(seconds: 2),
    double targetAccuracy = 100.0,
  }) async {
    location_package.LocationData? bestLocation;
    double? bestAccuracy;

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final location = await getCurrentLocation();

        if (location == null ||
            location.latitude == null ||
            location.longitude == null ||
            location.latitude == 0 ||
            location.longitude == 0) {
          debugPrint('⏳ Attempt $attempt: invalid location, retrying...');
          if (attempt < maxAttempts) await Future.delayed(delay);
          continue;
        }

        final accuracy = location.accuracy ?? 999999.0;

        // Keep best location
        if (bestAccuracy == null || accuracy < bestAccuracy) {
          bestLocation = location;
          bestAccuracy = accuracy;
          debugPrint(
            '✅ Attempt $attempt: accuracy improved to ${accuracy.toStringAsFixed(1)}m',
          );
        }

        // Good enough? Return immediately
        if (accuracy <= targetAccuracy) {
          debugPrint(
            '🎯 Attempt $attempt: target accuracy reached (${accuracy.toStringAsFixed(1)}m)',
          );
          return location;
        }

        // Try again if time permits
        if (attempt < maxAttempts) {
          debugPrint(
            '⏳ Attempt $attempt: accuracy too low (${accuracy.toStringAsFixed(1)}m), retrying...',
          );
          await Future.delayed(delay);
        }
      } catch (e) {
        debugPrint('❌ Attempt $attempt error: $e');
        if (attempt < maxAttempts) await Future.delayed(delay);
      }
    }

    if (bestLocation != null) {
      debugPrint(
        '✅ Using best location after $maxAttempts attempts: '
        'accuracy=${bestAccuracy?.toStringAsFixed(1)}m',
      );
      return bestLocation;
    }

    debugPrint('❌ Failed to get any location after $maxAttempts attempts');
    return null;
  }

  // =============================================
  // ✅ CHECK LOCATION MATCH
  // =============================================
  bool isLocationMatch(
    location_package.LocationData currentLocation,
    double savedLatitude,
    double savedLongitude, {
    double toleranceMeters = 50.0,
  }) {
    if (currentLocation.latitude == null || currentLocation.longitude == null) {
      return false;
    }

    final distance = calculateDistance(
      currentLocation.latitude!,
      currentLocation.longitude!,
      savedLatitude,
      savedLongitude,
    );

    return distance <= toleranceMeters;
  }

  // =============================================
  // ✅ CALCULATE DISTANCE (Haversine)
  // =============================================
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000; // Earth's radius in meters

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a =
        _sin(dLat / 2) * _sin(dLat / 2) +
        _cos(_toRadians(lat1)) *
            _cos(_toRadians(lat2)) *
            _sin(dLon / 2) *
            _sin(dLon / 2);

    final c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));
    return R * c;
  }

  // =============================================
  // ✅ GET LOCATION NAME
  // =============================================
  Future<String?> getLocationName(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final parts = [
          place.street,
          place.locality,
          place.country,
        ].where((p) => p != null && p.isNotEmpty).toList();
        return parts.join(', ');
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting location name: $e');
      return null;
    }
  }

  // =============================================
  // ✅ SAVE LOCATION TO DEVICE
  // =============================================
  Future<void> saveDeviceLocation({
    required String employeeId,
    required double latitude,
    required double longitude,
    required String deviceId,
    String? locationName,
    String? deviceName,
    String? deviceModel,
  }) async {
    try {
      final supabase = Supabase.instance.client;

      final existing = await supabase
          .from('employee_devices')
          .select()
          .eq('employee_id', employeeId)
          .eq('device_id', deviceId)
          .maybeSingle();

      if (existing != null) {
        await supabase
            .from('employee_devices')
            .update({
              'latitude': latitude,
              'longitude': longitude,
              'location_name': locationName,
              'device_name': deviceName,
              'device_model': deviceModel,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', existing['id']);
        debugPrint('✅ Device location updated: $employeeId');
      } else {
        await supabase.from('employee_devices').insert({
          'employee_id': employeeId,
          'device_id': deviceId,
          'device_name': deviceName,
          'device_model': deviceModel,
          'latitude': latitude,
          'longitude': longitude,
          'location_name': locationName,
          'is_active': true,
          'registered_at': DateTime.now().toIso8601String(),
        });
        debugPrint('✅ New device location saved: $employeeId');
      }
    } catch (e) {
      debugPrint('❌ Error saving device location: $e');
      throw Exception('Failed to save device location: $e');
    }
  }

  // =============================================
  // ✅ GET SAVED LOCATION
  // =============================================
  Future<Map<String, dynamic>?> getSavedLocation(
    String employeeId,
    String deviceId,
  ) async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('employee_devices')
          .select()
          .eq('employee_id', employeeId)
          .eq('device_id', deviceId)
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) return null;

      return {
        'latitude': response['latitude'],
        'longitude': response['longitude'],
        'locationName': response['location_name'],
        'deviceName': response['device_name'],
        'deviceModel': response['device_model'],
        'registeredAt': response['registered_at'],
      };
    } catch (e) {
      debugPrint('❌ Error getting saved location: $e');
      return null;
    }
  }

  // =============================================
  // ✅ CHECK IF LOCATION MATCHES SAVED
  // =============================================
  Future<bool> doesLocationMatchSaved({
    required String employeeId,
    required String deviceId,
    required location_package.LocationData currentLocation,
    double toleranceMeters = 50.0,
  }) async {
    try {
      final saved = await getSavedLocation(employeeId, deviceId);
      if (saved == null) return false;

      final savedLat = saved['latitude'] as double;
      final savedLng = saved['longitude'] as double;

      return isLocationMatch(
        currentLocation,
        savedLat,
        savedLng,
        toleranceMeters: toleranceMeters,
      );
    } catch (e) {
      debugPrint('❌ Error checking location match: $e');
      return false;
    }
  }

  // =============================================
  // ✅ GET DISTANCE FROM SAVED LOCATION
  // =============================================
  Future<double?> getDistanceFromSavedLocation({
    required String employeeId,
    required String deviceId,
    required location_package.LocationData currentLocation,
  }) async {
    try {
      final saved = await getSavedLocation(employeeId, deviceId);
      if (saved == null) return null;

      final savedLat = saved['latitude'] as double;
      final savedLng = saved['longitude'] as double;

      if (currentLocation.latitude == null ||
          currentLocation.longitude == null) {
        return null;
      }

      return calculateDistance(
        currentLocation.latitude!,
        currentLocation.longitude!,
        savedLat,
        savedLng,
      );
    } catch (e) {
      debugPrint('❌ Error getting distance from saved location: $e');
      return null;
    }
  }

  // =============================================
  // ✅ PRIVATE HELPERS
  // =============================================
  String _detectSource(double? accuracy) {
    if (accuracy == null) return 'Unknown';
    if (accuracy <= 20) return 'GPS';
    if (accuracy <= 100) return 'GPS/WiFi';
    if (accuracy <= 500) return 'WiFi';
    return 'IP (inaccurate)';
  }

  double _toRadians(double degrees) => degrees * (3.141592653589793 / 180);

  double _sin(double x) => x - x * x * x / 6 + x * x * x * x * x / 120;

  double _cos(double x) => 1 - x * x / 2 + x * x * x * x / 24;

  double _sqrt(double x) {
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 10; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  double _atan2(double y, double x) {
    if (x == 0) {
      return y > 0 ? 3.141592653589793 / 2 : -3.141592653589793 / 2;
    }
    final ratio = y / x;
    return ratio -
        ratio * ratio * ratio / 3 +
        ratio * ratio * ratio * ratio * ratio / 5;
  }
}

// ==================== LOCATION DATA EXTENSION ====================
extension LocationDataExtension on location_package.LocationData {
  /// التحقق من صحة الموقع
  bool get isValid => latitude != 0 && longitude != 0;

  /// عرض الموقع كنص
  String get display {
    if (latitude == null || longitude == null) return 'Unknown';
    return '(${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)})';
  }

  /// حساب المسافة إلى نقطة أخرى
  double distanceTo(double lat, double lng) {
    if (latitude == null || longitude == null) return double.infinity;
    return LocationService().calculateDistance(latitude!, longitude!, lat, lng);
  }

  /// التحقق من الموقع ضمن نطاق معين
  bool isWithinRange(double lat, double lng, double toleranceMeters) {
    if (latitude == null || longitude == null) return false;
    final distance = LocationService().calculateDistance(
      latitude!,
      longitude!,
      lat,
      lng,
    );
    return distance <= toleranceMeters;
  }
}
