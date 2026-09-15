// lib/data/models/company_location.dart

class CompanyLocation {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final int radiusMeters;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CompanyLocation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 200,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory CompanyLocation.fromJson(Map<String, dynamic> json) {
    return CompanyLocation(
      id: json['id'],
      name: json['name'] ?? 'غير معروف',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radiusMeters: (json['radius_meters'] as num?)?.toInt() ?? 200,
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'radius_meters': radiusMeters,
      'is_active': isActive,
    };
  }

  String get display =>
      '$name (${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)})';
}
