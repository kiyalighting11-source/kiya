// lib/data/models/warehouse.dart

class Warehouse {
  final String? id;
  final String name;
  final String? code;
  final String? location;
  final String? manager;
  final String? phone;
  final String? description;
  final bool? isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Warehouse({
    this.id,
    required this.name,
    this.code,
    this.location,
    this.manager,
    this.phone,
    this.description,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory Warehouse.fromJson(Map<String, dynamic> json) {
    return Warehouse(
      id: json['id'],
      name: json['name'] ?? '',
      code: json['code'],
      location: json['location'],
      manager: json['manager'],
      phone: json['phone'],
      description: json['description'],
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
      'code': code,
      'location': location,
      'manager': manager,
      'phone': phone,
      'description': description,
      'is_active': isActive,
    };
  }

  Warehouse copyWith({
    String? id,
    String? name,
    String? code,
    String? location,
    String? manager,
    String? phone,
    String? description,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Warehouse(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      location: location ?? this.location,
      manager: manager ?? this.manager,
      phone: phone ?? this.phone,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get displayName => '$name${code != null ? ' ($code)' : ''}';
}
