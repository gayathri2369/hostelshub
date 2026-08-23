import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../models/product_model.dart';
import '../../models/review_model.dart';
import '../../providers/product_provider.dart';
import '../../providers/review_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';
import 'product_reviews_screen.dart';
import 'review_submission_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch reviews for this product
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReviewProvider>().fetchReviewsForProduct(widget.productId);
    });
  }

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
                  
                  // ── Rating & Reviews Section ────────────────────────────────
                  _ReviewSection(product: product),
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

class _ReviewSection extends StatelessWidget {
  final ProductModel product;
  const _ReviewSection({required this.product});

  @override
  Widget build(BuildContext context) {
    final reviews = context.watch<ReviewProvider>();
    final auth = context.watch<AuthProvider>();
    final currentUser = auth.currentUser;
    
    final productReviews = reviews.getReviewsForProduct(product.id);
    final hasReviews = productReviews.isNotEmpty;
    
    // Check if user has reviewed
    final userReview = currentUser != null
        ? reviews.getUserReview(product.id, currentUser.id)
        : null;
    
    // Get top 3 recent reviews for preview
    final previewReviews = productReviews.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _SectionLabel(text: 'Ratings & Reviews'),
            if (hasReviews)
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductReviewsScreen(product: product),
                    ),
                  );
                },
                child: const Text('See All'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Rating Summary Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Average Rating
              Column(
                children: [
                  Text(
                    product.averageRating.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Row(
                    children: List.generate(5, (index) {
                      final starValue = index + 1;
                      return Icon(
                        starValue <= product.averageRating
                            ? Icons.star_rounded
                            : starValue - 0.5 <= product.averageRating
                                ? Icons.star_half_rounded
                                : Icons.star_border_rounded,
                        color: Colors.amber,
                        size: 20,
                      );
                    }),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${product.totalReviews} ${product.totalReviews == 1 ? 'review' : 'reviews'}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              
              // Rating Bar Preview
              Expanded(
                child: Column(
                  children: [
                    _RatingBar(rating: 5, count: productReviews.where((r) => r.rating == 5).length, total: product.totalReviews),
                    const SizedBox(height: 4),
                    _RatingBar(rating: 4, count: productReviews.where((r) => r.rating == 4).length, total: product.totalReviews),
                    const SizedBox(height: 4),
                    _RatingBar(rating: 3, count: productReviews.where((r) => r.rating == 3).length, total: product.totalReviews),
                    const SizedBox(height: 4),
                    _RatingBar(rating: 2, count: productReviews.where((r) => r.rating == 2).length, total: product.totalReviews),
                    const SizedBox(height: 4),
                    _RatingBar(rating: 1, count: productReviews.where((r) => r.rating == 1).length, total: product.totalReviews),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Write Review Button (if user hasn't reviewed)
        if (currentUser != null && userReview == null)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReviewSubmissionScreen(product: product),
                  ),
                );
                if (result == true) {
                  // Refresh reviews
                  // ignore: use_build_context_synchronously
                  context.read<ReviewProvider>().fetchReviewsForProduct(product.id);
                }
              },
              icon: const Icon(Icons.rate_review),
              label: const Text('Write a Review'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        
        // User's Review Preview (if exists)
        if (userReview != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Your Review',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReviewSubmissionScreen(
                              product: product,
                              existingReview: userReview,
                            ),
                          ),
                        );
                        if (result == true) {
                          // ignore: use_build_context_synchronously
                          context.read<ReviewProvider>().fetchReviewsForProduct(product.id);
                        }
                      },
                      child: const Text('Edit'),
                    ),
                  ],
                ),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < userReview.rating ? Icons.star_rounded : Icons.star_border_rounded,
                      size: 16,
                      color: Colors.amber,
                    );
                  }),
                ),
                if (userReview.reviewText != null && userReview.reviewText!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    userReview.reviewText!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        // Recent Reviews Preview
        if (previewReviews.isNotEmpty && userReview == null) ...[
          const Text(
            'Recent Reviews',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ...previewReviews.map((review) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ReviewPreviewCard(review: review),
          )),
        ] else if (previewReviews.length > 1) ...[
          // Show other reviews if user has reviewed
          const Text(
            'Other Reviews',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ...previewReviews.where((r) => r.id != userReview?.id).take(2).map((review) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ReviewPreviewCard(review: review),
          )),
        ],
        
        // No Reviews Yet
        if (!hasReviews)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.rate_review_outlined, size: 48, color: AppColors.textHint),
                  const SizedBox(height: 12),
                  const Text(
                    'No reviews yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Be the first to review this product!',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _RatingBar extends StatelessWidget {
  final int rating;
  final int count;
  final int total;

  const _RatingBar({
    required this.rating,
    required this.count,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total == 0 ? 0.0 : count / total;
    
    return Row(
      children: [
        Text(
          '$rating',
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.star, size: 12, color: Colors.amber),
        const SizedBox(width: 6),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 20,
          child: Text(
            '$count',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white70,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReviewPreviewCard extends StatelessWidget {
  final ReviewModel review;

  const _ReviewPreviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    review.buyerName[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.buyerName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < review.rating ? Icons.star_rounded : Icons.star_border_rounded,
                          size: 12,
                          color: Colors.amber,
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (review.reviewText != null && review.reviewText!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              review.reviewText!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
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
