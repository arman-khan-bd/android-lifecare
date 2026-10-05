class SectionModel {
  final int id;
  final String sectionKey;
  final String name;
  final bool isActive;
  final int sortOrder;
  final String? imageUrl;
  final String? previewImage;
  final String? defaultImage;
  final Map<String, dynamic> content;

  SectionModel({
    required this.id,
    required this.sectionKey,
    required this.name,
    required this.isActive,
    required this.sortOrder,
    this.imageUrl,
    this.previewImage,
    this.defaultImage,
    this.content = const {},
  });

  factory SectionModel.fromJson(Map<String, dynamic> json) {
    final rawContent = json['content'];
    Map<String, dynamic> parsedContent = {};
    if (rawContent is Map<String, dynamic>) {
      parsedContent = Map<String, dynamic>.from(rawContent);
    } else if (rawContent is Map) {
      parsedContent = rawContent.map((k, v) => MapEntry(k.toString(), v));
    }

    return SectionModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      sectionKey: json['section_key']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      isActive: json['is_active'] == true || json['is_active'] == 1 || json['is_active'] == '1',
      sortOrder: json['sort_order'] is int ? json['sort_order'] : int.tryParse(json['sort_order']?.toString() ?? '0') ?? 0,
      imageUrl: json['image_url']?.toString(),
      previewImage: json['preview_image']?.toString(),
      defaultImage: json['default_image']?.toString(),
      content: parsedContent,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'section_key': sectionKey,
      'name': name,
      'is_active': isActive,
      'sort_order': sortOrder,
      'image_url': imageUrl,
      'content': content,
    };
  }

  SectionModel copyWith({
    int? id,
    String? sectionKey,
    String? name,
    bool? isActive,
    int? sortOrder,
    String? imageUrl,
    String? previewImage,
    String? defaultImage,
    Map<String, dynamic>? content,
  }) {
    return SectionModel(
      id: id ?? this.id,
      sectionKey: sectionKey ?? this.sectionKey,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      imageUrl: imageUrl ?? this.imageUrl,
      previewImage: previewImage ?? this.previewImage,
      defaultImage: defaultImage ?? this.defaultImage,
      content: content ?? this.content,
    );
  }

  static String? _cleanImg(dynamic val) {
    if (val == null) return null;
    final str = val.toString().trim();
    if (str.isEmpty || str == 'null' || str == 'undefined') return null;
    if (str.contains('convertflow') || str.contains('themes/convertflow')) return null;
    return str;
  }

  /// Get the best display image URL for this section (custom image, content image, or default)
  String? get displayImage {
    if (sectionKey == 'author') {
      final aImg = _cleanImg(content['author_image']);
      if (aImg != null) return aImg;
      final pImg = _cleanImg(previewImage);
      if (pImg != null) return pImg;
      final iImg = _cleanImg(imageUrl);
      if (iImg != null) return iImg;
      final cImg = _cleanImg(content['image_url']);
      if (cImg != null) return cImg;
      return _cleanImg(defaultImage) ?? '/images/lifecare/brand_profile.jpg';
    }

    if (sectionKey == 'navbar') {
      final logo = _cleanImg(content['logo_url']) ?? _cleanImg(previewImage) ?? _cleanImg(imageUrl);
      if (logo != null) return logo;
    }

    if (sectionKey == 'hero' && heroSlides.isNotEmpty) {
      final banner = _cleanImg(heroSlides.first['banner_image']) ?? _cleanImg(heroSlides.first['mobile_image_url']);
      if (banner != null) return banner;
    }

    final custom = _cleanImg(imageUrl) ?? _cleanImg(previewImage) ?? _cleanImg(content['image_url']);
    if (custom != null) return custom;

    if (sectionKey == 'footer') {
      final fImg = _cleanImg(content['payment_banner_url']);
      if (fImg != null) return fImg;
    }

    return _cleanImg(defaultImage);
  }

  /// Navbar getters
  String get logoUrl => content['logo_url']?.toString() ?? imageUrl ?? '/images/logo.png';
  String get brandTitle => content['brand_title']?.toString() ?? 'Life Care';
  String get brandSubtitle => content['brand_subtitle']?.toString() ?? 'Medicine BD';
  String get tagline => content['tagline']?.toString() ?? '';
  String get phone => content['phone']?.toString() ?? '';
  String get orderButtonText => content['order_btn_text']?.toString() ?? content['order_button_text']?.toString() ?? 'অর্ডার করুন';

  /// Notice bar getters
  String get noticeText => content['text']?.toString() ?? '';
  String get noticeBadge => content['badge']?.toString() ?? 'অফার';
  int get stockCount {
    final sc = content['stock_count'] ?? content['stock_left'];
    if (sc is int) return sc;
    if (sc != null) {
      final digits = sc.toString().replaceAll(RegExp(r'[^\d]'), '');
      return int.tryParse(digits) ?? 23;
    }
    return 23;
  }

  /// Hero slides
  List<Map<String, dynamic>> get heroSlides {
    final raw = content['slides'];
    if (raw is List) {
      return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }
}
