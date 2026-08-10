import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';
import '../../utils/app_colors.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final product = context.watch<ProductProvider>().getProductById(widget.productId);

    if (product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Product Detail')),
        body: const Center(child: Text('Product not found.')),
      );
    }

    final isSold = product.status == ProductStatus.sold;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Hero image app bar ────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            leading: Padding(
              padding: const EdgeInsets.all(6),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: AppColors.primary, size: 18),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  product.imageUrls.isNotEmpty
                      ? _ProductImage(
                          imagePath: product.imageUrls[0],
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: AppColors.primaryLight.withValues(alpha: 0.2),
                          child: const Icon(Icons.image_outlined, size: 80,
                              color: AppColors.primaryLight),
                        ),
                  if (isSold)
                    Container(
                      color: Colors.black54,
                      child: const Center(
                        child: Text('SOLD', style: TextStyle(color: Colors.white,
                            fontSize: 36, fontWeight: FontWeight.w900,
                            letterSpacing: 4)),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Content ───────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(product.title,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary, height: 1.2)),
                      ),
                      const SizedBox(width: 12),
                      Text('₹${product.price.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800,
                              color: AppColors.primary)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Badges
                  Wrap(
                    spacing: 8,
                    children: [
                      _Badge(label: product.categoryLabel,
                          color: AppColors.primary, icon: Icons.category_outlined),
                      _Badge(
                        label: product.statusLabel,
                        color: isSold ? AppColors.error : AppColors.success,
                        icon: isSold ? Icons.cancel_outlined : Icons.check_circle_outline,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const _SectionLabel(text: 'Description'),
                  const SizedBox(height: 8),
                  Text(product.description,
                      style: const TextStyle(color: AppColors.textSecondary,
                          fontSize: 14, height: 1.6)),
                  const SizedBox(height: 24),
                  const _SectionLabel(text: 'Seller Info'),
                  const SizedBox(height: 12),
                  _SellerCard(product: product),
                  const SizedBox(height: 24),
                  const _SectionLabel(text: 'Posted On'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(_formatDate(product.createdAt),
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
          color: AppColors.textPrimary, letterSpacing: 0.3));
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _Badge({required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ));
}

class _SellerCard extends StatelessWidget {
  final ProductModel product;
  const _SellerCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
            child: Text(product.sellerName[0].toUpperCase(),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                    color: AppColors.primary)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.sellerName,
                    style: const TextStyle(fontWeight: FontWeight.w700,
                        fontSize: 15, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Row(children: [
                  const Icon(Icons.home_outlined, size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(product.sellerHostel,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ]),
                const SizedBox(height: 2),
                Row(children: [
                  const Icon(Icons.phone_outlined, size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(product.sellerPhone,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
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
    // Check if it's a local file path
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
          return Container(
            color: AppColors.primaryLight.withValues(alpha: 0.2),
            child: const Center(
              child: Icon(
                Icons.image_outlined,
                size: 80,
                color: AppColors.primaryLight,
              ),
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
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.primary,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: AppColors.primaryLight.withValues(alpha: 0.2),
            child: const Center(
              child: Icon(
                Icons.image_outlined,
                size: 80,
                color: AppColors.primaryLight,
              ),
            ),
          );
        },
      );
    }
  }
}
