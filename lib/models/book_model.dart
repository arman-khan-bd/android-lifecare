import '../widgets/app_network_image.dart';

class BookModel {
  final int id;
  final String title;
  final String? subtitle;
  final String? slug;
  final String author;
  final String? brand;
  final String? category;
  final String? description;
  final String? usageInstructions;
  final double price;
  final double discountPrice;
  final double effectivePrice;
  final int stockCount;
  final String stockStatus; // 'in_stock', 'limited_stock', 'out_of_stock'
  final bool isActive;
  final int pages;
  final int unitCount;
  final String? displayUnits;
  final String? dosageForm;
  final String? edition;
  final String? badge;
  final String? paperQuality;
  final String? bindingType;
  final String? origin;
  final String? certification;
  final bool freeDelivery;
  final bool isFeatured;
  final bool isPrescriptionRequired;
  final String? coverImage;
  final String? coverImageRaw;
  final List<String> galleryImages;
  final List<String> galleryImagesRaw;
  final String? samplePdfUrl;
  final List<String> features;
  final List<String> packageItems;
  final List<String> freeGifts;
  final List<String> keyPoints;
  final int ordersCount;
  final int totalSold;
  final String? createdAt;
  final String? updatedAt;

  // Compatibility getter for legacy code
  int get stock => stockCount;

  bool get isInStock => stockStatus == 'in_stock' && stockCount > 0;
  bool get isLimitedStock => stockStatus == 'limited_stock';
  bool get isOutOfStock => stockStatus == 'out_of_stock' || stockCount <= 0;

  String get displayBrand => (brand != null && brand!.isNotEmpty) ? brand! : (author.isNotEmpty ? author : 'Life Care Medicine BD');
  String get displayDosage => dosageForm ?? bindingType ?? 'ক্যাপসুল';
  int get displayUnitsCount => unitCount > 0 ? unitCount : (pages > 0 ? pages : 60);

  String? fullCoverUrl([String? baseUrl]) {
    final raw = coverImage ?? coverImageRaw;
    if (raw == null || raw.trim().isEmpty) return null;
    return AppNetworkImage.normalizeUrl(raw, baseUrl: baseUrl);
  }

  List<String> fullGalleryUrls([String? baseUrl]) {
    final list = galleryImages.isNotEmpty ? galleryImages : galleryImagesRaw;
    return list
        .map((url) => AppNetworkImage.normalizeUrl(url, baseUrl: baseUrl))
        .whereType<String>()
        .toList();
  }

  /// Returns full list of all images with cover image first, followed by unique gallery images.
  List<String> allImages([String? baseUrl]) {
    final list = <String>[];
    final cover = fullCoverUrl(baseUrl);
    if (cover != null && cover.isNotEmpty) list.add(cover);
    for (final img in fullGalleryUrls(baseUrl)) {
      if (!list.contains(img)) list.add(img);
    }
    return list;
  }

  BookModel({
    required this.id,
    required this.title,
    this.subtitle,
    this.slug,
    this.author = 'Life Care Medicine BD',
    this.brand,
    this.category,
    this.description,
    this.usageInstructions,
    required this.price,
    required this.discountPrice,
    double? effectivePrice,
    required this.stockCount,
    this.stockStatus = 'in_stock',
    required this.isActive,
    this.pages = 0,
    this.unitCount = 0,
    this.displayUnits,
    this.dosageForm,
    this.edition,
    this.badge,
    this.paperQuality,
    this.bindingType,
    this.origin,
    this.certification,
    this.freeDelivery = false,
    required this.isFeatured,
    this.isPrescriptionRequired = false,
    this.coverImage,
    this.coverImageRaw,
    this.galleryImages = const [],
    this.galleryImagesRaw = const [],
    this.samplePdfUrl,
    this.features = const [],
    this.packageItems = const [],
    this.freeGifts = const [],
    this.keyPoints = const [],
    required this.ordersCount,
    required this.totalSold,
    this.createdAt,
    this.updatedAt,
  }) : effectivePrice = effectivePrice ?? (discountPrice > 0 ? discountPrice : price);

  factory BookModel.fromJson(Map<String, dynamic> json) {
    final rawPrice = _toDouble(json['price']);
    final rawDiscount = _toDouble(json['discount_price']);

    int stockVal = 0;
    if (json['stock_count'] != null) {
      stockVal = json['stock_count'] is int ? json['stock_count'] : int.tryParse(json['stock_count'].toString()) ?? 0;
    } else if (json['stock'] != null) {
      stockVal = json['stock'] is int ? json['stock'] : int.tryParse(json['stock'].toString()) ?? 0;
    }

    String status = json['stock_status']?.toString() ?? (stockVal > 0 ? 'in_stock' : 'out_of_stock');
    bool active = json['is_active'] == true || json['is_active'] == 1 || status != 'out_of_stock';

    int parsedPages = json['pages'] is int ? json['pages'] : int.tryParse(json['pages']?.toString() ?? '0') ?? 0;
    int parsedUnitCount = json['unit_count'] is int ? json['unit_count'] : int.tryParse(json['unit_count']?.toString() ?? '0') ?? parsedPages;

    return BookModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      title: json['title'] ?? '',
      subtitle: json['subtitle'],
      slug: json['slug'],
      author: json['author'] ?? json['brand'] ?? 'Life Care Medicine BD',
      brand: json['brand'] ?? json['author'],
      category: json['category'],
      description: json['description'],
      usageInstructions: json['usage_instructions'],
      price: rawPrice,
      discountPrice: rawDiscount,
      effectivePrice: _toDouble(json['effective_price']) > 0
          ? _toDouble(json['effective_price'])
          : (rawDiscount > 0 ? rawDiscount : rawPrice),
      stockCount: stockVal,
      stockStatus: status,
      isActive: active,
      pages: parsedPages,
      unitCount: parsedUnitCount,
      displayUnits: json['display_units'],
      dosageForm: json['dosage_form'] ?? json['binding_type'],
      edition: json['edition'],
      badge: json['badge'],
      paperQuality: json['paper_quality'] ?? json['certification'],
      bindingType: json['binding_type'] ?? json['dosage_form'],
      origin: json['origin'] ?? 'বাংলাদেশ',
      certification: json['certification'] ?? json['paper_quality'],
      freeDelivery: json['free_delivery'] == true || json['free_delivery'] == 1 || json['free_delivery'] == '1',
      isFeatured: json['is_featured'] == true || json['is_featured'] == 1 || json['is_featured'] == '1',
      isPrescriptionRequired: json['is_prescription_required'] == true || json['is_prescription_required'] == 1,
      coverImage: json['cover_image'],
      coverImageRaw: json['cover_image_raw'],
      galleryImages: _toStringList(json['gallery_images']),
      galleryImagesRaw: _toStringList(json['gallery_images_raw']),
      samplePdfUrl: json['sample_pdf_url'],
      features: _toStringList(json['features']),
      packageItems: _toStringList(json['package_items']),
      freeGifts: _toStringList(json['free_gifts']),
      keyPoints: _toStringList(json['key_points']),
      ordersCount: json['orders_count'] is int ? json['orders_count'] : int.tryParse(json['orders_count']?.toString() ?? '0') ?? 0,
      totalSold: json['total_sold'] is int ? json['total_sold'] : int.tryParse(json['total_sold']?.toString() ?? '0') ?? 0,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'subtitle': subtitle,
      'slug': slug,
      'author': author,
      'brand': brand ?? author,
      'category': category,
      'description': description,
      'usage_instructions': usageInstructions,
      'price': price,
      'discount_price': discountPrice,
      'stock_count': stockCount,
      'stock_status': stockStatus,
      'pages': pages,
      'unit_count': unitCount,
      'dosage_form': dosageForm ?? bindingType,
      'edition': edition,
      'badge': badge,
      'paper_quality': paperQuality,
      'binding_type': bindingType,
      'origin': origin,
      'certification': certification,
      'free_delivery': freeDelivery,
      'is_featured': isFeatured,
      'is_prescription_required': isPrescriptionRequired,
      'cover_image': coverImage,
      'gallery_images': galleryImages,
      'sample_pdf_url': samplePdfUrl,
      'features': features,
      'package_items': packageItems,
      'free_gifts': freeGifts,
      'key_points': keyPoints,
    };
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static List<String> _toStringList(dynamic v) {
    if (v == null) return [];
    if (v is List) {
      return v.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
    }
    return [];
  }
}

/// Backwards compatibility typedef so screens can use MedicineModel and BookModel interchangeably
typedef MedicineModel = BookModel;

