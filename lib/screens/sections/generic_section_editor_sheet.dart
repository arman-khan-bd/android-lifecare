import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/section_model.dart';
import '../../providers/section_provider.dart';
import '../../services/permission_service.dart';
import '../../widgets/app_network_image.dart';

/// Generic section editor for any section (author, bookshelf, faq, footer, reviews, etc.)
class GenericSectionEditorSheet extends StatefulWidget {
  final SectionModel section;

  const GenericSectionEditorSheet({super.key, required this.section});

  static Future<void> show(BuildContext context, SectionModel section) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GenericSectionEditorSheet(section: section),
    );
  }

  @override
  State<GenericSectionEditorSheet> createState() => _GenericSectionEditorSheetState();
}

class _GenericSectionEditorSheetState extends State<GenericSectionEditorSheet> {
  final _picker = ImagePicker();
  late bool _isActive;
  late TextEditingController _nameController;
  late TextEditingController _imageUrlController;
  late Map<String, dynamic> _editableContent;
  bool _isSaving = false;
  bool _isUploadingImage = false;
  Uint8List? _pendingImageBytes;

  @override
  void initState() {
    super.initState();
    _isActive = widget.section.isActive;
    _nameController = TextEditingController(text: widget.section.name);
    _editableContent = Map<String, dynamic>.from(widget.section.content);

    final k = widget.section.sectionKey;
    String initialImage = widget.section.imageUrl ?? '';
    if (k == 'author') {
      initialImage = widget.section.content['author_image']?.toString() 
          ?? widget.section.imageUrl 
          ?? widget.section.content['image_url']?.toString() 
          ?? '';
    } else if (initialImage.isEmpty) {
      initialImage = widget.section.content['image_url']?.toString() ?? '';
    }
    if (initialImage.contains('convertflow')) {
      initialImage = '';
    }
    _imageUrlController = TextEditingController(text: initialImage);

    // Pre-seed default website content if missing so all fields are immediately visible and editable
    if (k == 'footer') {
      _editableContent.putIfAbsent('brand_title', () => 'Life Care');
      _editableContent.putIfAbsent('brand_subtitle', () => 'Medicine BD');
      _editableContent.putIfAbsent('description', () => '১০০% ন্যাচারাল ও অর্গানিক ফর্মুলেশনে তৈরি নিরাপদ ভেষজ খাদ্য সম্পূরক ও নির্ভরযোগ্য স্বাস্থ্য সেবা।');
      _editableContent.putIfAbsent('support_phone', () => _editableContent['phone'] ?? '০১৭০০-০০০০০০ (সকাল ৯টা - রাত ১০টা)');
      _editableContent.putIfAbsent('support_email', () => _editableContent['contact_email'] ?? _editableContent['email'] ?? 'support@lifecarebd.com');
      _editableContent.putIfAbsent('address', () => 'ঢাকা, বাংলাদেশ');
      _editableContent.putIfAbsent('copyright', () => _editableContent['copyright_text'] ?? '© ২০২৫-২০২৬ Life Care Medicine BD। সর্বস্বত্ব সংরক্ষিত।');
    } else if (k == 'floating_buttons') {
      _editableContent.putIfAbsent('phone', () => '+880 1700-000000');
      _editableContent.putIfAbsent('whatsapp', () => '+8801700000000');
      _editableContent.putIfAbsent('whatsapp_message', () => 'হ্যালো, আমি Life Care মেডিসিন অর্ডার করতে চাই।');
    } else if (k == 'bookshelf') {
      _editableContent.putIfAbsent('section_badge', () => 'আমাদের সকল মেডিসিন ও পণ্য');
      _editableContent.putIfAbsent('section_title', () => 'মেডিসিন ক্যাটালগ ও শপ');
      _editableContent.putIfAbsent('section_subtitle', () => 'আপনার প্রয়োজনীয় মেডিসিন ও স্বাস্থ্য পণ্য নির্বাচন করুন।');
    } else if (k == 'book_about') {
      _editableContent.putIfAbsent('section_badge', () => 'মেডিসিন পরিচিতি ও বিশেষত্ব');
      _editableContent.putIfAbsent('section_title', () => 'কেন লাইফ কেয়ার মেডিসিন গ্রাহকদের ১ম পছন্দ?');
      _editableContent.putIfAbsent('section_subtitle', () => '১০০% খাঁটি প্রাকৃতিক নির্যাস ও পরীক্ষিত উপাদানে তৈরি আমাদের প্রতিটি ওষুধ মানবদেহের স্বাভাবিক সুস্থতা ফিরিয়ে আনতে সাহায্য করে।');
      _editableContent.putIfAbsent('quote_badge', () => 'ন্যাচারাল ও বিশুদ্ধ ফর্মুলেশন');
      _editableContent.putIfAbsent('quote_title', () => 'প্রাকৃতিক উপাদান ও সর্বোচ্চ বিশুদ্ধতা নিশ্চয়তা');
      _editableContent.putIfAbsent('quote_text', () => 'দীর্ঘমেয়াদী সুস্থতায় ক্ষতিকারক কেমিক্যালমুক্ত নিরাপদ ও কার্যকরী ভেষজ স্বাস্থ্য সমাধান।');
      _editableContent.putIfAbsent('cta_text', () => 'মেডিসিন তালিকা দেখুন');
    } else if (k == 'author') {
      _editableContent.putIfAbsent('section_badge', () => '🌿 আমাদের সম্পর্কে • Life Care Medicine BD');
      _editableContent.putIfAbsent('author_name', () => 'Life Care Medicine BD');
      _editableContent.putIfAbsent('author_title', () => 'প্রাকৃতিক ও হারবাল হেলথকেয়ার সল্যুশন');
      _editableContent.putIfAbsent('author_tagline', () => 'Care, Trust & Natural Wellness');
      _editableContent.putIfAbsent('author_institute', () => 'লাইফ কেয়ার হেলথ ল্যাবস বাংলাদেশ');
      _editableContent.putIfAbsent('author_quote', () => '"আমরা বিশ্বাস করি, প্রকৃতির ভেষজ উপাদানের মাঝেই লুকিয়ে আছে সুস্থ ও সতেজ জীবনের শ্রেষ্ঠ সহায়ক যত্ন।"');
      _editableContent.putIfAbsent('bio_p1', () => _editableContent['author_bio'] ?? 'Life Care Medicine BD দীর্ঘ বছর ধরে বাংলাদেশে খাঁটি, নিরাপদ এবং গুণগত মানসম্পন্ন প্রাকৃতিক ভেষজ খাদ্য সম্পূরক সরবরাহ করে আসছে। আমাদের প্রতিটি পণ্য কঠোর মাননিয়ন্ত্রণের মাধ্যমে প্রস্তুত করা হয়, যাতে গ্রাহকরা পান সর্বোচ্চ বিশুদ্ধতা।');
      _editableContent.putIfAbsent('bio_p2', () => 'আমাদের টিম প্রাচীন আয়ুর্বেদিক জ্ঞানের সাথে আধুনিক বিজ্ঞানসম্মত পদ্ধতির সমন্বয়ে জয়েন্ট, হাড়, মাংসপেশি ও মেটাবলিক স্বাস্থ্য সুরক্ষায় বিশ্বস্ত পণ্য পৌঁছে দিচ্ছে সারা বাংলাদেশের প্রতিটি প্রান্তে।');
    } else if (k == 'dispatch' || k == 'parcel') {
      _editableContent.putIfAbsent('section_title', () => 'সারা দেশে দ্রুততম হোম ডেলিভারি');
      _editableContent.putIfAbsent('section_subtitle', () => 'অর্ডার করার ৪৮ থেকে ৭২ ঘণ্টার মধ্যে আপনার হাতে পণ্য পৌঁছে যাবে ইনশাআল্লাহ।');
      _editableContent.putIfAbsent('dispatch_title', () => 'নিরাপদ প্যাকেজিং ও দ্রুততম কুরিয়ার');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final hasPermission = await PermissionService.requestImagePickerPermission(
      source: ImageSource.gallery,
      context: context,
    );
    if (!hasPermission) return;

    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 90,
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      setState(() {
        _pendingImageBytes = bytes;
        _isUploadingImage = true;
      });

      final sp = Provider.of<SectionProvider>(context, listen: false);
      final target = widget.section.sectionKey == 'navbar' 
          ? 'logo_url' 
          : (widget.section.sectionKey == 'author' ? 'author_image' : 'image_url');

      final uploadedUrl = await sp.uploadSectionImage(
        widget.section.id,
        bytes,
        file.name,
        targetField: target,
      );

      if (uploadedUrl != null && mounted) {
        setState(() {
          _imageUrlController.text = uploadedUrl;
          _editableContent['image_url'] = uploadedUrl;
          if (widget.section.sectionKey == 'author') {
            _editableContent['author_image'] = uploadedUrl;
          }
          _pendingImageBytes = null;
          _isUploadingImage = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.primary,
            content: Text('ছবি সফলভাবে আপলোড ও অপ্টিমাইজ হয়েছে!'),
          ),
        );
      } else {
        setState(() => _isUploadingImage = false);
      }
    } catch (e) {
      setState(() => _isUploadingImage = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppTheme.accentRose, content: Text('আপলোড ব্যর্থ: $e')),
        );
      }
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final sp = Provider.of<SectionProvider>(context, listen: false);

    final updatedContent = Map<String, dynamic>.from(_editableContent);
    final img = _imageUrlController.text.trim();
    if (img.isNotEmpty) {
      updatedContent['image_url'] = img;
      if (widget.section.sectionKey == 'author') {
        updatedContent['author_image'] = img;
      }
    }
    if (widget.section.sectionKey == 'author') {
      if (updatedContent['bio_p1'] != null && updatedContent['author_bio'] == null) {
        updatedContent['author_bio'] = updatedContent['bio_p1'];
      }
    }

    // Bidirectional sync for website template aliases
    if (widget.section.sectionKey == 'footer') {
      final copy = updatedContent['copyright'] ?? updatedContent['copyright_text'];
      if (copy != null && copy.toString().trim().isNotEmpty) {
        updatedContent['copyright'] = copy;
        updatedContent['copyright_text'] = copy;
      }
      final email = updatedContent['support_email'] ?? updatedContent['contact_email'];
      if (email != null && email.toString().trim().isNotEmpty) {
        updatedContent['support_email'] = email;
        updatedContent['contact_email'] = email;
      }
      final phone = updatedContent['support_phone'] ?? updatedContent['phone'];
      if (phone != null && phone.toString().trim().isNotEmpty) {
        updatedContent['support_phone'] = phone;
        updatedContent['phone'] = phone;
      }
      if (updatedContent['brand_subtitle'] != null && updatedContent['footer_tagline'] == null) {
        updatedContent['footer_tagline'] = updatedContent['brand_subtitle'];
      }
    }

    final ok = await sp.updateSection(widget.section.id, {
      'name': _nameController.text.trim(),
      'is_active': _isActive,
      'image_url': _imageUrlController.text.trim(),
      'content': updatedContent,
    });

    if (mounted) {
      setState(() => _isSaving = false);
      if (ok) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.primary,
            content: Text("'${_nameController.text.trim()}' সেকশন সংরক্ষণ হয়েছে!"),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.accentRose,
            content: Text(sp.errorMessage ?? 'সংরক্ষণ ব্যর্থ হয়েছে।'),
          ),
        );
      }
    }
  }

  Color get _sectionColor {
    switch (widget.section.sectionKey) {
      case 'hero': return AppTheme.primary;
      case 'navbar': return AppTheme.accentCyan;
      case 'notice_bar': return AppTheme.accentAmber;
      case 'author': return AppTheme.accentPurple;
      case 'reviews': return AppTheme.accentBlue;
      case 'bookshelf': return const Color(0xFF10B981);
      case 'book_about': return const Color(0xFFF59E0B);
      case 'floating_buttons': return const Color(0xFF22C55E);
      case 'faq': return AppTheme.accentCyan;
      case 'footer': return AppTheme.accentRose;
      default: return AppTheme.primary;
    }
  }

  IconData get _sectionIcon {
    switch (widget.section.sectionKey) {
      case 'hero': return Icons.slideshow_rounded;
      case 'navbar': return Icons.palette_rounded;
      case 'notice_bar': return Icons.campaign_outlined;
      case 'author': return Icons.person_outline_rounded;
      case 'reviews': return Icons.star_outline_rounded;
      case 'bookshelf': return Icons.book_outlined;
      case 'book_about': return Icons.auto_stories_rounded;
      case 'floating_buttons': return Icons.touch_app_rounded;
      case 'faq': return Icons.help_outline_rounded;
      case 'footer': return Icons.web_asset_rounded;
      default: return Icons.widgets_outlined;
    }
  }

  String _formatFieldKey(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }

  List<_EditableField> get _fieldsForSection {
    final c = _editableContent;
    final List<_EditableField> fields = [];
    final handledKeys = <String>{'image_url', 'author_image', 'slides', 'features', 'highlights'};

    switch (widget.section.sectionKey) {
      case 'footer':
        fields.addAll([
          _EditableField('brand_title', 'ব্র্যান্ড নাম (Title)', Icons.business_rounded, c['brand_title']?.toString() ?? 'Life Care'),
          _EditableField('brand_subtitle', 'সাব-টাইটেল (Subtitle)', Icons.subtitles_rounded, c['brand_subtitle']?.toString() ?? 'Medicine BD'),
          _EditableField('description', 'ফুটার বিবরণ ও পরিচিতি', Icons.description_outlined, c['description']?.toString() ?? '', maxLines: 4),
          _EditableField('support_phone', 'যোগাযোগ ও হেল্পলাইন ফোন', Icons.phone_in_talk_rounded, c['support_phone']?.toString() ?? c['phone']?.toString() ?? ''),
          _EditableField('support_email', 'সাপোর্ট ইমেইল', Icons.email_outlined, c['support_email']?.toString() ?? c['contact_email']?.toString() ?? c['email']?.toString() ?? ''),
          _EditableField('address', 'অফিস / ওয়্যারহাউজ ঠিকানা', Icons.location_on_outlined, c['address']?.toString() ?? '', maxLines: 2),
          _EditableField('copyright', 'কপিরাইট টেক্সট', Icons.copyright_rounded, c['copyright']?.toString() ?? c['copyright_text']?.toString() ?? '', maxLines: 2),
        ]);
        handledKeys.addAll(['brand_title', 'brand_subtitle', 'description', 'support_phone', 'phone', 'support_email', 'contact_email', 'email', 'address', 'copyright', 'copyright_text', 'footer_tagline']);
        break;

      case 'floating_buttons':
        fields.addAll([
          _EditableField('phone', 'হেল্পলাইন সরাসরি কল নম্বর', Icons.phone_in_talk_rounded, c['phone']?.toString() ?? ''),
          _EditableField('whatsapp', 'হোয়াটসঅ্যাপ নম্বর (কান্ট্রি কোড সহ)', Icons.chat_bubble_outline_rounded, c['whatsapp']?.toString() ?? ''),
          _EditableField('whatsapp_message', 'হোয়াটসঅ্যাপ প্রিসেট মেসেজ', Icons.message_outlined, c['whatsapp_message']?.toString() ?? '', maxLines: 3),
        ]);
        handledKeys.addAll(['phone', 'whatsapp', 'whatsapp_message']);
        break;

      case 'bookshelf':
        fields.addAll([
          _EditableField('section_badge', 'ব্যাজ টেক্সট', Icons.stars_rounded, c['section_badge']?.toString() ?? 'আমাদের সকল মেডিসিন ও পণ্য'),
          _EditableField('section_title', 'মেডিসিন ক্যাটালগ শিরোনাম', Icons.title_rounded, c['section_title']?.toString() ?? 'আমাদের সকল মেডিসিন ও সাপ্লিমেন্ট'),
          _EditableField('section_subtitle', 'সাব-টাইটেল / বিবরণ', Icons.subtitles_rounded, c['section_subtitle']?.toString() ?? '', maxLines: 3),
        ]);
        handledKeys.addAll(['section_badge', 'section_title', 'section_subtitle']);
        break;

      case 'book_about':
        fields.addAll([
          _EditableField('section_badge', 'ব্যাজ টেক্সট', Icons.stars_rounded, c['section_badge']?.toString() ?? 'মেডিসিন পরিচিতি ও বিশেষত্ব'),
          _EditableField('section_title', 'মেডিসিন পরিচিতি শিরোনাম', Icons.title_rounded, c['section_title']?.toString() ?? 'কেন লাইফ কেয়ার মেডিসিন গ্রাহকদের ১ম পছন্দ?'),
          _EditableField('section_subtitle', 'সাবটাইটেল / সারসংক্ষেপ', Icons.subtitles_rounded, c['section_subtitle']?.toString() ?? '', maxLines: 3),
          _EditableField('quote_badge', 'কোটেশন ব্যাজ', Icons.bookmark_border_rounded, c['quote_badge']?.toString() ?? ''),
          _EditableField('quote_title', 'কোটেশন টাইটেল', Icons.format_quote_rounded, c['quote_title']?.toString() ?? ''),
          _EditableField('quote_text', 'কোটেশন টেক্সট', Icons.notes_rounded, c['quote_text']?.toString() ?? '', maxLines: 2),
          _EditableField('cta_text', 'বাটন টেক্সট', Icons.touch_app_outlined, c['cta_text']?.toString() ?? ''),
        ]);
        handledKeys.addAll(['section_badge', 'section_title', 'section_subtitle', 'quote_badge', 'quote_title', 'quote_text', 'cta_text']);
        break;

      case 'author':
        fields.addAll([
          _EditableField('section_badge', 'সেকশন ব্যাজ', Icons.stars_rounded, c['section_badge']?.toString() ?? '🌿 আমাদের সম্পর্কে • Life Care Medicine BD'),
          _EditableField('author_name', 'ব্র্যান্ড / অথর নাম', Icons.person_outline_rounded, c['author_name']?.toString() ?? 'Life Care Medicine BD'),
          _EditableField('author_title', 'পদবি / সাব-টাইটেল', Icons.badge_outlined, c['author_title']?.toString() ?? 'প্রাকৃতিক ও হারবাল হেলথকেয়ার সল্যুশন'),
          _EditableField('author_tagline', 'ট্যাগলাইন', Icons.label_outline_rounded, c['author_tagline']?.toString() ?? 'Care, Trust & Natural Wellness'),
          _EditableField('author_institute', 'প্রতিষ্ঠান / ল্যাব', Icons.business_outlined, c['author_institute']?.toString() ?? 'লাইফ কেয়ার হেলথ ল্যাবস বাংলাদেশ'),
          _EditableField('author_quote', 'বিশেষ উক্তি / অঙ্গীকার', Icons.format_quote_rounded, c['author_quote']?.toString() ?? '', maxLines: 2),
          _EditableField('bio_p1', 'পরিচিতি অনুচ্ছেদ ১', Icons.info_outline_rounded, c['bio_p1']?.toString() ?? c['author_bio']?.toString() ?? '', maxLines: 4),
          _EditableField('bio_p2', 'পরিচিতি অনুচ্ছেদ ২', Icons.notes_rounded, c['bio_p2']?.toString() ?? '', maxLines: 4),
        ]);
        handledKeys.addAll(['author_name', 'author_title', 'author_bio', 'author_quote', 'author_tagline', 'author_institute', 'bio_p1', 'bio_p2', 'section_badge', 'social_links', 'highlights', 'author_image']);
        break;

      case 'reviews':
        fields.addAll([
          _EditableField('section_title', 'সেকশন টাইটেল', Icons.title_rounded, c['section_title']?.toString() ?? 'হাজারো সুস্থ মানুষের বাস্তব বিশ্বাস ও রিভিউ'),
          _EditableField('section_subtitle', 'সাবটাইটেল', Icons.subtitles_rounded, c['section_subtitle']?.toString() ?? '', maxLines: 2),
          _EditableField('section_badge', 'ব্যাজ টেক্সট', Icons.stars_rounded, c['section_badge']?.toString() ?? ''),
          _EditableField('dispatch_title', 'ডেলিভারি ব্যানার টাইটেল', Icons.local_shipping_outlined, c['dispatch_title']?.toString() ?? '', maxLines: 2),
        ]);
        handledKeys.addAll(['section_title', 'section_subtitle', 'section_badge', 'dispatch_title']);
        break;

      case 'dispatch':
      case 'parcel':
        fields.addAll([
          _EditableField('section_title', 'ডেলিভারি শিরোনাম', Icons.title_rounded, c['section_title']?.toString() ?? 'সারা দেশে দ্রুততম হোম ডেলিভারি'),
          _EditableField('section_subtitle', 'সাবটাইটেল', Icons.subtitles_rounded, c['section_subtitle']?.toString() ?? '', maxLines: 2),
          _EditableField('dispatch_title', 'প্যাকেজিং ব্যানার শিরোনাম', Icons.local_shipping_outlined, c['dispatch_title']?.toString() ?? '', maxLines: 2),
        ]);
        handledKeys.addAll(['section_title', 'section_subtitle', 'dispatch_title']);
        break;

      case 'faq':
        fields.addAll([
          _EditableField('section_title', 'সেকশন টাইটেল', Icons.title_rounded, c['section_title']?.toString() ?? ''),
          _EditableField('section_subtitle', 'সাবটাইটেল', Icons.subtitles_rounded, c['section_subtitle']?.toString() ?? '', maxLines: 2),
        ]);
        handledKeys.addAll(['section_title', 'section_subtitle']);
        break;

      default:
        fields.addAll([
          _EditableField('section_title', 'সেকশন টাইটেল', Icons.title_rounded, c['section_title']?.toString() ?? ''),
          _EditableField('section_subtitle', 'সাবটাইটেল', Icons.subtitles_rounded, c['section_subtitle']?.toString() ?? '', maxLines: 2),
        ]);
        handledKeys.addAll(['section_title', 'section_subtitle']);
        break;
    }

    // Dynamic fallback for any other non-nested fields present in content from the website
    c.forEach((key, val) {
      if (!handledKeys.contains(key) && val != null && (val is String || val is num || val is bool)) {
        fields.add(
          _EditableField(
            key,
            _formatFieldKey(key),
            Icons.tune_rounded,
            val.toString(),
            maxLines: val.toString().length > 60 ? 3 : 1,
          ),
        );
      }
    });

    return fields;
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final screenHeight = mediaQuery.size.height;
    final targetHeight = screenHeight * 0.90;
    final availableHeight = (targetHeight - bottomInset).clamp(280.0, targetHeight);
    final color = _sectionColor;
    final fields = _fieldsForSection;

    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: bottomInset),
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      child: Container(
        height: availableHeight,
        decoration: const BoxDecoration(
          color: AppTheme.bgDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 44, height: 4,
              decoration: BoxDecoration(color: const Color(0xFF334155), borderRadius: BorderRadius.circular(4)),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                  child: Icon(_sectionIcon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.section.name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('কী: ${widget.section.sectionKey}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                    ],
                  ),
                ),
                Switch(value: _isActive, activeColor: AppTheme.primary, onChanged: (v) => setState(() => _isActive = v)),
                IconButton(icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Name
                  _buildTextField('সেকশন লেবেল নাম', _nameController, Icons.label_outlined),
                  const SizedBox(height: 18),

                  // Section Image
                  const Text('সেকশন ছবি (Section Image)', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickAndUploadImage,
                    child: Container(
                      width: double.infinity,
                      height: 160,
                      decoration: BoxDecoration(
                        color: const Color(0xFF161F30),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: color.withOpacity(0.3)),
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(13),
                            child: _pendingImageBytes != null
                                ? Image.memory(_pendingImageBytes!, width: double.infinity, height: 160, fit: BoxFit.cover)
                                : AppNetworkImage(
                                    imageUrl: _imageUrlController.text.isNotEmpty ? _imageUrlController.text : null,
                                    width: double.infinity,
                                    height: 160,
                                    fit: BoxFit.cover,
                                    fallbackIcon: _sectionIcon,
                                    fallbackText: 'ছবি নেই',
                                  ),
                          ),
                          if (_isUploadingImage)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(13)),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2.5),
                                    SizedBox(height: 8),
                                    Text('আপলোড হচ্ছে...', style: TextStyle(color: Colors.white, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ),
                          Positioned(
                            bottom: 8, right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(8)),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.upload_rounded, color: AppTheme.primary, size: 14),
                                  SizedBox(width: 4),
                                  Text('ছবি পরিবর্তন', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildTextField('ছবির URL (ম্যানুয়াল লিঙ্ক)', _imageUrlController, Icons.link_rounded),
                  const SizedBox(height: 18),

                  // Section-specific fields
                  if (fields.isNotEmpty) ...[
                    Text(
                      'সেকশন কন্টেন্ট (${widget.section.sectionKey.toUpperCase()})',
                      style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ...fields.map((field) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildDynamicTextField(field),
                    )),
                  ],

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // Save button
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              color: Color(0xFF161F30),
              border: Border(top: BorderSide(color: Color(0xFF263345))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF94A3B8),
                      side: const BorderSide(color: Color(0xFF334155)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('বাতিল'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon: _isSaving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : const Icon(Icons.save_rounded, color: Colors.black, size: 20),
                    label: Text(
                      _isSaving ? 'সংরক্ষণ হচ্ছে...' : 'সেকশন সেভ করুন',
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          scrollPadding: const EdgeInsets.only(bottom: 80),
          style: const TextStyle(color: Colors.white, fontSize: 13.5),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppTheme.primary, size: 18),
            filled: true, fillColor: const Color(0xFF161F30),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF263345))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF263345))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primary)),
          ),
        ),
      ],
    );
  }

  Widget _buildDynamicTextField(_EditableField field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(field.label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: field.initialValue,
          maxLines: field.maxLines,
          scrollPadding: const EdgeInsets.only(bottom: 80),
          style: const TextStyle(color: Colors.white, fontSize: 13.5),
          onChanged: (v) => setState(() => _editableContent[field.key] = v),
          decoration: InputDecoration(
            prefixIcon: Icon(field.icon, color: AppTheme.primary, size: 18),
            filled: true, fillColor: const Color(0xFF161F30),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF263345))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF263345))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primary)),
          ),
        ),
      ],
    );
  }
}

class _EditableField {
  final String key;
  final String label;
  final IconData icon;
  final String initialValue;
  final int maxLines;

  const _EditableField(this.key, this.label, this.icon, this.initialValue, {this.maxLines = 1});
}

