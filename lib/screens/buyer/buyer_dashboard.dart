import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/chat_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/back_navigation_guard.dart';
import '../../widgets/enhanced_product_card.dart';
import '../../main.dart';

class BuyerDashboard extends StatefulWidget {
  const BuyerDashboard({super.key});
  @override
  State<BuyerDashboard> createState() => _BuyerDashboardState();
}

class _BuyerDashboardState extends State<BuyerDashboard> {
  final _searchCtrl = TextEditingController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth     = context.watch<AuthProvider>();
    final products = context.watch<ProductProvider>();
    final chats    = context.watch<ChatProvider>();
    final user     = auth.currentUser!;
    final unread   = chats.totalUnreadFor(user.id);
    final filtered = products.filteredProducts;

    return BackNavigationGuard(
      isDashboard: true,
      child: kIsWeb ? _buildWebLayout(context, auth, products, chats, user, unread, filtered) : _buildMobileLayout(context, auth, products, chats, user, unread, filtered),
    );
  }

  // Web Layout: Sidebar + Main Content
  Widget _buildWebLayout(BuildContext context, AuthProvider auth, ProductProvider products, ChatProvider chats, UserModel user, int unread, List<ProductModel> filtered) {
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
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'T',
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
                        user.name.split(' ').first,
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
                          color: const Color(0xFFFF8C42),
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
                          isActive: true,
                          subtitle: 'Back to Browse',
                          onTap: () {},
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
                          onTap: () => Navigator.pushNamed(context, AppRoutes.donate),
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
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await auth.logout();
                              if (context.mounted) {
                                Navigator.pushReplacementNamed(context, AppRoutes.login);
                              }
                            },
                            icon: const Icon(Icons.logout, size: 16),
                            label: const Text('Sign Out'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white54),
                              minimumSize: const Size(double.infinity, 40),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Main Content Area
          Expanded(
            child: Column(
              children: [
                // Top Bar with Search
                Container(
                  padding: const EdgeInsets.all(20),
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
                      const Row(
                        children: [
                          Icon(Icons.home_work_rounded, color: AppColors.primary, size: 28),
                          SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'HostelHub',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(width: 40),
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: (v) => products.setSearchQuery(v),
                            decoration: InputDecoration(
                              hintText: 'Search for items to donate...',
                              hintStyle: const TextStyle(
                                color: AppColors.textHint,
                                fontSize: 14,
                              ),
                              prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                              suffixIcon: _searchCtrl.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18, color: AppColors.textSecondary),
                                      onPressed: () {
                                        _searchCtrl.clear();
                                        products.setSearchQuery('');
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Text(
                        'Hello, ${user.name.split(' ').first}! 👋',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
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
                
                // Category Tabs
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildWebCategoryTab(Icons.apps_rounded, 'All', products.selectedCategory == null, 
                            () => products.setCategory(null)),
                        _buildWebCategoryTab(Icons.menu_book_outlined, 'Books', products.selectedCategory == ProductCategory.books, 
                            () => products.setCategory(ProductCategory.books)),
                        _buildWebCategoryTab(Icons.checkroom_outlined, 'Clothing', products.selectedCategory == ProductCategory.clothing, 
                            () => products.setCategory(ProductCategory.clothing)),
                        _buildWebCategoryTab(Icons.devices_outlined, 'Electronics', products.selectedCategory == ProductCategory.electronics, 
                            () => products.setCategory(ProductCategory.electronics)),
                        _buildWebCategoryTab(Icons.chair_outlined, 'Furniture', products.selectedCategory == ProductCategory.furniture, 
                            () => products.setCategory(ProductCategory.furniture)),
                        _buildWebCategoryTab(Icons.kitchen_outlined, 'Kitchen', products.selectedCategory == ProductCategory.kitchenware, 
                            () => products.setCategory(ProductCategory.kitchenware)),
                        _buildWebCategoryTab(Icons.sports_soccer_outlined, 'Sports', products.selectedCategory == ProductCategory.sports, 
                            () => products.setCategory(ProductCategory.sports)),
                        _buildWebCategoryTab(Icons.edit_outlined, 'Stationery', products.selectedCategory == ProductCategory.stationery, 
                            () => products.setCategory(ProductCategory.stationery)),
                        _buildWebCategoryTab(Icons.category_outlined, 'Other', products.selectedCategory == ProductCategory.other, 
                            () => products.setCategory(ProductCategory.other)),
                      ],
                    ),
                  ),
                ),
                
                // Main Content - Scrollable
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Products Count Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              products.selectedCategory != null || products.searchQuery.isNotEmpty
                                  ? '${filtered.length} results'
                                  : 'All Products (${filtered.length})',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (products.selectedCategory != null || products.searchQuery.isNotEmpty)
                              TextButton.icon(
                                onPressed: () {
                                  products.clearFilters();
                                  _searchCtrl.clear();
                                },
                                icon: const Icon(Icons.close, size: 16),
                                label: const Text('Clear filters'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // Products Grid or Empty State
                        filtered.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(60),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.search_off_rounded,
                                          size: 80, color: AppColors.textHint),
                                      const SizedBox(height: 20),
                                      const Text('No products found',
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textSecondary)),
                                      const SizedBox(height: 12),
                                      TextButton(
                                        onPressed: () {
                                          products.clearFilters();
                                          _searchCtrl.clear();
                                        },
                                        child: const Text('Clear filters'),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 0.75,
                                ),
                                itemCount: filtered.length,
                                itemBuilder: (_, i) => EnhancedProductCard(
                                  product: filtered[i],
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    AppRoutes.productDetail,
                                    arguments: filtered[i].id,
                                  ),
                                  onWishlistToggle: () {
                                    final uid = context.read<AuthProvider>().currentUser!.id;
                                    products.toggleWishlist(filtered[i].id, uid);
                                  },
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

  Widget _buildWebCategoryTab(IconData icon, String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.border,
            width: 1.5,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Mobile Layout: Original design
  Widget _buildMobileLayout(BuildContext context, AuthProvider auth, ProductProvider products, ChatProvider chats, UserModel user, int unread, List<ProductModel> filtered) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(showDonate: false),
      body: CustomScrollView(
        slivers: [
          // ── Pinned SliverAppBar with hamburger in actions ────────────────
          SliverAppBar(
            expandedHeight: 130,
            pinned: true,
            floating: false,
            automaticallyImplyLeading: false,

            // ── Always-visible toolbar row (pinned) ──────────────────────
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hello, ${user.name.split(' ').first}! 👋',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12,
                        fontWeight: FontWeight.normal)),
                const Text('Find great deals',
                    style: TextStyle(color: Colors.white,
                        fontSize: 17, fontWeight: FontWeight.w800)),
              ],
            ),

            // ── Actions: chat badge + wishlist + hamburger (always visible) ─
            actions: [
              // Chat with unread badge
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
              // Wishlist
              IconButton(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.wishlist),
                icon: const Icon(Icons.favorite_border,
                    color: Colors.white, size: 23),
                tooltip: 'Wishlist',
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

            // ── Expanded hero area ───────────────────────────────────────
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient),
              ),
            ),

            // ── Pinned search bar ────────────────────────────────────────
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(58),
              child: Container(
                color: AppColors.primary,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: _SearchBar(
                  controller: _searchCtrl,
                  onChanged: (v) => products.setSearchQuery(v),
                ),
              ),
            ),
          ),

          // ── Category chips ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _CategoryRow(
              selected: products.selectedCategory,
              onSelected: (cat) => products.setCategory(cat),
            ),
          ),

          // ── Count / clear row ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    products.selectedCategory != null ||
                            products.searchQuery.isNotEmpty
                        ? '${filtered.length} results'
                        : 'All Products (${filtered.length})',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.textPrimary),
                  ),
                  if (products.selectedCategory != null ||
                      products.searchQuery.isNotEmpty)
                    TextButton.icon(
                      onPressed: () {
                        products.clearFilters();
                        _searchCtrl.clear();
                      },
                      icon: const Icon(Icons.close, size: 14),
                      label: const Text('Clear',
                          style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
            ),
          ),

          // ── Product grid ─────────────────────────────────────────────────
          filtered.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded,
                            size: 64, color: AppColors.textHint),
                        const SizedBox(height: 16),
                        const Text('No products found',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary)),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            products.clearFilters();
                            _searchCtrl.clear();
                          },
                          child: const Text('Clear filters'),
                        ),
                      ],
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => EnhancedProductCard(
                        product: filtered[i],
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.productDetail,
                          arguments: filtered[i].id,
                        ),
                        onWishlistToggle: () {
                          final uid = context.read<AuthProvider>().currentUser!.id;
                          products.toggleWishlist(filtered[i].id, uid);
                        },
                      ),
                      childCount: filtered.length,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                  ),
                ),

          // ── Switch to Seller banner ───────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              child: GestureDetector(
                onTap: () async {
                  await auth.switchRole(UserRole.seller);
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(
                        context, AppRoutes.sellerDashboard);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFFFF8C42), Color(0xFFFFB380)]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.sell_outlined,
                          color: Colors.white, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Have something to sell?',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14)),
                            Text('Switch to Seller mode',
                                style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded,
                          color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Search Bar ───────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search products, books, electronics...',
          hintStyle: const TextStyle(
              color: AppColors.textHint, fontSize: 13),
          prefixIcon: const Icon(Icons.search,
              color: AppColors.primary, size: 20),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear,
                      size: 18, color: AppColors.textSecondary),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

// ─── Category Chips ───────────────────────────────────────────────────────────
class _CategoryRow extends StatelessWidget {
  final ProductCategory? selected;
  final ValueChanged<ProductCategory?> onSelected;
  const _CategoryRow(
      {required this.selected, required this.onSelected});

  static const _cats = [
    (null, Icons.apps_rounded, 'All'),
    (ProductCategory.electronics, Icons.devices_outlined, 'Electronics'),
    (ProductCategory.books, Icons.menu_book_outlined, 'Books'),
    (ProductCategory.clothing, Icons.checkroom_outlined, 'Clothing'),
    (ProductCategory.furniture, Icons.chair_outlined, 'Furniture'),
    (ProductCategory.kitchenware, Icons.kitchen_outlined, 'Kitchen'),
    (ProductCategory.sports, Icons.sports_soccer_outlined, 'Sports'),
    (ProductCategory.stationery, Icons.edit_outlined, 'Stationery'),
    (ProductCategory.other, Icons.category_outlined, 'Other'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SizedBox(
        height: 80,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _cats.length,
          itemBuilder: (_, i) {
            final (cat, icon, label) = _cats[i];
            final isSelected = selected == cat;
            return GestureDetector(
              onTap: () => onSelected(cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color:
                      isSelected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.border,
                      width: 1.5),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                              color: AppColors.primary
                                  .withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 2))
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon,
                        size: 22,
                        color: isSelected
                            ? Colors.white
                            : AppColors.primary),
                    const SizedBox(height: 4),
                    Text(label,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
