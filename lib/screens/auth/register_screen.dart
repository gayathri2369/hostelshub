import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/chat_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/supabase_config.dart';
import '../../main.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _hostelCtrl = TextEditingController();
  final _roomCtrl = TextEditingController();
  UserRole _selectedRole = UserRole.buyer;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _hostelCtrl.dispose();
    _roomCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      password: _passwordCtrl.text,
      role: _selectedRole,
      hostelName: _hostelCtrl.text.trim(),
      roomNumber: _roomCtrl.text.trim(),
    );
    if (!mounted) return;
    if (success) {
      final user = auth.currentUser!;
      await Future.wait([
        context.read<ProductProvider>().loadData(user.id),
        context.read<ChatProvider>().loadConversations(user.id),
      ]);
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        _selectedRole == UserRole.seller
            ? AppRoutes.sellerDashboard
            : AppRoutes.buyerDashboard,
      );
    } else {
      final errorMsg = auth.errorMessage ?? 'Registration failed';
      final isRateLimit = errorMsg.toLowerCase().contains('rate limit');
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isRateLimit ? 'Email Rate Limit Exceeded' : 'Registration Failed',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                isRateLimit
                    ? 'Please disable email confirmations in Supabase dashboard → Auth → Providers → Email'
                    : errorMsg,
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 6),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use different layouts for web and mobile
    return kIsWeb ? _buildWebLayout() : _buildMobileLayout();
  }

  // Web Layout: Split screen design
  Widget _buildWebLayout() {
    return Scaffold(
      backgroundColor: const Color(0xFF1B5E40),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1400),
          margin: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF1B5E40),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              // Left side - Branding & Illustration
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.all(60),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF1B5E40),
                        const Color(0xFF2D6A4F),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      bottomLeft: Radius.circular(24),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Logo
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.home_work_rounded,
                                color: Color(0xFF1B5E40),
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Text(
                              'HostelHub',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 60),
                        
                        // Welcome text
                        const Text(
                          'Join HostelHub Today!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Create your account and start buying\nor selling items in your hostel community.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 18,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 48),
                        
                        // Why Join section
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Why join HostelHub?',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 24),
                              _buildWebFeature(
                                Icons.shopping_bag_outlined,
                                'Buy & Sell',
                                'Find great deals or list your items',
                              ),
                              const SizedBox(height: 20),
                              _buildWebFeature(
                                Icons.people_outline,
                                'Community',
                                'Connect with fellow hostel students',
                              ),
                              const SizedBox(height: 20),
                              _buildWebFeature(
                                Icons.favorite_outline,
                                'Save & Donate',
                                'Wishlist items or donate to others',
                              ),
                              const SizedBox(height: 20),
                              _buildWebFeature(
                                Icons.chat_bubble_outline,
                                'Chat',
                                'Message sellers directly',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // Illustration placeholder
                        Center(
                          child: Icon(
                            Icons.people_alt_rounded,
                            size: 180,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Right side - Registration form
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.all(60),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header
                        const Text(
                          'Create Account',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Join the HostelHub community today',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // Connection Status
                        if (SupabaseConfig.isConfigured)
                          Container(
                            padding: const EdgeInsets.all(14),
                            margin: const EdgeInsets.only(bottom: 24),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.cloud_done, size: 18, color: AppColors.success),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Connected to Supabase',
                                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        // Form
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Role Selection
                              const Text(
                                'I want to',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _RoleCard(
                                      role: UserRole.buyer,
                                      selectedRole: _selectedRole,
                                      icon: Icons.shopping_bag_outlined,
                                      label: 'Buy Items',
                                      subtitle: 'Browse & purchase',
                                      onTap: () =>
                                          setState(() => _selectedRole = UserRole.buyer),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _RoleCard(
                                      role: UserRole.seller,
                                      selectedRole: _selectedRole,
                                      icon: Icons.sell_outlined,
                                      label: 'Sell Items',
                                      subtitle: 'List & earn',
                                      onTap: () => setState(
                                          () => _selectedRole = UserRole.seller),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              _buildLabel('Full Name'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _nameCtrl,
                                decoration: const InputDecoration(
                                  hintText: 'Your full name',
                                  prefixIcon: Icon(Icons.person_outline,
                                      color: AppColors.primary),
                                ),
                                validator: (v) =>
                                    (v == null || v.isEmpty) ? 'Name is required' : null,
                              ),
                              const SizedBox(height: 16),

                              _buildLabel('Email Address'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  hintText: 'your@email.com',
                                  prefixIcon: Icon(Icons.email_outlined,
                                      color: AppColors.primary),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Email required';
                                  if (!v.contains('@')) return 'Enter valid email';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              _buildLabel('Phone Number'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _phoneCtrl,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  hintText: '10-digit mobile number',
                                  prefixIcon: Icon(Icons.phone_outlined,
                                      color: AppColors.primary),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Phone required';
                                  if (v.length < 10) return 'Enter valid phone number';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              _buildLabel('Password'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _passwordCtrl,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  hintText: 'Create a password',
                                  prefixIcon: const Icon(Icons.lock_outline,
                                      color: AppColors.primary),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: AppColors.textSecondary,
                                    ),
                                    onPressed: () => setState(
                                        () => _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              _buildLabel('Hostel Name'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _hostelCtrl,
                                decoration: const InputDecoration(
                                  hintText: 'e.g. Block A Hostel',
                                  prefixIcon: Icon(Icons.home_outlined,
                                      color: AppColors.primary),
                                ),
                                validator: (v) => (v == null || v.isEmpty)
                                    ? 'Hostel name required'
                                    : null,
                              ),
                              const SizedBox(height: 16),

                              _buildLabel('Room Number'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _roomCtrl,
                                decoration: const InputDecoration(
                                  hintText: 'e.g. 204',
                                  prefixIcon: Icon(Icons.door_front_door_outlined,
                                      color: AppColors.primary),
                                ),
                                validator: (v) => (v == null || v.isEmpty)
                                    ? 'Room number required'
                                    : null,
                              ),
                              const SizedBox(height: 32),

                              // Create Account button - MEDIUM SIZE
                              Center(
                                child: SizedBox(
                                  width: 300, // Medium width instead of full width
                                  child: Consumer<AuthProvider>(
                                    builder: (context, auth, child) => ElevatedButton(
                                      onPressed: auth.isLoading ? null : _register,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF1B5E40),
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                      ),
                                      child: auth.isLoading
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: const [
                                                Icon(Icons.person_add, size: 18),
                                                SizedBox(width: 8),
                                                Text('Create Account',
                                                    style: TextStyle(
                                                        fontWeight: FontWeight.w700)),
                                              ],
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              
                              // Sign in link
                              Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'Already have an account? ',
                                      style: TextStyle(color: AppColors.textSecondary),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text(
                                        'Sign In',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1B5E40),
                                        ),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebFeature(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Mobile Layout: Original design
  Widget _buildMobileLayout() {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios,
                          color: Colors.white, size: 20),
                    ),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Create Account',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Join the HostelHub community',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Connection Status
                      if (SupabaseConfig.isConfigured)
                        Container(
                          padding: const EdgeInsets.all(14),
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.cloud_done, size: 18, color: AppColors.success),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Connected to Supabase. Your data will be securely stored in the cloud.',
                                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      // Role Selection
                      const Text(
                        'I want to',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _RoleCard(
                              role: UserRole.buyer,
                              selectedRole: _selectedRole,
                              icon: Icons.shopping_bag_outlined,
                              label: 'Buy Items',
                              subtitle: 'Browse & purchase',
                              onTap: () =>
                                  setState(() => _selectedRole = UserRole.buyer),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _RoleCard(
                              role: UserRole.seller,
                              selectedRole: _selectedRole,
                              icon: Icons.sell_outlined,
                              label: 'Sell Items',
                              subtitle: 'List & earn',
                              onTap: () => setState(
                                  () => _selectedRole = UserRole.seller),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      _buildLabel('Full Name'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Your full name',
                          prefixIcon: Icon(Icons.person_outline,
                              color: AppColors.primary),
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 16),

                      _buildLabel('Email Address'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'your@email.com',
                          prefixIcon: Icon(Icons.email_outlined,
                              color: AppColors.primary),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Email required';
                          if (!v.contains('@')) return 'Enter valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      _buildLabel('Phone Number'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          hintText: '10-digit mobile number',
                          prefixIcon: Icon(Icons.phone_outlined,
                              color: AppColors.primary),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Phone required';
                          if (v.length < 10) return 'Enter valid phone number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      _buildLabel('Password'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: 'Create a password',
                          prefixIcon: const Icon(Icons.lock_outline,
                              color: AppColors.primary),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      _buildLabel('Hostel Name'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _hostelCtrl,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Block A Hostel',
                          prefixIcon: Icon(Icons.home_outlined,
                              color: AppColors.primary),
                        ),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Hostel name required'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      _buildLabel('Room Number'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _roomCtrl,
                        decoration: const InputDecoration(
                          hintText: 'e.g. 204',
                          prefixIcon: Icon(Icons.door_front_door_outlined,
                              color: AppColors.primary),
                        ),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Room number required'
                            : null,
                      ),
                      const SizedBox(height: 32),

                      Consumer<AuthProvider>(
                        builder: (context, auth, child) => ElevatedButton(
                          onPressed: auth.isLoading ? null : _register,
                          child: auth.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Create Account'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Already have an account? ',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Sign In'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 13,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final UserRole role;
  final UserRole selectedRole;
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _RoleCard({
    required this.role,
    required this.selectedRole,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = role == selectedRole;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            if (isSelected)
              Icon(Icons.check_circle, size: 16, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
