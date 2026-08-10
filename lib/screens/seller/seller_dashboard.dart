import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/chat_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/back_navigation_guard.dart';
import '../../main.dart';

class SellerDashboard extends StatefulWidget {
  const SellerDashboard({super.key});
  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final products = context.watch<ProductProvider>();
    final chats = context.watch<ChatProvider>();
    final user = auth.currentUser!;
    final myProducts = products.productsForSeller(user.id);
    final sold = myProducts.where((p) => p.status == ProductStatus.sold).length;
    final active = myProducts.where((p) => p.status == ProductStatus.available).length;
    final unread = chats.totalUnreadFor(user.id);

    return BackNavigationGuard(
      isDashboard: true,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.background,
        drawer: const AppDrawer(showDonate: true),
        body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            floating: false,
            automaticallyImplyLeading: false,

            // ── Always-visible title (pinned) ───────────────────────────
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hello, ${user.name.split(' ').first}! 👋',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12,
                        fontWeight: FontWeight.normal)),
                const Text('Seller Dashboard',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800)),
              ],
            ),

            // ── Actions: chat badge + hamburger (always visible) ────────
            actions: [
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.conversations),
                    icon: const Icon(Icons.chat_bubble_outline,
                        color: Colors.white, size: 23),
                    tooltip: 'Messages',
                  ),
                  if (unread > 0)
                    Positioned(
                      right: 6, top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                            color: AppColors.secondary,
                            shape: BoxShape.circle),
                        child: Text('$unread',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
              // ☰ Hamburger — opens stylish drawer
              IconButton(
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                icon: const Icon(Icons.menu_rounded,
                    color: Colors.white, size: 26),
                tooltip: 'Menu',
              ),
              const SizedBox(width: 4),
            ],

            // ── Expanded gradient hero ───────────────────────────────────
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats row
                  Row(
                    children: [
                      _StatCard(label: 'Total Listed', value: '${myProducts.length}',
                          icon: Icons.inventory_2_outlined, color: AppColors.primary),
                      const SizedBox(width: 12),
                      _StatCard(label: 'Active', value: '$active',
                          icon: Icons.check_circle_outline, color: AppColors.success),
                      const SizedBox(width: 12),
                      _StatCard(label: 'Sold', value: '$sold',
                          icon: Icons.sell_outlined, color: AppColors.secondary),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const Text('Quick Actions',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.add_circle_outline,
                          label: 'Sell Item',
                          subtitle: 'List a new product',
                          color: AppColors.primary,
                          onTap: () => Navigator.pushNamed(context, AppRoutes.sellItem),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.inventory_2_outlined,
                          label: 'My Products',
                          subtitle: 'Manage listings',
                          color: AppColors.info,
                          onTap: () => Navigator.pushNamed(context, AppRoutes.myProducts),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.chat_bubble_outline,
                          label: 'Buyer Chats',
                          subtitle: unread > 0 ? '$unread new messages' : 'No new messages',
                          color: AppColors.secondary,
                          badge: unread,
                          onTap: () => Navigator.pushNamed(context, AppRoutes.conversations),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.swap_horiz_rounded,
                          label: 'Switch to Buyer',
                          subtitle: 'Browse products',
                          color: AppColors.warning,
                          onTap: () {
                            auth.switchRole(UserRole.buyer);
                            Navigator.pushReplacementNamed(context, AppRoutes.buyerDashboard);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Recent Listings',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.myProducts),
                        child: const Text('See All'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          myProducts.isEmpty
              ? SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.storefront_outlined, size: 64, color: AppColors.textHint),
                          const SizedBox(height: 16),
                          const Text('No listings yet',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary)),
                          const SizedBox(height: 8),
                          const Text('Use "Sell Item" action above to post your first product',
                              style: TextStyle(color: AppColors.textHint)),
                        ],
                      ),
                    ),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final p = myProducts.take(3).toList()[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        child: _ProductListTile(product: p),
                      );
                    },
                    childCount: myProducts.take(3).length,
                  ),
                ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final int badge;
  final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.label, required this.subtitle,
      required this.color, required this.onTap, this.badge = 0});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            if (badge > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(10)),
                child: Text('$badge', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProductListTile extends StatelessWidget {
  final dynamic product;
  const _ProductListTile({required this.product});

  @override
  Widget build(BuildContext context) {
    final isSold = product.status == ProductStatus.sold;
    return GestureDetector(
      onTap: () {
        // Navigate to product detail screen
        Navigator.pushNamed(
          context,
          AppRoutes.productDetail,
          arguments: product.id,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 56, height: 56,
                color: AppColors.primaryLight.withValues(alpha: 0.2),
                child: const Icon(Icons.image_outlined, color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.title,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text('₹${product.price.toStringAsFixed(0)}',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isSold ? AppColors.error.withValues(alpha: 0.1) : AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(product.statusLabel,
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600,
                      color: isSold ? AppColors.error : AppColors.success)),
            ),
          ],
        ),
      ),
    );
  }
}

