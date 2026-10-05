class ApiConfig {
  // Main production domain for Life Care Medicine BD
  static const String defaultBaseUrl = 'http://lifecaremedicinebd.shop';

  // Active Base URL (normalized, no trailing slashes or /home)
  static String _baseUrl = defaultBaseUrl;

  static String get baseUrl => _baseUrl;

  static set baseUrl(String url) {
    _baseUrl = sanitizeUrl(url);
  }

  /// Sanitizes any raw domain/URL string (removes /home, trailing slashes, adds protocol if missing).
  static String sanitizeUrl(String raw) {
    String clean = raw.trim();
    if (clean.isEmpty) return defaultBaseUrl;
    // Strip trailing /home or /home/
    clean = clean.replaceAll(RegExp(r'/home/?$', caseSensitive: false), '');
    // Strip trailing slashes
    clean = clean.replaceAll(RegExp(r'/+$'), '');
    if (!clean.startsWith('http://') && !clean.startsWith('https://')) {
      clean = 'http://$clean';
    }
    return clean;
  }

  static String get apiBase => '$baseUrl/api/admin';

  // API Endpoints
  static String get login => '$apiBase/login';
  static String get logout => '$apiBase/logout';
  static String get profile => '$apiBase/profile';
  static String get overview => '$apiBase/overview';
  
  static String get orders => '$apiBase/orders';
  static String orderDetail(dynamic id) => '$apiBase/orders/$id';
  static String orderStatus(dynamic id) => '$apiBase/orders/$id/status';
  static String orderPaymentStatus(dynamic id) => '$apiBase/orders/$id/payment-status';
  static String orderCourier(dynamic id) => '$apiBase/orders/$id/courier';
  static String orderSendCourier(dynamic id) => '$apiBase/orders/$id/send-to-courier';
  static String get toggleBlock => '$apiBase/orders/toggle-block';

  static String get abandonedOrders => '$apiBase/abandoned-orders';
  static String abandonedOrderStatus(dynamic id) => '$apiBase/abandoned-orders/$id/status';
  static String abandonedOrderConvert(dynamic id) => '$apiBase/abandoned-orders/$id/convert';
  static String abandonedOrderDelete(dynamic id) => '$apiBase/abandoned-orders/$id';

  // Medicines & Products
  static String get medicines => '$apiBase/medicines';
  static String medicineDetail(dynamic id) => '$apiBase/medicines/$id';
  static String get medicineUploadImage => '$apiBase/medicines/upload-image';

  // Books (Backward Compatible Aliases)
  static String get books => '$apiBase/books';
  static String bookDetail(dynamic id) => '$apiBase/books/$id';
  static String get bookUploadImage => '$apiBase/books/upload-image';

  static String get reviews => '$apiBase/reviews';
  static String reviewDetail(dynamic id) => '$apiBase/reviews/$id';
  static String reviewPublish(dynamic id) => '$apiBase/reviews/$id/publish';
  static String reviewApprove(dynamic id) => '$apiBase/reviews/$id/approve';
  static String reviewToggleActive(dynamic id) => '$apiBase/reviews/$id/toggle-active';
  static String reviewToggleFeatured(dynamic id) => '$apiBase/reviews/$id/toggle-featured';
  static String reviewDelete(dynamic id) => '$apiBase/reviews/$id';
  static String get reviewUploadScreenshot => '$apiBase/reviews/upload-screenshot';

  static String get couriers => '$apiBase/couriers';
  static String get courierTest => '$apiBase/couriers/test';

  static String get sections => '$apiBase/sections';
  static String sectionDetail(dynamic id) => '$apiBase/sections/$id';
  static String sectionToggle(dynamic id) => '$apiBase/sections/$id/toggle';
  static String sectionImage(dynamic id) => '$apiBase/sections/$id/image';
  static String sectionResetImage(dynamic id) => '$apiBase/sections/$id/image/reset';
  static String get sectionUploadMedia => '$apiBase/sections/upload-media';
  static String get sectionsReorder => '$apiBase/sections/reorder';
  static String get heroSection => '$apiBase/sections/hero';

  static String get notificationsFeed => '$apiBase/notifications/feed';
  static String get notificationTest => '$apiBase/notifications/test';

  static String get securitySettings => '$apiBase/settings/security';
  static String get securityBlock => '$apiBase/settings/security/block';
  static String get securityUnblock => '$apiBase/settings/security/unblock';
  static String securityDelete(dynamic id) => '$apiBase/settings/security/$id';
}
