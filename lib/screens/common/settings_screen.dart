import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/chat_provider.dart';
import '../../utils/app_colors.dart';
import '../../main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifyChats    = true;
  bool _notifyListings = true;
  bool _notifyOffers   = false;
  bool _showPhone      = true;
  bool _showHostel     = true;

  @override
  Widget build(BuildContext context) {
    return kIsWeb ? _buildWebLayout() : _buildMobileLayout();
  }

  // Web Layout with Sidebar
  Widget _buildWebLayout() {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser!;

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
                        child: Center(
                          child: Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
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
                          color: user.role == UserRole.seller ? const Color(0xFFFF8C42) : AppColors.info,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.account_circle, size: 14, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              user.role == UserRole.seller ? 'Seller Account' : 'Buyer Account',
                              style: const TextStyle(
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
                          onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.profile),
                        ),
                        _buildWebMenuItem(
                          icon: Icons.volunteer_activism_outlined,
                          label: 'My Donations',
                          subtitle: 'Track your donations',
                          onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.donate),
                        ),
                        _buildWebMenuItem(
                          icon: Icons.favorite_outline,
                          label: 'Favorites',
                          subtitle: 'Your saved items',
                          onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.wishlist),
                        ),
                        _buildWebMenuItem(
                          icon: Icons.settings_outlined,
                          label: 'Settings',
                          subtitle: 'Notifications & privacy',
                          isActive: true,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Sign Out Button
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: OutlinedButton.icon(
                    onPressed: () => _handleSignOut(context, auth),
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Sign Out'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          
          // Main Content Area
          Expanded(
            child: Column(
              children: [
                // Top Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
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
                      const Icon(Icons.settings, color: AppColors.primary, size: 28),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Settings',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Manage your preferences and account settings',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSettingsContent(),
                        ],
                      ),
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

  // Mobile Layout
  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: ListView(
        children: [
          _buildSettingsContent(),
          // ── Logout ───────────────────────────────────────────────────────
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            child: OutlinedButton.icon(
              onPressed: () => _handleSignOut(context, context.read<AuthProvider>()),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Sign Out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Settings Content (shared between web and mobile)
  Widget _buildSettingsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Notifications ────────────────────────────────────────────────
        _SectionHeader(title: 'Notifications', icon: Icons.notifications_outlined),
        _SwitchTile(
          icon: Icons.chat_bubble_outline,
          iconColor: AppColors.primary,
          title: 'Chat Messages',
          subtitle: 'Notify when you receive a message',
          value: _notifyChats,
          onChanged: (v) => setState(() => _notifyChats = v),
        ),
        _SwitchTile(
          icon: Icons.inventory_2_outlined,
          iconColor: AppColors.info,
          title: 'New Listings',
          subtitle: 'Notify when new products are posted',
          value: _notifyListings,
          onChanged: (v) => setState(() => _notifyListings = v),
        ),
        _SwitchTile(
          icon: Icons.local_offer_outlined,
          iconColor: AppColors.secondary,
          title: 'Offers & Deals',
          subtitle: 'Notify about price drops and special offers',
          value: _notifyOffers,
          onChanged: (v) => setState(() => _notifyOffers = v),
        ),

        // ── Privacy ──────────────────────────────────────────────────────
        _SectionHeader(title: 'Privacy', icon: Icons.lock_outline),
        _SwitchTile(
          icon: Icons.phone_outlined,
          iconColor: AppColors.success,
          title: 'Show Phone Number',
          subtitle: 'Visible to buyers on product detail',
          value: _showPhone,
          onChanged: (v) => setState(() => _showPhone = v),
        ),
        _SwitchTile(
          icon: Icons.home_outlined,
          iconColor: AppColors.warning,
          title: 'Show Hostel Name',
          subtitle: 'Visible to other users',
          value: _showHostel,
          onChanged: (v) => setState(() => _showHostel = v),
        ),

        // ── Account ──────────────────────────────────────────────────────
        _SectionHeader(title: 'Account', icon: Icons.manage_accounts_outlined),
        _NavTile(
          icon: Icons.person_outline,
          iconColor: AppColors.primary,
          title: 'Edit Profile',
          subtitle: 'Update your personal information',
          onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
        ),
        _NavTile(
          icon: Icons.favorite_outline,
          iconColor: AppColors.error,
          title: 'Donate to HostelHub',
          subtitle: 'Support the platform and community',
          onTap: () => Navigator.pushNamed(context, AppRoutes.donate),
        ),

        // ── About ─────────────────────────────────────────────────────────
        _SectionHeader(title: 'About', icon: Icons.info_outline),
        _NavTile(
          icon: Icons.code_rounded,
          iconColor: AppColors.info,
          title: 'Version',
          subtitle: 'HostelHub v1.0.0',
          onTap: () {},
          trailing: const Text('1.0.0',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ),
        _NavTile(
          icon: Icons.description_outlined,
          iconColor: AppColors.textSecondary,
          title: 'Terms & Conditions',
          subtitle: 'Read our terms of service',
          onTap: () => _showInfoDialog(context, 'Terms & Conditions',
              'By using HostelHub, you agree to use the platform responsibly. '
              'All transactions are between users. HostelHub is not responsible '
              'for product quality or disputes.'),
        ),
        _NavTile(
          icon: Icons.privacy_tip_outlined,
          iconColor: AppColors.textSecondary,
          title: 'Privacy Policy',
          subtitle: 'Learn how we protect your data',
          onTap: () => _showInfoDialog(context, 'Privacy Policy',
              'We store your profile and listing data locally on your device. '
              'We do not share your personal information with third parties. '
              'Your phone number is only visible to buyers of your products.'),
        ),
      ],
    );
  }

  // Web Menu Item
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

  // Handle Sign Out
  Future<void> _handleSignOut(BuildContext context, AuthProvider auth) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out?'),
        content: const Text('You will need to log in again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      context.read<ProductProvider>().reset();
      context.read<ChatProvider>().reset();
      await auth.logout();
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    }
  }

  void _showInfoDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content,
            style: const TextStyle(height: 1.6, color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

// ── Shared tile widgets ───────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(title, style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w700,
            color: AppColors.primary, letterSpacing: 0.8,
          )),
        ],
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon, required this.iconColor,
    required this.title, required this.subtitle,
    required this.value, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: SwitchListTile(
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(title, style: const TextStyle(
            fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(
            fontSize: 12, color: AppColors.textSecondary)),
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  const _NavTile({
    required this.icon, required this.iconColor,
    required this.title, required this.subtitle,
    required this.onTap, this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(title, style: const TextStyle(
            fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(
            fontSize: 12, color: AppColors.textSecondary)),
        trailing: trailing ?? const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14, color: AppColors.textSecondary),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}
