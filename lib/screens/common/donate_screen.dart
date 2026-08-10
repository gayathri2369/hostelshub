import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import '../../services/mistral_ai_service.dart';
import '../../utils/app_colors.dart';
import '../../main.dart';

class DonateScreen extends StatefulWidget {
  const DonateScreen({super.key});
  @override
  State<DonateScreen> createState() => _DonateScreenState();
}

class _DonateScreenState extends State<DonateScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final List<String> _imagePaths = [];
  final ImagePicker _picker = ImagePicker();
  String _selectedCategory = 'Books';
  bool _donated = false;
  bool _isAnalyzing = false;

  static const _donationCategories = [
    'Books',
    'Clothes',
    'Home Items',
    'Electronics',
    'Stationery',
    'Furniture',
    'Sports Equipment',
    'Other',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  bool get _canDonate =>
      _titleCtrl.text.trim().isNotEmpty &&
      _descCtrl.text.trim().isNotEmpty;

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
                        'Unable to verify item condition with AI.',
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
                        backgroundColor: const Color(0xFF52B788),
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
                          '❌ Cannot Accept',
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
                                  'Only items in good condition can help students effectively.',
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
                        backgroundColor: const Color(0xFF52B788),
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
            final conditionColor = isNew ? const Color(0xFF52B788) : Colors.orange;
            
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
                        isNew ? '✨ New Item!' : '✅ Used Item',
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
                              Icon(Icons.volunteer_activism, color: Colors.blue, size: 18),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Thank you for donating used items in good condition!',
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
            
            setState(() => _imagePaths.add(permanentFile.path));
            
            // Auto-fill details if empty
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
            
            // Show success message
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
                              isNew ? '✓ New Item Accepted' : '✓ Used Item Accepted',
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF52B788),
                    ),
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
                'Add Photo of Donation Item',
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
                    color: const Color(0xFF52B788).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt, color: Color(0xFF52B788)),
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
                    color: const Color(0xFF74C69D).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library,
                      color: Color(0xFF74C69D)),
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

  void _submitDonation() {
    if (!_canDonate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }
    setState(() => _donated = true);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        kIsWeb ? _buildWebLayout() : _buildMobileLayout(),
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
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF52B788)),
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      '🤖 AI Analyzing Item...',
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

  // Web Layout matching the second image design
  Widget _buildWebLayout() {
    if (_donated) return _buildThankYouWeb();
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Left Sidebar
          Container(
            width: 250,
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
            child: Column(
              children: [
                const SizedBox(height: 40),
                // User Profile
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text(
                            'T',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'test5',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'test5@gmail.com',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF52B788),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.account_circle, size: 14, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'Donor Account',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 10),
                
                // Navigation Menu
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildWebMenuItem(
                          icon: Icons.home_outlined,
                          label: 'Home',
                          subtitle: 'Back to Browse',
                          onTap: () => Navigator.pop(context),
                        ),
                        _buildWebMenuItem(
                          icon: Icons.person_outline,
                          label: 'My Profile',
                          subtitle: 'View & edit info',
                          onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
                        ),
                        _buildWebMenuItem(
                          icon: Icons.volunteer_activism_outlined,
                          label: 'My Donations',
                          subtitle: 'Track your donations',
                          isActive: true,
                          onTap: () {},
                        ),
                        _buildWebMenuItem(
                          icon: Icons.favorite_outline,
                          label: 'Favorites',
                          subtitle: 'Your saved items',
                          onTap: () => Navigator.pushNamed(context, AppRoutes.wishlist),
                        ),
                        _buildWebMenuItem(
                          icon: Icons.settings_outlined,
                          label: 'Settings',
                          subtitle: 'Notifications & privacy',
                          onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Main Content
          Expanded(
            child: Column(
              children: [
                // Top Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Donate Items',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'Hello, test5! 👋',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF52B788),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Find great deals',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column - Form
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Hero Card
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF52B788), Color(0xFF74C69D)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF52B788).withValues(alpha: 0.3),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.favorite, color: Colors.white, size: 36),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Every donation makes a difference',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Share books, clothes, or home items with students in need and help build a better tomorrow. 💛',
                                            style: TextStyle(
                                              color: Colors.white.withValues(alpha: 0.9),
                                              fontSize: 13,
                                              height: 1.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.volunteer_activism_rounded,
                                        size: 48,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32),
                              
                              // Photos Section
                              const Text(
                                'Photos (Optional)',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Column(
                                  children: [
                                    GestureDetector(
                                      onTap: _showImageSourceDialog,
                                      child: Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF52B788).withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: const Color(0xFF52B788),
                                            width: 1.5,
                                            style: BorderStyle.solid,
                                          ),
                                        ),
                                        child: const Column(
                                          children: [
                                            Icon(Icons.add_photo_alternate_outlined,
                                                size: 32, color: Color(0xFF52B788)),
                                            SizedBox(height: 8),
                                            Text(
                                              'Add Photos',
                                              style: TextStyle(
                                                color: Color(0xFF52B788),
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'You can add photos of the items you want to donate',
                                              style: TextStyle(
                                                color: AppColors.textSecondary,
                                                fontSize: 12,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () => _pickImage(ImageSource.camera),
                                            icon: const Icon(Icons.camera_alt, size: 18),
                                            label: const Text('Camera'),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: const Color(0xFF52B788),
                                              side: const BorderSide(color: Color(0xFF52B788)),
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () => _pickImage(ImageSource.gallery),
                                            icon: const Icon(Icons.photo_library, size: 18),
                                            label: const Text('Gallery'),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: const Color(0xFF74C69D),
                                              side: const BorderSide(color: Color(0xFF74C69D)),
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (_imagePaths.isNotEmpty) ...[
                                      const SizedBox(height: 16),
                                      GridView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 4,
                                          crossAxisSpacing: 10,
                                          mainAxisSpacing: 10,
                                          childAspectRatio: 1,
                                        ),
                                        itemCount: _imagePaths.length,
                                        itemBuilder: (_, i) => Stack(
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF52B788).withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: AppColors.border),
                                              ),
                                              clipBehavior: Clip.hardEdge,
                                              child: Image.file(
                                                File(_imagePaths[i]),
                                                width: double.infinity,
                                                height: double.infinity,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => const Center(
                                                  child: Icon(Icons.broken_image, color: AppColors.textHint),
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              top: 4,
                                              right: 4,
                                              child: GestureDetector(
                                                onTap: () => _removeImage(i),
                                                child: Container(
                                                  padding: const EdgeInsets.all(4),
                                                  decoration: const BoxDecoration(
                                                    color: AppColors.error,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(Icons.close,
                                                      size: 14, color: Colors.white),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              
                              // Form Fields
                              const Text(
                                'What are you donating?',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _titleCtrl,
                                decoration: const InputDecoration(
                                  hintText: 'e.g., Engineering Textbooks, Winter Jacket, Study Table',
                                  prefixIcon: Icon(Icons.edit_outlined, color: AppColors.primary),
                                ),
                                textCapitalization: TextCapitalization.words,
                                onChanged: (_) => setState(() {}),
                              ),
                              const SizedBox(height: 20),
                              
                              const Text(
                                'Category',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedCategory,
                                    isExpanded: true,
                                    icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                                    items: _donationCategories.map((cat) {
                                      return DropdownMenuItem(value: cat, child: Text(cat));
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) setState(() => _selectedCategory = val);
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              
                              const Text(
                                'Description & Condition',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _descCtrl,
                                maxLines: 5,
                                decoration: const InputDecoration(
                                  hintText:
                                      'Describe the item, its condition, and why you\'re donating...',
                                  alignLabelWithHint: true,
                                ),
                                textCapitalization: TextCapitalization.sentences,
                                onChanged: (_) => setState(() {}),
                              ),
                              const SizedBox(height: 28),
                              
                              // Submit Button - Neat size for web
                              SizedBox(
                                width: 250,
                                child: ElevatedButton.icon(
                                  onPressed: _canDonate ? _submitDonation : null,
                                  icon: const Icon(Icons.volunteer_activism_rounded, size: 18),
                                  label: const Text('Submit Donation',
                                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF52B788),
                                    disabledBackgroundColor: AppColors.textHint,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Info note
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.info.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
                                ),
                                child: const Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.info_outline, size: 16, color: AppColors.info),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Your donation will be listed for free pickup. Students in need '
                                        'can contact you to collect the items.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(width: 32),
                        
                        // Right Column - Tips
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF52B788).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFF52B788).withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.lightbulb_outline,
                                            color: Color(0xFF52B788), size: 20),
                                        SizedBox(width: 8),
                                        Text(
                                          'Donation Ideas',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                            color: Color(0xFF52B788),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Not sure what to donate?',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    _buildTipItem('Course books you no longer need'),
                                    _buildTipItem('Clothes that don\'t fit anymore'),
                                    _buildTipItem('Kitchen utensils or bedding'),
                                    _buildTipItem('Study lamp or desk organizer'),
                                    _buildTipItem('Old electronics in working condition'),
                                    _buildTipItem('Anything useful can help someone!'),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.success.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    const Icon(Icons.verified_user,
                                        color: AppColors.success, size: 40),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Safe & Trusted',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: AppColors.success,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Your donation will be listed for free pickup. Students in need can contact you to collect the items.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebMenuItem({
    required IconData icon,
    required String label,
    String? subtitle,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: ListTile(
        leading: Icon(icon, color: Colors.white, size: 22),
        title: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              )
            : null,
        selected: isActive,
        selectedTileColor: Colors.white.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        onTap: onTap,
        enableFeedback: true,
        hoverColor: Colors.white.withValues(alpha: 0.1),
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 16, color: Color(0xFF52B788)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThankYouWeb() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF52B788), Color(0xFF74C69D)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF52B788).withValues(alpha: 0.4),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(Icons.volunteer_activism_rounded,
                    size: 56, color: Colors.white),
              ),
              const SizedBox(height: 32),
              const Text('Thank You! 🙏',
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              const Text(
                'Your generosity will help a fellow student in need.\n'
                'We\'ll notify interested students about your donation!',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 16, height: 1.6),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: 200,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back to App'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF52B788),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Mobile Layout - Original design
  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Donate Items'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: _donated ? _buildThankYou() : _buildDonateForm(),
    );
  }

  Widget _buildDonateForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF52B788), Color(0xFF74C69D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF52B788).withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(Icons.volunteer_activism_rounded,
                    color: Colors.white, size: 44),
                const SizedBox(height: 12),
                const Text('Donate',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(
                  'Share books, clothes, or home items\nwith students in need 🤝',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Photos Section
          const Text('Photos (Optional)',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 10),
          
          // Add Photo Button
          GestureDetector(
            onTap: _showImageSourceDialog,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF52B788).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF52B788), width: 1.5),
              ),
              child: const Column(
                children: [
                  Icon(Icons.add_photo_alternate_outlined, 
                      size: 32, color: Color(0xFF52B788)),
                  SizedBox(height: 8),
                  Text('Add Photos',
                      style: TextStyle(
                          color: Color(0xFF52B788), fontWeight: FontWeight.w600)),
                  SizedBox(height: 4),
                  Text('Camera or Gallery',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Quick Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: const Text('Camera'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF52B788),
                    side: const BorderSide(color: Color(0xFF52B788)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library, size: 18),
                  label: const Text('Gallery'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF74C69D),
                    side: const BorderSide(color: Color(0xFF74C69D)),
                  ),
                ),
              ),
            ],
          ),
          
          if (_imagePaths.isNotEmpty) ...[
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1,
              ),
              itemCount: _imagePaths.length,
              itemBuilder: (_, i) => Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF52B788).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: Image.file(
                      File(_imagePaths[i]),
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
                      onTap: () => _removeImage(i),
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
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 20),

          // Item Title
          const Text('What are you donating?',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 10),
          TextFormField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              hintText: 'e.g., Engineering Textbooks, Winter Jacket',
              prefixIcon: Icon(Icons.edit_outlined, color: AppColors.primary),
            ),
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),

          // Category
          const Text('Category',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCategory,
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down,
                    color: AppColors.primary),
                items: _donationCategories.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Description
          const Text('Description & Condition',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 10),
          TextFormField(
            controller: _descCtrl,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText:
                  'Describe the item, its condition, and why you\'re donating...',
              alignLabelWithHint: true,
            ),
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 28),

          // Donate button
          ElevatedButton.icon(
            onPressed: _canDonate ? _submitDonation : null,
            icon: const Icon(Icons.volunteer_activism_rounded, size: 18),
            label: const Text('Submit Donation',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF52B788),
              disabledBackgroundColor: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 16),

          // Info note
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 16, color: AppColors.info),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Your donation will be listed for free pickup. Students in need '
                    'can contact you to collect the items.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Examples
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline,
                        size: 16, color: AppColors.success),
                    SizedBox(width: 6),
                    Text('Donation Ideas:',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.success)),
                  ],
                ),
                SizedBox(height: 8),
                _DonationExample(text: 'Course books you no longer need'),
                _DonationExample(text: 'Clothes that don\'t fit anymore'),
                _DonationExample(text: 'Kitchen utensils or bedding'),
                _DonationExample(text: 'Study lamp or desk organizer'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThankYou() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF52B788), Color(0xFF74C69D)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF52B788).withValues(alpha: 0.4),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(Icons.volunteer_activism_rounded,
                  size: 56, color: Colors.white),
            ),
            const SizedBox(height: 32),
            const Text('Thank You! 🙏',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            const Text(
              'Your generosity will help a fellow student in need.\n'
              'We\'ll notify interested students about your donation!',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 15, height: 1.6),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to App'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF52B788),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DonationExample extends StatelessWidget {
  final String text;
  const _DonationExample({required this.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('• ',
                style: TextStyle(
                    color: AppColors.success, fontWeight: FontWeight.bold)),
            Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ),
          ],
        ),
      );
}
