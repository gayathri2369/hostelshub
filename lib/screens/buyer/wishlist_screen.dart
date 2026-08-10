import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../utils/app_colors.dart';
import '../../main.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>().wishlistProducts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wishlist'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${products.length} items',
                    style: const TextStyle(color: Colors.white,
                        fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
      body: products.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite_border_rounded,
                        size: 48, color: AppColors.error),
                  ),
                  const SizedBox(height: 20),
                  const Text('Your wishlist is empty',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  const Text('Tap the heart icon on any product to save it.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: 180,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                      label: const Text('Browse Products'),
                    ),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              itemCount: products.length,
              itemBuilder: (_, i) => _WishlistCard(product: products[i]),
            ),
    );
  }
}

class _WishlistCard extends StatelessWidget {
  final ProductModel product;
  const _WishlistCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ProductProvider>();
    final isSold = product.status == ProductStatus.sold;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.productDetail,
          arguments: product.id),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Container(
                    height: 120, width: double.infinity,
                    color: AppColors.primaryLight.withValues(alpha: 0.15),
                    child: const Icon(Icons.image_outlined,
                        size: 40, color: AppColors.primaryLight),
                  ),
                ),
                if (isSold)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Container(
                        color: Colors.black45,
                        alignment: Alignment.center,
                        child: const Text('SOLD',
                            style: TextStyle(color: Colors.white,
                                fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 2)),
                      ),
                    ),
                  ),
                Positioned(
                  top: 8, right: 8,
                  child: GestureDetector(
                    onTap: () {
                      final uid = context.read<AuthProvider>().currentUser!.id;
                      provider.toggleWishlist(product.id, uid);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.favorite_rounded,
                          size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.title,
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary, height: 1.3)),
                  const SizedBox(height: 6),
                  Text('₹${product.price.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                          color: isSold ? AppColors.textSecondary : AppColors.primary)),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.person_outline,
                        size: 11, color: AppColors.textSecondary),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(product.sellerName,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
