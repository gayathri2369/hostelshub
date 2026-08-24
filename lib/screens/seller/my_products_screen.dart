import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../utils/app_colors.dart';
import '../../main.dart';

class MyProductsScreen extends StatefulWidget {
  const MyProductsScreen({super.key});

  @override
  State<MyProductsScreen> createState() => _MyProductsScreenState();
}

class _MyProductsScreenState extends State<MyProductsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 3,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser!;

    final allProducts =
        context.watch<ProductProvider>().productsForSeller(user.id);

    final available = allProducts
        .where((p) => p.status == ProductStatus.available)
        .toList();

    final sold = allProducts
        .where((p) => p.status == ProductStatus.sold)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'My Products',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
          tabs: [
            Tab(
              text: 'All (${allProducts.length})',
            ),
            Tab(
              text: 'Active (${available.length})',
            ),
            Tab(
              text: 'Sold (${sold.length})',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ProductListView(
            products: allProducts,
          ),
          _ProductListView(
            products: available,
          ),
          _ProductListView(
            products: sold,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(
            context,
            AppRoutes.sellItem,
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Sell Item',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// PRODUCT GRID
// ============================================================

class _ProductListView extends StatelessWidget {
  final List<ProductModel> products;

  const _ProductListView({
    required this.products,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(
                    alpha: 0.12,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  size: 44,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'No products here',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your products will appear here',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount;
        double aspectRatio;

        // FIX: aspect ratio now scales with column count instead of
        // being a single fixed 0.73 for every breakpoint. That fixed
        // ratio was too short for 2-column mobile once the badge +
        // 2-line title + price/button row were all present, which is
        // what caused "BOTTOM OVERFLOWED BY N PIXELS".
        if (constraints.maxWidth >= 1200) {
          crossAxisCount = 4;
          aspectRatio = 0.72;
        } else if (constraints.maxWidth >= 700) {
          crossAxisCount = 3;
          aspectRatio = 0.70;
        } else {
          crossAxisCount = 2;
          aspectRatio = 0.62;
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(
            14,
            16,
            14,
            100,
          ),
          physics: const BouncingScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: aspectRatio,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            return _MyProductCard(
              product: products[index],
            );
          },
        );
      },
    );
  }
}

// ============================================================
// PRODUCT CARD
// ============================================================

class _MyProductCard extends StatelessWidget {
  final ProductModel product;

  const _MyProductCard({
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final isSold = product.status == ProductStatus.sold;

    final productProvider = context.read<ProductProvider>();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.black.withValues(
            alpha: 0.06,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.045,
            ),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      // FIX: mainAxisSize.min lets the card be exactly as tall as its
      // content instead of being forced into a rigid Expanded(flex)
      // split between image and details that could overflow.
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==================================================
          // IMAGE SECTION
          // ==================================================
          // FIX: AspectRatio instead of Expanded(flex: 6) inside an
          // unconstrained-height Column — this guarantees the image
          // never eats space the details section needs.
          AspectRatio(
            aspectRatio: 1.05,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  color: AppColors.primaryLight.withValues(
                    alpha: 0.10,
                  ),
                  child: product.imageUrls.isNotEmpty
                      ? _ProductImage(
                          imagePath: product.imageUrls[0],
                          fit: BoxFit.cover,
                        )
                      : Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 42,
                            color: AppColors.primaryLight,
                          ),
                        ),
                ),

                // STATUS BADGE
                Positioned(
                  top: 9,
                  left: 9,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 100),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isSold
                          ? AppColors.error
                          : AppColors.success,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      product.statusLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                // MORE MENU
                Positioned(
                  top: 7,
                  right: 7,
                  child: Material(
                    color: Colors.white,
                    elevation: 2,
                    shape: const CircleBorder(),
                    child: SizedBox(
                      width: 34,
                      height: 34,
                      child: PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        tooltip: 'More options',
                        icon: const Icon(
                          Icons.more_vert_rounded,
                          size: 20,
                          color: AppColors.textPrimary,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onSelected: (value) {
                          if (value == 'sold') {
                            _confirmMarkSold(
                              context,
                              productProvider,
                            );
                          }

                          if (value == 'delete') {
                            _confirmDelete(
                              context,
                              productProvider,
                            );
                          }
                        },
                        itemBuilder: (context) {
                          return [
                            if (!isSold)
                              const PopupMenuItem<String>(
                                value: 'sold',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.sell_outlined,
                                      size: 19,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Mark Sold',
                                      style: TextStyle(
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_outline_rounded,
                                    size: 19,
                                    color: AppColors.error,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'Delete',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.error,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ];
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ==================================================
          // PRODUCT DETAILS
          // ==================================================
          // FIX: no more Expanded(flex: 4) forcing a fixed pixel
          // budget. Padding + mainAxisSize.min means this section
          // simply takes the height it needs.
          Padding(
            padding: const EdgeInsets.fromLTRB(
              10,
              9,
              10,
              9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // CATEGORY
                Container(
                  constraints: const BoxConstraints(
                    maxWidth: 120,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(
                      alpha: 0.12,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    product.categoryLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                // TITLE
                Text(
                  product.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 8),

                // PRICE + VIEW
                // FIX: removed the hardcoded SizedBox(height: 30) +
                // Spacer combo that assumed a specific leftover pixel
                // budget. A plain Row with a fixed-size button and a
                // Flexible price label lays out correctly at any card
                // height.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        '₹${product.price.toStringAsFixed(0)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),

                    const SizedBox(width: 5),

                    SizedBox(
                      height: 30,
                      child: ElevatedButton(
                        onPressed: () {
                          // Add product details navigation here.
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: const Size(0, 30),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                          ),
                          tapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'View',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // MARK SOLD CONFIRMATION
  // ==========================================================

  Future<void> _confirmMarkSold(
    BuildContext context,
    ProductProvider provider,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Mark as Sold?',
            style: TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Mark "${product.title}" as sold?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Mark Sold',
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await provider.markAsSold(
        product.id,
      );
    }
  }

  // ==========================================================
  // DELETE CONFIRMATION
  // ==========================================================

  Future<void> _confirmDelete(
    BuildContext context,
    ProductProvider provider,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Delete Listing?',
            style: TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Delete "${product.title}" permanently?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Delete',
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await provider.deleteProduct(
        product.id,
      );
    }
  }
}

// ============================================================
// PRODUCT IMAGE
// ============================================================

class _ProductImage extends StatelessWidget {
  final String imagePath;
  final BoxFit fit;

  const _ProductImage({
    required this.imagePath,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imagePath,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      placeholder: (context, url) => Container(
        color: AppColors.primaryLight.withValues(alpha: 0.1),
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: AppColors.primaryLight.withValues(alpha: 0.1),
        child: Center(
          child: Icon(
            Icons.image_outlined,
            size: 42,
            color: AppColors.primaryLight,
          ),
        ),
      ),
    );
  }
}