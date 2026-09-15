// lib/data/repositories/company_location_repository.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/company_location.dart';

class CompanyLocationRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// جلب الموقع الافتراضي النشط
  Future<CompanyLocation?> getDefaultLocation() async {
    try {
      debugPrint('🔍 [Repo] Fetching company location...');
      debugPrint('🔍 [Repo] Auth user: ${_supabase.auth.currentUser?.id}');
      debugPrint('🔍 [Repo] Session: ${_supabase.auth.currentSession != null}');

      // ✅ استخدم select عادي بدل maybeSingle عشان نتجنب مشاكل
      final response = await _supabase
          .from('company_locations')
          .select(
            'id, name, latitude, longitude, radius_meters, is_active, created_at, updated_at',
          )
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(1);

      debugPrint('🔍 [Repo] Response count: ${response.length}');
      debugPrint('🔍 [Repo] Response: $response');

      if (response.isEmpty) {
        debugPrint('🔍 [Repo] ⚠️ No active company location found');
        return null;
      }

      final location = CompanyLocation.fromJson(response.first);
      debugPrint(
        '🔍 [Repo] ✅ Parsed: ${location.name} '
        '(${location.latitude}, ${location.longitude})',
      );
      return location;
    } catch (e, st) {
      debugPrint('🔍 [Repo] ❌ Exception: $e');
      debugPrint('🔍 [Repo] Stack: $st');
      return null;
    }
  }

  /// جلب كل المواقع
  Future<List<CompanyLocation>> getAllLocations() async {
    try {
      final response = await _supabase
          .from('company_locations')
          .select()
          .order('created_at', ascending: false);

      return response
          .map<CompanyLocation>((json) => CompanyLocation.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting locations: $e');
      return [];
    }
  }

  /// إضافة موقع جديد
  Future<CompanyLocation> createLocation(CompanyLocation location) async {
    final response = await _supabase
        .from('company_locations')
        .insert(location.toJson())
        .select()
        .single();

    return CompanyLocation.fromJson(response);
  }

  /// تحديث موقع
  Future<CompanyLocation> updateLocation(CompanyLocation location) async {
    final response = await _supabase
        .from('company_locations')
        .update(location.toJson())
        .eq('id', location.id)
        .select()
        .single();

    return CompanyLocation.fromJson(response);
  }

  /// حذف موقع
  Future<void> deleteLocation(String id) async {
    await _supabase.from('company_locations').delete().eq('id', id);
  }
}
