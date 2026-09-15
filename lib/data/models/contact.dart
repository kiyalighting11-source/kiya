// lib/data/models/contact.dart

// =============================================
// ✅ IMPORTS - MUST BE AT THE TOP
// =============================================
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

// =============================================
// ✅ CONTACT MODEL
// =============================================

/// ✅ Model for Contact - represents a customer or contact person
class Contact {
  // ==================== BASIC FIELDS ====================
  final String? id;
  final String? companyId;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;
  final String? mobile;
  final String? whatsappNumber;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final String? postalCode;
  final String? website;

  // ==================== COMPANY INFO ====================
  final String? company;
  final String? jobTitle;
  final String? department;

  // ==================== SOCIAL MEDIA ====================
  final String? facebook;
  final String? twitter;
  final String? linkedin;
  final String? instagram;
  final String? youtube;

  // ==================== CATEGORY & TAGS ====================
  final String? category;
  final List<String>? tags;
  final String? source;
  final String? status;

  // ==================== NOTES & METADATA ====================
  final String? notes;
  final String? avatarUrl;
  final DateTime? birthday;
  final DateTime? anniversary;

  // ==================== SYSTEM FIELDS ====================
  final bool isActive;
  final bool isFavorite;
  final bool isBlocked;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final String? updatedBy;

  // ==================== CONSTRUCTOR ====================
  Contact({
    this.id,
    this.companyId,
    required this.firstName,
    required this.lastName,
    this.email,
    this.phone,
    this.mobile,
    this.whatsappNumber,
    this.address,
    this.city,
    this.state,
    this.country,
    this.postalCode,
    this.website,
    this.company,
    this.jobTitle,
    this.department,
    this.facebook,
    this.twitter,
    this.linkedin,
    this.instagram,
    this.youtube,
    this.category,
    this.tags,
    this.source,
    this.status,
    this.notes,
    this.avatarUrl,
    this.birthday,
    this.anniversary,
    this.isActive = true,
    this.isFavorite = false,
    this.isBlocked = false,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
  });

  // ==================== GETTERS ====================

  /// ✅ Full name of the contact
  String get fullName => '$firstName $lastName'.trim();

  /// ✅ Display name (full name or email or phone)
  String get displayName {
    if (fullName.isNotEmpty) {
      return fullName;
    }
    if (email != null && email!.isNotEmpty) {
      return email!;
    }
    if (phone != null && phone!.isNotEmpty) {
      return phone!;
    }
    if (mobile != null && mobile!.isNotEmpty) {
      return mobile!;
    }
    return 'غير معروف';
  }

  /// ✅ Primary phone number (mobile > phone > whatsapp)
  String? get primaryPhone {
    if (mobile != null && mobile!.isNotEmpty) {
      return mobile;
    }
    if (phone != null && phone!.isNotEmpty) {
      return phone;
    }
    if (whatsappNumber != null && whatsappNumber!.isNotEmpty) {
      return whatsappNumber;
    }
    return null;
  }

  /// ✅ Primary email (email > whatsappNumber as email)
  String? get primaryEmail {
    if (email != null && email!.isNotEmpty) {
      return email;
    }
    return null;
  }

  /// ✅ Check if contact has valid phone number
  bool get hasPhone => primaryPhone != null && primaryPhone!.isNotEmpty;

  /// ✅ Check if contact has valid email
  bool get hasEmail => email != null && email!.isNotEmpty;

  /// ✅ Check if contact has whatsapp
  bool get hasWhatsapp => whatsappNumber != null && whatsappNumber!.isNotEmpty;

  /// ✅ Get initials for avatar
  String get initials {
    final first = firstName.isNotEmpty ? firstName[0] : '';
    final last = lastName.isNotEmpty ? lastName[0] : '';
    return '$first$last'.toUpperCase();
  }

  /// ✅ Get avatar color based on name
  Color get avatarColor {
    final colors = [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
      Colors.grey,
      Colors.blueGrey,
    ];

    final index = fullName.hashCode.abs() % colors.length;
    return colors[index];
  }

  /// ✅ Get avatar color with opacity for background
  Color get avatarBackgroundColor {
    return avatarColor.withValues(alpha: 0.1);
  }

  /// ✅ Get formatted birthday
  String? get formattedBirthday {
    if (birthday == null) {
      return null;
    }
    return DateFormat('d MMMM y', 'ar').format(birthday!);
  }

  /// ✅ Get age from birthday
  int? get age {
    if (birthday == null) {
      return null;
    }
    final today = DateTime.now();
    int age = today.year - birthday!.year;
    if (today.month < birthday!.month ||
        (today.month == birthday!.month && today.day < birthday!.day)) {
      age--;
    }
    return age;
  }

  /// ✅ Get full address
  String get fullAddress {
    final parts = <String>[];
    if (address != null && address!.isNotEmpty) {
      parts.add(address!);
    }
    if (city != null && city!.isNotEmpty) {
      parts.add(city!);
    }
    if (state != null && state!.isNotEmpty) {
      parts.add(state!);
    }
    if (country != null && country!.isNotEmpty) {
      parts.add(country!);
    }
    if (postalCode != null && postalCode!.isNotEmpty) {
      parts.add(postalCode!);
    }
    return parts.join(', ');
  }

  /// ✅ Check if contact is complete (has required fields)
  bool get isComplete {
    return firstName.isNotEmpty &&
        lastName.isNotEmpty &&
        (hasPhone || hasEmail);
  }

  /// ✅ Check if contact is valid
  bool get isValid {
    return id != null &&
        id!.isNotEmpty &&
        firstName.isNotEmpty &&
        lastName.isNotEmpty;
  }

  /// ✅ Get category display name
  String get categoryDisplay {
    if (category == null || category!.isEmpty) {
      return 'غير مصنف';
    }
    return category!;
  }

  /// ✅ Get status display name
  String get statusDisplay {
    if (status == null || status!.isEmpty) {
      return 'نشط';
    }
    return status!;
  }

  /// ✅ Get tags as string
  String get tagsDisplay {
    if (tags == null || tags!.isEmpty) {
      return 'لا يوجد';
    }
    return tags!.join(', ');
  }

  // ==================== FROM JSON ====================
  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'],
      companyId: json['company_id'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'],
      phone: json['phone'],
      mobile: json['mobile'],
      whatsappNumber: json['whatsapp_number'],
      address: json['address'],
      city: json['city'],
      state: json['state'],
      country: json['country'],
      postalCode: json['postal_code'],
      website: json['website'],
      company: json['company'],
      jobTitle: json['job_title'],
      department: json['department'],
      facebook: json['facebook'],
      twitter: json['twitter'],
      linkedin: json['linkedin'],
      instagram: json['instagram'],
      youtube: json['youtube'],
      category: json['category'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      source: json['source'],
      status: json['status'],
      notes: json['notes'],
      avatarUrl: json['avatar_url'],
      birthday: json['birthday'] != null
          ? DateTime.parse(json['birthday'])
          : null,
      anniversary: json['anniversary'] != null
          ? DateTime.parse(json['anniversary'])
          : null,
      isActive: json['is_active'] ?? true,
      isFavorite: json['is_favorite'] ?? false,
      isBlocked: json['is_blocked'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      createdBy: json['created_by'],
      updatedBy: json['updated_by'],
    );
  }

  // ==================== TO JSON ====================
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'mobile': mobile,
      'whatsapp_number': whatsappNumber,
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      'postal_code': postalCode,
      'website': website,
      'company': company,
      'job_title': jobTitle,
      'department': department,
      'facebook': facebook,
      'twitter': twitter,
      'linkedin': linkedin,
      'instagram': instagram,
      'youtube': youtube,
      'category': category,
      'tags': tags,
      'source': source,
      'status': status,
      'notes': notes,
      'avatar_url': avatarUrl,
      'birthday': birthday?.toIso8601String(),
      'anniversary': anniversary?.toIso8601String(),
      'is_active': isActive,
      'is_favorite': isFavorite,
      'is_blocked': isBlocked,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'created_by': createdBy,
      'updated_by': updatedBy,
    };
  }

  // ==================== COPY WITH ====================
  Contact copyWith({
    String? id,
    String? companyId,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? mobile,
    String? whatsappNumber,
    String? address,
    String? city,
    String? state,
    String? country,
    String? postalCode,
    String? website,
    String? company,
    String? jobTitle,
    String? department,
    String? facebook,
    String? twitter,
    String? linkedin,
    String? instagram,
    String? youtube,
    String? category,
    List<String>? tags,
    String? source,
    String? status,
    String? notes,
    String? avatarUrl,
    DateTime? birthday,
    DateTime? anniversary,
    bool? isActive,
    bool? isFavorite,
    bool? isBlocked,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
  }) {
    return Contact(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      mobile: mobile ?? this.mobile,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      postalCode: postalCode ?? this.postalCode,
      website: website ?? this.website,
      company: company ?? this.company,
      jobTitle: jobTitle ?? this.jobTitle,
      department: department ?? this.department,
      facebook: facebook ?? this.facebook,
      twitter: twitter ?? this.twitter,
      linkedin: linkedin ?? this.linkedin,
      instagram: instagram ?? this.instagram,
      youtube: youtube ?? this.youtube,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      source: source ?? this.source,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      birthday: birthday ?? this.birthday,
      anniversary: anniversary ?? this.anniversary,
      isActive: isActive ?? this.isActive,
      isFavorite: isFavorite ?? this.isFavorite,
      isBlocked: isBlocked ?? this.isBlocked,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  // ==================== OVERRIDES ====================
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is Contact && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Contact(id: $id, name: $fullName, email: $email, phone: $phone)';
  }
}

// =============================================
// ✅ CONTACT CATEGORY ENUM
// =============================================
enum ContactCategory {
  customer('عميل', Icons.person),
  supplier('مورد', Icons.local_shipping),
  partner('شريك', Icons.handshake),
  lead('عميل محتمل', Icons.people_outline),
  employee('موظف', Icons.work),
  other('آخر', Icons.more_horiz);

  final String arabic;
  final IconData icon;

  const ContactCategory(this.arabic, this.icon);

  static ContactCategory fromString(String value) {
    return ContactCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase() || e.arabic == value,
      orElse: () => ContactCategory.other,
    );
  }

  String get label => arabic;
}

// =============================================
// ✅ CONTACT STATUS ENUM
// =============================================
enum ContactStatus {
  active('نشط', Colors.green),
  inactive('غير نشط', Colors.grey),
  blocked('محظور', Colors.red),
  pending('قيد الانتظار', Colors.orange),
  archived('مؤرشف', Colors.blue);

  final String arabic;
  final Color color;

  const ContactStatus(this.arabic, this.color);

  static ContactStatus fromString(String value) {
    return ContactStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase() || e.arabic == value,
      orElse: () => ContactStatus.active,
    );
  }

  String get label => arabic;
}

// =============================================
// ✅ CONTACT SOURCE ENUM
// =============================================
enum ContactSource {
  website('الموقع الإلكتروني'),
  social('وسائل التواصل'),
  referral('إحالة'),
  email('البريد الإلكتروني'),
  phone('الهاتف'),
  event('فعالية'),
  other('آخر');

  final String arabic;

  const ContactSource(this.arabic);

  static ContactSource fromString(String value) {
    return ContactSource.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase() || e.arabic == value,
      orElse: () => ContactSource.other,
    );
  }

  String get label => arabic;
}

// =============================================
// ✅ CONTACT FILTERS
// =============================================
class ContactFilters {
  final String? searchQuery;
  final ContactCategory? category;
  final ContactStatus? status;
  final ContactSource? source;
  final bool? isFavorite;
  final bool? hasEmail;
  final bool? hasPhone;
  final bool? isActive;
  final DateTime? createdAfter;
  final DateTime? createdBefore;
  final String? companyId;
  final String? assignedTo;
  final List<String>? tags;
  final int? limit;
  final int? offset;
  final String? sortBy;
  final bool? sortAscending;

  ContactFilters({
    this.searchQuery,
    this.category,
    this.status,
    this.source,
    this.isFavorite,
    this.hasEmail,
    this.hasPhone,
    this.isActive,
    this.createdAfter,
    this.createdBefore,
    this.companyId,
    this.assignedTo,
    this.tags,
    this.limit,
    this.offset,
    this.sortBy,
    this.sortAscending = true,
  });

  bool get hasFilters {
    return searchQuery != null ||
        category != null ||
        status != null ||
        source != null ||
        isFavorite != null ||
        hasEmail != null ||
        hasPhone != null ||
        isActive != null ||
        createdAfter != null ||
        createdBefore != null ||
        companyId != null ||
        assignedTo != null ||
        (tags != null && tags!.isNotEmpty);
  }

  ContactFilters copyWith({
    String? searchQuery,
    ContactCategory? category,
    ContactStatus? status,
    ContactSource? source,
    bool? isFavorite,
    bool? hasEmail,
    bool? hasPhone,
    bool? isActive,
    DateTime? createdAfter,
    DateTime? createdBefore,
    String? companyId,
    String? assignedTo,
    List<String>? tags,
    int? limit,
    int? offset,
    String? sortBy,
    bool? sortAscending,
  }) {
    return ContactFilters(
      searchQuery: searchQuery ?? this.searchQuery,
      category: category ?? this.category,
      status: status ?? this.status,
      source: source ?? this.source,
      isFavorite: isFavorite ?? this.isFavorite,
      hasEmail: hasEmail ?? this.hasEmail,
      hasPhone: hasPhone ?? this.hasPhone,
      isActive: isActive ?? this.isActive,
      createdAfter: createdAfter ?? this.createdAfter,
      createdBefore: createdBefore ?? this.createdBefore,
      companyId: companyId ?? this.companyId,
      assignedTo: assignedTo ?? this.assignedTo,
      tags: tags ?? this.tags,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};
    if (searchQuery != null && searchQuery!.isNotEmpty) {
      params['search'] = searchQuery;
    }
    if (category != null) {
      params['category'] = category!.name;
    }
    if (status != null) {
      params['status'] = status!.name;
    }
    if (source != null) {
      params['source'] = source!.name;
    }
    if (isFavorite != null) {
      params['is_favorite'] = isFavorite;
    }
    if (hasEmail != null) {
      params['has_email'] = hasEmail;
    }
    if (hasPhone != null) {
      params['has_phone'] = hasPhone;
    }
    if (isActive != null) {
      params['is_active'] = isActive;
    }
    if (createdAfter != null) {
      params['created_after'] = createdAfter!.toIso8601String();
    }
    if (createdBefore != null) {
      params['created_before'] = createdBefore!.toIso8601String();
    }
    if (companyId != null) {
      params['company_id'] = companyId;
    }
    if (assignedTo != null) {
      params['assigned_to'] = assignedTo;
    }
    if (tags != null && tags!.isNotEmpty) {
      params['tags'] = tags;
    }
    if (limit != null) {
      params['limit'] = limit;
    }
    if (offset != null) {
      params['offset'] = offset;
    }
    if (sortBy != null) {
      params['sort_by'] = sortBy;
    }
    if (sortAscending != null) {
      params['sort_ascending'] = sortAscending;
    }
    return params;
  }
}

// =============================================
// ✅ CONTACT GROUP
// =============================================
class ContactGroup {
  final String id;
  final String name;
  final String? description;
  final List<String>? contactIds;
  final String? color;
  final String? icon;
  final int? contactCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ContactGroup({
    required this.id,
    required this.name,
    this.description,
    this.contactIds,
    this.color,
    this.icon,
    this.contactCount,
    this.createdAt,
    this.updatedAt,
  });

  factory ContactGroup.fromJson(Map<String, dynamic> json) {
    return ContactGroup(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      contactIds: json['contact_ids'] != null
          ? List<String>.from(json['contact_ids'])
          : null,
      color: json['color'],
      icon: json['icon'],
      contactCount: json['contact_count'],
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
      'id': id,
      'name': name,
      'description': description,
      'contact_ids': contactIds,
      'color': color,
      'icon': icon,
      'contact_count': contactCount,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  ContactGroup copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? contactIds,
    String? color,
    String? icon,
    int? contactCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ContactGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      contactIds: contactIds ?? this.contactIds,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      contactCount: contactCount ?? this.contactCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
