class Customer {
  final String? id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? country;
  final String? notes;
  final String? facebook;
  final String? instagram;
  final String? twitter;
  final String? website;
  final String? snapchat;
  final String? wechat;
  final String? whatsapp;
  final String? needs;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Customer({
    this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.country,
    this.notes,
    this.facebook,
    this.instagram,
    this.twitter,
    this.website,
    this.snapchat,
    this.wechat,
    this.whatsapp,
    this.needs,
    this.createdAt,
    this.updatedAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      name: json['name'] ?? '',
      phone: json['phone'],
      email: json['email'],
      address: json['address'],
      country: json['country'],
      notes: json['notes'],
      facebook: json['facebook'],
      instagram: json['instagram'],
      twitter: json['twitter'],
      website: json['website'],
      snapchat: json['snapchat'],
      wechat: json['wechat'],
      whatsapp: json['whatsapp'],
      needs: json['needs'],
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
      'phone': phone,
      'email': email,
      'address': address,
      'country': country,
      'notes': notes,
      'facebook': facebook,
      'instagram': instagram,
      'twitter': twitter,
      'website': website,
      'snapchat': snapchat,
      'wechat': wechat,
      'whatsapp': whatsapp,
      'needs': needs,
    };
  }

  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? country,
    String? notes,
    String? facebook,
    String? instagram,
    String? twitter,
    String? website,
    String? snapchat,
    String? wechat,
    String? whatsapp,
    String? needs,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      country: country ?? this.country,
      notes: notes ?? this.notes,
      facebook: facebook ?? this.facebook,
      instagram: instagram ?? this.instagram,
      twitter: twitter ?? this.twitter,
      website: website ?? this.website,
      snapchat: snapchat ?? this.snapchat,
      wechat: wechat ?? this.wechat,
      whatsapp: whatsapp ?? this.whatsapp,
      needs: needs ?? this.needs,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // استخراج اسم البلد من رقم الهاتف
  static String? extractCountryFromPhone(String? phone) {
    if (phone == null || phone.isEmpty) return null;

    // تنظيف الرقم من المسافات والرموز غير الأرقام
    String cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');

    // قائمة رموز الدول (يمكن توسيعها)
    final countryCodes = {
      // الدول العربية
      '+20': 'مصر',
      '+966': 'السعودية',
      '+971': 'الإمارات',
      '+962': 'الأردن',
      '+961': 'لبنان',
      '+970': 'فلسطين',
      '+972': 'إسرائيل',
      '+964': 'العراق',
      '+965': 'الكويت',
      '+968': 'عُمان',
      '+974': 'قطر',
      '+973': 'البحرين',
      '+967': 'اليمن',
      '+963': 'سوريا',
      '+218': 'ليبيا',
      '+216': 'تونس',
      '+213': 'الجزائر',
      '+212': 'المغرب',
      '+222': 'موريتانيا',
      '+249': 'السودان',
      '+252': 'الصومال',
      '+253': 'جيبوتي',
      '+211': 'جنوب السودان',
      // الدول الأفريقية
      '+256': 'أوغندا',
      '+254': 'كينيا',
      '+255': 'تنزانيا',
      '+251': 'إثيوبيا',
      '+250': 'رواندا',
      '+257': 'بوروندي',
      '+258': 'موزمبيق',
      '+260': 'زامبيا',
      '+261': 'مدغشقر',
      '+263': 'زيمبابوي',
      '+265': 'مالاوي',
      '+266': 'ليسوتو',
      '+267': 'بوتسوانا',
      '+268': 'إسواتيني',
      '+269': 'جزر القمر',
      '+27': 'جنوب أفريقيا',
      // الدول الأوروبية
      '+30': 'اليونان',
      '+31': 'هولندا',
      '+32': 'بلجيكا',
      '+33': 'فرنسا',
      '+34': 'إسبانيا',
      '+36': 'المجر',
      '+39': 'إيطاليا',
      '+40': 'رومانيا',
      '+41': 'سويسرا',
      '+43': 'النمسا',
      '+44': 'المملكة المتحدة',
      '+45': 'الدنمارك',
      '+46': 'السويد',
      '+47': 'النرويج',
      '+48': 'بولندا',
      '+49': 'ألمانيا',
      // الدول الأمريكية
      '+51': 'بيرو',
      '+52': 'المكسيك',
      '+53': 'كوبا',
      '+54': 'الأرجنتين',
      '+55': 'البرازيل',
      '+56': 'تشيلي',
      '+57': 'كولومبيا',
      '+58': 'فنزويلا',
      '+1': 'الولايات المتحدة/كندا',
      // الدول الآسيوية
      '+60': 'ماليزيا',
      '+61': 'أستراليا',
      '+62': 'إندونيسيا',
      '+63': 'الفلبين',
      '+64': 'نيوزيلندا',
      '+65': 'سنغافورة',
      '+66': 'تايلاند',
      '+81': 'اليابان',
      '+82': 'كوريا الجنوبية',
      '+84': 'فيتنام',
      '+86': 'الصين',
      '+90': 'تركيا',
      '+91': 'الهند',
      '+92': 'باكستان',
      '+93': 'أفغانستان',
      '+94': 'سريلانكا',
      '+95': 'ميانمار',
      '+98': 'إيران',
    };

    for (var entry in countryCodes.entries) {
      if (cleanPhone.startsWith(entry.key)) {
        return entry.value;
      }
    }

    return null;
  }

  // التحقق من صحة رقم الهاتف
  static bool isValidPhone(String? phone) {
    if (phone == null || phone.isEmpty) return false;
    final country = extractCountryFromPhone(phone);
    return country != null;
  }
}