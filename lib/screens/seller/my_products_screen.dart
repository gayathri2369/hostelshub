import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
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
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser!;
    final allProducts = context.watch<ProductProvider>().productsForSeller(user.id);
    final available = allProducts.where((p) => p.status == ProductStatus.available).toList();
    final sold = allProducts.where((p) => p.status == ProductStatus.sold).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Products'),
        leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(text: 'All (${allProducts.length})'),
            Tab(text: 'Active (${ available.length})'),
            Tab(text: 'Sold (${sold.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ProductListView(products: allProducts),
          _ProductListView(products: available),
          _ProductListView(products: sold),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.sellItem),
        icon: const Icon(Icons.add),
        label: const Text('Sell Item', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _ProductListView extends StatelessWidget {
  final List<ProductModel> products;
  const _ProductListView({required this.products});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            const Text('No products here', style: TextStyle(color: AppColors.textSecondary,
                fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (_, i) => _MyProductCard(product: products[i]),
    );
  }
}

class _MyProductCard extends StatefulWidget {
  final ProductModel product;
  const _MyProductCard({required this.product});
  @override
  State<_MyProductCard> createState() => _MyProductCardState();
}

class _MyProductCardState extends State<_MyProductCard> {
  @override
  Widget build(BuildContext context) {
    final product        = widget.product;
    final isSold         = product.status == ProductStatus.sold;
    final productProvider = context.read<ProductProvider>();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Container(
                  height: 150, width: double.infinity,
                  color: AppColors.primaryLight.withValues(alpha: 0.2),
                  child: product.imageUrls.isNotEmpty
                      ? _ProductImage(
                          imagePath: product.imageUrls[0],
                          fit: BoxFit.cover,
                        )
                      : const Icon(
                          Icons.image_outlined,
                          size: 48,
                          color: AppColors.primaryLight,
                        ),
                ),
              ),
              Positioned(
                top: 10, left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSold ? AppColors.error : AppColors.success,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(product.statusLabel,
                      style: const TextStyle(color: Colors.white, fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.title, style: const TextStyle(fontSize: 15,
                    fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text(product.description, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text('₹${product.price.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                            color: AppColors.primary)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(product.categoryLabel,
                          style: const TextStyle(fontSize: 11, color: AppColors.primary,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (!isSold)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _confirmMarkSold(productProvider),
                          icon: const Icon(Icons.sell_outlined, size: 16),
                          label: const Text('Mark Sold'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.secondary,
                            side: const BorderSide(color: AppColors.secondary),
                            minimumSize: const Size(0, 38),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                      ),
                    if (!isSold) const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _confirmDelete(productProvider),
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: const Text('Delete'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          minimumSize: const Size(0, 38),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
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

  Future<void> _confirmMarkSold(ProductProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Mark as Sold?'),
        content: Text('Mark "${widget.product.title}" as sold?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
              child: const Text('Mark Sold')),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await provider.markAsSold(widget.product.id);
    }
  }

  Future<void> _confirmDelete(ProductProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Listing?'),
        content: Text('Delete "${widget.product.title}" permanently?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await provider.deleteProduct(widget.product.id);
    }
  }
}


// Helper widget to display product images (handles both local files and network URLs)
class _ProductImage extends StatelessWidget {
  final String imagePath;
  final BoxFit fit;

  const _ProductImage({
    required this.imagePath,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    // Check if it's a local file path (contains "/" or "\")
    final isLocalFile = imagePath.startsWith('/') || 
                        imagePath.contains('\\') || 
                        !imagePath.startsWith('http');

    if (isLocalFile) {
      // Display local file image
      return Image.file(
        File(imagePath),
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(
              Icons.image_outlined,
              size: 48,
              color: AppColors.primaryLight,
            ),
          );
        },
      );
    } else {
      // Display network image
      return Image.network(
        imagePath,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(
              Icons.image_outlined,
              size: 48,
              color: AppColors.primaryLight,
            ),
          );
        },
      );
    }
  }
}
