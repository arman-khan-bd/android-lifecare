import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../config/api_config.dart';
import '../../config/app_theme.dart';
import '../../models/book_model.dart';
import '../../providers/book_provider.dart';
import '../../services/permission_service.dart';
import '../../widgets/app_network_image.dart';

typedef MedicineFormScreen = BookFormScreen;

class BookFormScreen extends StatefulWidget {
  final BookModel? book;

  const BookFormScreen({super.key, this.book});

  @override
  State<BookFormScreen> createState() => _BookFormScreenState();
}

class _BookFormScreenState extends State<BookFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  // Basic Info Controllers
  late TextEditingController _titleController;
  late TextEditingController _subtitleController;
  late TextEditingController _slugController;
  late TextEditingController _brandController;
  late TextEditingController _categoryController;
  late TextEditingController _badgeController;

  // Price & Inventory
  late TextEditingController _priceController;
  late TextEditingController _discountPriceController;
  late TextEditingController _stockController;
  String _stockStatus = 'in_stock';

  // Medicine Specifications
  late TextEditingController _dosageFormController;
  late TextEditingController _unitCountController;
  late TextEditingController _originController;
  late TextEditingController _certificationController;
  late TextEditingController _samplePdfController;

  // Description, Usage & Benefits
  late TextEditingController _descriptionController;
  late TextEditingController _usageInstructionsController;
  final List<String> _features = [];
  final TextEditingController _newFeatureController = TextEditingController();

  // Primary Cover Image
  String? _existingCoverUrl;
  Uint8List? _newCoverBytes;
  String? _newCoverFilename;
  late TextEditingController _customImageUrlController;

  // Multiple Gallery Images
  final List<String> _galleryImages = [];
  final TextEditingController _newGalleryUrlController = TextEditingController();

  // Toggles
  bool _freeDelivery = false;
  bool _isFeatured = false;
  bool _isCombo = false;
  bool _isPrescriptionRequired = false;

  bool _isSaving = false;
  String? _uploadStatusText;

  @override
  void initState() {
    super.initState();
    final b = widget.book;

    _titleController = TextEditingController(text: b?.title ?? '');
    _subtitleController = TextEditingController(text: b?.subtitle ?? '');
    _slugController = TextEditingController(text: b?.slug ?? '');
    _brandController = TextEditingController(text: b?.brand ?? b?.author ?? 'Life Care Medicine BD');
    _categoryController = TextEditingController(text: b?.category ?? 'ভেষজ ও অর্গানিক সাপ্লিমেন্ট');
    _badgeController = TextEditingController(text: b?.badge ?? '১০০% প্রিমিয়াম ও অরগানিক');

    _priceController = TextEditingController(text: b != null ? b.price.toStringAsFixed(0) : '');
    _discountPriceController = TextEditingController(text: b != null && b.discountPrice > 0 ? b.discountPrice.toStringAsFixed(0) : '');
    _stockController = TextEditingController(text: b != null ? b.stockCount.toString() : '100');
    _stockStatus = b?.stockStatus ?? 'in_stock';

    _dosageFormController = TextEditingController(text: b?.dosageForm ?? b?.edition ?? 'ক্যাপসুল');
    _unitCountController = TextEditingController(
      text: b?.unitCount != null && b!.unitCount > 0
          ? b.unitCount.toString()
          : (b != null && b.pages > 0 ? b.pages.toString() : '60'),
    );
    _originController = TextEditingController(text: b?.origin ?? 'বাংলাদেশ');
    _certificationController = TextEditingController(text: b?.certification ?? 'বিএসটিআই ও জিএমপি অনুমোদিত');
    _samplePdfController = TextEditingController(text: b?.samplePdfUrl ?? '');

    _descriptionController = TextEditingController(
      text: b?.description ?? 'লাইফ কেয়ার মেডিসিন BD-এর ১০০% বিশুদ্ধ ও কার্যকারী হারবাল স্বাস্থ্য পণ্য।',
    );
    _usageInstructionsController = TextEditingController(
      text: b?.usageInstructions ?? 'প্রতিদিন সকালে ও রাতে খাবারের ৩০ মিনিট পর ১টি করে সেব্য।',
    );

    if (b != null && b.features.isNotEmpty) {
      _features.addAll(b.features);
    } else if (b == null) {
      _features.addAll([
        '১০০% প্রাকৃতিক ও পার্শ্বপ্রতিক্রিয়ামুক্ত ভেষজ উপাদান',
        'উচ্চ কার্যকারিতা ও দীর্ঘস্থায়ী ফলাফল',
        'ল্যাব ও মান নিয়ন্ত্রণ সার্টিফাইড',
      ]);
    }

    _existingCoverUrl = b?.coverImage;
    _customImageUrlController = TextEditingController(text: b?.coverImage ?? '');
    _customImageUrlController.addListener(() {
      final text = _customImageUrlController.text.trim();
      if (_newCoverBytes == null && text != (_existingCoverUrl ?? '')) {
        setState(() {
          _existingCoverUrl = text.isNotEmpty ? text : null;
        });
      }
    });

    if (b != null && b.galleryImages.isNotEmpty) {
      _galleryImages.addAll(b.galleryImages);
    }

    _freeDelivery = b?.freeDelivery ?? true;
    _isFeatured = b?.isFeatured ?? false;
    _isCombo = b?.isCombo ?? false;
    _isPrescriptionRequired = b?.isPrescriptionRequired ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _slugController.dispose();
    _brandController.dispose();
    _categoryController.dispose();
    _badgeController.dispose();
    _priceController.dispose();
    _discountPriceController.dispose();
    _stockController.dispose();
    _dosageFormController.dispose();
    _unitCountController.dispose();
    _originController.dispose();
    _certificationController.dispose();
    _samplePdfController.dispose();
    _descriptionController.dispose();
    _usageInstructionsController.dispose();
    _newFeatureController.dispose();
    _customImageUrlController.dispose();
    _newGalleryUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickCoverImage(ImageSource source) async {
    final hasPermission = await PermissionService.requestImagePickerPermission(
      source: source,
      context: context,
    );
    if (!hasPermission) return;

    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1400,
        maxHeight: 1600,
        imageQuality: 92,
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _newCoverBytes = bytes;
          _newCoverFilename = file.name;
          _customImageUrlController.text = '';
        });
      }
    } catch (e) {
      _showError('ছবি নির্বাচন করতে সমস্যা হয়েছে: $e');
    }
  }

  Future<void> _pickMultipleGalleryImages() async {
    final hasPermission = await PermissionService.requestImagePickerPermission(
      source: ImageSource.gallery,
      context: context,
    );
    if (!hasPermission) return;

    try {
      final List<XFile> files = await _picker.pickMultiImage(
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 90,
      );

      if (files.isNotEmpty) {
        final provider = Provider.of<BookProvider>(context, listen: false);
        int uploadedCount = 0;

        for (int i = 0; i < files.length; i++) {
          final file = files[i];
          setState(() {
            _uploadStatusText = 'ছবি আপলোড হচ্ছে (${i + 1}/${files.length})...';
          });

          final bytes = await file.readAsBytes();
          final url = await provider.uploadImage(bytes, file.name, type: 'sample');
          if (url != null) {
            setState(() {
              _galleryImages.add(url);
            });
            uploadedCount++;
          }
        }

        setState(() => _uploadStatusText = null);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppTheme.primary,
              behavior: SnackBarBehavior.floating,
              content: Text('$uploadedCount টি ছবি সফলভাবে গ্যালারিতে যোগ হয়েছে',
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _uploadStatusText = null);
      _showError('ছবি আপলোডে সমস্যা: $e');
    }
  }

  Future<void> _pickSingleGalleryCamera() async {
    final hasPermission = await PermissionService.requestImagePickerPermission(
      source: ImageSource.camera,
      context: context,
    );
    if (!hasPermission) return;

    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 90,
      );
      if (file != null) {
        setState(() {
          _uploadStatusText = 'ক্যামেরা ছবি আপলোড হচ্ছে...';
        });
        final bytes = await file.readAsBytes();
        final provider = Provider.of<BookProvider>(context, listen: false);
        final url = await provider.uploadImage(bytes, file.name, type: 'sample');
        if (url != null) {
          setState(() {
            _galleryImages.add(url);
            _uploadStatusText = null;
          });
        } else {
          setState(() => _uploadStatusText = null);
          _showError(provider.errorMessage ?? 'ছবি আপলোড ব্যর্থ হয়েছে');
        }
      }
    } catch (e) {
      setState(() => _uploadStatusText = null);
      _showError('ছবি আপলোডে সমস্যা: $e');
    }
  }

  void _showAddGalleryUrlDialog() {
    final urlController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final currentUrl = urlController.text.trim();
          return AlertDialog(
            backgroundColor: AppTheme.surfaceDark,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('ইমেজ URL দিয়ে প্রোডাক্ট ছবি যোগ করুন',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ছবির সরাসরি লিংক (https://..., Google Drive ইত্যাদি) পেস্ট করুন:',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: urlController,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: '${ApiConfig.baseUrl}/uploads/medicines/...',
                      suffixIcon: currentUrl.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                urlController.clear();
                                setDialogState(() {});
                              },
                            )
                          : null,
                    ),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  if (currentUrl.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Text('লাইভ প্রিভিউ:',
                        style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Center(
                      child: AppNetworkImage(
                        imageUrl: currentUrl,
                        width: 140,
                        height: 140,
                        fit: BoxFit.contain,
                        borderRadius: BorderRadius.circular(10),
                        showBorder: true,
                        fallbackIcon: Icons.broken_image_rounded,
                        fallbackText: 'প্রিভিউ পাওয়া যায়নি',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('বাতিল', style: TextStyle(color: Color(0xFF94A3B8))),
              ),
              ElevatedButton(
                onPressed: currentUrl.isEmpty
                    ? null
                    : () {
                        setState(() {
                          _galleryImages.add(currentUrl);
                        });
                        Navigator.pop(ctx);
                      },
                child: const Text('যোগ করুন'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _addFeature() {
    final text = _newFeatureController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _features.add(text);
        _newFeatureController.clear();
      });
    }
  }

  void _removeFeature(int index) {
    setState(() => _features.removeAt(index));
  }

  void _makeGalleryImageCover(String imageUrl) {
    setState(() {
      _existingCoverUrl = imageUrl;
      _newCoverBytes = null;
      _newCoverFilename = null;
      _customImageUrlController.text = imageUrl;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
        content: Text('এই ছবিটি মূল কভার ছবি হিসেবে সেট করা হয়েছে',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Future<void> _saveBook() async {
    if (!_formKey.currentState!.validate()) {
      _showError('দয়া করে প্রয়োজনীয় ফিল্ডগুলো পূরণ করুন');
      return;
    }

    setState(() {
      _isSaving = true;
      _uploadStatusText = 'তথ্য প্রস্তুত করা হচ্ছে...';
    });

    final provider = Provider.of<BookProvider>(context, listen: false);

    // 1. Upload Cover Image if new bytes selected
    String? coverPath = _existingCoverUrl;
    if (_newCoverBytes != null && _newCoverFilename != null) {
      setState(() => _uploadStatusText = 'কভার ছবি আপলোড ও অপটিমাইজ হচ্ছে...');
      final uploadedPath = await provider.uploadImage(
        _newCoverBytes!,
        _newCoverFilename!,
        type: 'cover',
      );
      if (uploadedPath != null) {
        coverPath = uploadedPath;
      } else {
        setState(() => _isSaving = false);
        _showError(provider.errorMessage ?? 'কভার ছবি আপলোড ব্যর্থ হয়েছে।');
        return;
      }
    } else if (_customImageUrlController.text.trim().isNotEmpty) {
      coverPath = _customImageUrlController.text.trim();
    }

    // 2. Prepare payload compatible with both medicine and book attributes
    final data = <String, dynamic>{
      'title': _titleController.text.trim(),
      'subtitle': _subtitleController.text.trim().isNotEmpty ? _subtitleController.text.trim() : null,
      'slug': _slugController.text.trim().isNotEmpty ? _slugController.text.trim() : null,
      'brand': _brandController.text.trim(),
      'author': _brandController.text.trim(), // backward-compatible alias
      'category': _categoryController.text.trim(),
      'badge': _badgeController.text.trim(),
      'price': double.tryParse(_priceController.text) ?? 0.0,
      'discount_price': double.tryParse(_discountPriceController.text) ?? 0.0,
      'stock_count': int.tryParse(_stockController.text) ?? 100,
      'stock_status': _stockStatus,
      'dosage_form': _dosageFormController.text.trim(),
      'edition': _dosageFormController.text.trim(), // backward-compatible alias
      'unit_count': int.tryParse(_unitCountController.text) ?? 0,
      'pages': int.tryParse(_unitCountController.text) ?? 0, // backward-compatible alias
      'origin': _originController.text.trim(),
      'certification': _certificationController.text.trim(),
      'usage_instructions': _usageInstructionsController.text.trim().isNotEmpty ? _usageInstructionsController.text.trim() : null,
      'sample_pdf_url': _samplePdfController.text.trim().isNotEmpty ? _samplePdfController.text.trim() : null,
      'description': _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : 'লাইফ কেয়ার মেডিসিন BD-এর ১০০% বিশুদ্ধ ও কার্যকারী হারবাল স্বাস্থ্য পণ্য।',
      'features': _features,
      'key_points': _features,
      'free_delivery': _freeDelivery,
      'is_featured': _isFeatured,
      'is_combo': _isCombo,
      'is_prescription_required': _isPrescriptionRequired,
      'gallery_images': _galleryImages,
    };

    if (coverPath != null && coverPath.isNotEmpty) {
      data['cover_image'] = coverPath;
    }

    setState(() => _uploadStatusText = 'মেডিসিনের ডেটা সেভ করা হচ্ছে...');

    bool ok;
    if (widget.book == null) {
      ok = await provider.createBook(data);
    } else {
      ok = await provider.updateBook(widget.book!.id, data);
    }

    setState(() {
      _isSaving = false;
      _uploadStatusText = null;
    });

    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.black),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.book == null ? 'নতুন মেডিসিন সফলভাবে যোগ করা হয়েছে!' : 'মেডিসিনের সমস্ত তথ্য সফলভাবে আপডেট হয়েছে!',
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      _showError(provider.errorMessage ?? 'সেভ করতে ব্যর্থ হয়েছে।');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.accentRose,
        behavior: SnackBarBehavior.floating,
        content: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.book != null;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: Text(isEdit ? 'মেডিসিন এডিট ও বিস্তারিত' : 'নতুন মেডিসিন যোগ করুন'),
        actions: [
          TextButton.icon(
            icon: _isSaving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2))
                : const Icon(Icons.check_circle, color: AppTheme.primary, size: 20),
            label: Text(
              isEdit ? 'আপডেট' : 'পাবলিশ',
              style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 15),
            ),
            onPressed: _isSaving ? null : _saveBook,
          ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: const BoxDecoration(
          color: AppTheme.surfaceDark,
          border: Border(top: BorderSide(color: Color(0xFF263345))),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveBook,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 3,
              ),
              child: _isSaving
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)),
                        const SizedBox(width: 12),
                        Text(_uploadStatusText ?? 'সংরক্ষণ হচ্ছে...', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    )
                  : Text(
                      isEdit ? 'সমস্ত পরিবর্তন সংরক্ষণ করুন' : 'নতুন মেডিসিন প্রকাশ করুন',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Cover Image Card
              _buildSectionHeader('১. মেডিসিনের প্রধান কভার ছবি (Primary Cover Image)', Icons.image_rounded),
              _buildCoverImageCard(),
              const SizedBox(height: 20),

              // 2. Multiple Gallery Images Card
              _buildSectionHeader('২. একাধিক প্রোডাক্ট ছবি গ্যালারি (${_galleryImages.length} টি ছবি যুক্ত)', Icons.collections_rounded),
              _buildGalleryCard(),
              const SizedBox(height: 20),

              // 3. Basic Info Card
              _buildSectionHeader('৩. প্রাথমিক তথ্য ও ব্র্যান্ড (Medicine Info & Brand)', Icons.medical_services_rounded),
              _buildBasicInfoCard(),
              const SizedBox(height: 20),

              // 4. Price & Inventory Card
              _buildSectionHeader('৪. মূল্য ও স্টক ম্যানেজমেন্ট (Pricing & Stock)', Icons.monetization_on_rounded),
              _buildPricingCard(),
              const SizedBox(height: 20),

              // 5. Specifications Card
              _buildSectionHeader('৫. মেডিসিন স্পেসিফিকেশন ও মাত্রা (Specifications)', Icons.healing_rounded),
              _buildSpecsCard(),
              const SizedBox(height: 20),

              // 6. Description & Usage Card
              _buildSectionHeader('৬. বিস্তারিত বর্ণনা ও সেবনবিধি (Description & Usage)', Icons.description_rounded),
              _buildDescriptionCard(),
              const SizedBox(height: 20),

              // 7. Benefits Card
              _buildSectionHeader('৭. মূল স্বাস্থ্য উপকারিতা ও পয়েন্ট (Health Benefits)', Icons.checklist_rounded),
              _buildFeaturesCard(),
              const SizedBox(height: 20),

              // 8. Toggles Card
              _buildSectionHeader('৮. অতিরিক্ত সেটিংস ও ফিচার (Flags & Badges)', Icons.tune_rounded),
              _buildTogglesCard(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardContainer({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF263345)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildCoverImageCard() {
    return _buildCardContainer(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Preview Box
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 110,
                height: 155,
                color: const Color(0xFF1E293B),
                child: _newCoverBytes != null
                    ? Image.memory(_newCoverBytes!, fit: BoxFit.cover)
                    : (_existingCoverUrl != null && _existingCoverUrl!.isNotEmpty)
                        ? AppNetworkImage(
                            imageUrl: _existingCoverUrl!,
                            width: 110,
                            height: 155,
                            fit: BoxFit.cover,
                            borderRadius: BorderRadius.circular(12),
                            fallbackIcon: Icons.medical_services_rounded,
                            fallbackText: 'ছবি লোড হয়নি',
                          )
                        : const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_rounded, color: AppTheme.primary, size: 36),
                                SizedBox(height: 6),
                                Text('ছবি নেই', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                              ],
                            ),
                          ),
              ),
            ),
            const SizedBox(width: 16),
            // Upload Controls
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'মূল কভার ও প্যাকেজিং ছবি',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'ল্যান্ডিং পেজ ও কার্ট স্ক্রিনে এই ছবিটি প্রদর্শিত হবে। আপলোডকৃত ছবি স্বয়ংক্রিয়ভাবে অপটিমাইজ হবে।',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary.withOpacity(0.18),
                          foregroundColor: AppTheme.primary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(color: AppTheme.primary),
                          ),
                        ),
                        icon: const Icon(Icons.photo_library_rounded, size: 16),
                        label: const Text('গ্যালারি', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: () => _pickCoverImage(ImageSource.gallery),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E293B),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(color: Color(0xFF334155)),
                          ),
                        ),
                        icon: const Icon(Icons.camera_alt_rounded, size: 16),
                        label: const Text('ক্যামেরা', style: TextStyle(fontSize: 12)),
                        onPressed: () => _pickCoverImage(ImageSource.camera),
                      ),
                      if (_newCoverBytes != null)
                        TextButton.icon(
                          icon: const Icon(Icons.restore, color: AppTheme.accentRose, size: 16),
                          label: const Text('রিসেট', style: TextStyle(color: AppTheme.accentRose, fontSize: 12)),
                          onPressed: () {
                            setState(() {
                              _newCoverBytes = null;
                              _newCoverFilename = null;
                            });
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Divider(color: Color(0xFF263345)),
        const SizedBox(height: 8),
        _buildFieldLabel('অথবা সরাসরি ছবির URL পেস্ট করুন'),
        TextFormField(
          controller: _customImageUrlController,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: '${ApiConfig.baseUrl}/uploads/medicines/cover.webp',
            helperText: 'সরাসরি লিংক বা ইমেজ URL পেস্ট করলে সাথে সাথে প্রিভিউ দেখাবে',
            helperStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
            prefixIcon: const Icon(Icons.link_rounded, color: AppTheme.primary, size: 18),
            suffixIcon: _customImageUrlController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, color: Color(0xFF94A3B8), size: 18),
                    onPressed: () {
                      _customImageUrlController.clear();
                      setState(() {
                        _existingCoverUrl = null;
                      });
                    },
                  )
                : null,
          ),
          onChanged: (val) {
            setState(() {
              _existingCoverUrl = val.trim().isNotEmpty ? val.trim() : null;
              _newCoverBytes = null;
            });
          },
        ),
      ],
    );
  }

  Widget _buildGalleryCard() {
    return _buildCardContainer(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'মাল্টিপল প্রোডাক্ট ইমেজ গ্যালারি',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'একসাথে একাধিক ছবি নির্বাচন করে আপলোড করতে পারেন (${_galleryImages.length} টি ছবি যুক্ত)',
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                  ),
                ],
              ),
            ),
            if (_galleryImages.isNotEmpty)
              TextButton.icon(
                icon: const Icon(Icons.delete_sweep_rounded, color: AppTheme.accentRose, size: 16),
                label: const Text('সব মুছুন', style: TextStyle(color: AppTheme.accentRose, fontSize: 11)),
                onPressed: () {
                  setState(() => _galleryImages.clear());
                },
              ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.black,
                elevation: 1,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
              label: const Text('একসাথে একাধিক ছবি আপলোড', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              onPressed: _pickMultipleGalleryImages,
            ),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFF334155)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.camera_alt_outlined, size: 16),
              label: const Text('ক্যামেরা ছবি', style: TextStyle(fontSize: 12)),
              onPressed: _pickSingleGalleryCamera,
            ),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.accentCyan,
                side: const BorderSide(color: Color(0xFF334155)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.link_rounded, size: 16),
              label: const Text('URL থেকে যোগ', style: TextStyle(fontSize: 12)),
              onPressed: _showAddGalleryUrlDialog,
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (_galleryImages.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: const Column(
              children: [
                Icon(Icons.photo_library_outlined, color: Color(0xFF64748B), size: 36),
                SizedBox(height: 8),
                Text(
                  'এখনো কোনো অতিরিক্ত প্রোডাক্ট ছবি যোগ করা হয়নি।',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 4),
                Text(
                  'গ্রাহকদের মেডিসিনের বিভিন্ন দিক দেখাতে "একসাথে একাধিক ছবি আপলোড" বাটনে চাপুন।',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _galleryImages.length,
              itemBuilder: (ctx, i) {
                final imgUrl = _galleryImages[i];
                final isCurrentCover = (_existingCoverUrl == imgUrl);

                return Container(
                  width: 110,
                  margin: const EdgeInsets.only(right: 12),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isCurrentCover ? AppTheme.primary : const Color(0xFF334155),
                              width: isCurrentCover ? 2.5 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: AppNetworkImage(
                            imageUrl: imgUrl,
                            width: 110,
                            height: 140,
                            fit: BoxFit.cover,
                            borderRadius: BorderRadius.circular(11),
                            fallbackIcon: Icons.medical_services_outlined,
                          ),
                        ),
                      ),
                      // Top-left: Index badge
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.75),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('#${i + 1}',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      // Top-right: Delete button
                      Positioned(
                        top: 6,
                        right: 6,
                        child: GestureDetector(
                          onTap: () => setState(() => _galleryImages.removeAt(i)),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black87,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded, color: AppTheme.accentRose, size: 14),
                          ),
                        ),
                      ),
                      // Bottom: Set as Cover Button
                      Positioned(
                        bottom: 6,
                        left: 6,
                        right: 6,
                        child: GestureDetector(
                          onTap: () => _makeGalleryImageCover(imgUrl),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: isCurrentCover ? AppTheme.primary : Colors.black.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isCurrentCover ? AppTheme.primary : Colors.white24,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isCurrentCover ? Icons.star_rounded : Icons.star_border_rounded,
                                  size: 13,
                                  color: isCurrentCover ? Colors.black : Colors.amber,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  isCurrentCover ? 'কভার ছবি' : 'কভার বানান',
                                  style: TextStyle(
                                    color: isCurrentCover ? Colors.black : Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildBasicInfoCard() {
    return _buildCardContainer(
      children: [
        _buildFieldLabel('মেডিসিন / পণ্যের নাম (Product Title)*'),
        TextFormField(
          controller: _titleController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'উদাঃ প্রিমিয়াম অর্গানিক জিনসেং এক্সট্র্যাক্ট ক্যাপসুল'),
          validator: (v) => v == null || v.trim().isEmpty ? 'পণ্যের নাম আবশ্যক' : null,
        ),
        const SizedBox(height: 14),

        _buildFieldLabel('উপ-শিরোনাম বা ট্যাগলাইন (Subtitle)'),
        TextFormField(
          controller: _subtitleController,
          maxLines: 2,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'উদাঃ শারীরিক শক্তি ও রোগ প্রতিরোধ ক্ষমতা বৃদ্ধিতে ১০০% কার্যকর'),
        ),
        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('ব্র্যান্ড / প্রস্তুতকারক (Brand)*'),
                  TextFormField(
                    controller: _brandController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(hintText: 'Life Care Medicine BD'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'ব্র্যান্ড আবশ্যক' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('ক্যাটাগরি (Category)'),
                  TextFormField(
                    controller: _categoryController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(hintText: 'ভেষজ ও অর্গানিক সাপ্লিমেন্ট'),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('হাইলাইট ব্যাজ (Badge)'),
                  TextFormField(
                    controller: _badgeController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(hintText: '১০০% প্রিমিয়াম / হট ডিল'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('কাস্টম URL স্ল্যাগ (Slug)'),
                  TextFormField(
                    controller: _slugController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(hintText: 'organic-ginseng-capsule'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPricingCard() {
    final regular = double.tryParse(_priceController.text) ?? 0.0;
    final discount = double.tryParse(_discountPriceController.text) ?? 0.0;
    final effective = discount > 0 ? discount : regular;

    return _buildCardContainer(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('রেগুলার মূল্য (৳)*'),
                  TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(hintText: '১২৫০', prefixText: '৳ '),
                    validator: (v) => v == null || v.trim().isEmpty ? 'মূল্য আবশ্যক' : null,
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('ডিসকাউন্ট অফার মূল্য (৳)'),
                  TextFormField(
                    controller: _discountPriceController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(hintText: '৯৯৯', prefixText: '৳ '),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('কাস্টমার যে মূল্যে অর্ডার করবে:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
              Text('৳${effective.toStringAsFixed(0)}',
                  style: const TextStyle(color: AppTheme.primary, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('স্টক সংখ্যা (Stock)*'),
                  TextFormField(
                    controller: _stockController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(hintText: '১০০'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'স্টক সংখ্যা দিন' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('স্টক অবস্থা (Stock Status)'),
                  DropdownButtonFormField<String>(
                    value: _stockStatus,
                    dropdownColor: AppTheme.surfaceDark,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
                    items: const [
                      DropdownMenuItem(value: 'in_stock', child: Text('🟢 ইন স্টক (In Stock)')),
                      DropdownMenuItem(value: 'limited_stock', child: Text('🟡 সীমিত স্টক (Limited)')),
                      DropdownMenuItem(value: 'out_of_stock', child: Text('🔴 স্টক শেষ (Out of Stock)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _stockStatus = val);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSpecsCard() {
    return _buildCardContainer(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('ডোজ ফরম্যাট / ধরন (Dosage Form)'),
                  TextFormField(
                    controller: _dosageFormController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(hintText: 'ক্যাপসুল / ট্যাবলেট / সিরাপ'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('প্যাক সাইজ / সংখ্যা (Units Count)'),
                  TextFormField(
                    controller: _unitCountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(hintText: '৬০'),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('উৎপাদনকারী দেশ (Origin)'),
                  TextFormField(
                    controller: _originController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(hintText: 'বাংলাদেশ / জার্মানি'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('মান ও অনুমোদন (Certification)'),
                  TextFormField(
                    controller: _certificationController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(hintText: 'বিএসটিআই ও জিএমপি অনুমোদিত'),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        _buildFieldLabel('ব্রোশিউর বা ল্যাব রিপোর্ট লিংক (PDF Report URL)'),
        TextFormField(
          controller: _samplePdfController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'https://.../product_brochure.pdf'),
        ),
      ],
    );
  }

  Widget _buildDescriptionCard() {
    return _buildCardContainer(
      children: [
        _buildFieldLabel('মেডিসিন সম্পর্কে বিস্তারিত বিবরণ (Description)*'),
        TextFormField(
          controller: _descriptionController,
          maxLines: 5,
          style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5),
          decoration: const InputDecoration(
            hintText: 'পণ্যটির উপাদান, কার্যকারিতা ও কেন গ্রাহক এটি গ্রহণ করবেন তার বিস্তারিত বিবরণ...',
          ),
        ),
        const SizedBox(height: 14),

        _buildFieldLabel('সেবনবিধি ও নির্দেশিকা (Usage Instructions)'),
        TextFormField(
          controller: _usageInstructionsController,
          maxLines: 3,
          style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5),
          decoration: const InputDecoration(
            hintText: 'প্রতিদিন কয়বার, কিভাবে সেবন করতে হবে তার স্পষ্ট নিয়মাবলী...',
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesCard() {
    return _buildCardContainer(
      children: [
        const Text(
          'মেডিসিনের প্রধান প্রধান স্বাস্থ্য উপকারিতা ও আকর্ষণ (Key Benefits):',
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
        ),
        const SizedBox(height: 10),

        if (_features.isNotEmpty)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _features.length,
            itemBuilder: (ctx, i) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_features[i], style: const TextStyle(color: Colors.white, fontSize: 13)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.accentRose, size: 16),
                    onPressed: () => _removeFeature(i),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _newFeatureController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(hintText: 'নতুন উপকারিতা পয়েন্ট লিখুন...'),
                onFieldSubmitted: (_) => _addFeature(),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: _addFeature,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('যোগ', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTogglesCard() {
    return _buildCardContainer(
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('ফ্রি ডেলিভারি অফার (Free Delivery)',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          subtitle: const Text('এই মেডিসিন অর্ডারে সারাদেশে ফ্রি কুরিয়ার ডেলিভারি কার্যকর থাকবে',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
          value: _freeDelivery,
          activeColor: AppTheme.primary,
          onChanged: (val) => setState(() => _freeDelivery = val),
        ),
        const Divider(color: Color(0xFF263345)),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('ফিচার্ড মেডিসিন (Featured on Landing)',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          subtitle: const Text('ল্যান্ডিং পেজের শীর্ষে বিশেষ আকর্ষণীয়ভাবে হাইলাইট হবে',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
          value: _isFeatured,
          activeColor: AppTheme.primary,
          onChanged: (val) => setState(() => _isFeatured = val),
        ),
        const Divider(color: Color(0xFF263345)),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('কম্বো প্যাকেজ (Combo Pack)',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          subtitle: const Text('একাধিক পণ্যের স্পেশাল প্যাকেজ বা কোর্স হিসেবে চিহ্নিত করতে',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
          value: _isCombo,
          activeColor: AppTheme.primary,
          onChanged: (val) => setState(() => _isCombo = val),
        ),
        const Divider(color: Color(0xFF263345)),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('প্রেসক্রিপশন আবশ্যক (Prescription Required)',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          subtitle: const Text('ওটিসি নয় এমন প্রেসক্রিপশন মেডিসিনের ক্ষেত্রে চালু করুন',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
          value: _isPrescriptionRequired,
          activeColor: AppTheme.primary,
          onChanged: (val) => setState(() => _isPrescriptionRequired = val),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
