import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../services/mistral_ai_service.dart';
import '../../utils/app_colors.dart';
import '../../main.dart';

class SellItemFlow extends StatefulWidget {
  const SellItemFlow({super.key});

  @override
  State<SellItemFlow> createState() => _SellItemFlowState();
}

class _SellItemFlowState extends State<SellItemFlow> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 5;

  // Form data
  final List<String> _imagePaths = [];
  final List<ProductAnalysisResult> _imageAnalyses = []; // Store AI analysis results
  final ImagePicker _picker = ImagePicker();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  ProductCategory _category = ProductCategory.electronics;
  final _priceCtrl = TextEditingController();
  bool _isPosting = false;
  bool _isAnalyzing = false;

  final List<String> _stepLabels = [
    'Photos', 'Details', 'Category', 'Price', 'Preview'
  ];

  @override
  void initState() {
    super.initState();
    // Add listeners to update button state when text changes
    _titleCtrl.addListener(_updateButtonState);
    _descCtrl.addListener(_updateButtonState);
    _priceCtrl.addListener(_updateButtonState);
  }

  void _updateButtonState() {
    setState(() {}); // Rebuild to update button enabled/disabled state
  }

  @override
  void dispose() {
    _titleCtrl.removeListener(_updateButtonState);
    _descCtrl.removeListener(_updateButtonState);
    _priceCtrl.removeListener(_updateButtonState);
    _pageController.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image != null) {
        // Copy image to permanent app directory
        final Directory appDir = await getApplicationDocumentsDirectory();
        final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(image.path)}';
        final String permanentPath = path.join(appDir.path, 'product_images', fileName);
        
        // Create directory if it doesn't exist
        final Directory imageDir = Directory(path.join(appDir.path, 'product_images'));
        if (!await imageDir.exists()) {
          await imageDir.create(recursive: true);
        }
        
        // Copy the image to permanent location
        final File sourceFile = File(image.path);
        final File permanentFile = await sourceFile.copy(permanentPath);
        
        // Analyze the image with AI
        if (MistralAIService.isConfigured) {
          setState(() => _isAnalyzing = true);
          
          try {
            final analysis = await MistralAIService.analyzeProductImage(permanentFile.path);
            
            if (!mounted) return;
            
            // Check if API call failed
            if (!analysis.apiSuccess) {
              await showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 28),
                      SizedBox(width: 12),
                      Text('AI Verification Failed'),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Unable to verify product condition with AI.',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Error Details:',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              analysis.description,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '⚠️ Check:\n• Internet connection\n• Terminal for error logs\n• API key validity',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Allow upload despite API failure (with warning)
                        setState(() => _imagePaths.add(permanentFile.path));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('⚠️ Uploaded without AI verification - ensure item is in good condition!'),
                            backgroundColor: AppColors.warning,
                            duration: Duration(seconds: 5),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.warning,
                      ),
                      child: const Text('Upload Anyway'),
                    ),
                  ],
                ),
              );
              
              setState(() => _isAnalyzing = false);
              return;
            }
            
            // Check if product is broken
            if (analysis.isBroken) {
              // Show rejection dialog with full details
              await showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.block, color: AppColors.error, size: 32),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          '❌ Cannot Upload',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '🚫 BROKEN ITEM DETECTED',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.error,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildInfoRow('📦 Product', analysis.productName),
                              _buildInfoRow('🏷️ Brand', analysis.brand),
                              _buildInfoRow('📊 Condition', analysis.condition,
                                  valueColor: AppColors.error),
                              const SizedBox(height: 12),
                              const Text(
                                'Details:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                analysis.description,
                                style: const TextStyle(fontSize: 13, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue, size: 20),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Only items in good working condition can be listed to help students.',
                                  style: TextStyle(fontSize: 12, height: 1.3),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.photo_camera),
                      label: const Text('Try Another Item'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ),
              );
              
              // Delete the rejected image
              await permanentFile.delete();
              setState(() => _isAnalyzing = false);
              return;
            }
            
            // Product accepted - show success with details
            final isNew = analysis.condition.toUpperCase() == 'NEW';
            final conditionEmoji = isNew ? '✨' : '📦';
            final conditionColor = isNew ? AppColors.success : Colors.orange;
            
            await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: conditionColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isNew ? Icons.new_releases : Icons.check_circle,
                        color: conditionColor,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isNew ? '✨ New Product!' : '✅ Used Product',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: conditionColor,
                        ),
                      ),
                    ),
                  ],
                ),
                content: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: conditionColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: conditionColor.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Condition Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: conditionColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$conditionEmoji ${analysis.condition.toUpperCase()} CONDITION',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow('📦 Product', analysis.productName),
                      _buildInfoRow('🏷️ Brand', analysis.brand),
                      _buildInfoRow('📊 Condition', analysis.condition,
                          valueColor: conditionColor),
                      const SizedBox(height: 12),
                      const Text(
                        'Details:',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        analysis.description,
                        style: const TextStyle(fontSize: 13, height: 1.4),
                      ),
                      if (!isNew) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue, size: 18),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Used items are welcome! Help other students.',
                                  style: TextStyle(fontSize: 11, color: Colors.blue),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: conditionColor,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Continue'),
                  ),
                ],
              ),
            );
            
            setState(() {
              _imagePaths.add(permanentFile.path);
              _imageAnalyses.add(analysis);
            });
            
            // Auto-fill product details if empty
            if (_titleCtrl.text.isEmpty && analysis.productName != 'Unknown Product') {
              // Include brand in title if available
              if (analysis.brand != 'Unknown Brand') {
                _titleCtrl.text = '${analysis.brand} ${analysis.productName}';
              } else {
                _titleCtrl.text = analysis.productName;
              }
            }
            if (_descCtrl.text.isEmpty && analysis.description.isNotEmpty) {
              _descCtrl.text = 'Condition: ${analysis.condition}\n\n${analysis.description}';
              if (analysis.features.isNotEmpty) {
                _descCtrl.text += '\n\nFeatures: ${analysis.features.join(', ')}';
              }
            }
            
            // Show success message with analysis
            if (mounted) {
              final conditionEmoji = isNew ? '✨' : '📦';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(
                        isNew ? Icons.new_releases : Icons.check_circle,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isNew ? '✓ New Product Added' : '✓ Used Product Added',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              '${analysis.brand} ${analysis.productName} - $conditionEmoji ${analysis.condition}',
                              style: const TextStyle(fontSize: 12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: conditionColor,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          } catch (e) {
            // If AI call throws an exception, show error dialog with retry
            debugPrint('❌ EXCEPTION during AI analysis: $e');
            
            if (!mounted) return;
            setState(() => _isAnalyzing = false);
            
            final shouldRetry = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: const Row(
                  children: [
                    Icon(Icons.error_outline, color: AppColors.error, size: 28),
                    SizedBox(width: 12),
                    Text('Verification Failed'),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Couldn\'t verify this photo. Check your connection and try again.',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        e.toString(),
                        style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
            
            // Delete the image file and optionally retry
            await permanentFile.delete();
            
            if (shouldRetry == true && mounted) {
              // Retry by calling _pickImage again
              _pickImage(ImageSource.gallery);
            }
            return;
          } finally {
            if (mounted) setState(() => _isAnalyzing = false);
          }
        } else {
          // AI not configured, add without analysis
          setState(() => _imagePaths.add(permanentFile.path));
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAnalyzing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add Product Photo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt, color: AppColors.primary),
                ),
                title: const Text('Camera',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Take a new photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library,
                      color: AppColors.secondary),
                ),
                title: const Text('Gallery',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _removeImage(int index) {
    setState(() => _imagePaths.removeAt(index));
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _next() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
      setState(() => _currentStep++);
    }
  }

  void _back() {
    if (_currentStep > 0) {
      _pageController.previousPage(
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _postItem() async {
    setState(() => _isPosting = true);

    // Capture everything needed from context BEFORE the async call
    final auth     = context.read<AuthProvider>();
    final products = context.read<ProductProvider>();
    final user     = auth.currentUser!;
    final title    = _titleCtrl.text.trim();
    final desc     = _descCtrl.text.trim();
    final price    = double.tryParse(_priceCtrl.text.trim()) ?? 0;
    final images   = List<String>.from(_imagePaths); // Use local paths
    final category = _category;

    final product = await products.addProduct(
      title:        title,
      description:  desc,
      category:     category,
      price:        price,
      imageUrls:    images,
      sellerId:     user.id,
      sellerName:   user.name,
      sellerHostel: user.hostelName,
      sellerPhone:  user.phone,
    );

    if (!mounted) return;
    setState(() => _isPosting = false);
    Navigator.pushReplacementNamed(
        context, AppRoutes.productSuccess, arguments: product);
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0: return true;
      case 1: return _titleCtrl.text.isNotEmpty && _descCtrl.text.isNotEmpty;
      case 2: return true;
      case 3: return _priceCtrl.text.isNotEmpty && (double.tryParse(_priceCtrl.text) ?? 0) > 0;
      case 4: return true;
      default: return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Sell an Item'),
            leading: IconButton(
                onPressed: _back,
                icon: const Icon(Icons.arrow_back_ios_new_rounded)),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(68),
              child: _StepIndicator(
                  steps: _stepLabels, currentStep: _currentStep),
            ),
          ),
          body: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _Step1Photos(
                imagePaths: _imagePaths,
                onAddFromCamera: () => _pickImage(ImageSource.camera),
                onAddFromGallery: () => _pickImage(ImageSource.gallery),
                onShowDialog: _showImageSourceDialog,
                onRemove: _removeImage,
              ),
              _Step2Details(titleCtrl: _titleCtrl, descCtrl: _descCtrl),
              _Step3Category(selected: _category,
                  onChanged: (c) => setState(() => _category = c)),
              _Step4Price(priceCtrl: _priceCtrl),
              _Step5Preview(
                title: _titleCtrl.text,
                description: _descCtrl.text,
                category: _category,
                price: _priceCtrl.text,
                imagePaths: _imagePaths,
                sellerName: context.read<AuthProvider>().currentUser!.name,
                sellerHostel: context.read<AuthProvider>().currentUser!.hostelName,
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Row(
                children: [
                  if (_currentStep > 0)
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    onPressed: _back,
                    child: const Text('Back'),
                  ),
                ),
              if (_currentStep > 0) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: (_canProceed() && !_isPosting)
                      ? (_currentStep == _totalSteps - 1 ? _postItem : _next)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _currentStep == _totalSteps - 1
                        ? AppColors.secondary
                        : AppColors.primary,
                  ),
                  child: _isPosting
                      ? const SizedBox(height: 20, width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(_currentStep == _totalSteps - 1
                          ? 'Post Item 🚀' : 'Continue',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
        // AI Analyzing Overlay
        if (_isAnalyzing)
          Container(
            color: Colors.black54,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      '🤖 AI Analyzing Product...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Checking condition & quality',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Step Indicator ───────────────────────────────────────────────────────────
class _StepIndicator extends StatelessWidget {
  final List<String> steps;
  final int currentStep;
  const _StepIndicator({required this.steps, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: List.generate(steps.length, (i) {
          final done = i < currentStep;
          final active = i == currentStep;
          return Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    if (i > 0) Expanded(child: Container(height: 2,
                        color: done ? Colors.white : Colors.white30)),
                    Container(
                      width: 24, height: 24,
                      decoration: BoxDecoration(
                        color: (done || active) ? Colors.white : Colors.white30,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: done
                            ? const Icon(Icons.check, size: 14, color: AppColors.primary)
                            : Text('${i + 1}',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.bold,
                                    color: active ? AppColors.primary : Colors.white70)),
                      ),
                    ),
                    if (i < steps.length - 1) Expanded(child: Container(height: 2,
                        color: done ? Colors.white : Colors.white30)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(steps[i],
                    style: TextStyle(
                        fontSize: 10,
                        color: active ? Colors.white : Colors.white60,
                        fontWeight: active ? FontWeight.w700 : FontWeight.normal)),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ─── Step 1: Upload Photos ────────────────────────────────────────────────────
class _Step1Photos extends StatelessWidget {
  final List<String> imagePaths;
  final VoidCallback onAddFromCamera;
  final VoidCallback onAddFromGallery;
  final VoidCallback onShowDialog;
  final Function(int) onRemove;
  
  const _Step1Photos({
    required this.imagePaths,
    required this.onAddFromCamera,
    required this.onAddFromGallery,
    required this.onShowDialog,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Upload Product Photos',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          const Text('Add clear photos so buyers can see your item well.',
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          
          // Add Photo Button
          GestureDetector(
            onTap: onShowDialog,
            child: Container(
              width: double.infinity,
              height: 140,
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary, width: 2, style: BorderStyle.solid),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined, size: 40, color: AppColors.primary),
                  SizedBox(height: 8),
                  Text('Tap to Add Photo', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                  SizedBox(height: 4),
                  Text('Camera or Gallery', style: TextStyle(color: AppColors.textHint, fontSize: 12)),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Quick Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onAddFromCamera,
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: const Text('Camera'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onAddFromGallery,
                  icon: const Icon(Icons.photo_library, size: 18),
                  label: const Text('Gallery'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.secondary,
                    side: const BorderSide(color: AppColors.secondary),
                  ),
                ),
              ),
            ],
          ),
          
          if (imagePaths.isNotEmpty) ...[
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Added Photos', 
                    style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                Text('${imagePaths.length} ${imagePaths.length == 1 ? 'photo' : 'photos'}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1,
              ),
              itemCount: imagePaths.length,
              itemBuilder: (_, i) => Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: Image.file(
                      File(imagePaths[i]),
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.broken_image, color: AppColors.textHint),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4, right: 4,
                    child: GestureDetector(
                      onTap: () => onRemove(i),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 4, left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.lightbulb_outline, size: 18, color: AppColors.info),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Photos are optional but recommended. Good photos help sell faster!',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Step 2: Product Details ──────────────────────────────────────────────────
class _Step2Details extends StatelessWidget {
  final TextEditingController titleCtrl;
  final TextEditingController descCtrl;
  const _Step2Details({required this.titleCtrl, required this.descCtrl});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Product Details',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          const Text('Give your item a clear title and description.',
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 28),
          const Text('Product Title', style: TextStyle(fontWeight: FontWeight.w600,
              fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          TextFormField(
            controller: titleCtrl,
            decoration: const InputDecoration(
              hintText: 'e.g. Scientific Calculator Casio FX-991EX',
              prefixIcon: Icon(Icons.title, color: AppColors.primary),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 20),
          const Text('Description', style: TextStyle(fontWeight: FontWeight.w600,
              fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          TextFormField(
            controller: descCtrl,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Describe the condition, age, and reason for selling...',
              alignLabelWithHint: true,
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tips for a great listing:', style: TextStyle(fontWeight: FontWeight.w700,
                    fontSize: 13, color: AppColors.success)),
                SizedBox(height: 8),
                _Tip(text: 'Mention the condition (new / used / slightly used)'),
                _Tip(text: 'Include brand name and model if applicable'),
                _Tip(text: 'State if any accessories are included'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  final String text;
  const _Tip({required this.text});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('• ', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
          ],
        ),
      );
}

// ─── Step 3: Category ─────────────────────────────────────────────────────────
class _Step3Category extends StatelessWidget {
  final ProductCategory selected;
  final ValueChanged<ProductCategory> onChanged;
  const _Step3Category({required this.selected, required this.onChanged});

  static const _categories = [
    (ProductCategory.electronics, Icons.devices_outlined, 'Electronics'),
    (ProductCategory.books, Icons.menu_book_outlined, 'Books'),
    (ProductCategory.clothing, Icons.checkroom_outlined, 'Clothing'),
    (ProductCategory.furniture, Icons.chair_outlined, 'Furniture'),
    (ProductCategory.kitchenware, Icons.kitchen_outlined, 'Kitchenware'),
    (ProductCategory.sports, Icons.sports_soccer_outlined, 'Sports'),
    (ProductCategory.stationery, Icons.edit_outlined, 'Stationery'),
    (ProductCategory.other, Icons.category_outlined, 'Other'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Category',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          const Text('Pick the category that best describes your item.',
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.5),
            itemCount: _categories.length,
            itemBuilder: (_, i) {
              final (cat, icon, label) = _categories[i];
              final isSelected = selected == cat;
              return GestureDetector(
                onTap: () => onChanged(cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border, width: 2),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 30, color: isSelected ? Colors.white : AppColors.primary),
                      const SizedBox(height: 8),
                      Text(label,
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13,
                              color: isSelected ? Colors.white : AppColors.textPrimary)),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Step 4: Price ────────────────────────────────────────────────────────────
class _Step4Price extends StatelessWidget {
  final TextEditingController priceCtrl;
  const _Step4Price({required this.priceCtrl});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Set Your Price',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          const Text('Set a fair price. You can always negotiate with buyers.',
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 40),
          Center(
            child: Column(
              children: [
                const Text('₹', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w300,
                    color: AppColors.textSecondary)),
                SizedBox(
                  width: 220,
                  child: TextFormField(
                    controller: priceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800,
                        color: AppColors.primary),
                    decoration: const InputDecoration(
                      hintText: '0',
                      hintStyle: TextStyle(fontSize: 40, color: AppColors.textHint),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
                Container(height: 2, width: 180, color: AppColors.primary),
                const SizedBox(height: 8),
                const Text('Enter price in Indian Rupees',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 40),
          const Text('Suggested prices', style: TextStyle(fontWeight: FontWeight.w700,
              color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [100, 250, 500, 750, 1000, 1500, 2000].map((p) =>
              GestureDetector(
                onTap: () => priceCtrl.text = '$p',
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)],
                  ),
                  child: Text('₹$p', style: const TextStyle(fontWeight: FontWeight.w600,
                      color: AppColors.primary)),
                ),
              ),
            ).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Step 5: Preview ─────────────────────────────────────────────────────────
class _Step5Preview extends StatelessWidget {
  final String title, description, price, sellerName, sellerHostel;
  final ProductCategory category;
  final List<String> imagePaths;
  const _Step5Preview({required this.title, required this.description, required this.category,
      required this.price, required this.imagePaths, required this.sellerName, required this.sellerHostel});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Preview Listing',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          const Text('This is how buyers will see your product.',
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 4))],
            ),
            clipBehavior: Clip.hardEdge,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 200, width: double.infinity,
                  color: AppColors.primaryLight.withValues(alpha: 0.2),
                  child: imagePaths.isEmpty
                      ? const Center(child: Icon(Icons.image_outlined, size: 60, color: AppColors.primaryLight))
                      : Image.file(
                          File(imagePaths[0]),
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.broken_image, size: 60, color: AppColors.textHint),
                          ),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(title.isEmpty ? 'Product Title' : title,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary)),
                          ),
                          Text('₹${price.isEmpty ? '0' : price}',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                                  color: AppColors.primary)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(category.name[0].toUpperCase() + category.name.substring(1),
                            style: const TextStyle(fontSize: 12, color: AppColors.primary,
                                fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(height: 12),
                      Text(description.isEmpty ? 'Product description will appear here...' : description,
                          style: const TextStyle(color: AppColors.textSecondary, height: 1.5)),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
                            child: const Icon(Icons.person, color: AppColors.primary),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(sellerName, style: const TextStyle(fontWeight: FontWeight.w700)),
                              Text(sellerHostel, style: const TextStyle(fontSize: 12,
                                  color: AppColors.textSecondary)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.secondary, size: 18),
                SizedBox(width: 10),
                Expanded(child: Text('Your listing will go live after you tap "Post Item".',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
