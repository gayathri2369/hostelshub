import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../providers/chat_provider.dart';
import '../utils/app_colors.dart';
import '../main.dart';

/// Stylish animated slide-in drawer.
/// showDonate = true  → Seller  (shows Donate menu item)
/// showDonate = false → Buyer   (no Donate)
class AppDrawer extends StatefulWidget {
  final bool showDonate;
  const AppDrawer({super.key, this.showDonate = false});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {

  // ── Close drawer then navigate — safe against deactivated context ──────────
  void _closeAndNavigate(String route) {
    // Use root navigator captured NOW (before drawer closes)
    final nav = Navigator.of(context);
    nav.pop();                          // close drawer
    nav.pushNamed(route);               // navigate
  }

  // ── Sign-out: close drawer first, then show dialog from root context ───────
  // Helper: show confirm dialog synchronously-callable before any await
  Future<bool?> _showSignOutDialog(BuildContext ctx) {
    return showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18)),
        title: const Text('Sign Out?'),
        content: const Text('You will need to log in again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut() async {
    // Capture EVERYTHING from context before ANY async gap
    final auth       = context.read<AuthProvider>();
    final products   = context.read<ProductProvider>();
    final chats      = context.read<ChatProvider>();
    final rootNav    = Navigator.of(context, rootNavigator: true);
    final drawerNav  = Navigator.of(context);
    final overlayCtx = rootNav.overlay!.context;

    // 1. Close the drawer (sync)
    drawerNav.pop();

    // 2. Show dialog — uses overlayCtx which is root, always alive
    //    We call via helper to keep this function clean
    await Future.delayed(const Duration(milliseconds: 250));
    // overlayCtx belongs to the root overlay, not the drawer — safe to use after await
    // ignore: use_build_context_synchronously
    final confirm = await _showSignOutDialog(overlayCtx);

    // 3. Perform sign-out
    if (confirm == true) {
      products.reset();
      chats.reset();
      await auth.logout();
      rootNav.pushReplacementNamed(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth     = context.watch<AuthProvider>();
    final user     = auth.currentUser!;
    final isSeller = user.role == UserRole.seller;

    final initials = user.name.trim().split(' ')
        .map((w) => w.isNotEmpty ? w[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return Drawer(
      width: 285,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.horizontal(right: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                  24,
                  MediaQuery.of(context).padding.top + 24,
                  24,
                  28),
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(28),
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Close button
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Avatar
                  Container(
                    width: 68, height: 68,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
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
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  // Role chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isSeller
                          ? '🏪  Seller Account'
                          : '🛍️  Buyer Account',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Menu items ─────────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _DrawerItem(
                    icon: Icons.home_rounded,
                    label: 'Home',
                    subtitle: isSeller
                        ? 'Back to Seller Dashboard'
                        : 'Back to Browse',
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2D6A4F), Color(0xFF52B788)],
                    ),
                    onTap: () {
                      final nav = Navigator.of(context);
                      nav.pop(); // Close drawer
                      // Navigate to appropriate dashboard based on role
                      final targetRoute = isSeller 
                          ? AppRoutes.sellerDashboard 
                          : AppRoutes.buyerDashboard;
                      // Get current route
                      final currentRoute = ModalRoute.of(context)?.settings.name;
                      // Only navigate if not already on target dashboard
                      if (currentRoute != targetRoute) {
                        nav.pushReplacementNamed(targetRoute);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  _DrawerItem(
                    icon: Icons.person_rounded,
                    label: 'Profile',
                    subtitle: 'View & edit your info',
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3A86FF), Color(0xFF60A5FA)],
                    ),
                    onTap: () => _closeAndNavigate(AppRoutes.profile),
                  ),
                  const SizedBox(height: 10),
                  _DrawerItem(
                    icon: Icons.settings_rounded,
                    label: 'Settings',
                    subtitle: 'Notifications & privacy',
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
                    ),
                    onTap: () => _closeAndNavigate(AppRoutes.settings),
                  ),
                  // Donate — Seller only
                  if (widget.showDonate) ...[
                    const SizedBox(height: 10),
                    _DrawerItem(
                      icon: Icons.favorite_rounded,
                      label: 'Donate',
                      subtitle: 'Support HostelHub ❤️',
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF8C42), Color(0xFFFFB380)],
                      ),
                      onTap: () => _closeAndNavigate(AppRoutes.donate),
                    ),
                  ],
                ],
              ),
            ),

            // ── Footer: Sign Out ───────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  MediaQuery.of(context).padding.bottom + 20),
              child: GestureDetector(
                onTap: _signOut,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 14, horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.25)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded,
                          color: AppColors.error, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Sign Out',
                        style: TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
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
    );
  }
}

// ── Individual drawer tile ─────────────────────────────────────────────────────
class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Gradient icon box
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(13),
                boxShadow: [
                  BoxShadow(
                    color:
                        gradient.colors.first.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.textPrimary,
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
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 13, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}
