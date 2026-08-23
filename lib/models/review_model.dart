class ReviewModel {
  final String id;
  final String productId;
  final String buyerId;
  final String buyerName;
  final String? buyerEmail;
  final String sellerId;
  final String? sellerName;
  final int rating; // 1-5 stars
  final String? reviewText;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReviewModel({
    required this.id,
    required this.productId,
    required this.buyerId,
    required this.buyerName,
    this.buyerEmail,
    required this.sellerId,
    this.sellerName,
    required this.rating,
    this.reviewText,
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

  // Create from JSON (from Supabase with joins)
  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      buyerId: json['buyer_id'] as String,
      buyerName: json['buyer'] != null 
          ? (json['buyer']['name'] as String? ?? 'Anonymous')
          : 'Anonymous',
      buyerEmail: json['buyer'] != null 
          ? (json['buyer']['email'] as String?)
          : null,
      sellerId: json['seller_id'] as String,
      sellerName: json['seller'] != null 
          ? (json['seller']['name'] as String?)
          : null,
      rating: json['rating'] as int,
      reviewText: json['review_text'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
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
      reviewText: (row['review_text'] as String?),
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
    String? buyerEmail,
    String? sellerId,
    String? sellerName,
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
      buyerEmail: buyerEmail ?? this.buyerEmail,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
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
