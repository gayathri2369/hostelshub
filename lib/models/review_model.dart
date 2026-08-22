class ReviewModel {
  final String id;
  final String productId;
  final String buyerId;
  final String buyerName;
  final String sellerId;
  final int rating; // 1-5 stars
  final String reviewText;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReviewModel({
    required this.id,
    required this.productId,
    required this.buyerId,
    required this.buyerName,
    required this.sellerId,
    required this.rating,
    required this.reviewText,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert to Supabase format
  Map<String, dynamic> toSupabase() {
    return {
      'product_id': productId,
      'buyer_id': buyerId,
      'seller_id': sellerId,
      'rating': rating,
      'review_text': reviewText,
    };
  }

  // Create from Supabase data
  factory ReviewModel.fromSupabase(Map<String, dynamic> row) {
    return ReviewModel(
      id: row['id'] as String,
      productId: row['product_id'] as String,
      buyerId: row['buyer_id'] as String,
      buyerName: (row['buyer_name'] as String?) ?? 'Anonymous',
      sellerId: row['seller_id'] as String,
      rating: (row['rating'] as int?) ?? 5,
      reviewText: (row['review_text'] as String?) ?? '',
      createdAt: DateTime.parse(
        (row['created_at'] as String?) ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        (row['updated_at'] as String?) ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  // Copy with modifications
  ReviewModel copyWith({
    String? id,
    String? productId,
    String? buyerId,
    String? buyerName,
    String? sellerId,
    int? rating,
    String? reviewText,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      buyerId: buyerId ?? this.buyerId,
      buyerName: buyerName ?? this.buyerName,
      sellerId: sellerId ?? this.sellerId,
      rating: rating ?? this.rating,
      reviewText: reviewText ?? this.reviewText,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Get star rating as string
  String get starRating {
    return '⭐' * rating + '☆' * (5 - rating);
  }

  // Get rating percentage (for progress bars)
  double get ratingPercentage {
    return rating / 5.0;
  }
}
